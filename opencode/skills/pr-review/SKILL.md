---
name: pr-review-fix
description: Automated PR review fixer. Reads PR comments, fixes valid issues with an internal verify loop (lint, test, code review agents in parallel), replies to invalid ones, then loops until Claude gives 10/10 and Greptile gives 5/5 (or escalates to user when no actionable comments remain). Use when asked to fix PR review comments or improve PR review scores.
---

# PR Review Fix

Automated workflow for addressing PR review comments with an internal
verification feedback loop before committing.

## Inputs

- `<pr-number>` (optional): The GitHub PR number to process. If omitted,
  auto-detect from the current branch:
  ```bash
  PR_NUMBER=$(gh pr view --json number -q .number)
  ```
  If this fails (no PR for current branch), ask the user for the PR number.

## Default Behavior

This skill **always runs the full loop** (Phases 1–6, repeating until scores
pass or max iterations). Do not ask the user whether to loop — just start.
If the user explicitly says "run once", "single pass", or similar, skip
Phase 6 and stop after Phase 5.

## Phase 0: Precondition

The working tree must be clean before starting. If there are uncommitted
changes, ask the user to commit or stash them first. This skill will
modify, format, and potentially revert files — uncommitted work would
be at risk.

## Phase 1: Baseline

Before fixing anything, capture the current state so verification agents
can distinguish pre-existing failures from newly introduced ones:

1. Resolve the PR number (from input or auto-detect) and base branch.
   Persist these values for all subsequent phases:
   ```bash
   BASE=$(gh pr view "$PR_NUMBER" --json baseRefName -q .baseRefName)
   ```
2. Run `npm run lint && npm run check` — record exit code and output
   (Do NOT run `npm run format` here — the baseline must measure
   existing state without mutating the working tree.)
3. Run `NODE_ENV=test npm run test:unit -- --run` — record exit code and failing tests (if any)

This baseline is the reference for all verification passes. Only **newly
introduced** failures count as blockers.

## Phase 2: Triage

### CRITICAL: Use GraphQL to fetch threads, not REST

Always use the GraphQL `reviewThreads` API to get the complete picture of
all review threads. This is **mandatory** — the REST API (`/pulls/comments`)
returns flat comments without thread structure, resolution status, or
thread node IDs needed for resolution.

```bash
gh api graphql -f query='
query {
  repository(owner: "OWNER", name: "REPO") {
    pullRequest(number: PR_NUMBER) {
      reviewThreads(first: 100) {
        totalCount
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          isResolved
          isOutdated
          comments(first: 50) {
            totalCount
            nodes {
              databaseId
              author { login }
              body
              path
              line
              createdAt
            }
          }
        }
      }
    }
  }
}'
```

### CRITICAL: Paginate threads

The GraphQL API returns max 100 threads per page. PRs with many review
rounds can have 150+ threads. **Always check `pageInfo.hasNextPage`** and
paginate with `after: "<endCursor>"` until all threads are fetched. If you
only fetch the first 100, dozens of threads on later pages remain unresolved
and visible on the PR.

```bash
# Pagination loop
CURSOR=""
while true; do
  AFTER_ARG=""
  [ -n "$CURSOR" ] && AFTER_ARG=", after: \"$CURSOR\""
  RESULT=$(gh api graphql -f query="query { ... reviewThreads(first: 100${AFTER_ARG}) { ... } }")
  # Process threads...
  HAS_NEXT=$(echo "$RESULT" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage')
  CURSOR=$(echo "$RESULT" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor')
  [ "$HAS_NEXT" = "false" ] && break
done
```

### Thread tracking

Maintain a **thread registry** — a map of thread node IDs to their status:

- `{ threadId, author, status: 'pending' | 'fixed' | 'declined' | 'clarification', hasReply: boolean }`

`hasReply` is **not** a native GitHub GraphQL field — derive it by checking
whether any `comments.nodes[].author.login` matches the authenticated user's
login (run `gh api user -q .login` once at startup to resolve this). Do not
try to select `.hasReply` from the GraphQL response directly.

Initialize this registry from the GraphQL response. On every subsequent
iteration, re-fetch threads and update the registry. This prevents:

- Resolving threads without replying (the main bug in the previous version)
- Missing new threads posted in later review rounds
- Posting duplicate replies

### Classification

For each **unresolved thread with no reply** (`hasReply: false`), classify:

- **Valid** — a real issue (bug, security flaw, correctness problem, clear
  violation of project conventions) that should be fixed
- **Invalid** — not a real issue. This includes:
  - Suggestions that add unnecessary complexity or abstraction
  - Style preferences that contradict the project's existing patterns
  - Over-engineering (adding error handling for impossible cases, premature
    abstractions, unnecessary configurability)
  - Changes that would make the code harder to read or maintain
  - Automated reviewer comments that are false positives or irrelevant
  - Draft a reply explaining **why** the suggestion is being declined,
    referencing project conventions or concrete reasoning
- **Needs clarification** — ambiguous or requires a design decision; draft a
  reply asking for clarification

**Default stance: resist changes that don't clearly improve correctness,
security, or readability.** The burden of proof is on the suggestion, not on
the existing code. A reviewer saying "you should do X" is not sufficient
reason to do X — there must be a concrete benefit.

### Deduplication across reviewers

Multiple reviewers (claude, greptile, cursor, sentry) often flag the **same
issue** on the same or nearby lines. Group duplicate issues and fix once.
Reply to each thread individually referencing the fix, but do not apply
the same fix multiple times.

## Phase 3: Fix + Verify Loop

For each valid issue (or batch of closely related issues):

### 3a. Apply the fix

Make the code changes needed to address the comment.

### 3b. Format, then run verification agents in parallel

First, run `npm run format` sequentially (this writes files and must
complete before other agents read the working tree).

Then spawn these three agents **in a single message** so they run in
parallel. All are foreground (not background) — the main agent must wait
for results before deciding whether to commit.

1. **Code Reviewer agent** (tools: Read, Grep, Glob, Bash)
   - Run `git diff` to review the uncommitted changes for logic errors,
     regressions, security issues, and CLAUDE.md / project convention
     violations
   - Report: critical issues, warnings, suggestions

2. **Test Runner agent** (tools: Bash)
   - Run `NODE_ENV=test npm run test:unit -- --run`
   - Compare against the Phase 1 baseline
   - Report only **newly failing** tests with root cause analysis

3. **Lint & Type Check agent** (tools: Bash)
   - Run `npm run lint && npm run check`
   - Compare against the Phase 1 baseline
   - Report only **newly introduced** lint/type errors

### 3c. Evaluate results

- **Critical issues found** → fix them and re-run 3b
- **Only warnings/nits** → note them but proceed
- **All clean** → proceed to commit

**Max 5 verification iterations per fix batch.** If still failing after 5,
revert the fix batch's changes with `git checkout -- <files modified by
this batch>`. This is safe because Phase 0 ensures the working tree was
clean before the skill started — no pre-existing edits are at risk.
Report the remaining issues to the user for manual resolution, and move
on to the next comment.

### 3d. Commit

Once verification passes, create a conventional commit for this fix batch.
Select the appropriate type (`fix`, `refactor`, `test`, `chore`, `perf`, etc.)
and scope (from the project's vocabulary: `chat`, `mvbc`, `use-case`, `auth`,
`api`, `db`, `ui`, `claude`, etc. — see CLAUDE.md) based on the nature of the
change:

```
<type>(scope): description
```

## Phase 4: Self-Review

After all comment-driven fixes are committed (locally, not yet pushed):

1. Review the entire PR diff (`git diff origin/$BASE...HEAD`) for issues the
   reviewers may have missed
2. If new issues are found, apply Phase 3 (fix + verify loop) for each

## Phase 5: Reply to ALL Threads and Push

### CRITICAL: Every thread must get a reply before resolution

This is the most important rule in this phase. **Never resolve a thread
without first posting a reply.** The reply serves as an audit trail showing
what was changed (or why nothing was changed).

### Process

Re-fetch all threads via GraphQL. For each thread in the registry:

- **Fixed and no reply yet** → post a reply describing what was changed
  (reference the commit or the specific code change), then resolve:

  ```bash
  # Step 1: Reply (COMMENT_DB_ID = thread.comments.nodes[0].databaseId — the root comment)
  gh api repos/OWNER/REPO/pulls/PR_NUMBER/comments/COMMENT_DB_ID/replies \
    -f body="Fixed — <description of what changed>"

  # Step 2: Resolve
  gh api graphql -f query='mutation { resolveReviewThread(input: { threadId: "<node-id>" }) { thread { isResolved } } }'
  ```

  If resolution fails (e.g., 403 on bot-authored threads), log the failure
  and move on — do not retry or error out.

- **Fixed and already has reply** → just resolve (reply was posted in a
  previous iteration)

- **Declined (Invalid) from bot reviewers** (claude[bot], greptile-apps[bot],
  cursor[bot], sentry[bot]) → post the drafted explanation, then **resolve
  the thread**. Bot reviewers never come back to close threads themselves,
  so leaving them open just creates noise and drags down scores.

- **Declined (Invalid) from human reviewers** → post the drafted explanation.
  Do NOT mark resolved — let the human reviewer decide.

- **Outdated threads** (`isOutdated: true` in GraphQL) → resolve immediately
  regardless of classification. The code they reference has changed; the
  thread is stale. Post a brief reply if none exists ("Addressed by code
  changes — thread is outdated").

- **Needs clarification** → post the question if no reply exists.
  Do NOT mark resolved.

### Summary table

After all replies are posted, print a summary table of all unresolved
threads so there is always a visible inventory of what was left open:

```
**Unresolved Threads:**
| Author | Issue | Status | Reason |
|--------|-------|--------|--------|
| <login> | <short title> | Declined | <why> |
| <login> | <short title> | Needs clarification | <question asked> |
```

If there are no unresolved threads, print "All threads resolved."

Then push all commits to the branch.

### Post-push thread sweep

**Immediately after pushing** (before waiting for reviewers), do a thread
sweep: re-fetch all threads via GraphQL and reply+resolve any new
unresolved threads that reference already-fixed code. Bots (claude,
greptile, cursor, sentry) post new threads on every push for issues
that may already be fixed. If you don't sweep these immediately, they
accumulate and the PR looks like it has dozens of unresolved issues.

For each new unresolved thread with no reply:

1. Read the thread's comment body and the file/line it references
2. Check `git log --oneline -- <path>` and `git diff origin/$BASE...HEAD -- <path>`
   to determine if the cited issue was already addressed by a prior commit
3. **Only if the issue is confirmed fixed**: reply with a description of the
   fix and resolve the thread
4. **If the issue is NOT fixed**: add it to the thread registry as `pending`
   and process it in the next Phase 2–5 cycle

Do NOT blindly resolve all no-reply threads — each must be individually
verified against the actual code changes before resolution. If any threads
were added as `pending`, run a full Phase 2–5 pass before proceeding to
Phase 6.

## Phase 6: Automated Review Score Loop

1. Wait 5 minutes for automated reviewers to finish
2. **Re-fetch all threads via GraphQL** — this is critical. Reviewers post
   new inline threads on each push, not just summary comments. The summary
   comment (`Merge confidence: N/10`) lists warnings, but each warning also
   exists as a separate inline thread that needs a reply.
3. Check for **any new feedback**:

   **Claude** (Code Review) — look for the sticky summary comment with:

   > **Merge confidence: N/10**

   **Greptile** (Greptile Apps / Greptile Review) — look for the summary
   comment with:

   > **Confidence Score: N/5**

4. Targets:
   - Claude: **Merge confidence: 10/10**
   - Greptile: **Confidence Score: 5/5**
5. **Identify new threads** — compare the current thread list against the
   registry. Any thread with an ID not in the registry is new. Add it to
   the registry and classify it (Phase 2 logic). Only process threads that
   are `unresolved` AND have `no reply from us`.
6. If new unaddressed threads exist → apply Phases 2–5 for them.
   If scores are low but there are **no new threads to address**, there
   is nothing actionable — report the current scores to the user and stop.
7. If no new unaddressed threads and scores look good, **check for pending
   GitHub Actions** before declaring done:
   ```bash
   gh run list --branch "$(git branch --show-current)" --json status,databaseId --jq '[.[] | select(.status == "in_progress" or .status == "queued")] | length'
   ```
   If any runs are still in progress or queued, wait 2 more minutes and
   re-check. Repeat up to **10 times** (20 minutes max).
8. **Done** when all of:
   - Claude gives **Merge confidence: 10/10**
   - Greptile gives **Confidence Score: 5/5**
   - No new unaddressed threads (declined threads with replies are OK)
   - No pending GitHub Actions on the branch (or Actions timeout reached)

**Max 50 iterations.** If still not passing after 50 rounds, or if scores
are low but no new actionable threads remain, print a final status report
and stop:

```
**Final Status Report:**
| Metric | Score | Target |
|--------|-------|--------|
| Claude Merge Confidence | N/10 | 10/10 |
| Greptile Confidence Score | N/5 | 5/5 |
| Iterations completed | N | max 50 |
| Unresolved threads (no reply) | 0 | 0 |
| Unresolved threads (declined, has reply) | N | N/A |

**Unresolved Threads:**
| Author | Issue | Status | Reason |
|--------|-------|--------|--------|
| ... | ... | Declined | ... |
```

## Key Principles

- **Never commit unverified code.** Every fix passes through the parallel
  verification agents before reaching git.
- **Baseline comparison.** Only newly introduced failures block commits —
  pre-existing issues are ignored.
- **Parallel, not sequential.** Verification agents run simultaneously to
  minimize wall-clock time.
- **Foreground agents, not background.** The main agent must have results
  before deciding to commit or re-fix.
- **Atomic commits.** One commit per fix (or tightly related fix batch) so
  individual changes can be reviewed and reverted independently.
- **ALWAYS reply before resolving.** Never call `resolveReviewThread` on a
  thread that has no reply from us. The reply is the audit trail. This is
  the single most important rule for thread management.
- **Resolve bot-reviewer declined threads.** Bot reviewers (claude[bot],
  greptile-apps[bot], cursor[bot], sentry[bot]) never come back to close
  threads. After posting a decline reply, resolve the thread. Only leave
  human-reviewer declined threads open.
- **Auto-resolve outdated threads.** If `isOutdated: true`, the code has
  changed and the thread is stale. Resolve it with a brief note.
- **Track threads by node ID, not comment ID.** Comment IDs and thread IDs
  are different things. A thread has one node ID and may contain multiple
  comment IDs. Track threads, not comments.
- **Don't conflate summary warnings with inline threads.** The sticky
  summary comment lists warnings by number, but each warning also has a
  separate inline thread. Address both: fix the code (which satisfies the
  summary), AND reply to the inline thread (which closes it on GitHub).
- **Re-fetch threads on every iteration.** Reviewers post new inline
  threads on each push. The thread list from round 1 is stale by round 2.
  Always re-query via GraphQL before deciding what to do.
- **Push back on bad suggestions.** Do not apply changes that add unnecessary
  complexity, contradict project patterns, or don't concretely improve the
  code. A reviewer comment is a suggestion, not an order — decline with a
  clear explanation when the suggestion would make things worse.
- **No duplicate replies.** The thread registry prevents this — check
  `hasReply` before posting.

