---
name: pr-review
description: Strict adversarial PR reviewer. Distrusts the author, posts inline threads and a scored sticky summary, approves at >=9/10 or requests changes below. Provisions a worktree when given a PR id; runs Codex as a second pass when available. Use for "review this PR", "adversarial review", "be strict, don't trust the author".
---

# PR Review

A strict, adversarial code reviewer for a GitHub PR. It takes a hostile stance
toward the change, reviews the diff against the repo's own criteria, optionally
runs Codex as a second pass, scores merge confidence out of 10, and — in PR
mode — posts inline threads plus a scored sticky summary and either approves
the PR (≥9) or requests changes (<9).

This skill **reuses `local-review`** for scope resolution and criteria loading,
and **delegates worktree lifecycle to `pr-worktree`**. It does not duplicate
either. Where this file says "same as `local-review`", follow that skill's
section verbatim.

Unlike `local-review` (read-only, terminal only), this skill has side effects
in PR mode: it posts comments, submits a review, and adds/removes a label.
`--dry-run` suppresses every side effect while still computing the full review.

## Inputs

Arguments can appear in any order. Parse by format, not position:

- `<pr-number>` (optional) — provision a worktree for this PR (via
  `pr-worktree`) and review it in PR mode.
- Local scope flags — same as `local-review`: `--staged`, `--unstaged`,
  `--working`, `--full`, or an explicit `<ref>` / `<base>...<head>` range.
  Used only when no PR number is given (local mode).
- `--archive` (optional) — after the review posts, archive the worktree as the
  final operation (delegate to `pr-worktree --archive <N>`). No-op in local
  mode.
- `--dry-run` (optional) — run the full review and scoring but post nothing,
  approve nothing, and edit no labels. Print exactly what it would post. Use
  this to exercise the skill safely against a real PR.

Examples:

```text
/pr-review 1234              # provision worktree for PR 1234, review, post, score, approve/request
/pr-review 1234 --archive    # same, then archive the worktree last
/pr-review 1234 --dry-run    # full review of PR 1234, print what it would post, post nothing
/pr-review                   # review current context (PR-for-branch, else local diff)
/pr-review --staged          # local mode, staged changes only
```

## Phase 0 — Context

Decide mode and scope before anything else, then state the choice in one line.

Decision tree:

1. **PR id passed AND cwd is not already that PR's worktree** → invoke
   `pr-worktree <N>` to provision, then `cd` into the path it prints. Review
   runs inside that worktree. Mode = PR.
2. **PR id passed AND already inside its worktree** (the branch checked out is
   `pr-review/<N>`, or you were handed this cwd by a prior `pr-worktree` run)
   → skip provisioning; review here. Mode = PR.
3. **No PR id** → auto-detect using `local-review`'s "Scope resolution":
   - PR exists for the current branch → PR mode, scope
     `git diff origin/$BASE...HEAD`.
   - Else a branch/working-tree diff exists → local mode with that scope.
   - Else nothing to review → stop and say so.

State the chosen scope + mode in one line at the start, e.g.
`PR mode: PR #1234, git diff origin/main...HEAD (24 files, +812/-130)` or
`Local mode: git diff HEAD (3 files, +40/-6)`.

Record for later phases: `$BASE` (base ref), `$PR_AUTHOR`
(`gh pr view <N> --json author -q .author.login`), and the owner/repo for API
calls.

## Phase 1 — Load criteria

Identical to `local-review`'s "Phase 1: Load criteria" — do not reinvent it.
Run these reads in parallel before touching the diff:

1. **REVIEW.md** at the repo root — the source of truth. Apply its severity
   levels, always-flag rules, scoring, skip list, and summary format
   **verbatim**. Do not paraphrase or substitute.
2. **CLAUDE.md chain** — every CLAUDE.md from the repo root down to the touched
   directories.
3. **Stack checklist** — detect the stack from the changed files and load
   `.claude/skills/code-review/stacks/<stack>.md` if present; apply its `[ ]`
   items and anti-patterns as first-class, scored findings. Skip if the repo
   has no `stacks/` directory.
4. **The diff** from Phase 0 plus enough surrounding context per touched file
   to judge each flagged pattern.

If REVIEW.md is absent, use the standard fallback criteria — see
`local-review`'s "Standard criteria fallback". Do not copy that prose here;
load it from `local-review`. The always-flag headers you must scan for in the
fallback are:

- Security vulnerabilities (injection, auth bypass, secrets exposure)
- Missing auth checks on API routes / server handlers
- Hardcoded secrets, API keys, credentials, or tokens
- Server-only code exposed to client bundles
- Breaking API/interface changes without documentation
- Missing input validation at trust boundaries
- Missing error handling for expected failure cases
- Long or superfluous comments
- Dead parameters retained "for caller-signature compatibility"

Never invent project-specific rules that aren't grounded in REVIEW.md,
CLAUDE.md, the stack checklist, or the visible code.

## Phase 2 — Adversarial review (primary pass)

**Stance.** Review as a principal / platform-level engineer. Distrust the
author. Assume ill intent and assume the author does not know what they are
doing until the code proves otherwise. Your job is to make the work rock
solid and to report anything that is not. This is deliberately harsher than
`local-review`'s constructive default — hunt for what the author is hiding or
got wrong, not just what is stylistically off.

**Inflation guard.** A finding counts as Critical or Warning **only** when you
can name the concrete failure mode — a specific bug, security flaw,
regression, or broken contract that the code will actually exhibit. If you
cannot name one, it is at most a Suggestion. Hostility is in the scrutiny, not
in inflated severities.

Walk the diff through the five CI categories (same as `local-review`):
security, logic, performance, maintainability, testing. Then run the explicit
always-flag scan from Phase 1 — for each always-flag rule (REVIEW.md / stack
checklist / fallback headers), either flag a violation or record that none was
found. Do not skip the scan; it is the highest-signal part of the review.

**Distrust passes — run every one, every time:**

1. **Tests weakened** — tests deleted, skipped (`.skip`/`xit`/`@Disabled`),
   commented out, or relaxed (loosened assertions, widened tolerances, removed
   cases) to hide a regression rather than because the behavior legitimately
   changed.
2. **Auth missing/bypassed** — server handlers, API routes, or RPCs that drop,
   short-circuit, or fail to add an authentication/authorization check.
3. **Hardcoded secrets** — keys, tokens, passwords, credentials, or connection
   strings committed inline instead of read from config/env.
4. **Dead "compat" code** — parameters, branches, or functions kept "for
   compatibility" that are unused and lie about the contract (e.g. `_orgId`
   with a rationale comment). Flag per the fallback rule.
5. **Scope smuggling** — changes unrelated to the PR's stated purpose slipped
   into the diff (unexpected files, config toggles, dependency bumps,
   behavior changes outside the described scope).
6. **Missing input validation at trust boundaries** — request bodies, query
   params, webhook payloads, or cross-service inputs used without validation.

For each pass, state what you checked and whether anything triggered.

**Every finding carries:** a severity tag, a `file:line` that exists in the
diff (so it can anchor an inline comment), a concrete fix (what the code should
be, not just "this is wrong"), and the named failure mode.

Skip generated files, vendor code, and formatting-only changes unless REVIEW.md
says otherwise (same skip list as `local-review`).

## Phase 3 — Codex second eyes (auto when present)

Run a Codex adversarial pass over the same scope when the tooling is available;
otherwise skip silently.

Resolve the companion script with `~` (never a hardcoded absolute path):

```bash
COMPANION=$(ls ~/.claude/plugins/marketplaces/openai-codex/plugins/codex/scripts/codex-companion.mjs 2>/dev/null \
  || ls ~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs 2>/dev/null | head -1)
```

If `command -v codex` fails **or** `$COMPANION` is empty → skip Phase 3
silently (do not mention it in the output). Otherwise run it against the same
scope; launch it in the background for large diffs so it does not block the
primary pass:

```bash
node "$COMPANION" adversarial-review --base "$BASE" --scope branch
```

The companion emits verbose `[codex] …` progress lines while it works — ignore
those. There is no `--help`; any extra tokens are treated as focus text, not
flags. **Parse the tail**: the last assistant-message JSON carries `verdict`
and `summary`; the individual findings are in the final review text preceding
it. Extract both.

**Merge rules:**

- A finding raised by **both** the primary pass and Codex → high-confidence;
  keep it.
- A **Codex-only** finding → verify it against the actual code before adopting
  it. Drop it if you cannot confirm the failure mode in the diff.
- A **primary-only** finding → keep it (Codex not flagging it is not a reason
  to drop a confirmed issue).

Label each finding's source in the output — `(both)`, `(primary)`, or
`(codex)` — so the confidence level is visible.

## Phase 4 — Score

Use REVIEW.md's scoring rubric when present. Otherwise use the standard
fallback (same as `local-review` Phase 3): start at 10 and deduct — Critical
−3 to −5 each, Warning −1 to −2 each, missing tests for new/changed logic −1;
floor at 1. Score honestly: do not inflate to be agreeable, do not deflate for
nits.

**Threshold.** The approve threshold in Phase 5 is fixed at **9 on a 0–10
scale**, matching the `N/10` "Merge confidence" summary format. If a repo's
REVIEW.md rubric scores on a different scale, **normalize the score to 0–10
first**, then apply the threshold of 9. Never compare a raw non-0–10 score
against 9.

## Phase 5 — Output and side effects

### PR mode

1. **Inline threads.** Post one comment per finding, anchored to its
   `file:line`. Submit them as a **single review** through the GitHub reviews
   API with a `comments[]` array — a bare `gh pr review` cannot attach per-line
   comments, so use the API with a comments payload:

   ```bash
   # owner/repo/N resolved in Phase 0; EVENT is COMMENT here (the approve/
   # request-changes event is submitted separately in step 3 to keep the
   # inline batch independent of the verdict).
   gh api --method POST repos/{owner}/{repo}/pulls/<N>/reviews \
     -f event=COMMENT \
     -f body="See inline comments." \
     --input review.json   # review.json: { "comments": [ {path, line, side, body}, ... ] }
   ```

   Each comment's `path` is the file relative to repo root, `line` is a line
   present in the PR diff, `side` is `RIGHT` for added/changed lines, and
   `body` states severity + the concrete fix + the named failure mode. Skip a
   finding's inline comment (fold it into the sticky instead) if its line is
   not part of the diff hunks — GitHub rejects comments off the diff.

2. **Sticky summary.** Post/update one summary comment, **score first**, in the
   REVIEW.md summary format (fall back to `local-review`'s Phase 5 output shape
   when REVIEW.md defines none). It starts with a hidden marker on its own line
   so re-runs can find it:

   ```markdown
   <!-- pr-review:sticky -->
   ### Merge confidence: N/10
   ```

   followed by the one-line assessment, scope line, summary, PR hygiene,
   Critical/Warning/Suggestion sections, security assessment, and files
   reviewed — same structure as `local-review` Phase 5, with each finding's
   source label from Phase 3.

   Update in place on re-run: find the prior sticky by the marker —

   ```bash
   PRIOR=$(gh pr view <N> --json comments \
     -q '.comments[] | select(.body | contains("<!-- pr-review:sticky -->")) | .url' | head -1)
   ```

   If `$PRIOR` is found, edit that comment (e.g. via
   `gh api --method PATCH` on the comment id). Otherwise create a new comment
   (`gh pr comment <N> --body-file sticky.md`).

3. **Verdict.**
   - **Score ≥ 9 → approve.** `gh pr review <N> --approve --body "<one-liner>"`.
     But GitHub blocks approving your own PR, so if the caller authored it, use
     the label fallback instead:

     ```bash
     if [ "$(gh api user -q .login)" = "$PR_AUTHOR" ]; then
       gh pr edit <N> --add-label claude-approved
       gh pr comment <N> --body "Approved by pr-review: N/10. (Self-authored — GitHub blocks self-approve, applied claude-approved label instead.)"
     else
       gh pr review <N> --approve --body "Approved by pr-review: N/10."
     fi
     ```

   - **Score < 9 → request changes.**

     ```bash
     gh pr review <N> --request-changes --body "Requesting changes: N/10. See sticky summary and inline threads."
     gh pr edit <N> --remove-label claude-approved 2>/dev/null || true
     ```

### Local mode (no PR)

Print the full review to the terminal in `local-review`'s Phase 5 output
shape, score first. **Post nothing. Edit nothing. Add/remove no labels.**
There is no PR to approve or request changes on.

### `--dry-run`

Run every phase exactly as above, but perform **no** writes: post no comments,
submit no review, approve/request nothing, touch no labels. Instead print
exactly what it *would* post — the inline-comment payload (path/line/body per
finding), the full sticky body, and the approve-vs-request-changes decision
(including whether the self-author label fallback would trigger). Make zero
`gh`/`api` write calls.

### `--archive`

After the review has posted (PR mode only), delegate to
`pr-worktree --archive <N>` as the **final operation** — nothing runs after it,
because archiving may close the surface the skill is running in. In local mode
there is no worktree, so `--archive` is a silent no-op.

## Principles

- **Reuse, don't duplicate.** Scope resolution, criteria loading, the fallback
  rubric, and the output shape all come from `local-review`. Worktree
  provision/archive comes from `pr-worktree`. This skill adds only the hostile
  stance, the Codex merge, and the PR side effects.
- **Hostility in scrutiny, not severity.** Distrust the author and dig hard,
  but a Critical/Warning still requires a named concrete failure mode. Do not
  inflate.
- **Every finding is anchorable.** Severity, a `file:line` in the diff, a
  concrete fix, and the failure mode — or downgrade/drop it.
- **Score honestly against a fixed bar.** 9/10 on a 0–10 scale approves;
  normalize other scales before comparing.
- **Inline comments need the reviews API.** `gh pr review` alone cannot anchor
  per-line comments; submit them as one review with a `comments[]` array.
- **No hardcoded absolute paths.** Resolve the Codex companion via `~`/glob and
  owner/repo dynamically.
- **`--dry-run` is the safe path.** When testing against a real PR, dry-run
  first; it computes everything and writes nothing.
