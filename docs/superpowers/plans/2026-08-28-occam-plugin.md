# occam Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move four skills out of the dotfiles symlink install and into a standalone Claude Code plugin named `occam`, renamed to `razor`, `scrutiny`, `inquest` and `bench`, with intensity levels and token statistics deleted rather than ported.

**Architecture:** The repo at `~/Work/optura/occam` is both the plugin and its own single-plugin marketplace, following the layout of `openai-codex`. Skills and hooks sit at the repo root. `hooks/hooks.json` wires two events through `${CLAUDE_PLUGIN_ROOT}`. There is no `commands/` directory and no state migration.

**Tech Stack:** Markdown skills, Node.js hooks (no dependencies, `node --test`), POSIX shell.

**Spec:** `docs/superpowers/specs/2026-08-28-occam-plugin-design.md`

---

## File Structure

Created in `~/Work/optura/occam`:

| Path | Responsibility |
|---|---|
| `.claude-plugin/plugin.json` | Plugin identity and version |
| `.claude-plugin/marketplace.json` | Single-plugin marketplace pointing at `./` |
| `skills/razor/SKILL.md` | Compressed output and minimal code, one level |
| `skills/scrutiny/SKILL.md` | Read-only local review |
| `skills/inquest/SKILL.md` | Adversarial PR review that posts to GitHub |
| `skills/inquest/reference.md` | Command mechanics §1–§8 |
| `skills/inquest/sticky-template.md` | Sticky summary template |
| `skills/inquest/check-sticky.sh` | Sticky validator |
| `skills/bench/SKILL.md` | Worktree lifecycle, over supacode, herdr or plain git |
| `hooks/hooks.json` | Event wiring, two events |
| `hooks/razor-config.js` | On/off resolution and flag file access |
| `hooks/razor-activate.js` | SessionStart activation |
| `hooks/razor-mode-tracker.js` | UserPromptSubmit reminder |
| `hooks/razor-statusline.sh` | `[RAZOR]` badge |
| `scripts/install-statusline.sh` | Writes `statusLine` into `settings.json` |
| `tests/razor-config.test.js` | Unit tests for the on/off resolver |
| `README.md` | Install, skills, how to turn razor on, statusline |
| `LICENSE` | MIT |

Changed in `~/.dotfiles` (Task 12 only):

| Path | Change |
|---|---|
| `claude/skills/{tldr,local-review,pr-review,pr-worktree}` | Delete |
| `claude/hooks/tldr-*.{js,sh}` | Delete, all five |
| `claude/commands/tldr-stats.md` | Delete |
| `claude/settings.json.template` | Drop the two tldr hook entries, add the plugin |
| `scripts/claude-statusline.sh:148-153` | Resolve the badge inside the plugin |
| `AGENTS.md` | Record where these skills now live |

`install.sh` needs no change. It symlinks `skills`, `hooks` and `commands` as
whole directories, so deleting the files is the entire job.

---

### Task 1: Scaffold the repo

**Files:**
- Create: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `LICENSE`

- [ ] **Step 1: Create the directories**

```bash
cd ~/Work/optura/occam && mkdir -p .claude-plugin skills hooks scripts tests
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

No placeholder text. The plugin entry carries a real description.

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
      "description": "Terse output and adversarial code review: razor, scrutiny, inquest and bench.",
      "version": "1.0.0",
      "author": { "name": "Darius Cupsa" },
      "source": "./"
    }
  ]
}
```

- [ ] **Step 4: Verify both parse**

Run: `cd ~/Work/optura/occam && node -e "['plugin','marketplace'].forEach(f=>JSON.parse(require('fs').readFileSync('.claude-plugin/'+f+'.json')));console.log('OK')"`
Expected: `OK`

- [ ] **Step 5: Add an MIT LICENSE**

Standard MIT text, copyright `2026 Darius Cupsa`.

- [ ] **Step 6: Commit**

```bash
git add .claude-plugin LICENSE && git commit -m "feat: scaffold the occam plugin manifests"
```

---

### Task 2: Copy the four skills under their new names

Copy, do not move. The dotfiles copies stay until Task 11 proves the plugin works.

**Files:**
- Create: `skills/razor/SKILL.md`, `skills/scrutiny/SKILL.md`, `skills/inquest/{SKILL.md,reference.md,sticky-template.md,check-sticky.sh}`, `skills/bench/SKILL.md`

- [ ] **Step 1: Copy**

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

- [ ] **Step 2: Rewrite the four `name:` fields**

`razor`, `scrutiny`, `inquest`, `bench`. Leave every `description:` alone;
Tasks 3 and 4 handle those.

- [ ] **Step 3: Verify**

Run: `grep -h '^name:' skills/*/SKILL.md | sort`
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

### Task 3: Strip the intensity levels from `razor`

The levels reference three skills nobody wrote. Delete them from the body
before rewriting the references, so Task 4 has less to touch.

**Files:**
- Modify: `skills/razor/SKILL.md`

- [ ] **Step 1: Delete the level machinery from the frontmatter**

Remove the `argument-hint: "[lite|full|ultra]"` line. In `description:`,
delete the clause `Supports intensity levels: lite, full (default), ultra.`
Keep every trigger phrase: `tldr mode`, `use tldr`, `tldr style`,
`less tokens`, `be brief`, `be lazy`, `simplest solution`, `do less`. Change
the `/tldr` mention to `/razor`.

- [ ] **Step 2: Delete the level machinery from the body**

| Delete | Where |
|---|---|
| `Default: **full**. Switch: /tldr lite\|full\|ultra.` | Persistence section |
| The `\| **lite** \|` and `\| **ultra** \|` table rows | Intensity table |
| The `- lite:` and `- ultra:` example lines | Both example pairs, four lines |
| "at any level, including ultra" | STATE section, reword to "always" |

Keep the `| **full** |` row, but drop the now-pointless table header wording
about levels if it reads oddly with one row. The `## Intensity` heading may
go; its content becomes plain prose.

- [ ] **Step 3: Verify no level survives**

Run: `grep -n 'lite\|ultra\|argument-hint\|intensity levels' skills/razor/SKILL.md`
Expected: no output.

- [ ] **Step 4: Verify the triggers survive**

Run: `grep -c 'tldr' skills/razor/SKILL.md`
Expected: at least 1. Every hit must sit inside `description:`.

- [ ] **Step 5: Commit**

```bash
git add skills/razor && git commit -m "refactor(razor): drop the intensity levels

lite and ultra, and the commit/review/compress modes, referenced skills that
were never written. One behaviour remains, on or off."
```

---

### Task 4: Rewrite the cross-references

The four bodies hold 64 references to the old names. Some strings are
runtime artifacts, not prose. Read the table before editing.

**Files:**
- Modify: every file under `skills/`

- [ ] **Step 1: Apply the rename table**

| Old string | New string | Kind |
|---|---|---|
| `` `local-review` `` | `` `scrutiny` `` | Prose |
| `` `pr-review` `` | `` `inquest` `` | Prose |
| `` `pr-worktree` `` | `` `bench` `` | Prose |
| `/pr-worktree <N>` | `/bench <N>` | Command |
| `pr-review/<N>` | `inquest/<N>` | **Git branch name** |
| `pr-review-<N>` | `inquest-<N>` | **Worktree directory** |
| `.pr-review-map.json` | `.inquest-map.json` | **State file** |
| `<!-- pr-review:sticky -->` | `<!-- inquest:sticky -->` | **Wire marker** |
| `pr-review passed` | `inquest passed` | **GitHub label** |

- [ ] **Step 2: Change the sticky marker in all three files together**

The marker lives in `sticky-template.md` line 1, in `check-sticky.sh` which
validates that exact line, and in `reference.md` which greps for it to find
an existing sticky. Change all three in one edit or the validator fails.

Accepted consequence: a sticky already posted on an open PR is no longer
found, so a re-review posts a second one. Note this in the README.

- [ ] **Step 3: Define `SKILL_DIR` in `inquest`**

`skills/inquest/SKILL.md` uses `$SKILL_DIR` three times and never sets it.
Add this before the first use, in the sticky phase:

```bash
SKILL_DIR="${CLAUDE_PLUGIN_ROOT}/skills/inquest"
```

- [ ] **Step 4: Verify the old names are gone**

Run:
```bash
cd ~/Work/optura/occam
grep -rn 'local-review\|pr-worktree\|pr-review' skills/ ; echo "exit=$?"
```
Expected: no matches, `exit=1`. This covers `sticky-template.md`,
`check-sticky.sh` and `reference.md`, not only the two `SKILL.md` files.

Run:
```bash
grep -rn 'tldr' skills/ | grep -v '^skills/razor/SKILL.md:'
```
Expected: no output.

- [ ] **Step 5: Verify the validator still passes its own template**

Run:
```bash
cd ~/Work/optura/occam/skills/inquest
cp sticky-template.md /tmp/sticky-check.md
bash check-sticky.sh /tmp/sticky-check.md 2>&1 | head -5
```
Expected: it complains about unfilled `<…>` placeholders, **not** about a
missing or wrong marker on line 1. A marker complaint means Step 2 missed a
file.

- [ ] **Step 6: Commit**

```bash
git add skills && git commit -m "refactor: rename the skill cross-references

Includes the runtime artifacts, not only prose: the git branch prefix, the
worktree directory name, the state file, the sticky marker and the GitHub
label."
```

---

### Task 5: Give `bench` three worktree backends

**Files:**
- Modify: `skills/bench/SKILL.md`

- [ ] **Step 1: Add the backend probe before the provision flow**

`BENCH_BACKEND` overrides the probe so each path can be tested without
changing what is installed.

````markdown
## Backend

Resolve `BACKEND` first. Do not assume one is present.

```bash
if [ -n "${BENCH_BACKEND:-}" ]; then BACKEND="$BENCH_BACKEND"
elif command -v supacode >/dev/null 2>&1; then BACKEND=supacode
elif command -v herdr    >/dev/null 2>&1; then BACKEND=herdr
else BACKEND=git
fi
echo "backend=$BACKEND"
```

Print the result. A silent choice hides why a later command failed.
````

- [ ] **Step 2: Rewrite provision steps 4 and 5 as a three-way branch**

Provision steps 1–3 (resolve the PR, fetch the head, delete a stale branch)
are backend-independent and stay as they are.

````markdown
4. Create the worktree with the resolved backend.

   **supacode** — capture the printed ID in the same call that creates the
   worktree, per the Supacode ID-tracking rule:
   ```bash
   WT_ID=$(supacode repo worktree-new --branch inquest/<N> --name inquest-<N> --base "$SHA" | tail -n1)
   ```

   **herdr** — prints JSON. Ask for no focus, so provisioning never steals
   the user's current pane:
   ```bash
   herdr worktree create --cwd "$MAIN_ROOT" --branch inquest/<N> \
     --base "$SHA" --label inquest-<N> --no-focus
   ```
   Then resolve both values from the list, which has a known shape:
   ```bash
   herdr worktree list --cwd "$MAIN_ROOT" \
     | jq -r --arg b "inquest/<N>" \
       '.result.worktrees[] | select(.branch==$b) | .path, .open_workspace_id'
   ```
   `open_workspace_id` is what `herdr worktree remove --workspace` takes.
   Without `jq`, read the same two fields with `node -e`.

   **git** — no workspace manager, so there is no ID. `<owner>` is
   `headRepositoryOwner` from step 1:
   ```bash
   WT_PATH="$MAIN_ROOT/.claude/worktrees/<owner>/inquest-<N>"
   git worktree add "$WT_PATH" "$SHA"
   ```

5. Confirm the checkout is at the PR's head:
   ```bash
   git -C "$WT_PATH" rev-parse HEAD    # must equal $SHA
   ```
````

- [ ] **Step 3: Record the backend in the state file**

Under "State file", change the documented shape to:

```json
{ "1234": { "backend": "herdr", "id": "<WT_ID or empty>", "path": "/abs/path/inquest-1234" } }
```

`backend` is required. `id` is empty for the `git` backend.

- [ ] **Step 4: Rewrite the archive flow as the same three-way branch**

Read `backend`, `id` and `path` from the map. Keep the existing ordering
rule: delete the map entry **before** the archive call, because archiving
can close the surface the caller is running in.

```
supacode — supacode worktree archive -w "$WT_ID"
herdr    — herdr worktree remove --workspace "$WT_ID" --force
git      — git worktree remove "$WT_PATH" --force
           git branch -D inquest/<N>
```

With no map entry, fall back to the current backend's own list and match on
branch `inquest/<N>`. If nothing resolves, stop: "no worktree for PR <N>".

- [ ] **Step 5: Rewrite the description**

```
description: Provision or archive an isolated git worktree for a GitHub PR, through Supacode, herdr, or plain git — whichever is installed. Use when asked to "work on PR #N in isolation", spin up a worktree for a PR, or clean one up. `/bench <N>` provisions; `/bench --archive <N>` archives.
```

- [ ] **Step 6: Verify the probe**

Run:
```bash
unset BENCH_BACKEND
if command -v supacode >/dev/null 2>&1; then echo supacode
elif command -v herdr >/dev/null 2>&1; then echo herdr; else echo git; fi
BENCH_BACKEND=git bash -c 'echo "override=$BENCH_BACKEND"'
```
Expected: `herdr`, then `override=git`. Supacode is not installed here, so
the herdr path is the one Task 11 live-tests.

- [ ] **Step 7: Verify no unconditional supacode call survives**

Run: `grep -n 'supacode' skills/bench/SKILL.md`
Expected: every hit sits inside a `BACKEND=supacode` branch or the
description.

- [ ] **Step 8: Commit**

```bash
git add skills/bench && git commit -m "feat(bench): probe for supacode, herdr, then plain git

The skill assumed Supacode, which is not installed everywhere. Probe for a
backend, allow BENCH_BACKEND to override it, and record which backend made
the worktree, because the archive flow has to use the same one."
```

---

### Task 6: Port `razor-config.js` as an on/off resolver

The only file with real logic changes, so the only file with unit tests.
Write the tests first.

**Files:**
- Create: `hooks/razor-config.js`
- Test: `tests/razor-config.test.js`

- [ ] **Step 1: Copy the source**

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
  for (const k of ['RAZOR_DEFAULT_MODE', 'XDG_CONFIG_HOME', 'CLAUDE_CONFIG_DIR']) delete process.env[k];
  Object.assign(process.env, env);
  delete require.cache[require.resolve('../hooks/razor-config.js')];
  return require('../hooks/razor-config.js');
}
const tmp = () => fs.mkdtempSync(path.join(os.tmpdir(), 'razor-'));

test('off by default when nothing is configured', () => {
  const cfg = freshConfig({ XDG_CONFIG_HOME: tmp() });
  assert.strictEqual(cfg.isEnabledByDefault(), false);
});

test('RAZOR_DEFAULT_MODE=on enables it', () => {
  const cfg = freshConfig({ XDG_CONFIG_HOME: tmp(), RAZOR_DEFAULT_MODE: 'on' });
  assert.strictEqual(cfg.isEnabledByDefault(), true);
});

test('the config file enables it', () => {
  const x = tmp();
  fs.mkdirSync(path.join(x, 'razor'));
  fs.writeFileSync(path.join(x, 'razor', 'config.json'), '{"enabled":true}');
  const cfg = freshConfig({ XDG_CONFIG_HOME: x });
  assert.strictEqual(cfg.isEnabledByDefault(), true);
  assert.strictEqual(cfg.getConfigDir(), path.join(x, 'razor'));
});

test('the flag file round-trips and rejects junk', () => {
  const home = tmp();
  const cfg = freshConfig({ XDG_CONFIG_HOME: tmp(), CLAUDE_CONFIG_DIR: home });
  const flag = path.join(home, '.razor-active');

  assert.strictEqual(cfg.isActive(flag), false);
  cfg.safeWriteFlag(flag, 'on');
  assert.strictEqual(cfg.isActive(flag), true);

  fs.writeFileSync(flag, 'full');
  assert.strictEqual(cfg.isActive(flag), false);
});
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `cd ~/Work/optura/occam && node --test tests/`
Expected: FAIL. `isEnabledByDefault` and `isActive` are not functions, and
`getConfigDir` returns a `tldr` path.

- [ ] **Step 4: Make the changes**

1. `getConfigDir()` — replace all three `'tldr'` segments with `'razor'`.
2. Delete `VALID_MODES`.
3. Replace `getDefaultMode()` with:

```js
function isEnabledByDefault() {
  if ((process.env.RAZOR_DEFAULT_MODE || '').toLowerCase() === 'on') return true;
  try {
    return JSON.parse(fs.readFileSync(getConfigPath(), 'utf8')).enabled === true;
  } catch (e) {
    return false;
  }
}
```

4. Replace `readFlag()` with `isActive()`. Keep every symlink and size guard
   the original had; change only the final validation:

```js
    const raw = out.trim().toLowerCase();
    return raw === 'on';
```

   and make the guard failures `return false` instead of `return null`.
5. Delete `appendFlag` and `readHistory`. Nothing else uses them once
   statistics are gone.
6. `TLDR_DEBUG` → `RAZOR_DEBUG`, `[tldr]` → `[razor]`, and update the header
   comment.
7. New exports:

```js
module.exports = { isEnabledByDefault, getConfigDir, getConfigPath, safeWriteFlag, isActive };
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `cd ~/Work/optura/occam && node --test tests/`
Expected: PASS, 4 tests.

- [ ] **Step 6: Commit**

```bash
git add hooks/razor-config.js tests && git commit -m "feat: port the resolver as on/off, defaulting to off

A plugin must not compress a teammate's output without asking, so the
fallback is off. Levels and the statistics helpers are deleted."
```

---

### Task 7: Port the activation hook, the tracker and the badge

**Files:**
- Create: `hooks/razor-activate.js`, `hooks/razor-mode-tracker.js`, `hooks/razor-statusline.sh`

- [ ] **Step 1: Copy under the new names**

```bash
cd ~/Work/optura/occam
D=~/.dotfiles/claude/hooks
cp "$D/tldr-activate.js"     hooks/razor-activate.js
cp "$D/tldr-mode-tracker.js" hooks/razor-mode-tracker.js
cp "$D/tldr-statusline.sh"   hooks/razor-statusline.sh
chmod +x hooks/razor-statusline.sh
```

Do **not** copy `tldr-stats.js`. It is deleted, not ported.

- [ ] **Step 2: Rewrite `razor-activate.js`**

```js
#!/usr/bin/env node
// razor — Claude Code SessionStart activation hook

const fs = require('fs');
const path = require('path');
const os = require('os');
const { isEnabledByDefault, safeWriteFlag } = require('./razor-config');

const claudeDir = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
const flagPath = path.join(claudeDir, '.razor-active');

if (!isEnabledByDefault()) {
  try { fs.unlinkSync(flagPath); } catch (e) {}
  process.stdout.write('OK');
  process.exit(0);
}

safeWriteFlag(flagPath, 'on');

let body = '';
try {
  const raw = fs.readFileSync(path.join(__dirname, '..', 'skills', 'razor', 'SKILL.md'), 'utf8');
  body = raw.replace(/^---[\s\S]*?---\s*/, '');
} catch (e) { /* fall through */ }

process.stdout.write(body ? 'RAZOR MODE ACTIVE\n\n' + body : 'RAZOR MODE ACTIVE');
```

The level-filtering `reduce` over the body is deleted with the levels. The
relative path to `skills/` still resolves: `hooks/` and `skills/` are
siblings inside the plugin.

- [ ] **Step 3: Rewrite the matcher in `razor-mode-tracker.js`**

Claude Code namespaces a plugin's skills, so the command arrives as
`/occam:razor` as well as `/razor`. The old `startsWith('/tldr')` gate would
never fire. Replace the whole command block with:

```js
const CMDS = new Set(['/razor', '/occam:razor', '/razor:razor']);
const OFF_ARGS = new Set(['off', 'stop', 'disable']);

const parts = prompt.split(/\s+/);
if (CMDS.has(parts[0])) {
  if (OFF_ARGS.has(parts[1] || '')) {
    try { fs.unlinkSync(flagPath); } catch (e) {}
  } else {
    safeWriteFlag(flagPath, 'on');
  }
}
```

- [ ] **Step 4: Keep both trigger words in the regexes**

The natural-language regexes must match `tldr` **and** `razor`, so the
phrase the user already types keeps working. Change `\btldr\b` to
`\b(?:tldr|razor)\b` in all four regexes (two on, two off). Everything the
user sees still says razor only.

- [ ] **Step 5: Rewrite the banner and the flag read**

`readFlag` is gone. Use `isActive`:

```js
if (isActive(flagPath)) {
  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: "RAZOR MODE ACTIVE. " +
        "Drop articles/filler/pleasantries/hedging. Fragments OK. " +
        "Write in ASD-STE100 Simplified Technical English: one word one meaning, " +
        "short common verbs, active voice, one instruction per sentence, max 20 words. " +
        "Code/commits/security: write normal."
    }
  }));
}
```

Delete `INDEPENDENT_MODES` and the `VALID_MODES` argument parsing.

- [ ] **Step 6: Shrink `razor-statusline.sh` to the badge**

```bash
#!/bin/bash
# razor — statusline badge fragment. Prints [RAZOR] when razor is on.
# Designed to be appended to an existing statusline.

FLAG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.razor-active"

[ -L "$FLAG" ] && exit 0
[ -f "$FLAG" ] || exit 0
[ "$(head -c 8 "$FLAG" 2>/dev/null | tr -d '\n\r')" = "on" ] || exit 0

printf '\033[38;5;172m[RAZOR]\033[0m'
```

The savings suffix and `TLDR_STATUSLINE_SAVINGS` go with the statistics.

- [ ] **Step 7: Verify the hooks standalone**

```bash
cd ~/Work/optura/occam
C=$(mktemp -d); X=$(mktemp -d)
CLAUDE_CONFIG_DIR=$C XDG_CONFIG_HOME=$X node hooks/razor-activate.js; echo
CLAUDE_CONFIG_DIR=$C XDG_CONFIG_HOME=$X bash hooks/razor-statusline.sh; echo "[badge-off]"
CLAUDE_CONFIG_DIR=$C XDG_CONFIG_HOME=$X RAZOR_DEFAULT_MODE=on node hooks/razor-activate.js | head -1
CLAUDE_CONFIG_DIR=$C bash hooks/razor-statusline.sh; echo "[badge-on]"
```
Expected: `OK`, then nothing before `[badge-off]`, then `RAZOR MODE ACTIVE`,
then `[RAZOR]` before `[badge-on]`.

- [ ] **Step 8: Verify the tracker on both command forms and both words**

```bash
C=$(mktemp -d)
for p in '/razor' '/occam:razor' 'switch to tldr mode' 'razor mode please'; do
  echo "{\"prompt\":\"$p\"}" | CLAUDE_CONFIG_DIR=$C XDG_CONFIG_HOME=$(mktemp -d) \
    node hooks/razor-mode-tracker.js >/dev/null
  printf '%-22s -> %s\n' "$p" "$(cat $C/.razor-active 2>/dev/null || echo MISSING)"
  rm -f $C/.razor-active
done
echo '{"prompt":"/razor off"}' | CLAUDE_CONFIG_DIR=$C node hooks/razor-mode-tracker.js >/dev/null
ls $C/.razor-active 2>&1 | tail -1
```
Expected: all four prompts print `on`; the last line reports the flag is
gone.

- [ ] **Step 9: Verify nothing still says tldr outside the regexes**

Run: `grep -rn 'tldr\|TLDR' hooks/`
Expected: only the `(?:tldr|razor)` alternations in the tracker.

- [ ] **Step 10: Commit**

```bash
git add hooks && git commit -m "feat: port the activation hook, the tracker and the badge

The tracker accepts the namespaced /occam:razor form, and its plain-English
regexes accept both tldr and razor so the phrase already in use keeps
working. Everything the user sees says razor."
```

---

### Task 8: Wire the hooks

**Files:**
- Create: `hooks/hooks.json`

- [ ] **Step 1: Write it**

Two events. There is no `Stop` hook, because statistics are gone.

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
    ]
  }
}
```

- [ ] **Step 2: Verify it parses**

Run: `node -e "JSON.parse(require('fs').readFileSync('hooks/hooks.json'));console.log('OK')"`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add hooks/hooks.json && git commit -m "feat: wire the two hooks"
```

---

### Task 9: Statusline installer

**Files:**
- Create: `scripts/install-statusline.sh`

- [ ] **Step 1: Write it**

The backup is taken **after** the refusal check, so a refused run leaves no
stray `.bak`. Both plugin layouts are searched.

```bash
#!/usr/bin/env bash
# Writes the razor statusline into the user's Claude Code settings.json.
# Safe to re-run. Refuses to overwrite an existing statusLine.
set -euo pipefail

CFG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$CFG_DIR/settings.json"

SL=$(ls -d "$CFG_DIR"/plugins/cache/occam/occam/*/hooks/razor-statusline.sh 2>/dev/null | sort -V | tail -1 || true)
if [ -z "$SL" ]; then
  SL=$(ls -d "$CFG_DIR"/plugins/marketplaces/occam/hooks/razor-statusline.sh 2>/dev/null | head -1 || true)
fi

if [ -z "$SL" ]; then
  echo "razor-statusline.sh not found. Install the occam plugin first." >&2
  exit 1
fi

[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

SL="$SL" node -e '
const fs = require("fs");
const p = process.argv[1];
const s = JSON.parse(fs.readFileSync(p, "utf8"));
if (s.statusLine) {
  console.error("settings.json already has a statusLine. Left untouched.");
  console.error("Add this badge to your own script:  bash " + process.env.SL);
  process.exit(2);
}
fs.copyFileSync(p, p + ".bak");
s.statusLine = { type: "command", command: "bash " + process.env.SL };
fs.writeFileSync(p, JSON.stringify(s, null, 2) + "\n");
console.log("statusLine set. Backup at " + p + ".bak");
' "$SETTINGS"
```

- [ ] **Step 2: Verify the refusal path leaves no backup**

```bash
cd ~/Work/optura/occam && chmod +x scripts/install-statusline.sh
T=$(mktemp -d); mkdir -p "$T/plugins/marketplaces/occam/hooks"
cp hooks/razor-statusline.sh "$T/plugins/marketplaces/occam/hooks/"
echo '{"statusLine":{"type":"command","command":"mine"}}' > "$T/settings.json"
CLAUDE_CONFIG_DIR="$T" bash scripts/install-statusline.sh; echo "exit=$?"
ls "$T"/settings.json.bak 2>&1 | tail -1
```
Expected: the refusal message, `exit=2`, and **no** `.bak` file.

- [ ] **Step 3: Verify the happy path**

```bash
T=$(mktemp -d); mkdir -p "$T/plugins/marketplaces/occam/hooks"
cp hooks/razor-statusline.sh "$T/plugins/marketplaces/occam/hooks/"
echo '{}' > "$T/settings.json"
CLAUDE_CONFIG_DIR="$T" bash scripts/install-statusline.sh && cat "$T/settings.json"
```
Expected: `statusLine set.` and a `statusLine.command` ending in
`razor-statusline.sh`.

- [ ] **Step 4: Commit**

```bash
git add scripts && git commit -m "feat: add the statusline installer

A plugin cannot set the statusLine key, so ship a script that resolves the
installed plugin path and writes it."
```

---

### Task 10: README

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write it**

1. One-paragraph description.
2. **Install** — the two `claude plugin` commands.
3. **Skills** — a table of `razor`, `scrutiny`, `inquest`, `bench`, one line
   each. Note that Claude Code namespaces them, so both `/razor` and
   `/occam:razor` work.
4. **Razor is off by default** — the three ways to turn it on:
   `/razor` in a session, `RAZOR_DEFAULT_MODE=on`, or
   `~/.config/razor/config.json` with `{"enabled": true}`. `/razor off`
   turns it off. Saying "tldr mode" still works.
5. **Statusline (optional)** — run `scripts/install-statusline.sh`, and what
   to do when you already have a statusline.
6. **Coming from the dotfiles version** — nothing migrates. Delete
   `~/.claude/.tldr-active`, `.tldr-history.jsonl` and
   `.tldr-statusline-suffix` by hand if you want them gone. Intensity levels
   and `/tldr-stats` no longer exist. `RAZOR_DEFAULT_MODE` replaces
   `TLDR_DEFAULT_MODE`. A sticky already posted by the old `pr-review` is not
   recognised by `inquest`, so a re-review posts a second one.
7. **Optional dependency** — `inquest` uses the Codex companion when it is
   installed and records `skipped` when it is not.

- [ ] **Step 2: Commit and push**

```bash
git add README.md && git commit -m "docs: add the README"
git push -u origin main
```

---

### Task 11: Isolate the old install, then verify

The dotfiles copies are still live at this point. Their hooks fire and their
skills are still discoverable, so `tldr` and `razor` would both answer with
near-identical descriptions. That defeats Step 7, the one check that exists
to catch a missed cross-reference. Take the old install out of the way first.

- [ ] **Step 1: Disable the old hooks and hide the old skills**

```bash
cp ~/.claude/settings.json ~/.claude/settings.json.pre-occam
node -e '
const fs=require("fs"), p=process.env.HOME+"/.claude/settings.json";
const s=JSON.parse(fs.readFileSync(p,"utf8"));
for (const ev of Object.keys(s.hooks||{})) {
  for (const m of s.hooks[ev]) {
    m.hooks = (m.hooks||[]).filter(h => !/tldr-(activate|mode-tracker|stats)\.js/.test(h.command||""));
  }
}
fs.writeFileSync(p, JSON.stringify(s,null,2)+"\n");
console.log("tldr hooks removed from settings.json");
'
mkdir -p /tmp/occam-hidden
for s in tldr local-review pr-review pr-worktree; do
  mv ~/.dotfiles/claude/skills/$s /tmp/occam-hidden/ 2>/dev/null || true
done
ls ~/.claude/skills/
```
Expected: the four are gone from the listing. They are moved, not deleted;
Task 12 makes it permanent, and a failed verification puts them back with
`mv /tmp/occam-hidden/* ~/.dotfiles/claude/skills/`.

- [ ] **Step 2: Install from the remote**

```bash
claude plugin marketplace add darius-optura/occam
claude plugin install occam@occam
```

- [ ] **Step 3: Verify discovery**

Start a new session. Confirm `razor`, `scrutiny`, `inquest` and `bench`
appear exactly once each, and no `tldr`, `local-review`, `pr-review` or
`pr-worktree` appears. Note whether they list bare or namespaced.

- [ ] **Step 4: Verify off by default**

The session start prints `OK`, not a skill body, because
`~/.config/razor/config.json` does not exist yet. The statusline shows no
`[RAZOR]` badge.

- [ ] **Step 5: Verify on, off, and the old phrase**

Run `/razor`. Expected: the banner reads `RAZOR MODE ACTIVE` and the badge
appears. Type `tldr mode` in plain English in a fresh session — expected: it
also turns on. Run `/razor off`. Expected: banner and badge both go.

- [ ] **Step 6: Verify scrutiny**

Run `/scrutiny` against a working tree with uncommitted changes. Expected: a
scored review printed to the terminal, nothing posted anywhere.

- [ ] **Step 7: Verify inquest against a throwaway PR**

The step this plan exists for. Open a small throwaway PR and run
`/inquest <N>`.

Expected: `bench` prints `backend=herdr`; the branch is `inquest/<N>`;
inline threads and one sticky are posted; the sticky carries
`<!-- inquest:sticky -->`; the validator prints `OK`; a score out of 10 is
printed. Then run `/bench --archive <N>` and confirm the workspace closes
and the map entry is gone.

- [ ] **Step 8: Verify the plain-git backend**

Use the override, not a stripped `PATH` — `gh` lives in
`/opt/homebrew/bin`, so trimming `PATH` breaks the flow before it reaches
the backend.

```bash
BENCH_BACKEND=git   # then run /bench <N>
```
Expected: it creates `.claude/worktrees/<owner>/inquest-<N>`, and
`/bench --archive <N>` removes it and deletes branch `inquest/<N>`.

- [ ] **Step 9: Verify inquest without Codex**

Run `/inquest` once with the Codex CLI unavailable. Expected: it completes
and the sticky's Codex line reads `skipped — codex CLI not installed`. A
silent skip is a failure.

---

### Task 12: Strip the dotfiles repo

Only after Task 11 passes. If it did not, restore first:
`mv /tmp/occam-hidden/* ~/.dotfiles/claude/skills/` and
`cp ~/.claude/settings.json.pre-occam ~/.claude/settings.json`.

**Files:**
- Delete: the four skill dirs, five hooks, one command
- Modify: `claude/settings.json.template`, `scripts/claude-statusline.sh`, `AGENTS.md`

- [ ] **Step 1: Delete the moved files**

Task 11 Step 1 already moved the skill directories aside, so git sees them
as deleted.

```bash
cd ~/.dotfiles
git rm -r --cached claude/skills/tldr claude/skills/local-review \
                   claude/skills/pr-review claude/skills/pr-worktree
git rm claude/hooks/tldr-activate.js claude/hooks/tldr-mode-tracker.js \
       claude/hooks/tldr-stats.js claude/hooks/tldr-config.js \
       claude/hooks/tldr-statusline.sh claude/commands/tldr-stats.md
rm -rf /tmp/occam-hidden
```

- [ ] **Step 2: Update `claude/settings.json.template`**

Delete the `node __HOME__/.claude/hooks/tldr-activate.js` entry from
`SessionStart` and the `tldr-mode-tracker.js` entry from `UserPromptSubmit`
— two entries, not three. Leave `flow-breaker nudge` and
`remote-control-keepawake.sh`. Add `"occam@occam": true` to `enabledPlugins`
and the occam marketplace to `extraKnownMarketplaces`.

- [ ] **Step 3: Fix the badge in `scripts/claude-statusline.sh`**

Lines 148–153 call a file that no longer exists. Both plugin layouts are
searched, matching the installer.

```bash
# ── razor badge ──────────────────────────────────────────────────────────────
razor_sl=$(ls -d "${HOME}"/.claude/plugins/cache/occam/occam/*/hooks/razor-statusline.sh 2>/dev/null | sort -V | tail -1)
[ -z "$razor_sl" ] && razor_sl=$(ls -d "${HOME}"/.claude/plugins/marketplaces/occam/hooks/razor-statusline.sh 2>/dev/null | head -1)
if [ -n "$razor_sl" ]; then
  razor_badge=$(bash "$razor_sl" 2>/dev/null)
  [ -n "$razor_badge" ] && parts+=("$razor_badge")
fi
```

- [ ] **Step 4: Keep this machine compressed**

The plugin defaults to off. Read-modify-write, so an existing config keeps
its other keys.

```bash
mkdir -p ~/.config/razor
node -e '
const fs=require("fs"), p=process.env.HOME+"/.config/razor/config.json";
let c={}; try { c=JSON.parse(fs.readFileSync(p,"utf8")); } catch(e){}
c.enabled=true;
fs.writeFileSync(p, JSON.stringify(c,null,2)+"\n");
console.log(fs.readFileSync(p,"utf8"));
'
```

- [ ] **Step 5: Note the move in `AGENTS.md`**

One line: `razor`, `scrutiny`, `inquest` and `bench` live in
`darius-optura/occam` and install as the `occam` plugin. They are no longer
symlinked from this repo.

- [ ] **Step 6: Verify the install still works**

```bash
cd ~/.dotfiles && ./install.sh --dry-run 2>&1 | tail -20
```
Expected: no error about a missing `tldr-*` file.

- [ ] **Step 7: Verify the badge survived the move**

```bash
bash scripts/claude-statusline.sh; echo
```
Expected: with razor on, the line ends in `[RAZOR]`, exactly as before.

- [ ] **Step 8: Verify the remaining skills**

```bash
ls ~/.claude/skills/
```
Expected: `commit`, `diagnose`, `flow-breaker`, `gh-stack`, `supacode-cli`,
`supacode-deeplinks`. Nothing else.

- [ ] **Step 9: Clean up the verification backup**

```bash
rm -f ~/.claude/settings.json.pre-occam
```

- [ ] **Step 10: Commit**

```bash
git add -A claude scripts AGENTS.md
git commit -m "refactor(claude): move four skills into the occam plugin

The razor, scrutiny, inquest and bench skills now install from
darius-optura/occam instead of the symlink install. Intensity levels and
token statistics are gone rather than moved. The statusline resolves the
badge script inside the installed plugin."
```
