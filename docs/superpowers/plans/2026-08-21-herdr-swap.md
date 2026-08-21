# herdr Replaces tmux — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace tmux with herdr as the multiplexer Ghostty launches, with herdr owning git worktree create and remove and running `claude` + `codex` + `nvim` in each worktree.

**Architecture:** Ghostty launches herdr through `scripts/ghostty-shell`. herdr config lives in dotfiles. Generic dotfiles hooks call a repo-owned `.herdr/setup.sh` on worktree create and `.herdr/teardown.sh` on remove, so no repo detail leaks into dotfiles. The intent repo gets those two scripts, ported from the current `.zed/worktree-setup.sh` and `wtrm.fish`. Keybindings reconcile only in `ghostty/config`; herdr stays at its defaults.

**Tech Stack:** herdr (Rust binary), fish, Ghostty, git worktrees, Node/npm (intent bootstrap), TOML config.

**Spec:** `docs/superpowers/specs/2026-08-21-herdr-replaces-tmux-design.md`

---

## Preconditions

- Branch `herdr-swap` is checked out.
- herdr is not installed yet.
- Reference sources to port from:
  - `scripts/ghostty-shell` — host branch (Supacode vs Ghostty).
  - `ghostty/config` — `super+*` bindings.
  - `fish/functions/wt.fish`, `fish/functions/wtrm.fish` — worktree create/remove.
  - `/Users/darius/Work/optura/intent/.zed/worktree-setup.sh` — rich create flow.
  - `tmux/conf/keybindings.conf` — the `prefix+f` sessionizer bind.

## File structure

| File | Responsibility | Action |
| --- | --- | --- |
| `docs/superpowers/plans/verify-gate-findings.md` | Record real herdr facts from the binary | Create (Task 0) |
| herdr `config.toml` (path found in Task 0) | herdr defaults: shell, worktree dir, layout, hooks | Create |
| `scripts/herdr-run-repo-hook.sh` | Resolve the main checkout, run its `.herdr/<hook>.sh` if present | Create (Task 1) |
| `scripts/ghostty-shell` | Launch herdr for the Ghostty host | Modify |
| `ghostty/config` | Reconcile `super+*` to herdr letters, add worktree keys | Modify |
| `/Users/darius/Work/optura/intent/.herdr/setup.sh` | Repo create bootstrap (env, docs, deps, DB) | Create |
| `/Users/darius/Work/optura/intent/.herdr/teardown.sh` | Repo teardown (salvage docs, drop DB) | Create |
| `scripts/herdr-sessionizer` (conditional) | fish/fzf repo jump onto herdr | Create or skip |

There is no unit-test framework for shell/config here. Each task verifies with a runnable command and a stated expected output — that is the "test".

---

## Task 0: Install herdr and run the verify gate

**Files:**
- Create: `docs/superpowers/plans/verify-gate-findings.md`

This task resolves every branch in the plan. Do it first. Do not edit any config until it is done.

- [ ] **Step 1: Install herdr**

Run: `curl -fsSL https://herdr.dev/install.sh | sh`
Then: `herdr --version`
Expected: a version string prints, `herdr` is on `PATH`.

- [ ] **Step 2: Print the default config and find its path**

Run: `herdr --default-config | head -50`
Run: `herdr --help` and look for a config-path flag or env var; check `~/.config/herdr/` and `~/.herdr/`.
Record the real config file path.

- [ ] **Step 3: Answer each verify-gate question against the binary**

For each item below, run the command or read `herdr --default-config` / `herdr --help` and record the finding.

1. Config file path and format.
2. Does `[worktrees] directory` accept a per-repo template (e.g. `{{ repo_root }}/.claude/worktrees`)? Decides **approach A (native)** vs **approach B (wrapper `hw`)** for worktree location.
3. Do `worktree.created`, `worktree.opened`, `worktree.removed` fire, with `{{ branch }}` and `{{ worktree_path }}` available? A missing `worktree.removed` moves teardown to an `hw-rm` fish function.
4. Does the `worktree.created` hook complete before `worktree.opened` applies the layout, or do agent panes need a ready-signal wait?
5. Does `herdr worktree create` check out a named branch or a detached HEAD? Decides whether `setup.sh` keeps branch parsing.
6. Is the workspace layout core config or a plugin?
7. What is the attach / new-session subcommand (for `ghostty-shell`)?
8. Exact key names: prefix, splits, tab ops, pane focus, worktree create/open/remove, copy-mode, reload, session-list.
9. Can herdr attach a session by name from the CLI? Decides tmux-sessionizer rewrite vs drop.
10. Does the hook `run` action accept an external command with arguments (needed for the `herdr-run-repo-hook.sh` dispatcher), and what CWD does it run in?

- [ ] **Step 4: Write findings and commit**

Write `docs/superpowers/plans/verify-gate-findings.md` with a line per question and the decision it drives (A/B, hook-present, branch-vs-detached, etc.).

```bash
git add docs/superpowers/plans/verify-gate-findings.md
git commit -m "docs(plans): record herdr verify-gate findings from the binary"
```

**Gate:** later tasks read this file. Where a task says "approach A / B" or "if hook present", follow the recorded finding.

---

## Task 1: herdr config — shell, worktree dir, layout, hooks

**Files:**
- Create: herdr `config.toml` (path from Task 0). Track it in dotfiles and symlink from the real path (match the repo's existing stow/symlink pattern — check the `Makefile`).

- [ ] **Step 1: Seed the config**

Run: `herdr --default-config > <dotfiles>/herdr/config.toml`
Add the tracked file to the dotfiles install target (see `Makefile`), so it symlinks to the path Task 0 found.

- [ ] **Step 2: Set shell and worktree directory**

```toml
[terminal]
default_shell = "fish"

[worktrees]
# Approach A: per-repo template if Task 0 finding #2 supports it.
directory = "{{ repo_root }}/.claude/worktrees"
# Approach B (finding #2 = global-only): leave this at the herdr default and
# let Task 5c's `hw` wrapper place the checkout. Add a note here pointing to it.
```

- [ ] **Step 3: Define the workspace layout**

One tab, three panes — `claude`, `codex`, `nvim` — each `cd`'d to `{{ worktree_path }}`. Use the exact layout syntax from Task 0 finding #6 (core config or plugin). Bind the layout to `worktree.opened` (finding #3) so new and reopened worktrees both get panes.

- [ ] **Step 4: Create the hook dispatcher `scripts/herdr-run-repo-hook.sh`**

The dispatcher resolves the repo's **main** checkout from the worktree path, then
runs the main checkout's `.herdr/<hook>.sh` if it exists. This finds the script
regardless of what the new worktree contains (a worktree cut from `origin/main`
has no `.herdr/`), and puts the no-op-if-absent logic in one place.

```bash
#!/usr/bin/env bash
# herdr lifecycle hook dispatcher. Resolve the repo's MAIN checkout from the
# worktree, then run its .herdr/<hook>.sh if present. No-op when absent.
#   herdr-run-repo-hook.sh <hook> <worktree_path> [<branch>]
set -euo pipefail
hook="$1"; wt="$2"; branch="${3:-}"
main="$(dirname "$(git -C "$wt" rev-parse --path-format=absolute --git-common-dir)")"
script="$main/.herdr/$hook.sh"
[ -x "$script" ] || exit 0
exec "$script" "$wt" "$branch"
```
Run: `chmod +x <dotfiles>/scripts/herdr-run-repo-hook.sh`

- [ ] **Step 5: Wire the generic lifecycle hooks to the dispatcher**

Use the exact `run` syntax and template-var names from Task 0 findings #3 and #10.

```
worktree.created  ->  run  <dotfiles>/scripts/herdr-run-repo-hook.sh setup    "{{ worktree_path }}" "{{ branch }}"
worktree.removed  ->  run  <dotfiles>/scripts/herdr-run-repo-hook.sh teardown "{{ worktree_path }}" "{{ branch }}"
```

Keep the hook repo-agnostic — never name intent here.

**Ordering (finding #4):** if `created` does not block `opened`, make the agent panes wait for a ready signal. `setup.sh` writes `.herdr/.ready` on success; the `claude`/`codex` pane command runs `until [ -f .herdr/.ready ]; do sleep 0.5; done` first.

- [ ] **Step 6: Verify herdr starts with the config**

Run: `herdr` (then detach). 
Expected: herdr starts, no config parse error, `default_shell` is fish.

- [ ] **Step 7: Commit**

```bash
git add herdr/config.toml scripts/herdr-run-repo-hook.sh Makefile
git commit -m "feat(herdr): add config and repo-hook dispatcher for lifecycle hooks"
```

---

## Task 2: intent `.herdr/setup.sh` — create bootstrap

**Files:**
- Create: `/Users/darius/Work/optura/intent/.herdr/setup.sh`

Port `intent/.zed/worktree-setup.sh`, dropping the Zed env-var caller. herdr passes the worktree path and branch as args.

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Per-worktree bootstrap, run by herdr's worktree.created hook.
#   setup.sh <worktree-path> <branch>
set -euo pipefail

wt_root="$1"
branch="${2:-}"
main_root="$(dirname "$(git -C "$wt_root" rev-parse --path-format=absolute --git-common-dir)")"
cd "$wt_root"

# Finding #5: if herdr leaves a detached HEAD, cut the branch from origin/main.
# If herdr checks out a named branch, this block is a no-op and can be removed.
if ! git symbolic-ref -q HEAD >/dev/null && [ -n "$branch" ]; then
	git fetch origin main --quiet
	git switch --no-track -c "$branch" origin/main
fi

# .env is gitignored and holds shared secrets — link main's copy.
ln -sf "$main_root/.env" .env

# docs/ is gitignored, local-only specs/ADRs — seed from main.
if [ -d "$main_root/docs" ]; then
	mkdir -p docs
	rsync -a --update "$main_root/docs/" docs/
fi

npm install
npx vite-node scripts/worktree/db-restore.ts

# Ready signal for the agent panes (see herdr config Task 1 Step 5).
# .herdr/ may be absent when the worktree is cut from a base without it.
mkdir -p .herdr
touch .herdr/.ready
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x /Users/darius/Work/optura/intent/.herdr/setup.sh`

- [ ] **Step 3: Dry-run the bootstrap by hand**

Create a scratch worktree the old way and run the script against it:
Run: `cd /Users/darius/Work/optura/intent && git worktree add --no-track -b tmp-herdr-test .claude/worktrees/tmp-herdr-test origin/main`
Run: `.herdr/setup.sh "$(pwd)/.claude/worktrees/tmp-herdr-test" tmp-herdr-test`
Expected: `.env` symlink exists, `docs/` populated, `node_modules/` present, db-restore ran, `.herdr/.ready` exists in the worktree.

- [ ] **Step 4: Ignore the ready signal, then commit (in the intent repo)**

Add `.herdr/.ready` to the intent repo's `.gitignore` so the local signal is not
untracked noise and a reopened worktree's persisted `.ready` reads as intentional.

```bash
cd /Users/darius/Work/optura/intent
echo ".herdr/.ready" >> .gitignore
git add .herdr/setup.sh .gitignore
git commit -m "feat(worktree): add .herdr/setup.sh for herdr worktree.created bootstrap"
```
Leave the scratch worktree for Task 3, then remove it there.

---

## Task 3: intent `.herdr/teardown.sh` — remove teardown

**Files:**
- Create: `/Users/darius/Work/optura/intent/.herdr/teardown.sh`

Port the state-cleanup steps from `wtrm.fish` (salvage docs, drop DB). herdr's `worktree remove` handles the git removal, so this script does **not** call `git worktree remove`.

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Per-worktree teardown, run by herdr's worktree.removed hook, BEFORE git
# unlinks the checkout.
#   teardown.sh <worktree-path> <branch>
set -euo pipefail

wt_root="$1"
main_root="$(dirname "$(git -C "$wt_root" rev-parse --path-format=absolute --git-common-dir)")"

# Pull gitignored docs/ back into main before the checkout disappears.
npx --prefix "$main_root" vite-node "$main_root/scripts/worktree/salvage-docs.ts" "$wt_root"

# db-drop derives the DB name from cwd, so run it inside the worktree.
if [ -d "$wt_root/node_modules" ]; then
	( cd "$wt_root" && npx vite-node scripts/worktree/db-drop.ts --force )
else
	echo "teardown: no node_modules in $wt_root — skipping DB drop" >&2
fi
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x /Users/darius/Work/optura/intent/.herdr/teardown.sh`

- [ ] **Step 3: Dry-run against the scratch worktree from Task 2**

Run: `/Users/darius/Work/optura/intent/.herdr/teardown.sh "/Users/darius/Work/optura/intent/.claude/worktrees/tmp-herdr-test" tmp-herdr-test`
Expected: salvage-docs ran, db-drop ran, no error.
If `npx --prefix "$main_root"` does not resolve main's `node_modules` for
`salvage-docs.ts`, fall back to the original `wtrm.fish` pattern — run it from a
CWD inside the main checkout: `( cd "$main_root" && npx vite-node scripts/worktree/salvage-docs.ts "$wt_root" )`.
Then remove the scratch worktree:
Run: `cd /Users/darius/Work/optura/intent && git worktree remove --force .claude/worktrees/tmp-herdr-test && git branch -D tmp-herdr-test`

- [ ] **Step 4: Commit (in the intent repo)**

```bash
cd /Users/darius/Work/optura/intent
git add .herdr/teardown.sh
git commit -m "feat(worktree): add .herdr/teardown.sh for herdr worktree.removed cleanup"
```

---

## Task 4: End-to-end worktree test through herdr

**Files:** none (verification only).

- [ ] **Step 1: Create a worktree through herdr**

In a herdr session inside the intent repo, press the worktree-create key (Task 0 finding #8) or run the create subcommand. Name the branch `herdr-e2e-test`.
Expected: herdr creates the worktree at `.claude/worktrees/herdr-e2e-test` (approach A) or wherever `hw` placed it (approach B), `setup.sh` runs, the workspace opens with `claude` + `codex` + `nvim` panes.

- [ ] **Step 2: Assert the bootstrap ran and ordering held**

Expected: agent panes only became interactive after `.herdr/.ready` appeared; `.env`, `docs/`, `node_modules/` all present.

- [ ] **Step 3: Remove the worktree through herdr**

Press the worktree-remove key (or subcommand).
Expected: `teardown.sh` runs (salvage-docs, db-drop), the worktree and branch are gone.

- [ ] **Step 4: Record result in the findings file and commit**

```bash
git add docs/superpowers/plans/verify-gate-findings.md
git commit -m "test(herdr): record end-to-end worktree create/remove result"
```

---

## Task 5: Swap the Ghostty shell entry to herdr

**Files:**
- Modify: `scripts/ghostty-shell`

- [ ] **Step 1: Change the Ghostty branch**

Keep the Supacode branch unchanged. Replace the tmux line with the herdr attach/new command from Task 0 finding #7. Example shape (use the real subcommand):

```sh
if [ -n "$SUPACODE_SOCKET_PATH" ]; then
    exec /usr/local/bin/fish
else
    exec /usr/local/bin/fish --login -c "herdr attach default || herdr new default"
fi
```

- [ ] **Step 2: Verify in a new Ghostty window**

Open a new Ghostty window.
Expected: herdr starts (not tmux), fish is the shell, the `default` session persists across window close/reopen.
Expected: a Supacode terminal still opens plain fish, no herdr.

- [ ] **Step 3: Commit**

```bash
git add scripts/ghostty-shell
git commit -m "feat(ghostty): launch herdr instead of tmux for the Ghostty host"
```

- [ ] **Step 5c (approach B only): add the `hw` wrapper**

If Task 0 finding #2 is global-only, add `fish/functions/hw.fish`: cut the worktree at `.claude/worktrees/<branch>` from `origin/main`, then hand the path to herdr to open. If finding #3 has no `worktree.removed`, also add `fish/functions/hw-rm.fish` that runs `.herdr/teardown.sh` then `git worktree remove`. Commit separately. Skip this step entirely under approach A.

---

## Task 6: Reconcile keybindings in ghostty/config

**Files:**
- Modify: `ghostty/config`

Use the real herdr key names from Task 0 finding #8. The values below assume herdr's documented defaults; correct them to the findings.

- [ ] **Step 1: Remap splits and pane navigation**

Change these lines so `super+*` sends herdr's letter:

| line today | change to |
| --- | --- |
| `super+shift+n=text:\x02%` | `super+shift+n=text:\x02-` (split_horizontal) |
| `super+n=text:\x02\"` | `super+n=text:\x02v` (split_vertical) |
| `super+up=text:\x02\x1b[a` | `super+up=text:\x02k` |
| `super+down=text:\x02\x1b[b` | `super+down=text:\x02j` |
| `super+left=text:\x02\x1b[d` | `super+left=text:\x02h` |
| `super+right=text:\x02\x1b[c` | `super+right=text:\x02l` |

- [ ] **Step 2: Drop the dead tpm binds**

Remove `super+shift+i=text:\x02I` and `super+shift+u=text:\x02U`. herdr has no plugin manager.

- [ ] **Step 3: Add worktree keys**

```
keybind = super+shift+g=text:\x02G
keybind = super+shift+o=text:\x02O
keybind = super+alt+d=text:\x02\x1bd
```
Correct the letters to finding #8 (herdr worktree create/open/remove).

- [ ] **Step 4: Fix copy-mode / reload / session-list if the letters differ**

Compare `super+[` (`\x02[`), `super+r` (`\x02r`), `super+k` (`\x02s`) against finding #8 and adjust only if herdr uses a different letter.

- [ ] **Step 5: Verify each changed key**

Reload Ghostty config. In a herdr session, press each remapped key.
Expected: split H, split V, focus left/down/up/right, worktree create/open/remove all fire the right herdr action.

- [ ] **Step 6: Commit**

```bash
git add ghostty/config
git commit -m "feat(ghostty): remap super+* keys to herdr letters, add worktree keys"
```

---

## Task 7: tmux-sessionizer decision

**Files:**
- Create (conditional): `scripts/herdr-sessionizer`
- Modify (conditional): `ghostty/config` (`super+f`)

Follow Task 0 finding #9.

- [ ] **Step 1a (finding #9 = attach-by-name exists): rewrite onto herdr**

Copy `~/.local/bin/tmux-sessionizer` to `scripts/herdr-sessionizer`. Replace the `tmux` session calls with the herdr attach-or-create-by-name command. Keep the fzf front end. Point `super+f` at it (run it directly, or via a herdr run key).
Verify: press `super+f`, fzf lists project dirs, picking one opens a herdr session for it.

- [ ] **Step 1b (finding #9 = no attach-by-name): drop it**

Leave `super+f` for herdr's own session/worktree picker key (finding #8). Note the drop in the findings file.

- [ ] **Step 2: Commit**

```bash
git add scripts/herdr-sessionizer ghostty/config   # or just the findings note
git commit -m "feat(herdr): port sessionizer onto herdr"   # or: "chore: drop tmux-sessionizer under herdr"
```

---

## Task 8: Retire tmux and the fish worktree helpers (dormant)

**Files:**
- No deletions yet — dormancy only.

- [ ] **Step 1: Confirm tmux is no longer launched**

Grep the repo for any remaining tmux launch: `rg -n "tmux (attach|new)" scripts ghostty fish`
Expected: only historic/commented references; `ghostty-shell` launches herdr.

- [ ] **Step 2: Mark the trial**

Add a dated note to `docs/superpowers/plans/verify-gate-findings.md`: keep `tmux/`, `tmux.conf`, `fish/functions/wt.fish`, `fish/functions/wtrm.fish` dormant for one week (until 2026-08-28), then delete in a follow-up commit if herdr holds up.

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/plans/verify-gate-findings.md
git commit -m "chore: mark tmux and wt/wtrm dormant pending one-week herdr trial"
```

---

## Done criteria

- Ghostty launches herdr; Supacode still launches plain fish.
- Creating a worktree in herdr runs `setup.sh` (env, docs, deps, DB) and opens `claude` + `codex` + `nvim`, agents starting only after bootstrap.
- Removing a worktree runs `teardown.sh` (salvage docs, drop DB).
- `super+*` splits, tab switching, pane nav, and worktree keys all drive herdr.
- tmux and `wt`/`wtrm` are dormant, deletable after the trial week.
