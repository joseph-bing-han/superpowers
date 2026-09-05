#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(mktemp -d)"
trap 'rm -rf "$REPO_ROOT"' EXIT
source "$SCRIPT_DIR/prompt-contract-helpers.sh"

cat > "$REPO_ROOT/sample.md" <<'EOF'
## Current
Authorized work
continues safely.
### Detail
Context is retained.
## Legacy
Old packet rules.
## Empty
EOF
printf '## Whitespace\n \t \n' >> "$REPO_ROOT/sample.md"

assert_section_contains sample.md '## Current' 'Authorized work continues safely' 'wrapped Markdown matches across lines'
assert_section_contains sample.md '## Current' 'Context is retained' 'a section includes its nested headings'
assert_section_not_contains sample.md '## Current' 'Old packet rules' 'a section excludes the next peer section'
assert_file_not_contains sample.md 'Missing marker' 'absent patterns pass negative assertions'

expect_failure() {
  local description="$1"
  shift
  if "$@" > "$REPO_ROOT/assertion-output" 2>&1; then
    echo "FAIL: $description"
    return 1
  fi
  echo "PASS: $description"
}

expect_failure 'missing patterns fail positive assertions' assert_file_contains sample.md 'Missing marker' sample
expect_failure 'present patterns fail negative assertions' assert_file_not_contains sample.md 'Authorized work' sample
expect_failure 'missing files cannot pass negative assertions' assert_file_not_contains missing.md 'anything' sample
expect_failure 'missing sections cannot pass negative assertions' assert_section_not_contains sample.md '## Missing' 'anything' sample
expect_failure 'empty sections cannot pass negative assertions' assert_section_not_contains sample.md '## Empty' 'anything' sample
expect_failure 'whitespace-only sections cannot pass negative assertions' assert_section_not_contains sample.md '## Whitespace' 'anything' sample
expect_failure 'invalid patterns cannot pass negative assertions' assert_file_not_contains sample.md '[' sample

(
  cat() { return 42; }
  expect_failure 'failed file reads cannot pass negative assertions' assert_file_not_contains sample.md 'anything' sample
)
(
  awk() { printf '%s' 'Authorized work'; return 42; }
  expect_failure 'failed section reads cannot pass with partial output' assert_section_contains sample.md '## Current' 'Authorized work' sample
)
(
  set +o pipefail
  tr() { return 42; }
  expect_failure 'failed normalization cannot pass negative assertions' assert_file_not_contains sample.md 'anything' sample
)
echo 'Prompt contract helper checks passed.'
