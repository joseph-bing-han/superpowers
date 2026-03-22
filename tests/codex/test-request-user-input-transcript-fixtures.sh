#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TERMINAL_FIXTURE="$REPO_ROOT/tests/codex/fixtures/request-user-input-terminal-choice.jsonl"
HANDOFF_FIXTURE="$REPO_ROOT/tests/codex/fixtures/request-user-input-execution-handoff.jsonl"

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
  echo "FAIL: jq is required for transcript fixture checks"
  exit 1
fi

assert_file_exists "$TERMINAL_FIXTURE" "terminal-choice fixture exists"
assert_jq_true "$TERMINAL_FIXTURE" 'map(select(.payload.type == "function_call" and .payload.name == "request_user_input")) | length == 1' "terminal-choice fixture captures one request_user_input function_call"
assert_jq_true "$TERMINAL_FIXTURE" 'map(select(.payload.type == "function_call_output")) | length == 1' "terminal-choice fixture captures one function_call_output event"
assert_jq_true "$TERMINAL_FIXTURE" '(map(select(.payload.type == "function_call")) | .[0].payload.call_id) == (map(select(.payload.type == "function_call_output")) | .[0].payload.call_id)' "terminal-choice fixture keeps a shared call_id across call and output"
assert_jq_true "$TERMINAL_FIXTURE" 'map(select(.payload.type == "function_call")) | .[0].payload.arguments | fromjson | .questions | length == 1' "terminal-choice fixture captures one question payload"
assert_jq_true "$TERMINAL_FIXTURE" 'map(select(.payload.type == "function_call")) | .[0].payload.arguments | fromjson | .questions[0].id == "terminal_choice"' "terminal-choice fixture preserves the terminal-choice question id"
assert_jq_true "$TERMINAL_FIXTURE" 'map(select(.payload.type == "function_call")) | .[0].payload.arguments | fromjson | .questions[0].options | map(.label) == ["结束 (Recommended)", "继续", "自由输入"]' "terminal-choice fixture preserves the exact option labels"
assert_jq_true "$TERMINAL_FIXTURE" 'map(select(.payload.type == "function_call_output")) | .[0].payload.output | fromjson | .answers.terminal_choice.answers == ["结束 (Recommended)"]' "terminal-choice fixture preserves the exact selected answer"

assert_file_exists "$HANDOFF_FIXTURE" "execution-handoff fixture exists"
assert_jq_true "$HANDOFF_FIXTURE" 'map(select(.payload.type == "function_call" and .payload.name == "request_user_input")) | length == 1' "execution-handoff fixture captures one request_user_input function_call"
assert_jq_true "$HANDOFF_FIXTURE" 'map(select(.payload.type == "function_call_output")) | length == 1' "execution-handoff fixture captures one function_call_output event"
assert_jq_true "$HANDOFF_FIXTURE" '(map(select(.payload.type == "function_call")) | .[0].payload.call_id) == (map(select(.payload.type == "function_call_output")) | .[0].payload.call_id)' "execution-handoff fixture keeps a shared call_id across call and output"
assert_jq_true "$HANDOFF_FIXTURE" 'map(select(.payload.type == "function_call")) | .[0].payload.arguments | fromjson | .questions | length == 1' "execution-handoff fixture captures one question payload"
assert_jq_true "$HANDOFF_FIXTURE" 'map(select(.payload.type == "function_call")) | .[0].payload.arguments | fromjson | .questions[0].id == "execution_path"' "execution-handoff fixture preserves the execution-path question id"
assert_jq_true "$HANDOFF_FIXTURE" 'map(select(.payload.type == "function_call")) | .[0].payload.arguments | fromjson | .questions[0].options | map(.label) == ["Subagent-Driven", "Inline Execution", "先停在这里"]' "execution-handoff fixture preserves the exact option labels"
assert_jq_true "$HANDOFF_FIXTURE" 'map(select(.payload.type == "function_call_output")) | .[0].payload.output | fromjson | .answers.execution_path.answers == ["Subagent-Driven"]' "execution-handoff fixture preserves the exact selected answer"

echo "All request_user_input transcript fixture checks passed."
