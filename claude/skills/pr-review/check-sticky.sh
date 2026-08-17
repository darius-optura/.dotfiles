#!/usr/bin/env bash
# Validates a filled pr-review sticky.md against sticky-template.md.
# Prints "OK" and exits 0 only when the file passes every check.
set -u

f="${1:?usage: check-sticky.sh sticky.md}"
fail=0
err() { echo "FAIL: $1"; fail=1; }

[ -f "$f" ] || { echo "FAIL: file not found: $f"; exit 1; }

# 1. Marker must be the first line.
[ "$(head -1 "$f")" = "<!-- pr-review:sticky -->" ] \
  || err "marker <!-- pr-review:sticky --> is not line 1"

# 2. Required anchors, present and in template order.
anchors=(
  "### Merge confidence: "
  "Reviewed head SHA: "
  "Base: "
  "Provenance note: "
  "Scope inspected: "
  "#### Critical Issues"
  "#### Warnings"
  "#### Suggestions"
  "#### Security"
  "#### PR Hygiene"
  "Adversarial validation: "
  "Codex second pass: "
  "CI inspected on this head: "
  "Verdict: "
)
last=0
for a in "${anchors[@]}"; do
  line=$(grep -nF "$a" "$f" | head -1 | cut -d: -f1)
  if [ -z "$line" ]; then
    err "missing anchor: $a"
    continue
  fi
  [ "$line" -gt "$last" ] || err "anchor out of order: $a"
  last=$line
done

# 3. Score line format: <0-10>/10.
grep -qE '^### Merge confidence: ([0-9]|10)/10$' "$f" \
  || err "score line must be exactly '### Merge confidence: <0-10>/10'"

# 4. Verdict must carry one of the three allowed values, bolded.
grep -qE '^Verdict: \*\*(Approve|Request changes|Comment \(not approved\))\*\*' "$f" \
  || err "Verdict must be **Approve**, **Request changes**, or **Comment (not approved)**"

# 5. No unfilled template placeholders may remain.
placeholders=(
  '<N>' '<one-line assessment>' '<HEAD_SHA>' '<BASE_BRANCH>' '<BASE_SHA>'
  '<one line>' '<what the PR does>' '<n>' '<table or' '<numbered list or'
  '<assessment or' '<pass/fail table>' '<distrust passes' '<ran at' 'CODEX_HEAD_SHA'
  '<check groups' '<Approve | Request changes' '<blocking reason'
  '<baseRefOid =='
)
for p in "${placeholders[@]}"; do
  grep -qF "$p" "$f" && err "unfilled template placeholder remains: $p"
done

# 6. No headings outside the template (REVIEW.md must not reshape the sticky).
#    Fenced code blocks are skipped so code comments do not false-positive.
while IFS= read -r h; do
  case "$h" in
    "### Merge confidence: "*) ;;
    "#### Critical Issues"*) ;;
    "#### Warnings"*) ;;
    "#### Suggestions") ;;
    "#### Security") ;;
    "#### PR Hygiene") ;;
    *) err "heading not in template: $h" ;;
  esac
done < <(awk '/^```/{f=!f;next} !f && /^#{1,6} /' "$f")

if [ "$fail" -eq 0 ]; then
  echo "OK"
else
  exit 1
fi
