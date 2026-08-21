# herdr Replaces tmux — Implementation Plan (rev. scripted wrapper)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace tmux with herdr as the multiplexer Ghostty launches, with a `hw` fish wrapper that creates a git worktree in-repo, bootstraps it, and lays out `claude` + `codex` + `nvim` through herdr's socket API. `hw-rm` tears it down.

**Architecture:** herdr 0.8.2 has no lifecycle hooks and no declarative layout (see `verify-gate-findings.md`), so a wrapper owns orchestration. Ghostty launches `herdr --session default` via `scripts/ghostty-shell`. `hw`/`hw-rm` fish functions call `herdr worktree create/remove`, run repo-owned `.herdr/setup.sh`/`teardown.sh`, and drive `herdr pane split` + `herdr agent start`. Keybindings reconcile only in `ghostty/config`; herdr keeps its defaults.

**Tech Stack:** herdr 0.8.2 (Rust binary, socket API returns JSON), fish, Ghostty, git worktrees, Node/npm (intent bootstrap), jq (parse herdr JSON).

**Spec:** `docs/superpowers/specs/2026-08-21-herdr-replaces-tmux-design.md` (see the 2026-08-21 revision note).

**Findings:** `docs/superpowers/plans/verify-gate-findings.md` — confirmed CLI, key names, and API shape. Trust it over any assumed syntax.

---

## Task 0: Verify gate — DONE

herdr 0.8.2 installed at `~/.local/bin/herdr`; findings recorded and committed.
Confirmed: config `~/.config/herdr/config.toml`; `herdr --session <name>`;
`herdr worktree create --path --branch --base`; `herdr pane split`;
`herdr agent start <name> --kind <claude|codex> --pane <id>`; real key names.
No further action.

---

## Task 1: herdr config — shell only

**Files:**
- Create: `herdr/config.toml` in dotfiles, symlinked to `~/.config/herdr/config.toml` (add to `Makefile`, match the repo's symlink pattern).

Config is minimal now — no hooks, no layout (the wrapper does those). herdr keeps
default keybindings (reconcile happens in `ghostty/config`, Task 6). Set two keys
that are unset by default so the worktree open/remove keys work.

- [ ] **Step 1: Seed and trim**

Run: `herdr --default-config > <dotfiles>/herdr/config.toml`
Uncomment/set only:
```toml
[terminal]
default_shell = "fish"

[keys]
open_worktree = "prefix+shift+o"
remove_worktree = "prefix+alt+d"
```
Leave `[worktrees] directory` at default — the wrapper passes `--path`, so the global base is unused.

- [ ] **Step 2: Symlink via Makefile and reload**

Add the symlink target to `Makefile`. Create the link.
Run: `herdr server reload-config` (if a server runs) — expect no parse error. Or `herdr --session cfgtest` then detach.

- [ ] **Step 3: Commit**

```bash
git add herdr/config.toml Makefile
git commit -m "feat(herdr): add config.toml with fish shell and worktree keys"
```

---

## Task 2: intent `.herdr/setup.sh` — create bootstrap

**Files:**
- Create: `/Users/darius/Work/optura/intent/.herdr/setup.sh`

Port `intent/.zed/worktree-setup.sh`, dropping the Zed caller. The wrapper creates
a **named** branch (`worktree create --branch`), so no detached-HEAD parsing and no
async ready-signal are needed — the wrapper runs this synchronously before it
starts the agents.

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Per-worktree bootstrap, run by the hw wrapper after `herdr worktree create`.
#   setup.sh <worktree-path> <branch>
set -euo pipefail

wt_root="$1"
main_root="$(dirname "$(git -C "$wt_root" rev-parse --path-format=absolute --git-common-dir)")"
cd "$wt_root"

# .env is gitignored and holds shared secrets — link main's copy.
ln -sf "$main_root/.env" .env

# docs/ is gitignored, local-only specs/ADRs — seed from main.
if [ -d "$main_root/docs" ]; then
	mkdir -p docs
	rsync -a --update "$main_root/docs/" docs/
fi

npm install
npx vite-node scripts/worktree/db-restore.ts
```

- [ ] **Step 2: chmod + dry-run**

Run: `chmod +x /Users/darius/Work/optura/intent/.herdr/setup.sh`
Run: `cd /Users/darius/Work/optura/intent && git worktree add --no-track -b tmp-herdr-test .claude/worktrees/tmp-herdr-test origin/main`
Run: `.herdr/setup.sh "$(pwd)/.claude/worktrees/tmp-herdr-test" tmp-herdr-test`
Expected: `.env` symlink, `docs/` populated, `node_modules/` present, db-restore ran, no error.

- [ ] **Step 3: Commit (intent repo)**

```bash
cd /Users/darius/Work/optura/intent
git add .herdr/setup.sh
git commit -m "feat(worktree): add .herdr/setup.sh for hw worktree bootstrap"
```
Leave the scratch worktree for Task 3.

---

## Task 3: intent `.herdr/teardown.sh` — remove teardown

**Files:**
- Create: `/Users/darius/Work/optura/intent/.herdr/teardown.sh`

Port the state cleanup from `wtrm.fish`. Does **not** call `git worktree remove`
— `hw-rm` does that after this script.

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Per-worktree teardown, run by hw-rm BEFORE `herdr worktree remove`.
#   teardown.sh <worktree-path> <branch>
set -euo pipefail

wt_root="$1"
main_root="$(dirname "$(git -C "$wt_root" rev-parse --path-format=absolute --git-common-dir)")"

# Pull gitignored docs/ back into main before the checkout disappears.
( cd "$main_root" && npx vite-node scripts/worktree/salvage-docs.ts "$wt_root" )

# db-drop derives the DB name from cwd, so run it inside the worktree.
if [ -d "$wt_root/node_modules" ]; then
	( cd "$wt_root" && npx vite-node scripts/worktree/db-drop.ts --force )
else
	echo "teardown: no node_modules in $wt_root — skipping DB drop" >&2
fi
```

- [ ] **Step 2: chmod + dry-run against the scratch worktree**

Run: `chmod +x /Users/darius/Work/optura/intent/.herdr/teardown.sh`
Run: `/Users/darius/Work/optura/intent/.herdr/teardown.sh "/Users/darius/Work/optura/intent/.claude/worktrees/tmp-herdr-test" tmp-herdr-test`
Expected: salvage-docs ran, db-drop ran, no error.
Then: `cd /Users/darius/Work/optura/intent && git worktree remove --force .claude/worktrees/tmp-herdr-test && git branch -D tmp-herdr-test`

- [ ] **Step 3: Commit (intent repo)**

```bash
cd /Users/darius/Work/optura/intent
git add .herdr/teardown.sh
git commit -m "feat(worktree): add .herdr/teardown.sh for hw-rm cleanup"
```

---

## Task 4: `hw` and `hw-rm` fish wrappers — the core

**Files:**
- Create: `fish/functions/hw.fish`
- Create: `fish/functions/hw-rm.fish`

herdr socket-API commands return JSON; parse pane IDs with `jq`. Verify exact JSON
paths against live output — the skill file states `worktree create` opens a
workspace and creation responses expose IDs (`.result.root_pane.pane_id`,
`pane split` → `.result.pane.pane_id`). Confirm on the binary before trusting.

- [ ] **Step 1: Write `hw.fish`**

```fish
function hw --description 'herdr worktree: create off origin/main, bootstrap, lay out claude+codex+nvim'
    if test (count $argv) -ne 1
        echo "usage: hw <branch>" >&2; return 1
    end
    set -l branch $argv[1]
    set -l common (git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    test -z "$common"; and echo "hw: not in a git repo" >&2; and return 1
    set -l main (path dirname $common)
    set -l dir "$main/.claude/worktrees/$branch"
    test -e $dir; and echo "hw: $dir exists" >&2; and return 1

    git -C $main fetch origin main --quiet; or return 1

    # 1. Create + open the worktree workspace. Capture the root pane id.
    set -l created (herdr worktree create --path $dir --branch $branch --base origin/main --no-focus)
    set -l root (echo $created | jq -r '.result.root_pane.pane_id')

    # 2. Bootstrap (repo-owned, optional).
    if test -x "$main/.herdr/setup.sh"
        "$main/.herdr/setup.sh" $dir $branch; or return 1
    end

    # 3. Layout: nvim in root, claude top-right, codex bottom-right.
    set -l right (herdr pane split --pane $root --direction right --cwd $dir --no-focus | jq -r '.result.pane.pane_id')
    herdr agent start claude --kind claude --pane $right
    set -l bottom (herdr pane split --pane $right --direction down --cwd $dir --no-focus | jq -r '.result.pane.pane_id')
    herdr agent start codex --kind codex --pane $bottom
    herdr pane send-text --pane $root "nvim ."\n
    herdr pane focus --pane $root

    echo "hw: $branch -> $dir"
end
```

- [ ] **Step 2: Write `hw-rm.fish`**

```fish
function hw-rm --description 'herdr worktree teardown: salvage docs, drop DB, remove worktree'
    set -l common (git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    test -z "$common"; and echo "hw-rm: not in a git repo" >&2; and return 1
    set -l main (path dirname $common)

    set -l target
    if test (count $argv) -eq 0
        set target (git rev-parse --show-toplevel)
    else if test -d $argv[1]
        set target (path resolve $argv[1])
    else
        set target "$main/.claude/worktrees/$argv[1]"
    end
    if test (path resolve $target) = (path resolve $main)
        echo "hw-rm: refusing to remove the main checkout" >&2; return 1
    end
    test -d $target; or begin; echo "hw-rm: no worktree at $target" >&2; return 1; end

    set -l branch (git -C $target rev-parse --abbrev-ref HEAD)

    if test -x "$main/.herdr/teardown.sh"
        "$main/.herdr/teardown.sh" $target $branch; or return 1
    end

    # Leave the worktree before it is unlinked.
    string match -q "$target*" (pwd); and cd $main
    herdr worktree remove --path $target; or git -C $main worktree remove --force $target; or return 1
    test "$branch" != HEAD; and git -C $main branch -D $branch
    echo "hw-rm: removed $target"
end
```

- [ ] **Step 3: Verify JSON paths and flags against live herdr**

Before trusting the field paths and flags above, confirm on the binary:
Run: `herdr worktree create --help`, `herdr pane split --help`, `herdr agent start --help`, `herdr pane send-text --help`, `herdr worktree remove --help`.
Adjust `--pane`/`--path` flag names and the `jq` paths to match real output. `herdr --skill` documents the API shape.

- [ ] **Step 4: Commit**

```bash
git add fish/functions/hw.fish fish/functions/hw-rm.fish
git commit -m "feat(fish): add hw/hw-rm herdr worktree wrappers"
```

---

## Task 5: Swap the Ghostty shell entry to herdr

**Files:**
- Modify: `scripts/ghostty-shell`

- [ ] **Step 1: Change the Ghostty branch**

Keep the Supacode branch unchanged. Replace the tmux line:
```sh
if [ -n "$SUPACODE_SOCKET_PATH" ]; then
    exec /usr/local/bin/fish
else
    exec /usr/local/bin/fish --login -c "herdr --session default"
fi
```
Ensure `~/.local/bin` is on PATH for the Ghostty shell (check `fish/config.fish`; add if missing).

- [ ] **Step 2: Verify — INTERACTIVE (hand to the user)**

Open a new Ghostty window.
Expected: herdr starts (not tmux), fish is the shell, the `default` session persists across window close/reopen. A Supacode terminal still opens plain fish.

- [ ] **Step 3: Commit**

```bash
git add scripts/ghostty-shell fish/config.fish
git commit -m "feat(ghostty): launch herdr --session default instead of tmux"
```

---

## Task 6: Reconcile keybindings in ghostty/config

**Files:**
- Modify: `ghostty/config`

Keep herdr at default keys; change what `super+*` **sends** (approach A). Values
below use the confirmed herdr 0.8.2 names.

- [ ] **Step 1: Remap splits and pane navigation**

| line today | change to | herdr action |
| --- | --- | --- |
| `super+shift+n=text:\x02%` | `super+shift+n=text:\x02-` | `split_horizontal = prefix+minus` |
| `super+n=text:\x02\"` | `super+n=text:\x02v` | `split_vertical = prefix+v` |
| `super+up=text:\x02\x1b[a` | `super+up=text:\x02k` | `focus_pane_up` |
| `super+down=text:\x02\x1b[b` | `super+down=text:\x02j` | `focus_pane_down` |
| `super+left=text:\x02\x1b[d` | `super+left=text:\x02h` | `focus_pane_left` |
| `super+right=text:\x02\x1b[c` | `super+right=text:\x02l` | `focus_pane_right` |

Note: `super+shift+n` sent `%` (a tmux split); herdr uses `prefix+shift+n` for
`new_workspace`. Sending `prefix+minus` avoids that clash and gets a horizontal split.

- [ ] **Step 2: Fix the mismatched single-letter binds**

- `super+k` sends `\x02s`. In herdr `prefix+s` is **settings**, not session-list. Decide: keep as a settings shortcut (rename intent), or repoint. If you want a session picker, herdr uses `prefix+w` (`workspace_picker`) — consider `super+k=text:\x02w`.
- `super+r` sends `\x02r`. In herdr `prefix+r` is **resize_mode**; reload is `prefix+shift+r`. If `super+r` was meant as reload, change to `super+r=text:\x02R` (i.e. `prefix+shift+r`).
- `super+q` sends `\x02d` → herdr `prefix+q` is detach; `\x02d` is not a herdr key. Change to `super+q=text:\x02q` (detach).

- [ ] **Step 3: Drop dead binds**

Remove `super+shift+i` (`\x02I`) and `super+shift+u` (`\x02U`) — tpm, no herdr equivalent.

- [ ] **Step 4: Add worktree keys**

```
keybind = super+shift+g=text:\x02G
keybind = super+shift+o=text:\x02O
keybind = super+alt+d=text:\x02\x1bd
```
`super+shift+g` → `prefix+shift+g` (`new_worktree`); `super+shift+o` → `prefix+shift+o` (`open_worktree`, set in Task 1); `super+alt+d` → `prefix+alt+d` (`remove_worktree`, set in Task 1). Confirm the escape bytes render the intended chords in Ghostty.

- [ ] **Step 5: Verify — INTERACTIVE (hand to the user)**

Reload Ghostty. In a herdr session press each remapped key.
Expected: split H/V, focus h/j/k/l, worktree create/open/remove all fire the right herdr action.

- [ ] **Step 6: Commit**

```bash
git add ghostty/config
git commit -m "feat(ghostty): remap super+* keys to herdr 0.8.2 letters, add worktree keys"
```

---

## Task 7: tmux-sessionizer → herdr

**Files:**
- Create: `scripts/herdr-sessionizer`
- Modify: `ghostty/config` (`super+f`)

herdr attaches a session by name (`herdr --session <name>` / `herdr session attach
<name>`), so the rewrite is viable.

- [ ] **Step 1: Rewrite onto herdr**

Copy `~/.local/bin/tmux-sessionizer` to `scripts/herdr-sessionizer`. Replace the
`tmux` session calls: fzf a project dir, derive a session name (basename, dots →
underscores), then `herdr --session <name>` (with the dir as cwd). Keep the fzf
front end.

- [ ] **Step 2: Point `super+f` at it**

Today `super+f` sends `\x02f`, and tmux ran the sessionizer on `prefix+f`. herdr
has no `prefix+f` runner. Options: (a) a herdr `[[keys.command]]` on `prefix+f`
of type `shell`/`popup` running `herdr-sessionizer`; or (b) change `super+f` in
`ghostty/config` to launch `herdr-sessionizer` directly. Pick one, wire it.

- [ ] **Step 3: Verify — INTERACTIVE (hand to the user)**

Press `super+f`. Expected: fzf lists project dirs; picking one opens/attaches a herdr session for it.

- [ ] **Step 4: Commit**

```bash
git add scripts/herdr-sessionizer ghostty/config herdr/config.toml
git commit -m "feat(herdr): port sessionizer onto herdr session attach"
```

---

## Task 8: Retire tmux and the old fish helpers (dormant)

**Files:** dormancy only, no deletions.

- [ ] **Step 1: Confirm tmux is not launched**

Run: `rg -n "tmux (attach|new)" scripts ghostty fish`
Expected: `ghostty-shell` launches herdr; only historic references remain.

- [ ] **Step 2: Mark the trial**

Append to `verify-gate-findings.md`: keep `tmux/`, `tmux.conf`, `fish/functions/wt.fish`, `fish/functions/wtrm.fish` dormant until 2026-08-28, then delete if herdr holds up. `hw`/`hw-rm` supersede `wt`/`wtrm`.

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/plans/verify-gate-findings.md
git commit -m "chore: mark tmux and wt/wtrm dormant pending one-week herdr trial"
```

---

## Done criteria

- Ghostty launches `herdr --session default`; Supacode still launches plain fish.
- `hw <branch>` creates an in-repo worktree, runs `setup.sh`, and opens `nvim` + `claude` + `codex` laid out in one workspace.
- `hw-rm` runs `teardown.sh` (salvage docs, drop DB) then removes the worktree + branch.
- `super+*` splits, tab switching, pane nav, and worktree keys drive herdr.
- `super+f` opens a herdr session picker.
- tmux and `wt`/`wtrm` are dormant, deletable after the trial week.
