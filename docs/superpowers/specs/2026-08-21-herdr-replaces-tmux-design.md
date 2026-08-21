# herdr replaces tmux for Ghostty agent and worktree work

Date: 2026-08-21
Status: Approved design, ready for implementation plan

## Goal

Move the primary workflow back to Ghostty and replace tmux with
[herdr](https://herdr.dev) as the terminal multiplexer. herdr adds first-class
agent state and git worktree management. The target is a Ghostty experience
close to the current Supacode setup at `~/Work/optura/intent`: create a
worktree, run coding agents in it, edit in the terminal, tear the worktree down
cleanly.

herdr is "tmux for agents": a single Rust binary, a headless server for
persistence, `ctrl+b` prefix, panes and splits, plus `herdr worktree create`
and `worktree.created` / `worktree.removed` lifecycle events.

## Decisions

| Decision | Choice |
| --- | --- |
| Scope | Full swap. herdr becomes the default multiplexer Ghostty launches. |
| Worktree ownership | herdr owns worktree creation. Retire `wt` (approach B swaps it for a thin `hw`, not full removal — see Worktree location). |
| Editing | Terminal-only. Each worktree workspace has an nvim pane. No Zed. |
| Agents | `claude` and `codex`. |
| Bootstrap | A fresh worktree needs setup (env, docs, deps, dev DB). |
| Worktree location | Keep in-repo at `<repo>/.claude/worktrees/<branch>`. |
| tmux | Kept dormant one week for rollback, then deleted. |

## Current state (facts gathered)

- `scripts/ghostty-shell` branches by host app. Supacode terminals run `fish`
  with no multiplexer (`SUPACODE_SOCKET_PATH` is set). Plain Ghostty runs
  `fish --login -c "tmux attach -t default || tmux new -s default"`.
- `ghostty/config` maps `super+*` keys to text that sends the tmux prefix
  `ctrl+b` (`\x02`) plus a command letter.
- The current worktree lifecycle at intent is the rich `wt` / Zed flow, not
  Conductor's bare `npm i`:
  - Create (`intent/.zed/worktree-setup.sh`): symlink `.env` to main's `.env`;
    rsync main's gitignored `docs/` (ADRs, specs) in; `npm install`;
    `npx vite-node scripts/worktree/db-restore.ts` for a per-branch dev DB.
  - Teardown (`fish/functions/wtrm.fish`): `salvage-docs.ts` rsyncs new ADRs
    back to main; `db-drop.ts` drops the branch DB; `git worktree remove` plus
    delete the branch.
- `intent/.conductor/settings.local.toml` sets Conductor's own setup to
  `npm i` and run to `npm run dev`. This is the minimal path, superseded by the
  rich flow above.
- herdr is not installed yet. Supacode is installed at
  `/Applications/supacode.app`.

## herdr facts (from docs, to confirm on the binary)

- Install: `curl -fsSL https://herdr.dev/install.sh | sh`. One ~10 MB binary,
  no dependencies.
- Config: `config.toml`. Print defaults with `herdr --default-config`.
- Known sections: `[terminal] default_shell`, `[worktrees] directory`,
  `[server]`, `[theme]`, `[keys.*]`, `[ui]`.
- `[worktrees] directory` is a single global base. herdr creates checkouts
  under `<directory>/<repo>/<branch-slug>`. Relative values resolve to an
  absolute path when the app applies the config.
- Default worktree keys: `new_worktree = "prefix+shift+g"`,
  `open_worktree = "prefix+shift+o"`, `remove_worktree = "prefix+alt+d"`.
- Lifecycle events `worktree.created` and `worktree.opened` fire so a layout or
  setup step can run. Docs also describe teardown on removal with template
  variables `{{ branch }}` and `{{ worktree_path }}`. Core vs plugin support is
  not certain from the docs — the verify gate settles it.

## Architecture

Six units, each with one job.

### 1. Shell entry — `scripts/ghostty-shell`

Keep the host branch. Supacode stays `fish`, no change. The Ghostty branch
launches herdr instead of tmux: attach the default session, else create it.
herdr's headless server keeps panes alive across Ghostty restarts, the same
role the tmux `default` session played.

Depends on: herdr installed and on `PATH`; the exact attach/new subcommand
(confirm on the binary).

### 2. herdr config — `config.toml` (tracked in dotfiles)

Seed from `herdr --default-config`, then set:

- `[terminal] default_shell = "fish"`.
- Worktree base pointing at the repo's `.claude/worktrees` (see the worktree
  location note below).
- A default workspace layout, one tab, three panes — `claude`, `codex`,
  `nvim` — each with the worktree as its working directory. The layout applies
  on `worktree.opened` so both a new worktree and an existing one reopened get
  their panes. A new worktree fires `worktree.created` first, then
  `worktree.opened`.
- Keybindings section (see unit 5).

**Ordering — must hold.** The `worktree.created` bootstrap (unit 3) must finish
before the layout's agent panes start. Otherwise `claude` and `codex` launch in
a worktree with no `.env` and no `node_modules`, and the first run breaks. The
plan must guarantee this — a synchronous `created` hook that completes before
`opened` applies the layout, or an agent-pane command that waits for a ready
signal `setup.sh` writes.

Depends on: the config file path (confirm on the binary); whether the layout is
core config or needs a plugin.

### 3. Per-repo lifecycle scripts — in the intent repo

The dotfiles herdr hooks stay generic. They only call a repo-owned script if it
exists, so no repo detail leaks into dotfiles. This mirrors the old
`.zed/worktree-setup.sh` convention, moved off Zed.

- `worktree.created` hook runs `$repo/.herdr/setup.sh "$worktree_path" "$branch"`.
- `worktree.removed` hook runs `$repo/.herdr/teardown.sh "$worktree_path" "$branch"`.

`intent/.herdr/setup.sh` reproduces the create flow: symlink `.env`, rsync main's
`docs/` in, `npm install`, `db-restore.ts`. If herdr checks out a named branch,
the script drops the detached-HEAD branch parsing the Zed version needed and
takes the branch as an argument. If herdr leaves a detached HEAD, the script
keeps that parsing. The verify gate settles which.

`intent/.herdr/teardown.sh` reproduces the teardown: `salvage-docs.ts`, then
`db-drop.ts`.

Depends on: herdr firing both events with `{{ branch }}` and
`{{ worktree_path }}` (verify gate).

### 4. Retire `wt` and `wtrm`

herdr owns worktree create and remove. The logic moves into the intent repo's
`.herdr/setup.sh` and `.herdr/teardown.sh`. Keep `fish/functions/wt.fish` and
`fish/functions/wtrm.fish` dormant for one week as a rollback, then delete them.

### 5. Keybindings — `ghostty/config`

Ghostty `super+*` keys already send the prefix `ctrl+b`. herdr's default prefix
is also `ctrl+b`, so split and tab navigation whose letters match tmux keeps
working. A follow-up pass remaps the herdr command letters that differ and adds
the worktree keys (`super+shift+g` create, `super+shift+o` open,
`super+alt+d` remove). This pass runs after the core swap works, not before.

### 6. Decommission tmux

Full swap. `ghostty-shell` stops launching tmux. Keep `tmux/`, `tmux.conf`, and
the `super+*` bindings in the repo but dormant for one trial week — instant
rollback by reverting `ghostty-shell`. Delete tmux config after herdr proves
out.

## Worktree location

Worktrees stay in-repo at `<repo>/.claude/worktrees/<branch>`. herdr's
`[worktrees] directory` is a single global base that yields
`<directory>/<repo>/<branch-slug>`, which is not the in-repo layout. Two paths,
chosen by the verify gate:

- If `directory` accepts a per-repo template (for example
  `{{ repo_root }}/.claude/worktrees`), set it. herdr stays native (approach A).
- If `directory` is global-only, add a thin `hw <branch>` fish function
  (approach B). It cuts the worktree at `.claude/worktrees/<branch>`, then hands
  the path to herdr for the layout and agents. herdr still runs everything; it
  only gives up choosing the path.

The intent lifecycle scripts derive main via `git --git-common-dir` and the DB
name from the branch, not a hardcoded path, so both paths work without editing
those scripts.

## Verify gate — first step of the implementation plan

Install herdr, run `herdr --default-config`, and confirm on the real binary,
before any config or script edit:

1. Config file path and format.
2. Whether `[worktrees] directory` accepts a per-repo template. Decides
   approach A vs B for worktree location.
3. That `worktree.created`, `worktree.opened`, and `worktree.removed` fire with
   `{{ branch }}` and `{{ worktree_path }}`. A missing `worktree.removed` moves
   teardown to an `hw-rm` fish function fallback.
4. Whether a `worktree.created` hook completes before the `worktree.opened`
   layout applies, or the agent panes need a ready-signal wait. Decides the
   ordering guarantee in unit 2.
5. Whether herdr checks out a named branch or a detached HEAD. Decides whether
   `setup.sh` keeps the branch parsing.
6. Whether the workspace layout is core config or needs a plugin.
7. The attach / new-session subcommand for `ghostty-shell`.
8. The prefix and worktree keybinding names.

Findings feed the plan. The plan does not assume any uncertain key.

## Constraints

- dotfiles must stay multi-arch (macOS ARM, Intel, Debian). Never hardcode a
  machine path in dotfiles. Repo-specific detail lives in the target repo's
  `.herdr/` scripts, not in dotfiles.
- Utility scripts stay in `dotfiles/scripts/`, not `~/.claude/`.

## Out of scope

- Migrating any tmux plugin behavior (resurrect, continuum, catppuccin status)
  to herdr. Revisit only if a specific need appears after the swap.
- Any repo other than intent. The dotfiles hooks are generic, so other repos
  opt in later by adding their own `.herdr/` scripts.

## Rollback

Revert `scripts/ghostty-shell` to the tmux launch line. tmux config and the
dormant `wt` / `wtrm` fish functions are untouched for the trial week, so
rollback is one file.
