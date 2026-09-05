#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "$REPO_ROOT/tests/shared/prompt-contract-helpers.sh"

assert_file_contains skills/executing-plans/SKILL.md 'authorized task IDs' 'execution passes the authorized task subset to review'
assert_file_contains skills/executing-plans/SKILL.md 'Passing the plan with its explicit authorized scope' 'batch-review guidance retains the authorized completion standard'
assert_file_contains skills/requesting-code-review/SKILL.md 'REVIEW_SCOPE' 'review dispatch declares a scope input'
assert_file_contains skills/requesting-code-review/code-reviewer.md '\{REVIEW_SCOPE\}' 'the dispatched prompt includes review scope'
for file in agents/code-reviewer.md skills/requesting-code-review/code-reviewer.md; do
  assert_file_contains "$file" 'deferred or excluded tasks' "$file distinguishes deferred work from missing functionality"
  assert_file_contains "$file" 'every in-scope task' "$file still checks all authorized tasks"
  assert_file_contains "$file" 'defects.*authorized deliverable|authorized deliverable.*defects' "$file still reports defects affecting the authorized deliverable"
  assert_file_not_contains "$file" 'Is all planned functionality present\?|Check every task, not a sample' "$file does not impose whole-plan completion on a subset"
done
echo 'Review scope checks passed.'
