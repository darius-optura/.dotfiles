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

## Language

All prose this skill emits obeys ASD-STE100 Simplified Technical English. This
covers every inline thread body, every thread reply, the sticky summary, the
terminal review in local mode, and the verdict line. The rule holds every time
the skill runs. Do not depend on the session `tldr` mode — write in STE even
when `tldr` is off.

STE rules for every emitted sentence:

- Active voice. "The handler skips the auth check." Not "The auth check is
  skipped."
- One instruction per sentence. Two actions become two sentences.
- Instruction ≤ 20 words. Description ≤ 25 words.
- Short common verbs: `use` not utilize, `fix` not remediate, `start` not
  initiate, `make sure` not ensure, `remove` not eliminate, `find` not locate.
- One word, one meaning; one meaning, one word. Pick one term per concept and
  repeat it. Never vary `flag`/`option`/`switch` for style.
- Put a warning or caution before the instruction it applies to.
- No -ing nouns. No noun clusters over 3 words.
- No filler, no hedging adverbs that carry no information, no idioms.

Full sentences with articles. This is the `tldr` commit/PR boundary, not ultra
fragments. Review text stays GitHub-readable and unambiguous for the author who
acts on it. Do not drop articles and do not write fragment-salad.

Keep these exact and unchanged (STE technical-name exemption): code,
identifiers, error strings, CLI flags, file paths, `file:line` anchors,
severity tags (`[Critical]` / `[Warning]` / `[Suggestion]` / `[Nit]`), the
score line, the provenance header, and the `Verdict:` line.

These STE rules mirror `claude/skills/tldr/SKILL.md` ("STE — ASD-STE100"
section); keep the two in sync if either changes.

## Common shortcuts that are FORBIDDEN

Do not take any of these shortcuts. Each one broke a live run:

- Do NOT skip Phase 3 (Codex) when `codex` is installed. Run the availability
  check, then run the pass.
- Do NOT read the base SHA from a local ref. Use the PR's `baseRefOid` or the
  merge-base, never a bare local `origin/<base>` tip.
- Do NOT post before the Phase 5 "Pre-post verification" gate passes.
- Do NOT invent a finding without a named failure mode.
- Do NOT dedup against your own prior sticky or threads — filter your own
  output (`user.login == $ME`, sticky marker) first.

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
   - PR exists for the current branch → PR mode. Resolve the PR number and
     author so Phase 5 has them:
     ```bash
     N=$(gh pr view --json number -q .number)
     PR_AUTHOR=$(gh pr view --json author -q .author.login)
     BASE=$(gh pr view --json baseRefName -q .baseRefName)
     ```
     Scope `git diff origin/$BASE...HEAD`.
   - Else a branch/working-tree diff exists → local mode with that scope. For a
     branch or an explicit `<ref>` / `<base>...<head>` range, resolve `$BASE`
     too, so Phase 3 can run Codex: take the range's base side when the arg is
     a range, else `BASE=$(git merge-base HEAD origin/<default>)`. For a pure
     working-tree scope (`--staged`, `--unstaged`, `--working`) leave `$BASE`
     unset — there is no base branch.
   - Else nothing to review → stop and say so.

State the chosen scope + mode in one line at the start, e.g.
`PR mode: PR #1234, git diff origin/main...HEAD (24 files, +812/-130)` or
`Local mode: git diff HEAD (3 files, +40/-6)`.

Record for later phases (PR mode): `$N` (PR number), `$BASE` (base ref),
`$PR_AUTHOR` (`gh pr view <N> --json author -q .author.login`), and the
owner/repo for API calls. In local mode there is no PR number, base ref, or
author to record.

**Prefer the provisioned worktree.** The no-worktree review path shares the
main checkout, so a concurrent run or an auto-sync can move HEAD mid-review.
The provisioned worktree (the Phase 0 default) isolates the review from that.
Pin to explicit SHAs everywhere — provenance (Phase 5) and the Codex head guard
(Phase 3) both compare and report a resolved SHA, never a moving ref name.

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
fallback are (this list mirrors `local-review`'s "Always flag" section — keep
the two in sync if either changes):

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

## Phase 1.5 — Prior review state + CI status (PR mode only)

Skip this phase entirely in local mode (there is no PR to read state from).

First resolve the shared identifiers once, early. Later phases reuse these:

```bash
# owner/repo as literal values — GraphQL needs them literal; REST templates {owner}/{repo}
OWNER=$(gh repo view --json owner -q .owner.login)
REPO=$(gh repo view --json name -q .name)
# the reviewed head SHA — reused in Phase 5 provenance
HEAD_SHA=$(gh pr view <N> --json headRefOid -q .headRefOid)
# your login, with a 503 fallback — ALL self-author and own-output checks use $ME
ME=$(gh api user -q .login 2>/dev/null \
  || gh api graphql -f query='{viewer{login}}' -q .data.viewer.login 2>/dev/null)
# last resort if both fail: git config user.name / user.email, matched against the
# PR author. Best-effort only — a git identity can differ from the GitHub login.
```

**Retry transient failures.** GitHub REST and GraphQL can return an
intermittent 503 or 404. Wrap the `$ME` resolution and the Phase 1.5 pulls in a
retry-with-backoff (for example 3 attempts, 1s / 2s / 4s). When a REST call
still fails, use the documented GraphQL fallback for that data before you treat
the data as unavailable.

In PR mode, pull the PR's existing review state and CI status **in parallel**
before reviewing, so the pass is aware of what has already been said and what
is already known to be broken:

```bash
# existing reviews + issue comments (the sticky lives here)
gh pr view <N> --json reviews,comments
# existing inline review comments — human and bot
gh api repos/{owner}/{repo}/pulls/<N>/comments --paginate
#   each: .path, .line / .original_line, .body, .user.login, .id, .in_reply_to_id
# CI / status checks — gh pr checks needs no SHA
gh pr checks <N>   # or: gh api repos/{owner}/{repo}/commits/"$HEAD_SHA"/check-runs
```

**Parse each page.** `gh api ... --paginate` concatenates one JSON array per
page. A naive single parse breaks on the second page. Parse per page, or add
`--slurp` and flatten the result.

**GraphQL fallback for the inline comments.** The REST
`pulls/<N>/comments` pull can return 503 or 404 while GraphQL still answers. If
that REST call fails, fall back to a GraphQL `reviewThreads` query on the pull
request:

```bash
gh api graphql -f query='
{ repository(owner:"'"$OWNER"'", name:"'"$REPO"'") {
    pullRequest(number: <N>) {
      reviewThreads(first: 100) { nodes {
        isResolved
        comments(first: 50) { nodes { databaseId path line body author { login } } }
      } }
    } } }'
```

Each thread gives its comments with `databaseId`, `path`, `line`, `body`, and
`author.login`. Field mapping to the REST shape the dedup consumes: GraphQL
`author.login` is REST `user.login`, and GraphQL `databaseId` is the REST
comment `id` — pass `databaseId` as `in_reply_to_id` for a reply. Use the
GraphQL `isResolved` field as the reliable resolved-signal for a thread — it is
more dependable than inferring resolution from REST.

If a reply-target id is still unavailable (an older GraphQL schema without
`databaseId`), restrict the fallback to the "stay silent" dedup action — do not
attempt a reply without a target id.

Use them:

- **Dedup before posting (two signals).** Before opening a new thread for a
  finding at `file:line`:
  1. **Structural** — look for an existing inline comment on the same `path`
     within a small line window (±~5 lines; lines drift across pushes, so an
     exact match is not required).
  2. **Semantic** — if a structural candidate exists, read its `body` and judge
     whether it describes the **same failure mode**.

  Both signals match → do **not** open a new thread. Either stay silent or
  reply to the existing thread (agree / escalate / "verified, still open") via
  `in_reply_to_id`. Bot **SUMMARY tables** (free text, no line anchor) get the
  semantic pass only; note that this is a weaker signal.

- **Your own prior output — two different rules.** Filtering your own output
  from dedup applies to the SUMMARY sticky only, never to your own open inline
  threads.
  1. **Own SUMMARY sticky** (marker `<!-- pr-review:sticky -->`) → never treat
     it as a finding. Update it in place (Phase 5, step 5). Unchanged behavior.
  2. **Own prior INLINE threads** (author equals `$ME`) → you MUST match these,
     so a re-run does not re-post them and spam the PR. Before opening a thread
     for a finding, check your own open threads by (`path`, ±~5 line window,
     same failure mode):
     - Match found AND the issue still exists → do NOT open a new thread. Reply
       to the existing thread via `in_reply_to_id` ("still open on this head"),
       or stay silent.
     - Match found AND the issue is now fixed → do NOT re-post. Optionally note
       or resolve the thread.
     - No own open thread for this finding → it is genuinely new; open a new
       thread.

- **Distrust resolved / dismissed threads.** A resolved thread is a *claim*,
  not proof — verify the code actually fixed the issue before trusting it. An
  author dismissing a still-valid finding becomes its own finding.

- **Score only on findings you independently confirm.** A bot's unresolved
  Critical that you reproduce counts at its real severity and moves the score.
  A bot's word alone never moves the score.

- **CI state feeds the verdict.** A failing check on the reviewed head means
  this cannot be a clean approve, regardless of the diff score — note the
  failing checks by name. State CI status in the sticky summary (Phase 5).

- **Required-status is not knowable read-only.** `gh pr checks` does not expose
  branch-protection required-status; repo-admin API access is needed to confirm
  which checks are required. So the skill assumes a failing check is
  merge-blocking, unless it is a known or acknowledged false positive. When the
  skill makes this assumption, state it in the sticky.

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

## Phase 3 — Codex second eyes (MANDATORY when the tooling is present)

This phase is not optional. You MUST run the availability check every time. You
MUST run the Codex pass whenever the tooling is present. **Do not skip this
phase because the diff is large or slow. The only allowed skip is genuine
absence of the tooling.**

**Step 1 — availability check (always run).** You MUST run both checks:

```bash
command -v codex
COMPANION=$(ls ~/.claude/plugins/marketplaces/openai-codex/plugins/codex/scripts/codex-companion.mjs 2>/dev/null \
  || ls ~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs 2>/dev/null | head -1)
```

Use `~` for the companion path — never a hardcoded absolute path.

**Step 2 — decide from the check result:**

- **`codex` present AND `$COMPANION` non-empty → you MUST run the Codex pass.**
  There is no "skip for brevity, size, or time" option. A large or slow diff is
  not a reason to skip — launch it in the background instead (see Step 3).
- **`codex` absent OR `$COMPANION` empty → skip the pass.** A silent skip is
  FORBIDDEN. The sticky (Phase 5) MUST state, verbatim: "Codex second pass
  skipped — `codex` CLI not installed." The sticky always states whether Codex
  ran or the reason it did not.

**Gate on mode.** The companion reviews a branch against a base, so it needs a
real base ref — PR mode, or local mode with a branch/ref range (`$BASE` set in
Phase 0). For a pure working-tree scope (`--staged`, `--unstaged`, `--working`)
there is no base branch; state in the sticky that Codex needs a base ref and
did not run for this scope.

**Step 3 — verify HEAD is the PR head (guard, MUST run before Codex).** The
companion diffs `merge-base(HEAD, base)..HEAD` against the currently
checked-out HEAD. Codex MUST always review the PR head, never whatever HEAD is
checked out. In the normal worktree path (Phase 0 provisions the PR worktree)
HEAD is already the PR head. But a review started from another branch (for
example `gh pr diff` from `main`) would point Codex at the WRONG code and emit
a meaningless pass. So compare the two SHAs first:

```bash
CUR=$(git rev-parse HEAD)   # actual working-tree HEAD
# HEAD_SHA is the PR head (headRefOid) from Phase 1.5
```

- `$CUR` equals `$HEAD_SHA` → HEAD is the PR head. Continue to Step 4.
- `$CUR` differs from `$HEAD_SHA` → check out the PR head SHA detached before
  Codex, then restore the prior ref afterward. This is a local, reversible git
  operation, allowed even under `--dry-run` (it makes no GitHub write):
  ```bash
  PRIOR=$(git rev-parse --abbrev-ref HEAD)   # or $CUR when detached already
  git checkout --detach "$HEAD_SHA"
  # ... run Codex (Step 4) ...
  git checkout "$PRIOR"
  ```
- Checkout is not possible (dirty tree, locked worktree) → do NOT run Codex
  against the wrong HEAD. Mark the Codex pass invalid and state in the sticky:
  "Codex second pass invalid — could not check out the PR head." Never treat a
  wrong-HEAD run as a real pass.

**Step 4 — run it.** Pass `--base "$BASE"` **only when `$BASE` is set** (Phase 0
leaves it unset for pure working-tree scopes). Launch it in the background for
large diffs so it does not block the primary pass:

```bash
if [ -n "$BASE" ]; then
  node "$COMPANION" adversarial-review --base "$BASE" --scope branch
else
  node "$COMPANION" adversarial-review --scope branch
fi
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

**Pre-post verification (gate — the FIRST step, run before any write).** Decide
the event (step 1) and build the findings (step 2) first, then confirm every
item below. Each item is a hard gate. **If any item fails, STOP. Do not post.
Report the failed item to the user and fix it first.** Do not run any write
call (`gh pr review`, `gh api` POST/PATCH, `gh pr edit`, `--archive`) until
every item passes:

1. Codex ran against the PR head (Phase 3), OR the sticky states the reason it
   did not: the verbatim line "Codex second pass skipped — `codex` CLI not
   installed", no base ref for the scope, or "Codex second pass invalid —
   could not check out the PR head."
2. The provenance SHAs came from the PR (`headRefOid` / `baseRefOid` or the
   merge-base), NOT a bare local `origin/<base>` tip.
3. The `Verdict:` line matches the final `event`: Approve ↔ `APPROVE`, Request
   changes ↔ `REQUEST_CHANGES`, Comment ↔ `COMMENT`.
4. `$ME` and `$PR_AUTHOR` were both resolved. If they match, Rule 0
   (self-author ⇒ `COMMENT`) was applied.
5. Under `--dry-run`: zero writes were made — no `gh pr review`, no `gh api`
   POST/PATCH, no `gh pr edit`, no `--archive`.
6. Every posted finding carries a severity tag, an in-diff `file:line`, a
   concrete fix, and a named failure mode. The dedup pass (Phase 1.5) ran
   against the existing threads.

**The inline threads and the approve/request-changes verdict are ONE reviews
POST, not separate calls.** A single `POST` to
`repos/{owner}/{repo}/pulls/<N>/reviews` carries the verdict as `event`, a
short review body, and every inline thread in a `comments[]` array. A bare
`gh pr review` cannot attach per-line comments, and splitting the event off
into a second call would submit a redundant review — so build one JSON payload
and post it once.

1. **Decide the review event.** This is the `event` field of the single reviews
   POST below. Apply the rules in this order.

   **Rule 0 — self-authored overrides everything.** If `$ME` (resolved in Phase
   1.5) equals `$PR_AUTHOR`, set `event = COMMENT` always — any score, any CI
   state. GitHub returns 422 for BOTH `APPROVE` and `REQUEST_CHANGES` on your
   own PR, not only approve. Put the requested changes or the approval rationale
   in the body. Never add or expect the `claude-approved` label in the
   self-author case. Skip the rest of the rules below.

   **Rule 1 — score-based event** (not self-authored):
   - Score ≥ 9 → `APPROVE`.
   - Score < 9 → `REQUEST_CHANGES`.

   **Rule 2 — CI gate, applied after Rule 1.** A failing check on the reviewed
   head blocks a clean approve, even at score ≥ 9 (this matches Phase 1.5). So
   downgrade:
   - A failing check that is a real defect → emit `REQUEST_CHANGES`. Name the
     failing check in the body and the verdict.
   - A failing check that is not a real defect (a flake or an unrelated failure
     you cannot dismiss read-only) → do not emit `APPROVE`; emit `COMMENT`
     instead. Name the blocking check in the body and the verdict.
   - A failing check that is a known or acknowledged false positive → the event
     may stay `APPROVE`, but name the check in the body with the exact text
     "dismiss before merge".

2. **Build the inline comments.** One entry per finding, anchored to its
   `file:line`. Each entry's `path` is the file relative to repo root, `line`
   is a line present in the PR diff, `side` is `RIGHT` for added/changed lines,
   and `body` states severity + the concrete fix + the named failure mode. Skip
   a finding's inline comment (fold it into the sticky instead) if its line is
   not part of the diff hunks — GitHub rejects comments off the diff.

3. **Post the single review.** Build ONE JSON payload — `event`, `body`,
   `comments[]` together — and pass it via `--input` (or stdin) with **no `-f`
   fields** (mixing `-f` with `--input` drops the file's body and creates a
   stuck PENDING review that never posts):

   ```bash
   # N from Phase 0; owner/repo from Phase 1.5; EVENT decided in step 1.
   cat > review.json <<'JSON'
   {
     "event": "REQUEST_CHANGES",
     "body": "<short review body — points at the sticky + inline threads>",
     "comments": [
       { "path": "src/foo.ts", "line": 42, "side": "RIGHT",
         "body": "[Warning] <fix> — <named failure mode>" }
     ]
   }
   JSON
   gh api --method POST repos/{owner}/{repo}/pulls/<N>/reviews --input review.json
   ```

   Set `"event"` to the value from step 1. With an empty `comments` array this
   still submits the verdict as a plain review.

4. **Labels.** Labels apply only to a non-self-authored PR. In the self-author
   case (Rule 0) add no label and remove none — the event is `COMMENT` and the
   body carries the rationale.
   - `event = APPROVE` → ensure the label exists, then add it tolerantly (both
     `|| true` so a pre-existing label or a repo without label perms does not
     abort the run):
     ```bash
     gh label create claude-approved --color 2ea44f --description "pr-review passed" 2>/dev/null || true
     gh pr edit <N> --add-label claude-approved 2>/dev/null || true
     ```
   - `event = REQUEST_CHANGES` → remove any stale approval label:
     ```bash
     gh pr edit <N> --remove-label claude-approved 2>/dev/null || true
     ```
   - `event = COMMENT` (not self-authored — a CI-gated downgrade) → remove any
     stale approval label, same as `REQUEST_CHANGES`.

5. **Sticky summary.** Post/update one summary comment (a PR issue comment,
   separate from the review above), **score first**, everything wrapped by the
   hidden marker so re-runs can find and replace it in place. The body, in
   order:

   1. `### Merge confidence: N/10` on its own line (the REVIEW.md score-first
      requirement stays), then a one-line assessment.
   2. **Provenance header**, this exact shape — so the sticky states which
      commit was actually reviewed:
      ```markdown
      Reviewed head SHA: `<full head sha>`
      Base: `<base-branch>` @ `<full base sha>`
      ```
      The provenance header must report the SHAs the reviewed diff actually
      used. Reuse `$HEAD_SHA` from Phase 1.5. Resolve the base from the PR
      itself, not from a local ref — a local `origin/<base>` tip differs from
      the PR's real base:
      ```bash
      BASE=$(gh pr view <N> --json baseRefName -q .baseRefName)
      BASE_SHA=$(gh pr view <N> --json baseRefOid -q .baseRefOid)
      ```
      A `gh pr diff` review diffs against the merge-base, so `baseRefOid` is the
      PR base ref tip, not the merge-base — label it as the base ref in the
      header.

      In the worktree-checkout path the local refs are the reviewed ones, and
      the scope `origin/$BASE...HEAD` is a three-dot diff against the
      merge-base. So report the merge-base SHA the diff actually used:
      ```bash
      # worktree mode only — the checked-out refs are what the diff used
      HEAD_SHA=$(git rev-parse HEAD)
      BASE_SHA=$(git merge-base HEAD "origin/$BASE")
      ```
      Both paths report the base the diff compared against; keep that meaning
      consistent.
   3. One **"scope inspected"** line — what was read: the diff, changed files,
      tests, existing review threads (Phase 1.5), and CI.
   4. **Findings sections** in the existing REVIEW.md / `local-review` shape —
      Critical / Warnings / Suggestions tables, then Security — each finding
      carrying its Phase 3 source label.
   5. **Adversarial validation** paragraph — what you scrutinized and
      **cleared** (this defends against false positives), plus a sentence
      stating existing review findings were verified and not duplicated (e.g.
      "Existing review findings are resolved and were not duplicated").
   6. **Codex second pass** — one line stating the Phase 3 result: that Codex
      ran against the PR head, or the verbatim line "Codex second pass skipped
      — `codex` CLI not installed", or that Codex needs a base ref and did not
      run for this scope, or "Codex second pass invalid — could not check out
      the PR head." This line is required every run.
   7. **CI inspected on this head** — one line listing the check groups and
      their state (all green / which are failing), from Phase 1.5.
   8. **Verdict line — derive it from the FINAL `event` from step 1, not from
      the score** (the CI gate and Rule 0 can move the event away from the
      score):
      - `event = APPROVE` → `Verdict: **Approve**`.
      - `event = REQUEST_CHANGES` → `Verdict: **Request changes**`.
      - `event = COMMENT` → `Verdict: **Comment (not approved)**`.

      When a check blocks the verdict, name that check in the verdict line,
      matching the body text from step 1.

   The marker sits at the very top of the body, on its own line:

   ```markdown
   <!-- pr-review:sticky -->
   ### Merge confidence: N/10
   ```

   Include the PR hygiene result (see the hygiene step below) within the
   findings/assessment area, as `local-review` Phase 5 lays out.

   Update in place on re-run using REST end-to-end. Issue comments carry a
   numeric `id`; list them, pick the one whose body contains the marker, and
   extract that numeric id:

   ```bash
   STICKY_ID=$(gh api repos/{owner}/{repo}/issues/<N>/comments --paginate \
     -q '.[] | select(.body | contains("<!-- pr-review:sticky -->")) | .id' | head -1)
   ```

   If `$STICKY_ID` is non-empty, update that comment in place:

   ```bash
   gh api -X PATCH repos/{owner}/{repo}/issues/comments/$STICKY_ID -f body=@sticky.md
   ```

   Otherwise create a new one:

   ```bash
   gh api repos/{owner}/{repo}/issues/<N>/comments -f body=@sticky.md
   ```

**PR hygiene.** PR mode always has a PR, so grade hygiene: pull the title and
description (`gh pr view <N> --json title,body`) and evaluate them exactly as
`local-review`'s "Phase 4: PR hygiene" describes, then render the result in the
sticky's PR hygiene section.

### Local mode (no PR)

Print the full review to the terminal in `local-review`'s Phase 5 output
shape, score first. **Post nothing. Edit nothing. Add/remove no labels.**
There is no PR to approve or request changes on.

### `--dry-run`

Run every phase exactly as above, but perform **no** writes: post no comments,
submit no review, approve/request nothing, touch no labels. Instead print
exactly what it *would* post — the review JSON payload (event + body +
comments[] with path/line per finding), the full sticky body, and the final
event decision (APPROVE / REQUEST_CHANGES / COMMENT), including whether Rule 0
(self-authored) or the CI gate moved the event off the score. Make zero
`gh`/`api` write calls.

`--dry-run` also **no-ops `--archive`.** Archiving's real destructive step is
`supacode worktree archive`, not a `gh` call, so the "no gh writes" gate does
not cover it — under `--dry-run`, skip the archive entirely and just print that
it would archive the worktree.

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
