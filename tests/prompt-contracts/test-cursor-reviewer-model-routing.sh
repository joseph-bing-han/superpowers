#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "$REPO_ROOT/tests/shared/prompt-contract-helpers.sh"
REFERENCE="skills/using-superpowers/references/cursor-tools.md"

assert_section_contains "$REFERENCE" '## Reviewer Model Routing' 'actual runtime configuration' 'reviewer capability comes from the runtime'
assert_section_contains "$REFERENCE" '## Reviewer Model Routing' 'prompt text cannot switch the model' 'prose cannot upgrade a running reviewer'
assert_section_contains "$REFERENCE" '## Reviewer Model Routing' 'Do not silently substitute.*search-only|lightweight agent' 'unavailable review cannot silently downgrade to search'
assert_section_contains "$REFERENCE" '## Reviewer Model Routing' 'report the limitation.*self-review' 'unavailable independent review has an honest fallback'
assert_section_contains "$REFERENCE" '## Reviewer Model Routing' 'Do not install models, change global settings' 'review preferences do not authorize configuration changes'

assert_frontmatter_field() {
  local file="$1" field="$2" expected="$3" actual
  actual="$(awk -v field="$field" '
    NR == 1 && $0 == "---" { active = 1; next }
    active && $0 == "---" { exit }
    active && $1 == field ":" { print $2 }
  ' "$REPO_ROOT/$file")"
  if [[ "$actual" != "$expected" ]]; then
    echo "FAIL: $file requires $field: $expected, got $actual"
    return 1
  fi
  echo "PASS: $file has $field: $expected"
}

for reviewer in plan-reviewer spec-reviewer code-reviewer; do
  file="agents/$reviewer.md"
  assert_frontmatter_field "$file" name "$reviewer"
  assert_frontmatter_field "$file" readonly true
  assert_file_contains "$file" 'model: [[:alnum:]][^ ]*' "$file declares a runtime model default"
  assert_file_contains "$file" 'model and effort actually configured by the host' "$file respects the configured capability"
  assert_file_contains "$REFERENCE" "agents/$reviewer.md" "$reviewer has a documented preset"
done

for file in skills/writing-plans/plan-document-reviewer-prompt.md skills/brainstorming/spec-document-reviewer-prompt.md skills/requesting-code-review/code-reviewer.md; do
  assert_file_contains "$file" 'using-superpowers/references/cursor-tools.md' "$file points to the platform routing contract"
  assert_file_contains "$file" 'never dispatch a reviewer through.*explore' "$file rejects search-only reviewer dispatch"
  assert_file_not_contains "$file" 'reviewer model tiers|Task tool \(general-purpose\)' "$file does not require removed tiers or a hardcoded fallback"
done
echo 'Cursor reviewer routing checks passed.'
