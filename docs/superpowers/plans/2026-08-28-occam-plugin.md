# occam Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move four skills out of the dotfiles symlink install and into a standalone Claude Code plugin named `occam`, renamed to `razor`, `scrutiny`, `inquest` and `bench`.

**Architecture:** The repo at `~/Work/optura/occam` is both the plugin and its own single-plugin marketplace, following the layout of `openai-codex`. Skills, commands and hooks sit at the repo root. `hooks/hooks.json` wires three events through `${CLAUDE_PLUGIN_ROOT}`. Two behaviour changes come with the move: the default mode flips to `off`, and the statusline gets an installer because a plugin cannot set the `statusLine` key.

**Tech Stack:** Markdown skills, Node.js hooks (no dependencies, `node --test` for the one unit under test), POSIX shell.

**Spec:** `docs/superpowers/specs/2026-08-28-occam-plugin-design.md`

---

## File Structure

Files created in `~/Work/optura/occam`:

| Path | Responsibility |
|---|---|
| `.claude-plugin/plugin.json` | Plugin identity and version |
| `.claude-plugin/marketplace.json` | Single-plugin marketplace pointing at `./` |
| `skills/razor/SKILL.md` | Compressed output and minimal code |
| `skills/scrutiny/SKILL.md` | Read-only local review |
| `skills/inquest/SKILL.md` | Adversarial PR review that posts to GitHub |
| `skills/inquest/reference.md` | Command mechanics §1–§8 |
| `skills/inquest/sticky-template.md` | Sticky summary template |
| `skills/inquest/check-sticky.sh` | Sticky validator |
| `skills/bench/SKILL.md` | Worktree lifecycle for a PR, over supacode, herdr or plain git |
| `commands/razor-stats.md` | `/razor-stats` slash command |
| `hooks/hooks.json` | Event wiring |
| `hooks/razor-config.js` | Mode resolution, state paths, legacy migration |
| `hooks/razor-activate.js` | SessionStart activation |
| `hooks/razor-mode-tracker.js` | UserPromptSubmit reminder |
| `hooks/razor-stats.js` | Token accounting, `--refresh` on Stop |
| `hooks/razor-statusline.sh` | Badge for an existing statusline |
| `scripts/install-statusline.sh` | Writes `statusLine` into `settings.json` |
| `tests/razor-config.test.js` | Unit tests for the two behaviour changes |
| `README.md` | Install, commands, statusline step |
| `LICENSE` | MIT |

Files changed in `~/.dotfiles` (last task only):

| Path | Change |
|---|---|
| `claude/skills/{tldr,local-review,pr-review,pr-worktree}` | Delete |
| `claude/hooks/tldr-*.{js,sh}` | Delete |
| `claude/commands/tldr-stats.md` | Delete |
| `claude/settings.json.template` | Drop three hook entries, add the plugin |
| `scripts/claude-statusline.sh:148-153` | Resolve the badge script inside the plugin |
| `AGENTS.md` | Record where these skills now live |

`install.sh` needs no change. It symlinks the `skills`, `hooks` and `commands`
directories as a whole, not file by file.

---

### Task 1: Scaffold the repo

**Files:**
- Create: `~/Work/optura/occam/.claude-plugin/plugin.json`
- Create: `~/Work/optura/occam/.claude-plugin/marketplace.json`
- Create: `~/Work/optura/occam/LICENSE`

- [ ] **Step 1: Create the manifest directory**

```bash
cd ~/Work/optura/occam && mkdir -p .claude-plugin skills commands hooks scripts tests
```

- [ ] **Step 2: Write `.claude-plugin/plugin.json`**

```json
{
  "name": "occam",
  "description": "Terse output, adversarial review. /razor cuts words and code; /scrutiny and /inquest cut bad diffs.",
  "version": "1.0.0",
  "author": { "name": "Darius Cupsa" },
  "homepage": "https://github.com/darius-optura/occam",
  "repository": "https://github.com/darius-optura/occam",
  "license": "MIT",
  "keywords": ["skills", "code-review", "token-efficiency", "brevity"]
}
```

- [ ] **Step 3: Write `.claude-plugin/marketplace.json`**

```json
{
  "name": "occam",
  "owner": { "name": "darius-optura" },
  "metadata": {
    "description": "Occam's razor for Claude Code: fewest words, fewest lines, fewest assumptions.",
    "version": "1.0.0"
  },
  "plugins": [
    {
      "name": "occam",
      "description": "Terse output, adversarial review.",
      "version": "1.0.0",
      "author": { "name": "Darius Cupsa" },
      "source": "./"
    }
  ]
}
```

- [ ] **Step 4: Verify both files parse**

Run: `cd ~/Work/optura/occam && node -e "['plugin','marketplace'].forEach(f=>JSON.parse(require('fs').readFileSync('.claude-plugin/'+f+'.json')));console.log('OK')"`
Expected: `OK`

- [ ] **Step 5: Add an MIT LICENSE**

Standard MIT text, copyright `2026 Darius Cupsa`.

- [ ] **Step 6: Commit**

```bash
cd ~/Work/optura/occam
git add .claude-plugin LICENSE
git commit -m "feat: scaffold the occam plugin manifests"
```

---

### Task 2: Copy and rename the four skills

Copy, do not move. The dotfiles copies stay until Task 10 proves the plugin works.

**Files:**
- Create: `skills/razor/SKILL.md`, `skills/scrutiny/SKILL.md`, `skills/inquest/{SKILL.md,reference.md,sticky-template.md,check-sticky.sh}`, `skills/bench/SKILL.md`

- [ ] **Step 1: Copy the files under their new names**

```bash
cd ~/Work/optura/occam
D=~/.dotfiles/claude/skills
mkdir -p skills/razor skills/scrutiny skills/inquest skills/bench
cp "$D/tldr/SKILL.md"          skills/razor/SKILL.md
cp "$D/local-review/SKILL.md"  skills/scrutiny/SKILL.md
cp "$D/pr-review/"*            skills/inquest/
cp "$D/pr-worktree/SKILL.md"   skills/bench/SKILL.md
chmod +x skills/inquest/check-sticky.sh
```

- [ ] **Step 2: Rewrite the four `name:` frontmatter fields**

`skills/razor/SKILL.md` → `name: razor`, `skills/scrutiny/SKILL.md` →
`name: scrutiny`, `skills/inquest/SKILL.md` → `name: inquest`,
`skills/bench/SKILL.md` → `name: bench`.

Leave every `description:` field alone in this step. Task 3 handles them.

- [ ] **Step 3: Verify the frontmatter**

Run: `cd ~/Work/optura/occam && grep -h '^name:' skills/*/SKILL.md | sort`
Expected:
```
name: bench
name: inquest
name: razor
name: scrutiny
```

- [ ] **Step 4: Commit**

```bash
git add skills && git commit -m "feat: add the four skills under their new names"
```

---

### Task 3: Rewrite the cross-references inside the skill bodies

The bodies hold 41 references to the old names. A blind `sed` is wrong here:
some strings are runtime artifacts, not prose. Read the table before editing.

**Files:**
- Modify: `skills/razor/SKILL.md`, `skills/scrutiny/SKILL.md`, `skills/inquest/SKILL.md`, `skills/inquest/reference.md`, `skills/bench/SKILL.md`

- [ ] **Step 1: Apply the rename table**

| Old string | New string | Note |
|---|---|---|
| `` `local-review` `` | `` `scrutiny` `` | Skill reference in prose |
| `` `pr-review` `` | `` `inquest` `` | Skill reference in prose |
| `` `pr-worktree` `` | `` `bench` `` | Skill reference in prose |
| `/pr-worktree <N>` | `/bench <N>` | Command in `bench` description |
| `pr-review/<N>` | `inquest/<N>` | **Git branch name**, in `bench` |
| `pr-review-<N>` | `inquest-<N>` | **Worktree directory name**, in `bench` |
| `.pr-review-map.json` | `.inquest-map.json` | **State file**, in `bench` |
| `tldr` in `razor` prose | `razor` | Skill self-reference |

- [ ] **Step 2: Keep the trigger words in the `razor` description**

The `description:` field of `skills/razor/SKILL.md` must still contain the
literal strings `tldr mode`, `use tldr`, `tldr style`, `be brief` and
`be lazy`. Saying "tldr mode" must keep starting the skill. Rewrite only the
`/tldr` command mention to `/razor`.

- [ ] **Step 3: Define `SKILL_DIR` explicitly in `inquest`**

`skills/inquest/SKILL.md` uses `$SKILL_DIR` at three places without ever
setting it. Inside a plugin the directory is known. Add this line to the
skill body where the sticky phase begins, before the first use:

```bash
SKILL_DIR="${CLAUDE_PLUGIN_ROOT}/skills/inquest"
```

- [ ] **Step 4: Verify no old name survives outside the trigger list**

Run:
```bash
cd ~/Work/optura/occam
grep -rn 'local-review\|pr-worktree\|pr-review' skills/ ; echo "exit=$?"
```
Expected: no matches, `exit=1`.

Run:
```bash
grep -rn 'tldr' skills/ | grep -v '^skills/razor/SKILL.md:'
```
Expected: no output. Every remaining `tldr` lives in the `razor` description.

- [ ] **Step 5: Commit**

```bash
git add skills && git commit -m "refactor: rename the skill cross-references"
```

---

### Task 4: Give `bench` three worktree backends

`bench` currently assumes Supacode. Supacode is not on this machine, and a
teammate may not have it. Probe for a backend instead of assuming one.

**Files:**
- Modify: `skills/bench/SKILL.md`

- [ ] **Step 1: Add the backend probe to the top of the provision flow**

Insert this section before "Provision flow". It runs once per invocation.

```markdown
## Backend

Resolve `BACKEND` first. Do not assume one is present.

```bash
if command -v supacode >/dev/null 2>&1; then BACKEND=supacode
elif command -v herdr  >/dev/null 2>&1; then BACKEND=herdr
else BACKEND=git
fi
echo "backend=$BACKEND"
```

Print the result. A silent choice hides why a later command failed.
```

- [ ] **Step 2: Rewrite provision step 4 as a branch over the three backends**

Steps 1–3 of the provision flow (resolve the PR, fetch the head, delete a
stale branch) are backend-independent and stay as they are. Replace step 4
and step 5 with:

```markdown
4. Create the worktree with the resolved backend.

   **supacode** — capture the printed ID in the same call that creates the
   worktree, per the Supacode ID-tracking rule:
   ```bash
   WT_ID=$(supacode repo worktree-new --branch inquest/<N> --name inquest-<N> --base "$SHA" | tail -n1)
   ```

   **herdr** — `herdr worktree create` prints JSON. Ask for no focus, so
   provisioning never steals the user's current pane:
   ```bash
   OUT=$(herdr worktree create --cwd "$MAIN_ROOT" --branch inquest/<N> \
           --base "$SHA" --label inquest-<N> --no-focus)
   echo "$OUT"
   ```
   Read `WT_PATH` and `WT_ID` out of that JSON. If the shape is not what you
   expect, do not guess — resolve both from the list instead:
   ```bash
   herdr worktree list --cwd "$MAIN_ROOT" \
     | jq -r --arg b "inquest/<N>" '.result.worktrees[] | select(.branch==$b) | .path, .open_workspace_id'
   ```
   `open_workspace_id` is the value `herdr worktree remove --workspace` takes.

   **git** — no workspace manager, so there is no ID. `<owner>` is
   `headRepositoryOwner` from step 1:
   ```bash
   WT_PATH="$MAIN_ROOT/.claude/worktrees/<owner>/inquest-<N>"
   git worktree add "$WT_PATH" "$SHA"
   ```

5. Confirm `WT_PATH` exists and holds the PR's head SHA:
   ```bash
   git -C "$WT_PATH" rev-parse HEAD    # must equal $SHA
   ```
```

- [ ] **Step 3: Record the backend in the state file**

The archive flow must use the backend that created the worktree. Change the
state file shape documented under "State file" to:

```json
{ "1234": { "backend": "herdr", "id": "<WT_ID or empty>", "path": "/abs/path/inquest-1234" } }
```

`backend` is required. `id` is empty for the `git` backend.

- [ ] **Step 4: Rewrite the archive flow as the same three-way branch**

Read `backend`, `id` and `path` from the map. Keep the existing ordering
rule: delete the map entry **before** the archive call, because archiving
can close the surface the caller is running in.

```markdown
**supacode** — `supacode worktree archive -w "$WT_ID"`
**herdr**    — `herdr worktree remove --workspace "$WT_ID" --force`
**git**      — `git worktree remove "$WT_PATH" --force` then
               `git branch -D inquest/<N>`
```

When the map has no entry, fall back to the current backend's own list, and
match on branch `inquest/<N>`. If nothing resolves, stop and report "no
worktree for PR <N>".

- [ ] **Step 5: Update the skill description**

The frontmatter still says "Supacode worktree". Rewrite it:

```
description: Provision or archive an isolated git worktree for a GitHub PR, through Supacode, herdr, or plain git — whichever is installed. Use when asked to "work on PR #N in isolation", spin up a worktree for a PR, or clean one up. `/bench <N>` provisions; `/bench --archive <N>` archives.
```

- [ ] **Step 6: Verify the probe picks herdr on this machine**

Run:
```bash
if command -v supacode >/dev/null 2>&1; then echo supacode
elif command -v herdr >/dev/null 2>&1; then echo herdr
else echo git; fi
```
Expected: `herdr`. Supacode is not installed here, so the herdr path is the
one that gets live-tested in Task 10. The Supacode path stays unverified.

- [ ] **Step 7: Verify the skill no longer assumes one backend**

Run: `grep -c 'supacode' skills/bench/SKILL.md`
Expected: every remaining hit sits inside a `BACKEND=supacode` branch or the
description. No unconditional `supacode` command survives outside a branch.

- [ ] **Step 8: Commit**

```bash
git add skills/bench && git commit -m "feat(bench): probe for supacode, herdr, then plain git

The skill assumed Supacode. Supacode is not installed everywhere, so probe
for a backend and record which one made the worktree, because the archive
flow has to use the same one."
```

---

### Task 5: Port `razor-config.js` with the two behaviour changes

This is the only file with real logic changes, so it is the only file with
unit tests. Write the tests first.

**Files:**
- Create: `hooks/razor-config.js` (copied from `tldr-config.js`, then changed)
- Test: `tests/razor-config.test.js`

- [ ] **Step 1: Copy the file**

```bash
cp ~/.dotfiles/claude/hooks/tldr-config.js ~/Work/optura/occam/hooks/razor-config.js
```

- [ ] **Step 2: Write the failing tests**

```js
// tests/razor-config.test.js
const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');

function freshConfig(env) {
  for (const k of Object.keys(env)) process.env[k] = env[k];
  delete require.cache[require.resolve('../hooks/razor-config.js')];
  return require('../hooks/razor-config.js');
}

test('default mode is off when nothing is configured', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'razor-'));
  const cfg = freshConfig({ XDG_CONFIG_HOME: tmp, RAZOR_DEFAULT_MODE: '' });
  delete process.env.RAZOR_DEFAULT_MODE;
  assert.strictEqual(cfg.getDefaultMode(), 'off');
});

test('RAZOR_DEFAULT_MODE wins over the default', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'razor-'));
  const cfg = freshConfig({ XDG_CONFIG_HOME: tmp, RAZOR_DEFAULT_MODE: 'full' });
  assert.strictEqual(cfg.getDefaultMode(), 'full');
});

test('the config directory is named razor', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'razor-'));
  const cfg = freshConfig({ XDG_CONFIG_HOME: tmp });
  assert.strictEqual(cfg.getConfigDir(), path.join(tmp, 'razor'));
});

test('migration renames a legacy flag and never overwrites', () => {
  const home = fs.mkdtempSync(path.join(os.tmpdir(), 'razor-home-'));
  const xdg = fs.mkdtempSync(path.join(os.tmpdir(), 'razor-xdg-'));
  fs.writeFileSync(path.join(home, '.tldr-active'), 'full');
  fs.mkdirSync(path.join(xdg, 'tldr'), { recursive: true });
  fs.writeFileSync(path.join(xdg, 'tldr', 'config.json'), '{"defaultMode":"full"}');

  const cfg = freshConfig({ CLAUDE_CONFIG_DIR: home, XDG_CONFIG_HOME: xdg });
  cfg.migrateLegacyState();

  assert.strictEqual(fs.readFileSync(path.join(home, '.razor-active'), 'utf8'), 'full');
  assert.ok(!fs.existsSync(path.join(home, '.tldr-active')));
  assert.ok(fs.existsSync(path.join(xdg, 'razor', 'config.json')));

  // A second legacy file must not clobber an existing new file.
  fs.writeFileSync(path.join(home, '.tldr-active'), 'lite');
  cfg.migrateLegacyState();
  assert.strictEqual(fs.readFileSync(path.join(home, '.razor-active'), 'utf8'), 'full');
});
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `cd ~/Work/optura/occam && node --test tests/`
Expected: FAIL. `getConfigDir` returns a `tldr` path, the default is `full`,
and `migrateLegacyState` is not a function.

- [ ] **Step 4: Make the three changes**

In `hooks/razor-config.js`:

1. Replace every `'tldr'` directory segment in `getConfigDir()` with
   `'razor'` (three places: XDG, Windows, POSIX fallback).
2. In `getDefaultMode()`, read `process.env.RAZOR_DEFAULT_MODE` instead of
   `TLDR_DEFAULT_MODE`, and change the final `return 'full';` to
   `return 'off';`.
3. Update the header comment block to match.

- [ ] **Step 5: Add `migrateLegacyState()`**

```js
// One-time rename of pre-occam state. Runs on SessionStart. Never overwrites.
function legacyConfigDir() {
  if (process.env.XDG_CONFIG_HOME) return path.join(process.env.XDG_CONFIG_HOME, 'tldr');
  if (process.platform === 'win32') {
    return path.join(process.env.APPDATA || path.join(os.homedir(), 'AppData', 'Roaming'), 'tldr');
  }
  return path.join(os.homedir(), '.config', 'tldr');
}

function migrateLegacyState() {
  const claudeDir = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
  const pairs = [
    [path.join(claudeDir, '.tldr-active'), path.join(claudeDir, '.razor-active')],
    [path.join(claudeDir, '.tldr-history.jsonl'), path.join(claudeDir, '.razor-history.jsonl')],
    [path.join(claudeDir, '.tldr-statusline-suffix'), path.join(claudeDir, '.razor-statusline-suffix')],
    [legacyConfigDir(), getConfigDir()],
  ];
  for (const [from, to] of pairs) {
    try {
      if (!fs.existsSync(from) || fs.existsSync(to)) continue;
      fs.mkdirSync(path.dirname(to), { recursive: true });
      fs.renameSync(from, to);
    } catch (e) { /* silent — a failed migration must never break the session */ }
  }
}
```

Add `migrateLegacyState` to `module.exports`.

- [ ] **Step 6: Run the tests to verify they pass**

Run: `cd ~/Work/optura/occam && node --test tests/`
Expected: PASS, 4 tests.

- [ ] **Step 7: Commit**

```bash
git add hooks/razor-config.js tests && git commit -m "feat: port the config resolver, default the mode to off

A plugin must not compress a teammate's output without asking, so the
fallback mode becomes off. Add a one-time migration that renames the
pre-occam state files, so existing token statistics survive the rename."
```

---

### Task 6: Port the three remaining hooks

**Files:**
- Create: `hooks/razor-activate.js`, `hooks/razor-mode-tracker.js`, `hooks/razor-stats.js`, `hooks/razor-statusline.sh`

- [ ] **Step 1: Copy under the new names**

```bash
cd ~/Work/optura/occam
D=~/.dotfiles/claude/hooks
cp "$D/tldr-activate.js"     hooks/razor-activate.js
cp "$D/tldr-mode-tracker.js" hooks/razor-mode-tracker.js
cp "$D/tldr-stats.js"        hooks/razor-stats.js
cp "$D/tldr-statusline.sh"   hooks/razor-statusline.sh
chmod +x hooks/razor-statusline.sh
```

- [ ] **Step 2: Rewrite the internals**

In all four files:

| Old | New |
|---|---|
| `require('./tldr-config')` | `require('./razor-config')` |
| `.tldr-active` | `.razor-active` |
| `.tldr-history.jsonl` | `.razor-history.jsonl` |
| `.tldr-statusline-suffix` | `.razor-statusline-suffix` |
| `TLDR_DEBUG` | `RAZOR_DEBUG` |
| `TLDR MODE ACTIVE` | `RAZOR MODE ACTIVE` |
| `[tldr]` log prefix | `[razor]` |
| `'tldr'` in the skill path | `'razor'` |
| `/tldr-` command prefix | `/razor-` |

`razor-activate.js` reads the skill body at
`path.join(__dirname, '..', 'skills', 'tldr', 'SKILL.md')`. Change `tldr` to
`razor`. The relative path itself stays correct: `hooks/` and `skills/` are
siblings inside the plugin.

- [ ] **Step 3: Call the migration from the activation hook**

In `hooks/razor-activate.js`, import and call it before anything else reads
state:

```js
const { getDefaultMode, safeWriteFlag, migrateLegacyState } = require('./razor-config');

migrateLegacyState();
```

- [ ] **Step 4: Verify the hooks run standalone**

Run:
```bash
cd ~/Work/optura/occam
CLAUDE_CONFIG_DIR=$(mktemp -d) XDG_CONFIG_HOME=$(mktemp -d) node hooks/razor-activate.js
```
Expected: prints `OK` and exits 0. The default is `off`, so no skill body
is printed.

Run:
```bash
CLAUDE_CONFIG_DIR=$(mktemp -d) XDG_CONFIG_HOME=$(mktemp -d) RAZOR_DEFAULT_MODE=full \
  node hooks/razor-activate.js | head -3
```
Expected: output begins `RAZOR MODE ACTIVE`.

- [ ] **Step 5: Verify nothing still says tldr**

Run: `cd ~/Work/optura/occam && grep -rn 'tldr\|TLDR' hooks/`
Expected: only the legacy path strings inside `razor-config.js`'s
`migrateLegacyState` and `legacyConfigDir`. Nothing else.

- [ ] **Step 6: Commit**

```bash
git add hooks && git commit -m "feat: port the activation, tracker, stats and statusline hooks"
```

---

### Task 7: Wire the hooks and the command

**Files:**
- Create: `hooks/hooks.json`, `commands/razor-stats.md`

- [ ] **Step 1: Write `hooks/hooks.json`**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          { "type": "command", "command": "node \"${CLAUDE_PLUGIN_ROOT}/hooks/razor-activate.js\"" }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": "node \"${CLAUDE_PLUGIN_ROOT}/hooks/razor-mode-tracker.js\"" }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "node \"${CLAUDE_PLUGIN_ROOT}/hooks/razor-stats.js\" --refresh" }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: Write `commands/razor-stats.md`**

```markdown
---
description: Razor token usage + savings (--share | --all | --since 7d)
argument-hint: [--share|--all|--since 7d]
allowed-tools: Bash(node ${CLAUDE_PLUGIN_ROOT}/hooks/razor-stats.js:*)
---

!`node ${CLAUDE_PLUGIN_ROOT}/hooks/razor-stats.js $ARGUMENTS`

Echo the bash output above verbatim inside a fenced code block. No commentary, no summary, no extra prose — just the code block.
```

- [ ] **Step 3: Verify the JSON parses**

Run: `cd ~/Work/optura/occam && node -e "JSON.parse(require('fs').readFileSync('hooks/hooks.json'));console.log('OK')"`
Expected: `OK`

- [ ] **Step 4: Commit**

```bash
git add hooks/hooks.json commands && git commit -m "feat: wire the three hooks and the /razor-stats command"
```

---

### Task 8: Statusline installer

A plugin cannot set `statusLine`, and the installed plugin path carries a
version that changes on upgrade. The script resolves the path at run time.

**Files:**
- Create: `scripts/install-statusline.sh`

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Writes the razor statusline into the user's Claude Code settings.json.
# Safe to re-run. Refuses to overwrite an existing statusLine.
set -euo pipefail

CFG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$CFG_DIR/settings.json"

SL=$(ls -d "$CFG_DIR"/plugins/cache/occam/occam/*/hooks/razor-statusline.sh 2>/dev/null | sort -V | tail -1 || true)
[ -z "$SL" ] && SL=$(ls -d "$CFG_DIR"/plugins/marketplaces/occam/hooks/razor-statusline.sh 2>/dev/null | head -1 || true)

if [ -z "$SL" ]; then
  echo "razor-statusline.sh not found. Install the occam plugin first." >&2
  exit 1
fi

[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
cp "$SETTINGS" "$SETTINGS.bak"

SL="$SL" node -e '
const fs = require("fs");
const p = process.argv[1];
const s = JSON.parse(fs.readFileSync(p, "utf8"));
if (s.statusLine) {
  console.error("settings.json already has a statusLine. Left untouched.");
  console.error("Add this badge to your own script:  bash " + process.env.SL);
  process.exit(2);
}
s.statusLine = { type: "command", command: "bash " + process.env.SL };
fs.writeFileSync(p, JSON.stringify(s, null, 2) + "\n");
console.log("statusLine set. Backup at " + p + ".bak");
' "$SETTINGS"
```

- [ ] **Step 2: Verify the refusal path**

Run:
```bash
cd ~/Work/optura/occam && chmod +x scripts/install-statusline.sh
T=$(mktemp -d); mkdir -p "$T/plugins/marketplaces/occam/hooks"
cp hooks/razor-statusline.sh "$T/plugins/marketplaces/occam/hooks/"
echo '{"statusLine":{"type":"command","command":"mine"}}' > "$T/settings.json"
CLAUDE_CONFIG_DIR="$T" bash scripts/install-statusline.sh; echo "exit=$?"
```
Expected: the message `settings.json already has a statusLine. Left untouched.`
and `exit=2`. The existing `statusLine` value is unchanged.

- [ ] **Step 3: Verify the happy path**

Run:
```bash
T=$(mktemp -d); mkdir -p "$T/plugins/marketplaces/occam/hooks"
cp hooks/razor-statusline.sh "$T/plugins/marketplaces/occam/hooks/"
echo '{}' > "$T/settings.json"
CLAUDE_CONFIG_DIR="$T" bash scripts/install-statusline.sh && cat "$T/settings.json"
```
Expected: `statusLine set.` and the JSON holds a `statusLine.command` ending
in `razor-statusline.sh`.

- [ ] **Step 4: Commit**

```bash
git add scripts && git commit -m "feat: add the statusline installer

A plugin cannot set the statusLine key, so ship a script that resolves the
installed plugin path and writes it. It refuses to overwrite an existing
statusline and prints the badge command instead."
```

---

### Task 9: README

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write it**

Sections, in this order:

1. One-paragraph description.
2. **Install** — the two `claude plugin` commands.
3. **Commands** — a table of `/razor`, `/razor-stats`, `/scrutiny`,
   `/inquest`, `/bench`, one line each.
4. **Razor is off by default** — how to turn it on, all three ways.
5. **Statusline (optional)** — run `scripts/install-statusline.sh`, and what
   to do when you already have a statusline.
6. **Upgrading from the dotfiles version** — the state files migrate
   automatically on the first session; `RAZOR_DEFAULT_MODE` replaces
   `TLDR_DEFAULT_MODE`.
7. **Optional dependency** — `inquest` uses the Codex companion when it is
   installed and records `skipped` when it is not.

- [ ] **Step 2: Commit and push**

```bash
git add README.md && git commit -m "docs: add the README"
git push -u origin main
```

---

### Task 10: Install and verify end to end

Nothing gets deleted from the dotfiles until every check here passes.

- [ ] **Step 1: Install from the remote**

```bash
claude plugin marketplace add darius-optura/occam
claude plugin install occam@occam
```

- [ ] **Step 2: Verify the skills are discovered**

Start a new Claude Code session. Confirm `razor`, `scrutiny`, `inquest` and
`bench` appear in the skill list, and `/razor-stats` in the command list.

- [ ] **Step 3: Verify razor is off by default and the migration ran**

The session start prints `OK`, not a skill body, on a machine with no
`~/.config/razor/config.json`. Then check:

```bash
ls -la ~/.claude/.razor-history.jsonl ~/.config/razor/config.json
ls ~/.claude/.tldr-history.jsonl 2>&1
```
Expected: the razor paths exist, the tldr path is gone.

**Warning:** confirm `.razor-history.jsonl` is roughly 162 KB before you go
on. If it is missing or empty, the statistics were lost. Stop and restore
from `~/.claude/.tldr-history.jsonl` before continuing.

- [ ] **Step 4: Verify razor turns on**

Run `/razor` in a session. Expected: the banner reads `RAZOR MODE ACTIVE`.
Then run `/razor-stats`. Expected: it reports the migrated history, not zero.

- [ ] **Step 5: Verify scrutiny**

Run `/scrutiny` against a working tree that has uncommitted changes.
Expected: a scored review printed to the terminal, nothing posted anywhere.

- [ ] **Step 6: Verify inquest against a throwaway PR**

This is the step the plan exists for. `inquest` is the largest skill and the
only one that writes to GitHub, so a missed reference fails here, not at
install time. Open a small throwaway PR and run `/inquest <N>`.

Expected: it provisions a worktree through `bench`, posts inline threads and
one sticky summary, prints a score out of 10, and the sticky validator
prints `OK`. Confirm `bench` printed `backend=herdr`, and that the worktree
branch is named `inquest/<N>`.

Then archive it: `/bench --archive <N>`. Confirm the workspace closes and
the map entry is gone.

- [ ] **Step 6b: Verify the plain git backend**

The herdr path is the only one this machine exercises by default. Force the
fallback and confirm it works, because a teammate may have neither tool:

```bash
env PATH=/usr/bin:/bin bash -c 'command -v supacode || command -v herdr || echo git'
```
Expected: `git`. Then run `/bench <N>` once with that reduced `PATH` and
confirm it creates `.claude/worktrees/<owner>/inquest-<N>` and that
`/bench --archive <N>` removes it and deletes branch `inquest/<N>`.

- [ ] **Step 7: Verify inquest without Codex**

Run `/inquest` once with the Codex CLI unavailable (`PATH` without `codex`).
Expected: it completes and the sticky's Codex line reads
`skipped — codex CLI not installed`. A silent skip is a failure.

---

### Task 11: Strip the dotfiles repo

Only after Task 10 passes.

**Files:**
- Delete: `claude/skills/{tldr,local-review,pr-review,pr-worktree}`, `claude/hooks/tldr-*.{js,sh}`, `claude/commands/tldr-stats.md`
- Modify: `claude/settings.json.template`, `scripts/claude-statusline.sh`, `AGENTS.md`

- [ ] **Step 1: Delete the moved files**

```bash
cd ~/.dotfiles
git rm -r claude/skills/tldr claude/skills/local-review \
          claude/skills/pr-review claude/skills/pr-worktree
git rm claude/hooks/tldr-activate.js claude/hooks/tldr-mode-tracker.js \
       claude/hooks/tldr-stats.js claude/hooks/tldr-config.js \
       claude/hooks/tldr-statusline.sh claude/commands/tldr-stats.md
```

- [ ] **Step 2: Update `claude/settings.json.template`**

Remove the `node __HOME__/.claude/hooks/tldr-activate.js` entry from
`SessionStart` and the `tldr-mode-tracker.js` entry from `UserPromptSubmit`.
Leave `flow-breaker nudge` and `remote-control-keepawake.sh` in place. Add
`"occam@occam": true` to `enabledPlugins`.

- [ ] **Step 3: Fix the statusline badge**

`scripts/claude-statusline.sh:150` calls a file that no longer exists.
Replace the badge block with a resolver:

```bash
# ── razor badge ──────────────────────────────────────────────────────────────
razor_sl=$(ls -d "${HOME}"/.claude/plugins/cache/occam/occam/*/hooks/razor-statusline.sh 2>/dev/null | sort -V | tail -1)
if [ -n "$razor_sl" ]; then
  razor_badge=$(bash "$razor_sl" 2>/dev/null)
  [ -n "$razor_badge" ] && parts+=("$razor_badge")
fi
```

- [ ] **Step 4: Keep this machine in compressed mode**

The plugin defaults to `off`. This machine wants `full`:

```bash
mkdir -p ~/.config/razor
echo '{"defaultMode":"full"}' > ~/.config/razor/config.json
```

- [ ] **Step 5: Note the move in `AGENTS.md`**

One line: the `razor`, `scrutiny`, `inquest` and `bench` skills live in
`darius-optura/occam` and install as the `occam` plugin. They are no longer
symlinked from this repo.

- [ ] **Step 6: Verify the dotfiles install still works**

Run: `cd ~/.dotfiles && ./install.sh --dry-run 2>&1 | tail -20`
Expected: no error about a missing `tldr-*` file. `install.sh` symlinks the
`skills`, `hooks` and `commands` directories as a whole, so it needs no edit.

Run: `bash scripts/claude-statusline.sh` in a session that has the plugin.
Expected: the razor badge appears, exactly as before the move.

- [ ] **Step 7: Verify the remaining skills survived**

Run: `ls ~/.claude/skills/`
Expected: `commit`, `diagnose`, `flow-breaker`, `gh-stack`, `supacode-cli`,
`supacode-deeplinks`. No `tldr`, no review skills.

- [ ] **Step 8: Commit**

```bash
git add -A claude scripts AGENTS.md
git commit -m "refactor(claude): move four skills into the occam plugin

The razor, scrutiny, inquest and bench skills now install from
darius-optura/occam instead of the symlink install. The statusline
resolves the badge script inside the installed plugin."
```
