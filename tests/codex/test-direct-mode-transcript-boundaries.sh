#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIRECT_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-direct-mode-plain-answer-positive.jsonl"
LIGHTWEIGHT_SUBTASK_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-direct-mode-lightweight-subtask-positive.jsonl"

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

assert_jq_true() {
  local file="$1"
  local filter="$2"
  local description="$3"

  if jq -e -s "$filter" "$file" >/dev/null; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Filter: $filter"
    exit 1
  fi
}

if ! command -v jq >/dev/null 2>&1; then
  echo "FAIL: jq is required for direct-mode transcript boundary checks"
  exit 1
fi

assert_file_exists "$DIRECT_FIXTURE" "plain direct-mode fixture exists"
assert_jq_true "$DIRECT_FIXTURE" 'map(select(.payload.type == "function_call" and .payload.name == "request_user_input")) | length == 0' "plain direct-mode fixture never opens request_user_input"
assert_jq_true "$DIRECT_FIXTURE" 'map(select(.payload.type == "message")) | length >= 1' "plain direct-mode fixture captures at least one assistant message"
assert_jq_true "$DIRECT_FIXTURE" 'map(select(.payload.type == "message"))[0].payload.content[0].text | test("result|answer|translation"; "i")' "plain direct-mode fixture emits a user-visible result first"
assert_jq_true "$DIRECT_FIXTURE" '[.[] | .payload.metadata.endgate?] | map(select(. != null)) | length == 0' "plain direct-mode fixture has no workflow endgate carrier"

assert_file_exists "$LIGHTWEIGHT_SUBTASK_FIXTURE" "workflow lightweight-subtask fixture exists"
assert_jq_true "$LIGHTWEIGHT_SUBTASK_FIXTURE" 'map(select(.payload.type == "message")) | length >= 2' "lightweight-subtask fixture keeps both workflow context and a direct answer"
assert_jq_true "$LIGHTWEIGHT_SUBTASK_FIXTURE" 'map(select(.payload.type == "function_call" and .payload.name == "request_user_input")) | length == 0' "lightweight-subtask fixture never opens request_user_input"
assert_jq_true "$LIGHTWEIGHT_SUBTASK_FIXTURE" 'map(select(.payload.type == "message"))[1].payload.content[0].text | test("copy|text-only|translation|direct result"; "i")' "lightweight-subtask fixture shows a direct lightweight result"
assert_jq_true "$LIGHTWEIGHT_SUBTASK_FIXTURE" '[.[] | .payload.metadata.endgate?] | map(select(. != null)) | length == 0' "lightweight-subtask fixture does not inherit workflow endgate metadata"

echo "All direct-mode transcript boundary checks passed."
