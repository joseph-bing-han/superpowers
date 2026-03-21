#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

assert_contains() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if rg -q "$pattern" "$REPO_ROOT/$file"; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Pattern: $pattern"
    exit 1
  fi
}

assert_not_contains() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if rg -q "$pattern" "$REPO_ROOT/$file"; then
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Forbidden pattern: $pattern"
    exit 1
  else
    echo "PASS: $description"
  fi
}

assert_contains "skills/using-superpowers/SKILL.md" "numbered options" "global rule mentions numbered options"
assert_contains "skills/using-superpowers/SKILL.md" "recommended.*1|option 1" "global rule reserves slot 1 for the recommendation"
assert_contains "skills/using-superpowers/SKILL.md" "request_user_input" "global rule names request_user_input for tool-backed enumerable choices"
assert_contains "skills/using-superpowers/SKILL.md" "non-dangerous.*enumerable.*request_user_input|request_user_input.*non-dangerous.*enumerable" "non-dangerous enumerable choices use request_user_input"
assert_contains "skills/using-superpowers/SKILL.md" "free-text fallback" "global rule keeps a free-text fallback when allowed"
assert_contains "skills/using-superpowers/SKILL.md" "two-stage confirmation|numeric -> letter|numbered.*lettered" "dangerous actions require two-stage confirmation"
assert_contains "skills/using-superpowers/SKILL.md" "exact text|copyable text" "typed confirmations show exact copyable text"
assert_contains "skills/brainstorming/SKILL.md" "1\\. Agree and continue|1\\. Approve and continue" "brainstorming approval uses numbered choice"
assert_contains "skills/brainstorming/SKILL.md" "Input other feedback|Input other requirements" "brainstorming keeps a free-text fallback"
assert_contains "skills/writing-plans/SKILL.md" "1\\. Subagent-Driven" "plan execution handoff stays numbered"
assert_contains "skills/executing-plans/SKILL.md" "numbered options|structured options" "executor guidance mentions numbered options"
assert_contains "skills/finishing-a-development-branch/SKILL.md" 'Reply with `1`, `2`, or `3`\.' "finishing flow uses explicit numeric replies for non-destructive options"
assert_contains "skills/finishing-a-development-branch/SKILL.md" "Type 'discard' to confirm\\." "dangerous actions still require typed confirmation"
assert_not_contains "skills/finishing-a-development-branch/SKILL.md" "What would you like to do\\?" "finishing flow no longer uses open-ended completion prompt"
assert_not_contains "skills/finishing-a-development-branch/SKILL.md" "Which option\\?" "finishing flow no longer uses open-ended option prompt"
assert_not_contains "skills/using-superpowers/SKILL.md" "only when the choice cannot be fully enumerated" "global rule drops the old restrictive free-text wording"
assert_not_contains "skills/using-superpowers/SKILL.md" "Keep typed confirmations for dangerous or destructive actions" "global rule drops the old typed-confirmation wording"
assert_contains "docs/README.codex.md" "tool-backed choice UI|request_user_input" "Codex docs mention tool-backed choice UI or request_user_input"
assert_contains "docs/README.codex.md" "non-dangerous.*enumerable.*request_user_input|request_user_input.*non-dangerous.*enumerable" "Codex docs route non-dangerous enumerable choices through request_user_input"
assert_contains "docs/README.codex.md" "dangerous.*two-stage confirmation|two-stage confirmation.*dangerous" "Codex docs require two-stage confirmation for dangerous enumerable choices"
assert_contains "docs/README.codex.md" "raw single-key submit|input layer" "Codex docs mention the raw single-key input boundary"

echo "All numeric-choice prompt contract checks passed."
