#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE="${BASH_SOURCE[0]-$PWD/tests/codex/test-openspec-lane-entry-transcript-audit.sh}"
REPO_ROOT="$(cd "$(dirname "$SCRIPT_SOURCE")/../.." && pwd)"
NEGATIVE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/openspec-lane-entry-ordinary-doc-before-confirmation-negative.jsonl"
POSITIVE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/openspec-lane-entry-confirmation-before-change-positive.jsonl"

assert_file_exists() {
  local file="$1"
  local description="$2"

  if [[ -f "$file" ]]; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  Missing file: $file"
    exit 1
  fi
}

find_first_line() {
  local file="$1"
  local pattern="$2"

  rg -n -- "$pattern" "$file" | head -n 1 | cut -d: -f1 || true
}

audit_lane_entry_fixture() {
  local file="$1"
  local ordinary_doc_line=""
  local lane_confirmation_line=""
  local change_creation_line=""

  ordinary_doc_line="$(find_first_line "$file" 'docs/specs/|docs/plans/')"
  lane_confirmation_line="$(find_first_line "$file" 'request_user_input.*创建 OpenSpec 提案|创建 OpenSpec 提案.*request_user_input')"
  change_creation_line="$(find_first_line "$file" 'openspec new change')"

  if [[ -z "$lane_confirmation_line" ]]; then
    echo "missing lane confirmation"
    return 1
  fi

  if [[ -n "$ordinary_doc_line" && "$ordinary_doc_line" -lt "$lane_confirmation_line" ]]; then
    echo "ordinary docs created before lane confirmation"
    return 1
  fi

  if [[ -n "$change_creation_line" && "$change_creation_line" -lt "$lane_confirmation_line" ]]; then
    echo "change created before lane confirmation"
    return 1
  fi

  if [[ -z "$ordinary_doc_line" && -z "$change_creation_line" ]]; then
    echo "missing post-confirmation outcome"
    return 1
  fi
}

assert_fixture_passes() {
  local file="$1"
  local description="$2"

  if audit_lane_entry_fixture "$file" >/dev/null; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    audit_lane_entry_fixture "$file" || true
    exit 1
  fi
}

assert_fixture_fails() {
  local file="$1"
  local expected_substring="$2"
  local description="$3"
  local output

  if output="$(audit_lane_entry_fixture "$file" 2>&1)"; then
    echo "FAIL: $description"
    echo "  Fixture unexpectedly passed"
    exit 1
  fi

  if printf '%s\n' "$output" | rg -q -- "$expected_substring"; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  Expected substring: $expected_substring"
    echo "  Actual output: $output"
    exit 1
  fi
}

assert_file_exists "$NEGATIVE_FIXTURE" "negative OpenSpec lane-entry fixture exists"
assert_file_exists "$POSITIVE_FIXTURE" "positive OpenSpec lane-entry fixture exists"

assert_fixture_fails \
  "$NEGATIVE_FIXTURE" \
  "ordinary docs created before lane confirmation" \
  "negative fixture is rejected when ordinary docs land before OpenSpec lane confirmation"

assert_fixture_passes \
  "$POSITIVE_FIXTURE" \
  "positive fixture passes when lane confirmation happens before change creation"

echo "All OpenSpec lane-entry transcript audit checks passed."
