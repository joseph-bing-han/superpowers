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

assert_contains "skills/using-superpowers/SKILL.md" "numbered options" "global rule mentions numbered options"
assert_contains "skills/using-superpowers/SKILL.md" "recommended.*1|option 1" "global rule reserves slot 1 for the recommendation"
assert_contains "skills/brainstorming/SKILL.md" "1\\. Agree and continue|1\\. Approve and continue" "brainstorming approval uses numbered choice"
assert_contains "skills/brainstorming/SKILL.md" "Input other feedback|Input other requirements" "brainstorming keeps a free-text fallback"
assert_contains "skills/writing-plans/SKILL.md" "1\\. Subagent-Driven" "plan execution handoff stays numbered"
assert_contains "skills/executing-plans/SKILL.md" "numbered options|structured options" "executor guidance mentions numbered options"
assert_contains "skills/finishing-a-development-branch/SKILL.md" "Type 'discard' to confirm\\." "dangerous actions still require typed confirmation"
assert_contains "docs/README.codex.md" "single-key|raw key|numbered options" "Codex docs describe the scope boundary"

echo "All numeric-choice prompt contract checks passed."
