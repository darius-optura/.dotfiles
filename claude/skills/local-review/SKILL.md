---
name: local-review
description: Local code reviewer that runs the same review process as the GitHub CI claude review, but against the local working tree or branch diff — without posting anything to GitHub. Reads REVIEW.md (if present in the repo) for criteria and scoring; otherwise falls back to standard criteria. Use when asked to "review my changes", "review this branch", "do a local review", or "score my diff".
---

# Local Review

Mirrors the GitHub CI Claude review (severity tags, scoring, summary
format), but runs locally against the working tree or branch diff. **No
GitHub posting, no fix loop, no thread management.** This is read-only
analysis that prints a review to the terminal.

For the post-and-fix workflow against a real PR, use `pr-review-fix` (a
project skill) instead.

## Inputs

Arguments can appear in any order. Parse by format, not position:

- `<ref>` (optional): A git ref or `<base>...<head>` range. If omitted,
  the skill picks a sensible default (see "Scope resolution" below).
- `--staged` — review only staged changes (`git diff --cached`).
- `--unstaged` — review only unstaged changes (`git diff`).
- `--working` — review staged + unstaged combined (`git diff HEAD`).
- `--full` — force full branch review even if a smaller scope was given.

Examples:

```text
/pr-review                    # auto-detect: branch diff vs base, or working tree
/pr-review main               # diff main...HEAD
/pr-review origin/main...HEAD # explicit range
/pr-review --staged           # just what's staged
/pr-review --unstaged         # just unstaged edits
```

## Scope resolution

When no scope flag is provided:

1. If a PR exists for the current branch, use `git diff origin/$BASE...HEAD`
   where `$BASE` comes from `gh pr view --json baseRefName -q .baseRefName`.
2. Else if the current branch is not the default branch and has commits
   ahead of it, use `git diff $(git merge-base HEAD origin/<default>)...HEAD`.
   Resolve `<default>` via `git symbolic-ref refs/remotes/origin/HEAD` →
   strip `refs/remotes/origin/` prefix; fall back to `main` if that fails.
3. Else (on the default branch with no PR), review the working tree —
   `git diff HEAD` (staged + unstaged combined).
4. If even that is empty, stop and tell the user there is nothing to review.

State the scope you chose in one line at the start of the review so the
user knows what was actually evaluated.

## Phase 1: Load criteria

Always run these reads in parallel before reviewing the diff:

1. **REVIEW.md** — if present in the repo root, read it. Treat its
   contents as the source of truth for severity levels, always-flag
   rules, scoring, summary format, and skip rules. **Do not paraphrase
   or substitute** — apply its rules verbatim where they conflict with
   the standard fallback below.
2. **CLAUDE.md** — read every CLAUDE.md from the repo root down to the
   directories touched by the diff. These define project conventions
   that should inform what counts as a violation.
3. The diff itself (`git diff <scope>` from Phase 0) plus, for each
   touched file, enough surrounding context to judge whether a flagged
   pattern is actually wrong (read the full file when it's small; read
   the relevant function/class when it's large).

If REVIEW.md is absent, use the standard criteria fallback in
"Standard criteria fallback" below. Never invent project-specific rules
that aren't grounded in REVIEW.md, CLAUDE.md, or the visible code.

## Phase 2: Review

Walk the diff and identify issues. For each one, decide:

- **Severity** — using REVIEW.md's levels if defined, else the standard
  fallback (`[Critical]`, `[Warning]`, `[Suggestion]`, `[Nit]`).
- **Location** — `file:line` referencing a line that exists in the diff.
- **Concrete fix** — what the change should look like, not just "this
  is wrong". One or two lines is enough.

Apply the same default stance the CI review uses: **be constructive,
focus on issues that matter, not style nits.** A finding only counts
as Critical/Warning if you can name the concrete failure mode (bug,
security flaw, regression, broken contract). If you cannot, it is at
most a Suggestion.

If REVIEW.md or CLAUDE.md lists "always flag" patterns, scan the diff
explicitly for each one and either flag or note that none were found.
Do not skip the always-flag scan — it is the highest-signal part of
the review.

### Skip

Skip these unless REVIEW.md says otherwise:

- Generated files (migrations, lock files, auto-generated types)
- Vendor / third-party code
- Formatting-only changes (the formatter owns these)

## Phase 3: Score

Use REVIEW.md's scoring rubric if defined. Otherwise use the standard
fallback: start at 10 and deduct.

- Critical issue: −3 to −5 each
- Warning: −1 to −2 each
- Missing tests for new/changed logic: −1
- PR hygiene issues (only if a PR exists — see Phase 4): per REVIEW.md
  or fallback rubric

Floor at 1. Be honest — if there are real problems, the score should
reflect them. Do not inflate to be agreeable, and do not deflate for
nits.

## Phase 4: PR hygiene (conditional)

Only evaluate PR hygiene if a PR exists for the current branch. Pull
title and description with `gh pr view --json title,body`.

If no PR exists yet, skip this section entirely — do not invent a
hygiene check from commit messages, and do not deduct hygiene points.
Add a single line to the summary noting "PR hygiene: skipped (no PR
open for this branch)."

## Phase 5: Output

Print the review to the terminal in the same shape the CI sticky
summary uses, so it is interchangeable with the GitHub version:

1. **Header** — `### Merge confidence: N/10` on its own line, then a
   one-line assessment.
2. **Scope** — one line stating exactly what was diffed (e.g.
   `Scope: git diff origin/main...HEAD (24 files, +812/-130)`).
3. **Summary** — what the change does and its impact.
4. **PR Hygiene** — pass/fail checklist if a PR exists, else skipped.
5. **Critical Issues (N)** — table: `# | File:Line | Issue | Suggested fix`.
6. **Warnings (N)** — same table format.
7. **Suggestions (N)** — numbered list with `file:line` references.
8. **Security** — assessment, or "No security concerns found".
9. **Files Reviewed** — table: `File | Changes`.

If a section is empty, print the header with `(0)` and a single line
("No critical issues." / "No warnings." / etc.) so the structure is
predictable.

Do NOT post anything to GitHub. Do NOT modify any files. Do NOT run
formatters, linters, or tests as part of this skill — review only.
If the user wants to apply fixes, they can ask separately and use the
`pr-review-fix` skill or run their fix workflow.

## Standard criteria fallback

Used when REVIEW.md is absent. Keep this minimal — it should not
override repo-specific rules when REVIEW.md exists.

### Always flag

- Security vulnerabilities (injection, auth bypass, secrets exposure)
- Missing auth checks on API routes / server handlers
- Hardcoded secrets, API keys, credentials, or tokens
- Server-only code exposed to client bundles
- Breaking API or interface changes without documentation
- Missing input validation at trust boundaries
- Missing error handling for expected failure cases
- Long or superfluous comments — multi-line comment blocks, docstrings
  longer than one line, or comments that restate what the code does
  (well-named identifiers already convey "what"). Comments referencing
  the current task/PR/caller ("added for X flow", "used by Y", "fixes
  issue #123") rot fast and belong in PR descriptions, not code. Flag
  as **[Suggestion]** with concrete fix: delete, or compress to one
  line explaining a non-obvious *why* (hidden constraint, subtle
  invariant, workaround for specific bug).
- Dead parameters retained "for caller-signature compatibility" —
  parameters renamed to `_foo` (or otherwise marked unused) with a
  comment justifying their presence as preserving the caller signature.
  This pattern lies about the function's contract, hides incomplete
  refactors, and rots over time. Flag as **[Warning]** with concrete
  fix: update call sites to drop the arg, or — if a transition is
  genuinely required — replace the vague rationale with a documented
  deprecation plan (removal date / tracking issue). Example trigger:
  ```ts
  orgId: string | null,
  // Authoring-org parameter retained for caller-signature compatibility
  // but unused — orgFanout owns per-org `agent_org_state` writes.
  _orgId: string | null,
  ```

### Severity levels

- **[Critical]** — Blocks merge. Security vulnerability, production
  bug, data corruption.
- **[Warning]** — Should fix. Logic error, missing edge case,
  performance regression.
- **[Suggestion]** — Optional. Better pattern, readability, refactor.
- **[Nit]** — Trivial. Style, naming (only when inconsistent with the
  surrounding code).

### Scoring

Start at 10, deduct as in Phase 3. Scale:

- 1–3 do not merge
- 4–6 needs changes
- 7–8 good to merge
- 9–10 excellent

## Key principles

- **Mirror the CI, don't replace it.** Output should be drop-in
  comparable with the GitHub sticky summary so the user can trust the
  same scoring locally.
- **REVIEW.md is the source of truth.** When the repo has one, follow
  it. Don't override its severity tags, scoring, or skip list with
  the standard fallback.
- **No side effects.** Read-only analysis. Never edit files, never
  post to GitHub, never run linters/tests.
- **Be specific.** Every finding has a file, a line, and a concrete
  suggested change. If you can't write that, downgrade or drop it.
- **Score honestly.** If the diff has real problems, the number should
  show it. The point of running this is to learn where the work stands
  before opening a PR — sugarcoating defeats the purpose.
