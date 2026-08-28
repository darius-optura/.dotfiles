# occam — package the review and compression skills as an installable plugin

Date: 2026-08-28
Status: Approved, ready for an implementation plan
Repo: git@github.com:darius-optura/occam.git, cloned empty at ~/Work/optura/occam

## Goal

Four skills currently reach a machine only through the dotfiles symlink install.
Move them into a standalone Claude Code plugin named `occam`, so a teammate
installs them with two commands and gets no other part of the dotfiles.

Audience is a small team, not the public. The repo can stay private.

## Decisions

| Question | Decision |
|---|---|
| Which skills | `tldr`, `local-review`, `pr-review`, plus `pr-worktree` because `pr-review` calls it |
| Repo home | New dedicated repo, `darius-optura/occam` |
| Migration | Move the files. Dotfiles installs the plugin like any teammate does |
| Plugin count | One plugin, not two |
| Name | Plugin and repo `occam`. Skills `razor`, `scrutiny`, `inquest`, `bench` |
| Rename depth | All the way — file names, state file, environment variable and banner text |
| Intensity levels | **Dropped.** One behaviour, on or off |
| Token statistics | **Dropped.** No stats hook, no command, no history file |
| Statusline badge | Kept, simplified to on/off |

`commit`, `flow-breaker`, `gh-stack`, `supacode-cli`, `supacode-deeplinks` and
`diagnose` stay private in the dotfiles repo. They are out of scope.

## What the cut removes

The source `tldr` skill carries two subsystems that the plugin does not want.
Both are deleted rather than ported.

**Intensity levels.** `lite`, `full` and `ultra`, plus three modes
(`commit`, `review`, `compress`) that reference skills nobody ever wrote.
Deleting them removes `VALID_MODES`, `INDEPENDENT_MODES`, the
`/tldr-commit|-review|-compress` branches in the tracker, and the code in
the activation hook that filters the skill body down to the active level.
`SKILL.md` loses its `lite` and `ultra` table rows, both example pairs, its
`argument-hint`, and the "Supports intensity levels" clause in the
description.

**Token statistics.** `tldr-stats.js` (12 KB), the `/tldr-stats` command,
the `Stop` hook that refreshed them, the `appendFlag` and `readHistory`
helpers that only statistics used, and the `.tldr-history.jsonl` and
`.tldr-statusline-suffix` files.

What survives is one flag file that says on or off, one hook that prints the
skill on session start, one hook that watches for the on and off phrases,
and a badge that reads the flag.

## Repo layout

The repo is both the plugin and its own single-plugin marketplace. This
layout follows the `openai-codex` marketplace, read from the local plugin
cache.

```
occam/
  .claude-plugin/
    marketplace.json
    plugin.json
  skills/
    razor/SKILL.md
    scrutiny/SKILL.md
    inquest/SKILL.md
    inquest/reference.md
    inquest/sticky-template.md
    inquest/check-sticky.sh
    bench/SKILL.md
  hooks/
    hooks.json
    razor-config.js
    razor-activate.js
    razor-mode-tracker.js
    razor-statusline.sh
  scripts/
    install-statusline.sh
  tests/
    razor-config.test.js
  README.md
```

There is no `commands/` directory. The only command was `/tldr-stats`, and
statistics are gone. `/razor` is the skill itself.

Install:

```
claude plugin marketplace add darius-optura/occam
claude plugin install occam@occam
```

## Rename map

| From (dotfiles) | To (occam) |
|---|---|
| `claude/skills/tldr/SKILL.md` | `skills/razor/SKILL.md` |
| `claude/skills/local-review/SKILL.md` | `skills/scrutiny/SKILL.md` |
| `claude/skills/pr-review/*` | `skills/inquest/*` |
| `claude/skills/pr-worktree/SKILL.md` | `skills/bench/SKILL.md` |
| `claude/hooks/tldr-config.js` | `hooks/razor-config.js` |
| `claude/hooks/tldr-activate.js` | `hooks/razor-activate.js` |
| `claude/hooks/tldr-mode-tracker.js` | `hooks/razor-mode-tracker.js` |
| `claude/hooks/tldr-statusline.sh` | `hooks/razor-statusline.sh` |
| `claude/hooks/tldr-stats.js` | deleted |
| `claude/commands/tldr-stats.md` | deleted |

The four skill bodies hold **64** references to the old names, counted with
`grep -rioE 'tldr|local-review|pr-review|pr-worktree'` over the four
directories. Each `SKILL.md` also needs a new `name:` field.

## Change 1 — one mode, off by default

`getDefaultMode()` returns `'full'` when nothing is configured. That default
is correct for a personal symlink install. It is wrong for a plugin: a
teammate who installs `occam` for the review skills would be forced into
compressed output without asking.

The resolver becomes a boolean. `isEnabledByDefault()` returns `false`
unless `RAZOR_DEFAULT_MODE=on` is set, or `~/.config/razor/config.json`
holds `{"enabled": true}`. The flag file `~/.claude/.razor-active` holds the
literal string `on` and nothing else; its absence means off.

Turning it on inside a session stays possible three ways: the `/razor`
command, the phrase "razor mode" or "tldr mode" in plain English, or the
config file. The dotfiles install writes the config file, so this machine
behaves exactly as it does today.

## Change 2 — trigger words and namespacing

The tracker gates on `prompt.startsWith('/tldr')` and matches the literal
commands `/tldr` and `/tldr:tldr`. Claude Code namespaces a plugin's skills,
so the invocation becomes `/occam:razor` as well as `/razor`. A plain
rename would make the tracker stop firing for the very commands the
verification exercises.

The matcher must accept all of `/razor`, `/occam:razor` and `/razor:razor`,
each with an optional `off`, `stop` or `disable` argument.

The natural-language regexes are a second question. "Rename all the way" and
"the phrase tldr mode must still work" collide inside them. Resolution: the
regexes accept **both** words, `tldr` and `razor`. Everything the user sees
— the banner, the badge, the flag file, the config file — says razor only.

## Change 3 — the statusline needs an installer

`statusLine` is a key in `settings.json`. A plugin cannot set it, and the
plugin's own path contains a version number that changes on every upgrade.

`razor-statusline.sh` shrinks to five lines: print `[RAZOR]` when the flag
file exists, print nothing otherwise. The savings suffix and the
`TLDR_STATUSLINE_SAVINGS` switch go with the statistics.

`scripts/install-statusline.sh` resolves the installed plugin directory and
writes the `statusLine` entry into the user's `settings.json`. It refuses to
overwrite an existing `statusLine` and prints the badge command instead, so
somebody who already has a statusline can paste one line into it.

This machine is that somebody. `scripts/claude-statusline.sh` calls the
badge as one segment of a larger line, so it gets the resolver, not the
installer.

## Change 4 — no state migration

Statistics are gone, so the 162 KB history file has nothing to migrate into.
`~/.config/tldr/config.json` was never created on this machine; the current
behaviour comes from the `return 'full'` fallback. What remains is a
four-byte flag file.

Migrating that is not worth the code. The old files stay where they are,
unused. The README says a user may delete `~/.claude/.tldr-active`,
`~/.claude/.tldr-history.jsonl` and `~/.claude/.tldr-statusline-suffix` by
hand, and that `RAZOR_DEFAULT_MODE` replaces `TLDR_DEFAULT_MODE`.

## Change 5 — bench probes three worktree backends

`pr-worktree` assumes Supacode. Supacode is not installed on this machine
and a teammate may not have it either. `bench` probes, in this order:

1. `command -v supacode` → Supacode backend. Existing flow, unchanged.
2. `command -v herdr` → herdr backend.
3. Neither → plain `git worktree add`.

`BENCH_BACKEND` overrides the probe, so each path can be tested without
changing what is installed.

The herdr flags are verified on this machine:
`herdr worktree create --workspace|--cwd|--branch|--base|--path|--label|--focus|--no-focus`,
`herdr worktree remove --workspace <id> --force`, and
`herdr worktree list --cwd <path>` emitting
`{"result":{"worktrees":[{"branch":…,"path":…,"open_workspace_id":…}]}}`.

The chosen backend is recorded in the state file, because `--archive` must
use the same backend that created the worktree:

```json
{ "1234": { "backend": "herdr", "id": "<workspace-id>", "path": "/abs/path/inquest-1234" } }
```

The state file itself is renamed from `.pr-review-map.json` to
`.inquest-map.json`. Existing entries are not migrated. Archive any open PR
worktree before the switch; there are none right now.

Only the herdr and plain-git paths can be tested on this machine. The
Supacode path stays as written and stays unverified.

## Change 6 — the sticky marker

`inquest` finds and updates its summary comment by an HTML marker,
`<!-- pr-review:sticky -->`. The string lives in three files that must
change together: `sticky-template.md` line 1, `check-sticky.sh` which
validates that exact line, and `reference.md` which greps for it.

The marker is renamed to `<!-- inquest:sticky -->`. Consequence, accepted: a
sticky already posted on an open PR is no longer found, so a re-review posts
a second one. `reference.md` also creates a label named `pr-review passed`,
which becomes `inquest passed`.

## Dotfiles changes

1. Delete the four skill directories, the five hook files and
   `claude/commands/tldr-stats.md`.
2. In `claude/settings.json.template`, delete the two tldr hook entries —
   `tldr-activate.js` under `SessionStart` and `tldr-mode-tracker.js` under
   `UserPromptSubmit`. Add `"occam@occam": true` to `enabledPlugins` and the
   marketplace to `extraKnownMarketplaces`.
3. Rewrite the badge block in `scripts/claude-statusline.sh` (lines 148–153)
   to resolve `razor-statusline.sh` inside the installed plugin. Check both
   the `plugins/cache/...` and `plugins/marketplaces/...` layouts.
4. Write `~/.config/razor/config.json` with `{"enabled": true}`, so this
   machine keeps the behaviour it has today.
5. Add a line to `AGENTS.md` recording where these skills now live.

`install.sh` needs no change. It symlinks the `skills`, `hooks` and
`commands` directories as whole directories, not file by file, so deleting
the files is the entire job.

## Verification

The old install must be taken out of the way first. Until the dotfiles are
stripped, `~/.claude/settings.json` still runs `tldr-activate.js` and
`tldr-mode-tracker.js`, and `~/.claude/skills/` still symlinks all four old
skills. Both would fire during the checks, and `tldr` and `razor` would be
discoverable at once with near-identical descriptions — which defeats the
one step that exists to catch a missed cross-reference.

So: disable the two hook entries and move the four skill directories aside
before the checks, and only then run them.

1. Install on a clean `CLAUDE_CONFIG_DIR`. Confirm the four skills appear.
2. Start a session with no configuration. Confirm razor stays off.
3. Run `/razor`, confirm the banner reads `RAZOR MODE ACTIVE` and the badge
   appears. Run `/razor off`, confirm both go away.
4. Confirm the phrase "tldr mode" still turns it on.
5. Run `/scrutiny` against a working tree that has changes.
6. Run `/inquest` against a throwaway PR. Confirm `bench` prints
   `backend=herdr`, the branch is `inquest/<N>`, inline threads and one
   sticky are posted, and the validator prints `OK`. Then `/bench --archive`.
7. Re-run with `BENCH_BACKEND=git` and confirm the plain-git path works.
   Do not test this by stripping `PATH` — that removes `gh`, which sits in
   `/opt/homebrew/bin`, and the flow fails before it reaches the backend.
8. Run `/inquest` once with the Codex CLI unavailable. Confirm the sticky's
   Codex line reads `skipped — codex CLI not installed`.
9. `grep -ri 'tldr\|local-review\|pr-review\|pr-worktree'` over the repo
   returns only the deliberate trigger words.

## Risks

`inquest` is the largest skill and the only one that writes to GitHub. A
missed cross-reference fails during a review, not during install. Steps 6
and 8 exist for that reason and are not optional.

`pr-review` looks for the Codex companion under
`~/.claude/plugins/.../codex-companion.mjs`. That dependency is optional
today and stays optional.

## Out of scope

- Publishing the marketplace publicly.
- Moving any other skill, hook or command.
- Changing what the review skills do. This is a packaging change only.
- Writing the `razor-commit`, `razor-review` or `razor-compress` skills that
  the deleted modes referenced.
