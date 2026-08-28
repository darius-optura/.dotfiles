# occam — package the review and compression skills as an installable plugin

Date: 2026-08-28
Status: Approved, ready for an implementation plan

## Goal

Four skills currently reach a machine only through the dotfiles symlink install.
Move them into a standalone Claude Code plugin named `occam`, so a teammate
installs them with two commands and gets no other part of the dotfiles.

Audience is a small team, not the public. The repo can stay private.

## Decisions

| Question | Decision |
|---|---|
| Which skills | `tldr`, `local-review`, `pr-review`, plus `pr-worktree` because `pr-review` calls it |
| Repo home | New dedicated repo, `<owner>/occam` |
| Migration | Move the files. Dotfiles installs the plugin like any teammate does |
| Plugin count | One plugin, not two |
| Name | Plugin and repo `occam`. Skills `razor`, `scrutiny`, `inquest`, `bench` |
| Rename depth | All the way — file names, state files, environment variables and banner text |

`commit`, `flow-breaker`, `gh-stack`, `supacode-cli`, `supacode-deeplinks` and
`diagnose` stay private in the dotfiles repo. They are out of scope.

## Repo layout

The repo is both the plugin and its own marketplace. This layout follows the
`openai-codex` marketplace, read from the local plugin cache.

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
  commands/
    razor-stats.md
  hooks/
    hooks.json
    razor-activate.js
    razor-mode-tracker.js
    razor-stats.js
    razor-config.js
    razor-statusline.sh
  scripts/
    install-statusline.sh
  README.md
```

`marketplace.json`:

```json
{
  "name": "occam",
  "owner": { "name": "<owner>" },
  "metadata": { "description": "Terse output, adversarial review.", "version": "1.0.0" },
  "plugins": [
    { "name": "occam", "description": "...", "version": "1.0.0", "source": "./" }
  ]
}
```

Install:

```
claude plugin marketplace add <owner>/occam
claude plugin install occam@occam
```

## Rename map

| From (dotfiles) | To (occam) |
|---|---|
| `claude/skills/tldr/SKILL.md` | `skills/razor/SKILL.md` |
| `claude/skills/local-review/SKILL.md` | `skills/scrutiny/SKILL.md` |
| `claude/skills/pr-review/*` | `skills/inquest/*` |
| `claude/skills/pr-worktree/SKILL.md` | `skills/bench/SKILL.md` |
| `claude/commands/tldr-stats.md` | `commands/razor-stats.md` |
| `claude/hooks/tldr-activate.js` | `hooks/razor-activate.js` |
| `claude/hooks/tldr-mode-tracker.js` | `hooks/razor-mode-tracker.js` |
| `claude/hooks/tldr-stats.js` | `hooks/razor-stats.js` |
| `claude/hooks/tldr-config.js` | `hooks/razor-config.js` |
| `claude/hooks/tldr-statusline.sh` | `hooks/razor-statusline.sh` |

Each `SKILL.md` gets a new `name:` field in its frontmatter. The skill bodies
carry 41 references to the old names. `inquest` names `scrutiny` and `bench`
in its text; those references must change with the file names.

The `razor` description keeps the trigger words `tldr`, `be brief` and
`be lazy`. The phrase "tldr mode" must continue to start the skill.

## Hooks

The plugin ships `hooks/hooks.json`. Paths use `${CLAUDE_PLUGIN_ROOT}`.

| Event | Command |
|---|---|
| `SessionStart` (matcher `startup\|resume`) | `node "${CLAUDE_PLUGIN_ROOT}/hooks/razor-activate.js"` |
| `UserPromptSubmit` | `node "${CLAUDE_PLUGIN_ROOT}/hooks/razor-mode-tracker.js"` |
| `Stop` | `node "${CLAUDE_PLUGIN_ROOT}/hooks/razor-stats.js" --refresh` |

`razor-activate.js` reads the skill body through a path relative to its own
directory (`../skills/razor/SKILL.md`). `hooks/` and `skills/` stay siblings in
the plugin, so that path still resolves. No change is needed there.

## Change 1 — the default mode must become off

`getDefaultMode()` in `tldr-config.js` returns `full` when no configuration
file and no environment variable exist. That default is correct for a personal
symlink install. It is wrong for a plugin: a teammate who installs `occam` for
the review skills would be forced into compressed output without asking.

Change the fallback to `off`. Turning it on stays possible three ways:

1. `/razor` in a session.
2. `RAZOR_DEFAULT_MODE=full` in the environment.
3. `"defaultMode": "full"` in `~/.config/razor/config.json`.

The dotfiles install writes option 3, so this machine behaves as it does today.

## Change 2 — the statusline needs an installer

`statusLine` is a key in `settings.json`. A plugin cannot set it, and the
plugin's own path contains a version number that changes on every upgrade.

Ship `scripts/install-statusline.sh`. It resolves the installed plugin
directory, then writes the `statusLine` entry into the user's `settings.json`.
The README states that the statusline is an opt-in extra step.

## Change 3 — one-time state migration

On first run, `razor-config.js` renames old state if it finds it:

| Old | New |
|---|---|
| `${CLAUDE_CONFIG_DIR:-~/.claude}/.tldr-active` | `.razor-active` |
| `${CLAUDE_CONFIG_DIR:-~/.claude}/.tldr-history.jsonl` | `.razor-history.jsonl` |
| `${CLAUDE_CONFIG_DIR:-~/.claude}/.tldr-statusline-suffix` | `.razor-statusline-suffix` |
| `~/.config/tldr/config.json` | `~/.config/razor/config.json` |

The rename runs once and only when the new path does not yet exist. It must
never overwrite. The existing 162 KB history file must survive, or the saving
statistics reset to zero.

The environment variable becomes `RAZOR_DEFAULT_MODE`. The old name is not
read. Only this machine sets it, and the dotfiles change below updates it.

## Dotfiles changes

1. Delete the four skill directories, the five hook files and `tldr-stats.md`.
2. Remove those symlinks from `install.sh`.
3. In `settings.json.template`, delete the three `__HOME__` tldr hook entries.
   Add the marketplace and `"occam@occam": true` to `enabledPlugins`.
4. Point `statusLine` at the installed plugin, or run the installer script.
5. Add a line to `AGENTS.md` that says where these skills now live.

## Verification

Run each step before the dotfiles copies are deleted.

1. `claude plugin install occam@occam` on a clean machine or a clean
   `CLAUDE_CONFIG_DIR`. Confirm the four skills appear in the skill list.
2. Start a session with no configuration. Confirm compression stays off.
3. Run `/razor`, then confirm the banner reads `RAZOR MODE ACTIVE`.
4. Run `/razor-stats`. Confirm it reads the migrated history.
5. Run `/scrutiny` against a working tree that has changes.
6. Run `/inquest` against a throwaway pull request. Confirm it posts inline
   threads and one sticky summary, and that it calls `bench` correctly.
7. `grep -ri 'tldr\|local-review\|pr-review\|pr-worktree' occam/` returns only
   the deliberate trigger words in the `razor` description.

## Risks

`inquest` is the largest skill and the only one that writes to GitHub. A
missed cross-reference fails during a review, not during install. Step 6 of
the verification exists for that reason and is not optional.

`pr-review` looks for the Codex companion script under
`~/.claude/plugins/.../codex-companion.mjs`. That dependency is optional today
and stays optional. The skill must still work when Codex is absent.

## Out of scope

- Publishing the marketplace publicly.
- Moving any other skill, hook or command.
- Changing what the review skills do. This is a packaging change only.
