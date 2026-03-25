#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE="${BASH_SOURCE[0]-$PWD/tests/codex/test-runtime-endgate-transcript-audit.sh}"
REPO_ROOT="$(cd "$(dirname "$SCRIPT_SOURCE")/../.." && pwd)"
NEGATIVE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-prose-endgate-leak-negative.jsonl"
FOLLOWUP_NEGATIVE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-prose-endgate-leak-followup-offer-negative.jsonl"
PRIOR_TOOL_NEGATIVE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-prose-endgate-leak-prior-tool-call-negative.jsonl"
RECOMMENDATION_NEGATIVE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-prose-endgate-recommendation-leak-negative.jsonl"
SESSION_SHAPED_RECOMMENDATION_NEGATIVE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-prose-endgate-session-shaped-recommendation-leak-negative.jsonl"
VALUE_FRAMED_NEGATIVE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-prose-endgate-value-framed-leak-negative.jsonl"
REQUEST_USER_INPUT_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-prose-endgate-repaired-request-user-input.jsonl"
AUTOCONTINUE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-prose-endgate-repaired-autocontinue.jsonl"
PACKET_AUTOCONTINUE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-endgate-packet-autocontinue-positive.jsonl"
ITEM_PACKET_AUTOCONTINUE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-endgate-item-packet-autocontinue-positive.jsonl"
PACKET_TERMINAL_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-endgate-packet-terminal-choice-positive.jsonl"
PACKET_UNFULFILLED_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-endgate-packet-unfulfilled-negative.jsonl"
ITEM_PACKET_UNFULFILLED_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-endgate-item-packet-unfulfilled-negative.jsonl"
PACKET_MISSING_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-endgate-packet-missing-packet-negative.jsonl"
STRICT_SESSION_MISSING_PACKET_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-endgate-strict-session-missing-packet-negative.jsonl"

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
  local strict_packet_fixture="false"

  if [[ "$(basename "$file")" == runtime-endgate-packet-* ]]; then
    strict_packet_fixture="true"
  fi

  jq -c -s --arg strict_packet_fixture "$strict_packet_fixture" '
    def raw_turn_id:
      .turn_id // .payload.turn_id // null;
    def top_type:
      .type // "";
    def payload_type:
      .payload.type // "";
    def item_type:
      .item.type // "";
    def jsonish_to_object:
      if . == null then
        {}
      elif type == "string" then
        (fromjson? // {})
      elif type == "object" then
        .
      else
        {}
      end;
    def tool_arguments:
      (.payload.arguments // .item.arguments // .item.input // null) | jsonish_to_object;
    def is_task_complete:
      (top_type == "response_item" and payload_type == "task_complete")
      or
      (top_type == "event_msg" and payload_type == "task_complete")
      or top_type == "turn.completed";
    def is_turn_started:
      top_type == "turn.started"
      or (top_type == "response_item" and payload_type == "task_started")
      or (top_type == "event_msg" and payload_type == "task_started");
    def is_request_user_input:
      (
        top_type == "response_item"
        and payload_type == "function_call"
        and (.payload.name // "") == "request_user_input"
      )
      or (
        (top_type == "item.started" or top_type == "item.completed")
        and ((.item.tool // .item.name // "") == "request_user_input")
      );
    def is_auto_continue_action:
      (
        top_type == "response_item"
        and payload_type == "function_call"
        and (.payload.name // "") != ""
        and (.payload.name // "") != "request_user_input"
      )
      or (
        top_type == "item.started"
        and (
          item_type == "command_execution"
          or item_type == "mcp_tool_call"
          or item_type == "web_search"
          or item_type == "tool_call"
        )
        and ((.item.tool // .item.name // "") != "request_user_input")
      );
    def assistant_text:
      if top_type == "response_item" and payload_type == "message" then
        [
          .payload.content[]?
          | if type == "object" then
              (.text // .content // "")
            else
              tostring
            end
        ] | join(" ")
      elif top_type == "item.completed" and item_type == "agent_message" then
        (.item.text // "")
      else
        ""
      end;
    def transcript_text:
      if (assistant_text | length) > 0 then
        assistant_text
      elif top_type == "response_item" and payload_type == "function_call_output" then
        (.payload.output // "")
      elif top_type == "item.completed" then
        (.item.aggregated_output // .item.output // "")
      elif top_type == "event_msg" and payload_type == "agent_message" then
        (.payload.message // "")
      else
        ""
      end;
    def parse_endgate_packet($text):
      ($text | split("\n") | map(select(test("^ENDGATE_[A-Z_]+: ")))) as $lines
      | if ($lines | length) < 4 then
          null
        else
          reduce $lines[] as $line (
            {};
            ($line | capture("^(?<key>ENDGATE_[A-Z_]+): (?<value>.*)$")) as $field
            | . + {($field.key): $field.value}
          )
        end;
    def request_user_input_question_id:
      if is_request_user_input then
        (tool_arguments | .questions[0].id // "")
      else
        ""
      end;
    def is_strict_packet_mode_evidence:
      transcript_text
      | test(
          "this repository is in strict packet mode|Every [^\n]* uses `endgate-state-packet`|Every [^\n]* is packetized";
          "i"
        );
    def is_invitation_text:
      test(
        "如果你同意|如果你愿意|如果你要|如果你下一步是要|我下一步可以|我可以继续接着做|我可以继续(补|做|推进)|I can .* next if you agree|if you want, I can .* next";
        "i"
      );
    def is_recommendation_framed_next_step_text:
      test(
        "如果要进入下一步|如果进入下一步|如果按我的判断，下一步应该先|下一步最值得做的不是|下一步最值得做的是|下一步最合适的是|下一步最有价值的不是|下一步最有价值的是|我下一步最有价值的不是|我下一步最有价值的是|接下来更值得做的是|我建议直接做一份|我建议直接|我建议先|建议直接做一份|建议先把|the next best step is|i recommend .* next";
        "i"
      );

    reduce to_entries[] as $entry (
      {
        current_turn_id: null,
        synthetic_turn_counter: 0,
        annotated_entries: []
      };
      ($entry.value | raw_turn_id) as $explicit_turn_id
      | if (($entry.value | is_turn_started) and $explicit_turn_id == null) then
          .synthetic_turn_counter += 1
          | .current_turn_id = ("turn-seq-" + (.synthetic_turn_counter | tostring))
        else
          .
        end
      | ($explicit_turn_id // .current_turn_id // "turn-unknown") as $resolved_turn_id
      | .current_turn_id = ($explicit_turn_id // .current_turn_id)
      | .annotated_entries += [
          $entry + {
            audit_turn_id: $resolved_turn_id
          }
        ]
    )
    | .annotated_entries
    | sort_by([.audit_turn_id, .key])
    | group_by(.audit_turn_id)
    | map(
        . as $turn
        | ($turn[0].audit_turn_id) as $current_turn_id
        | ($turn | length) as $turn_length
        | ([range(0; ($turn | length)) | select($turn[.].value | is_task_complete)] | first) as $task_complete_index
        | (($strict_packet_fixture == "true") or any($turn[]?; .value | is_strict_packet_mode_evidence)) as $strict_turn_mode
        | (
            [range(0; $turn_length)
             | select(
                 ($turn[.].value | (assistant_text | length > 0))
                 and (($turn[.].value | assistant_text | parse_endgate_packet(.)) != null)
               )
            ] | last
          ) as $last_packet_index
        | if $last_packet_index != null then
            ($turn[$last_packet_index].value | assistant_text) as $packet_text
            | ($packet_text | parse_endgate_packet(.)) as $packet
            | ($turn[($last_packet_index + 1):($task_complete_index // $turn_length)] // []) as $post_packet_window
            | if $packet.ENDGATE_STATE == "AUTO_CONTINUE" then
                if any($post_packet_window[]?; .value | is_auto_continue_action) then
                  empty
                else
                  {
                    turn_id: $current_turn_id,
                    declared_packet: $packet,
                    leak_reason: "unfulfilled endgate-state-packet"
                  }
                end
              elif $packet.ENDGATE_STATE == "TERMINAL_CHOICE" then
                if any($post_packet_window[]?; (.value | is_request_user_input) and (.value | request_user_input_question_id) == "terminal_choice") then
                  empty
                else
                  {
                    turn_id: $current_turn_id,
                    declared_packet: $packet,
                    leak_reason: "missing terminal-choice popup for endgate-state-packet"
                  }
                end
              elif $packet.ENDGATE_STATE == "NEEDS_USER_DECISION" then
                if any($post_packet_window[]?; (.value | is_request_user_input) and (.value | request_user_input_question_id) != "terminal_choice") then
                  empty
                else
                  {
                    turn_id: $current_turn_id,
                    declared_packet: $packet,
                    leak_reason: "missing specific request_user_input for endgate-state-packet"
                  }
                end
              else
                  {
                    turn_id: $current_turn_id,
                    declared_packet: $packet,
                    leak_reason: "unknown endgate-state-packet state"
                  }
              end
          elif $strict_turn_mode and ($task_complete_index != null or any($turn[]?; .value | is_request_user_input)) then
            {
              turn_id: $current_turn_id,
              leak_reason: "missing endgate-state-packet in strict packet transcript"
            }
          elif $task_complete_index == null then
            empty
          else
            ([range(0; $task_complete_index) | select(($turn[.].value | assistant_text | length) > 0)] | last) as $last_assistant_index
            | if $last_assistant_index == null then
                empty
              else
                ($turn[$last_assistant_index].value | assistant_text) as $last_assistant_text
                | {
                    turn_id: $current_turn_id,
                    last_assistant_text: $last_assistant_text,
                    has_request_user_input: any($turn[($last_assistant_index + 1):$task_complete_index][]?; .value | is_request_user_input),
                    has_auto_continue_action: any($turn[($last_assistant_index + 1):$task_complete_index][]?; .value | is_auto_continue_action),
                    leak_reason: "runtime prose-endgate leak"
                  }
                | select(
                    ($last_assistant_text | length > 0)
                    and (
                      $last_assistant_text
                      | (is_invitation_text or is_recommendation_framed_next_step_text)
                    )
                    and (.has_request_user_input | not)
                    and (.has_auto_continue_action | not)
                  )
              end
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
assert_file_exists "$FOLLOWUP_NEGATIVE_FIXTURE" "followup-offer negative runtime prose-endgate fixture exists"
assert_file_exists "$PRIOR_TOOL_NEGATIVE_FIXTURE" "prior-tool-call negative runtime prose-endgate fixture exists"
assert_file_exists "$RECOMMENDATION_NEGATIVE_FIXTURE" "recommendation-framed negative runtime prose-endgate fixture exists"
assert_file_exists "$SESSION_SHAPED_RECOMMENDATION_NEGATIVE_FIXTURE" "session-shaped recommendation negative runtime prose-endgate fixture exists"
assert_file_exists "$VALUE_FRAMED_NEGATIVE_FIXTURE" "value-framed negative runtime prose-endgate fixture exists"
assert_file_exists "$REQUEST_USER_INPUT_FIXTURE" "request_user_input repair fixture exists"
assert_file_exists "$AUTOCONTINUE_FIXTURE" "autocontinue repair fixture exists"
assert_file_exists "$PACKET_AUTOCONTINUE_FIXTURE" "packet autocontinue runtime fixture exists"
assert_file_exists "$ITEM_PACKET_AUTOCONTINUE_FIXTURE" "item-based packet autocontinue runtime fixture exists"
assert_file_exists "$PACKET_TERMINAL_FIXTURE" "packet terminal-choice runtime fixture exists"
assert_file_exists "$PACKET_UNFULFILLED_FIXTURE" "packet unfulfilled negative runtime fixture exists"
assert_file_exists "$ITEM_PACKET_UNFULFILLED_FIXTURE" "item-based packet unfulfilled negative runtime fixture exists"
assert_file_exists "$PACKET_MISSING_FIXTURE" "packet strict-mode missing-packet runtime fixture exists"
assert_file_exists "$STRICT_SESSION_MISSING_PACKET_FIXTURE" "strict-session missing-packet runtime fixture exists"

assert_audit_fails "$NEGATIVE_FIXTURE" "negative fixture is rejected for a runtime prose-endgate leak"
assert_audit_fails "$FOLLOWUP_NEGATIVE_FIXTURE" "followup-offer negative fixture is rejected for a runtime prose-endgate leak"
assert_audit_fails "$PRIOR_TOOL_NEGATIVE_FIXTURE" "prior-tool-call negative fixture is rejected for a runtime prose-endgate leak"
assert_audit_fails "$RECOMMENDATION_NEGATIVE_FIXTURE" "recommendation-framed negative fixture is rejected for a runtime prose-endgate leak"
assert_audit_fails "$SESSION_SHAPED_RECOMMENDATION_NEGATIVE_FIXTURE" "session-shaped recommendation negative fixture is rejected for a runtime prose-endgate leak"
assert_audit_fails "$VALUE_FRAMED_NEGATIVE_FIXTURE" "value-framed negative fixture is rejected for a runtime prose-endgate leak"
assert_audit_passes "$REQUEST_USER_INPUT_FIXTURE" "request_user_input repair fixture clears the runtime prose-endgate audit"
assert_audit_passes "$AUTOCONTINUE_FIXTURE" "autocontinue repair fixture clears the runtime prose-endgate audit"
assert_audit_passes "$PACKET_AUTOCONTINUE_FIXTURE" "packet autocontinue fixture clears the runtime endgate audit"
assert_audit_passes "$ITEM_PACKET_AUTOCONTINUE_FIXTURE" "item-based packet autocontinue fixture clears the runtime endgate audit"
assert_audit_passes "$PACKET_TERMINAL_FIXTURE" "packet terminal-choice fixture clears the runtime endgate audit"
assert_audit_fails "$PACKET_UNFULFILLED_FIXTURE" "packet unfulfilled fixture is rejected when no post-packet continuation happens"
assert_audit_fails "$ITEM_PACKET_UNFULFILLED_FIXTURE" "item-based packet unfulfilled fixture is rejected when no post-packet continuation happens"
assert_audit_fails "$PACKET_MISSING_FIXTURE" "packet strict-mode fixture is rejected when the packet is missing"
assert_audit_fails "$STRICT_SESSION_MISSING_PACKET_FIXTURE" "strict-session transcript is rejected when the packet is missing"

echo "All runtime endgate transcript audit checks passed."
