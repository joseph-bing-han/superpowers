#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NEGATIVE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-prose-endgate-leak-negative.jsonl"
REQUEST_USER_INPUT_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-prose-endgate-repaired-request-user-input.jsonl"
AUTOCONTINUE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-prose-endgate-repaired-autocontinue.jsonl"

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

run_endgate_audit() {
  local file="$1"

  jq -c -s '
    def event_type:
      .payload.type // .type // "";
    def turn_id:
      .turn_id // .payload.turn_id // "turn-unknown";
    def is_task_complete:
      event_type == "task_complete";
    def is_request_user_input:
      event_type == "function_call" and (.payload.name // "") == "request_user_input";
    def is_auto_continue_action:
      event_type == "function_call"
      and (.payload.name // "") != ""
      and (.payload.name // "") != "request_user_input";
    def assistant_text:
      if event_type != "message" then
        ""
      elif (.payload.content? | type) == "array" then
        [
          .payload.content[]?
          | if type == "object" then
              (.text // .content // "")
            else
              tostring
            end
        ] | join(" ")
      else
        (.payload.text // .payload.content // "")
      end;
    def is_invitation_text:
      test("如果你同意|我下一步可以|I can .* next if you agree"; "i");

    to_entries
    | sort_by([(.value | turn_id), .key])
    | group_by(.value | turn_id)
    | map(
        . as $turn
        | ($turn[0].value | turn_id) as $current_turn_id
        | ([range(0; ($turn | length)) | select($turn[.].value | is_task_complete)] | first) as $task_complete_index
        | if $task_complete_index == null then
            empty
          else
            ([range(0; $task_complete_index) | $turn[.].value | select(event_type == "message") | assistant_text | select(length > 0)] | last // "") as $last_assistant_text
            | {
                turn_id: $current_turn_id,
                last_assistant_text: $last_assistant_text,
                has_request_user_input: any($turn[]; .value | is_request_user_input),
                has_auto_continue_action: any($turn[]; .value | is_auto_continue_action),
                leak_reason: "runtime prose-endgate leak"
              }
            | select(
                ($last_assistant_text | is_invitation_text)
                and (.has_request_user_input | not)
                and (.has_auto_continue_action | not)
              )
          end
      )
  ' "$file"
}

assert_audit_fails() {
  local file="$1"
  local description="$2"
  local result

  result="$(run_endgate_audit "$file")"

  if printf '%s' "$result" | jq -e 'length > 0' >/dev/null; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Expected at least one runtime prose-endgate leak"
    exit 1
  fi
}

assert_audit_passes() {
  local file="$1"
  local description="$2"
  local result

  result="$(run_endgate_audit "$file")"

  if printf '%s' "$result" | jq -e 'length == 0' >/dev/null; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Unexpected leaks: $result"
    exit 1
  fi
}

if ! command -v jq >/dev/null 2>&1; then
  echo "FAIL: jq is required for runtime endgate transcript checks"
  exit 1
fi

assert_file_exists "$NEGATIVE_FIXTURE" "negative runtime prose-endgate fixture exists"
assert_file_exists "$REQUEST_USER_INPUT_FIXTURE" "request_user_input repair fixture exists"
assert_file_exists "$AUTOCONTINUE_FIXTURE" "autocontinue repair fixture exists"

assert_audit_fails "$NEGATIVE_FIXTURE" "negative fixture is rejected for a runtime prose-endgate leak"
assert_audit_passes "$REQUEST_USER_INPUT_FIXTURE" "request_user_input repair fixture clears the runtime prose-endgate audit"
assert_audit_passes "$AUTOCONTINUE_FIXTURE" "autocontinue repair fixture clears the runtime prose-endgate audit"

echo "All runtime endgate transcript audit checks passed."
