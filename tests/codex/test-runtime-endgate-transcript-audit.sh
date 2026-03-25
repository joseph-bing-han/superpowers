#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE="${BASH_SOURCE[0]-$PWD/tests/codex/test-runtime-endgate-transcript-audit.sh}"
REPO_ROOT="$(cd "$(dirname "$SCRIPT_SOURCE")/../.." && pwd)"
source "$REPO_ROOT/tests/shared/workflow-contract-helpers.sh"
NEGATIVE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-prose-endgate-leak-negative.jsonl"
FOLLOWUP_NEGATIVE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-prose-endgate-leak-followup-offer-negative.jsonl"
PRIOR_TOOL_NEGATIVE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-prose-endgate-leak-prior-tool-call-negative.jsonl"
RECOMMENDATION_NEGATIVE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-prose-endgate-recommendation-leak-negative.jsonl"
SESSION_SHAPED_RECOMMENDATION_NEGATIVE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-prose-endgate-session-shaped-recommendation-leak-negative.jsonl"
VALUE_FRAMED_NEGATIVE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-prose-endgate-value-framed-leak-negative.jsonl"
REQUEST_USER_INPUT_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-prose-endgate-repaired-request-user-input.jsonl"
AUTOCONTINUE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-prose-endgate-repaired-autocontinue.jsonl"
STRUCTURED_AUTOCONTINUE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-endgate-structured-carrier-autocontinue-positive.jsonl"
STRUCTURED_NEEDS_USER_DECISION_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-endgate-structured-carrier-needs-user-decision-positive.jsonl"
STRUCTURED_TERMINAL_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-endgate-structured-carrier-terminal-choice-positive.jsonl"
PACKET_AUTOCONTINUE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-endgate-packet-autocontinue-positive.jsonl"
ITEM_PACKET_AUTOCONTINUE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-endgate-item-packet-autocontinue-positive.jsonl"
PACKET_TERMINAL_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-endgate-packet-terminal-choice-positive.jsonl"
PACKET_UNFULFILLED_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-endgate-packet-unfulfilled-negative.jsonl"
ITEM_PACKET_UNFULFILLED_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-endgate-item-packet-unfulfilled-negative.jsonl"
PACKET_MISSING_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-endgate-packet-missing-packet-negative.jsonl"
STRICT_SESSION_MISSING_PACKET_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-endgate-strict-session-missing-packet-negative.jsonl"
INVITATION_TEXT_PATTERN='如果你同意|如果你愿意|如果你要|如果你下一步是要|我下一步可以|我可以继续接着做|我可以继续(补|做|推进)|I can .* next if you agree|if you want, I can .* next'
RECOMMENDATION_TEXT_PATTERN='如果要进入下一步|如果进入下一步|如果按我的判断，下一步应该先|下一步最值得做的不是|下一步最值得做的是|下一步最合适的是|下一步最有价值的不是|下一步最有价值的是|我下一步最有价值的不是|我下一步最有价值的是|接下来更值得做的是|我建议直接做一份|我建议直接|我建议先|建议直接做一份|建议先把|the next best step is|i recommend .* next'

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

build_runtime_audit_turn_contexts() {
  local file="$1"
  local strict_fixture="$2"

  jq -c -s --arg strict_fixture "$strict_fixture" '
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
        | {
            turn_id: $turn[0].audit_turn_id,
            turn_length: ($turn | length),
            task_complete_index: ([range(0; ($turn | length)) | select($turn[.].value | is_task_complete)] | first),
            has_request_user_input: any($turn[]?; .value | is_request_user_input),
            has_auto_continue_action: any($turn[]?; .value | is_auto_continue_action),
            strict_turn_mode: (($strict_fixture == "true") or any($turn[]?; .value | is_strict_packet_mode_evidence)),
            entries: [
              range(0; ($turn | length)) as $index
              | ($turn[$index].value) as $value
              | {
                  index: $index,
                  source_line_number: ($turn[$index].key + 1),
                  raw_entry: $value,
                  assistant_text: ($value | assistant_text),
                  transcript_text: ($value | transcript_text),
                  is_request_user_input: ($value | is_request_user_input),
                  request_user_input_question_id: ($value | request_user_input_question_id),
                  is_auto_continue_action: ($value | is_auto_continue_action)
                }
            ]
          }
      )
  ' "$file"
}

assistant_text_triggers_legacy_prose_leak() {
  local text="$1"

  if printf '%s\n' "$text" | grep -Eqi "$INVITATION_TEXT_PATTERN"; then
    return 0
  fi

  printf '%s\n' "$text" | grep -Eqi "$RECOMMENDATION_TEXT_PATTERN"
}

run_endgate_audit() {
  local file="$1"
  local strict_fixture="false"
  local turn_contexts
  local turn_context
  local results=()

  if [[ "$(basename "$file")" == runtime-endgate-* ]]; then
    strict_fixture="true"
  fi

  turn_contexts="$(build_runtime_audit_turn_contexts "$file" "$strict_fixture")"

  while IFS= read -r turn_context; do
    local turn_id
    local turn_length
    local task_complete_index
    local strict_turn_mode
    local has_request_user_input
    local turn_has_auto_continue_action
    local last_carrier_index=""
    local last_carrier_kind=""
    local last_carrier_object=""
    local last_carrier_state=""
    local last_assistant_index=""
    local last_assistant_text=""
    local post_window_end
    local post_window_start
    local has_auto_continue_action="false"
    local has_terminal_choice_popup="false"
    local has_specific_request_user_input="false"
    local has_request_user_input_after_last_assistant="false"
    local has_auto_continue_after_last_assistant="false"

    turn_id="$(printf '%s\n' "$turn_context" | jq -r '.turn_id')"
    turn_length="$(printf '%s\n' "$turn_context" | jq -r '.turn_length')"
    task_complete_index="$(printf '%s\n' "$turn_context" | jq -r '.task_complete_index // empty')"
    strict_turn_mode="$(printf '%s\n' "$turn_context" | jq -r '.strict_turn_mode')"
    has_request_user_input="$(printf '%s\n' "$turn_context" | jq -r '.has_request_user_input')"
    turn_has_auto_continue_action="$(printf '%s\n' "$turn_context" | jq -r '.has_auto_continue_action')"

    for ((index = 0; index < turn_length; index++)); do
      local entry_json
      local source_line_number
      local raw_entry
      local assistant_text
      local snapshot_file
      local carrier_object

      entry_json="$(printf '%s\n' "$turn_context" | jq -c ".entries[$index]")"
      source_line_number="$(printf '%s\n' "$entry_json" | jq -r '.source_line_number')"
      raw_entry="$(sed -n "${source_line_number}p" "$file")"
      assistant_text="$(printf '%s\n' "$entry_json" | jq -r '.assistant_text')"
      snapshot_file="$(mktemp "${TMPDIR:-/tmp}/runtime-endgate-entry.XXXXXX")"

      printf '%s\n' "$raw_entry" > "$snapshot_file"
      if [ -n "$assistant_text" ]; then
        printf '\n%s\n' "$assistant_text" >> "$snapshot_file"
      fi

      carrier_object="$(print_endgate_carrier_object "$snapshot_file")"
      if [ -n "$carrier_object" ]; then
        last_carrier_index="$index"
        last_carrier_kind="$(extract_endgate_carrier_kind "$snapshot_file")"
        last_carrier_object="$carrier_object"
        last_carrier_state="$(extract_endgate_carrier_field "$snapshot_file" "ENDGATE_STATE")"
      fi

      rm -f "$snapshot_file"
    done

    if [ -n "$last_carrier_index" ]; then
      post_window_start=$((last_carrier_index + 1))
      post_window_end="$turn_length"

      if [ -n "$task_complete_index" ]; then
        post_window_end="$task_complete_index"
      fi

      has_auto_continue_action="$(printf '%s\n' "$turn_context" | jq -r --argjson start "$post_window_start" --argjson end "$post_window_end" '
        any(.entries[$start:$end][]?; .is_auto_continue_action)
      ')"
      has_terminal_choice_popup="$(printf '%s\n' "$turn_context" | jq -r --argjson start "$post_window_start" --argjson end "$post_window_end" '
        any(.entries[$start:$end][]?; .is_request_user_input and .request_user_input_question_id == "terminal_choice")
      ')"
      has_specific_request_user_input="$(printf '%s\n' "$turn_context" | jq -r --argjson start "$post_window_start" --argjson end "$post_window_end" '
        any(.entries[$start:$end][]?; .is_request_user_input and .request_user_input_question_id != "terminal_choice")
      ')"

      case "$last_carrier_state" in
        AUTO_CONTINUE)
          if [ "$has_auto_continue_action" = "true" ]; then
            results+=("$(jq -n --arg turn_id "$turn_id" --arg carrier_kind "$last_carrier_kind" --argjson declared_carrier "$last_carrier_object" '
              {
                turn_id: $turn_id,
                status: "pass",
                validation_mode: (if $carrier_kind == "structured" then "valid structured carrier" else "valid tail block fallback" end),
                carrier_kind: $carrier_kind,
                declared_carrier: $declared_carrier
              }
            ')")
          else
            results+=("$(jq -n --arg turn_id "$turn_id" --arg carrier_kind "$last_carrier_kind" --argjson declared_carrier "$last_carrier_object" '
              {
                turn_id: $turn_id,
                status: "fail",
                failure_mode: "missing post-carrier action",
                expected_post_carrier_action: "auto_continue_action",
                carrier_kind: $carrier_kind,
                declared_carrier: $declared_carrier
              }
            ')")
          fi
          ;;
        TERMINAL_CHOICE)
          if [ "$has_terminal_choice_popup" = "true" ]; then
            results+=("$(jq -n --arg turn_id "$turn_id" --arg carrier_kind "$last_carrier_kind" --argjson declared_carrier "$last_carrier_object" '
              {
                turn_id: $turn_id,
                status: "pass",
                validation_mode: (if $carrier_kind == "structured" then "valid structured carrier" else "valid tail block fallback" end),
                carrier_kind: $carrier_kind,
                declared_carrier: $declared_carrier
              }
            ')")
          else
            results+=("$(jq -n --arg turn_id "$turn_id" --arg carrier_kind "$last_carrier_kind" --argjson declared_carrier "$last_carrier_object" '
              {
                turn_id: $turn_id,
                status: "fail",
                failure_mode: "missing post-carrier action",
                expected_post_carrier_action: "terminal_choice_popup",
                carrier_kind: $carrier_kind,
                declared_carrier: $declared_carrier
              }
            ')")
          fi
          ;;
        NEEDS_USER_DECISION)
          if [ "$has_specific_request_user_input" = "true" ]; then
            results+=("$(jq -n --arg turn_id "$turn_id" --arg carrier_kind "$last_carrier_kind" --argjson declared_carrier "$last_carrier_object" '
              {
                turn_id: $turn_id,
                status: "pass",
                validation_mode: (if $carrier_kind == "structured" then "valid structured carrier" else "valid tail block fallback" end),
                carrier_kind: $carrier_kind,
                declared_carrier: $declared_carrier
              }
            ')")
          else
            results+=("$(jq -n --arg turn_id "$turn_id" --arg carrier_kind "$last_carrier_kind" --argjson declared_carrier "$last_carrier_object" '
              {
                turn_id: $turn_id,
                status: "fail",
                failure_mode: "missing post-carrier action",
                expected_post_carrier_action: "specific_request_user_input",
                carrier_kind: $carrier_kind,
                declared_carrier: $declared_carrier
              }
            ')")
          fi
          ;;
        *)
          results+=("$(jq -n --arg turn_id "$turn_id" --arg carrier_kind "$last_carrier_kind" --arg carrier_state "$last_carrier_state" --argjson declared_carrier "$last_carrier_object" '
            {
              turn_id: $turn_id,
              status: "fail",
              failure_mode: "unknown carrier state",
              carrier_kind: $carrier_kind,
              carrier_state: $carrier_state,
              declared_carrier: $declared_carrier
            }
          ')")
          ;;
      esac

      continue
    fi

    if [ "$strict_turn_mode" = "true" ] && { [ -n "$task_complete_index" ] || [ "$has_request_user_input" = "true" ] || [ "$turn_has_auto_continue_action" = "true" ]; }; then
      results+=("$(jq -n --arg turn_id "$turn_id" '
        {
          turn_id: $turn_id,
          status: "fail",
          failure_mode: "missing canonical carrier"
        }
      ')")
      continue
    fi

    last_assistant_index="$(printf '%s\n' "$turn_context" | jq -r '
      [ .entries[] | select((.assistant_text // "") != "") | .index ] | last // empty
    ')"

    if [ -z "$last_assistant_index" ]; then
      continue
    fi

    last_assistant_text="$(printf '%s\n' "$turn_context" | jq -r --argjson index "$last_assistant_index" '.entries[$index].assistant_text')"
    post_window_start=$((last_assistant_index + 1))
    post_window_end="$turn_length"

    if [ -n "$task_complete_index" ]; then
      post_window_end="$task_complete_index"
    fi

    has_request_user_input_after_last_assistant="$(printf '%s\n' "$turn_context" | jq -r --argjson start "$post_window_start" --argjson end "$post_window_end" '
      any(.entries[$start:$end][]?; .is_request_user_input)
    ')"
    has_auto_continue_after_last_assistant="$(printf '%s\n' "$turn_context" | jq -r --argjson start "$post_window_start" --argjson end "$post_window_end" '
      any(.entries[$start:$end][]?; .is_auto_continue_action)
    ')"

    if assistant_text_triggers_legacy_prose_leak "$last_assistant_text"; then
      if [ "$has_request_user_input_after_last_assistant" = "true" ] || [ "$has_auto_continue_after_last_assistant" = "true" ]; then
        results+=("$(jq -n --arg turn_id "$turn_id" '
          {
            turn_id: $turn_id,
            status: "pass",
            validation_mode: "legacy prose safety net"
          }
        ')")
      else
        results+=("$(jq -n --arg turn_id "$turn_id" --arg last_assistant_text "$last_assistant_text" '
          {
            turn_id: $turn_id,
            status: "fail",
            failure_mode: "legacy prose leak",
            last_assistant_text: $last_assistant_text
          }
        ')")
      fi
    fi
  done < <(printf '%s\n' "$turn_contexts" | jq -c '.[]')

  if [ "${#results[@]}" -eq 0 ]; then
    printf '[]\n'
    return 0
  fi

  printf '%s\n' "${results[@]}" | jq -s '.'
}

assert_audit_fails() {
  local file="$1"
  local description="$2"
  local result

  result="$(run_endgate_audit "$file")"

  if printf '%s' "$result" | jq -e 'any(.[]?; .status == "fail")' >/dev/null; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Expected at least one audit failure"
    exit 1
  fi
}

assert_audit_fails_with_mode() {
  local file="$1"
  local expected_mode="$2"
  local description="$3"
  local result

  result="$(run_endgate_audit "$file")"

  if printf '%s' "$result" | jq -e --arg expected_mode "$expected_mode" '
    any(.[]?; .status == "fail" and .failure_mode == $expected_mode)
  ' >/dev/null; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Expected failure mode: $expected_mode"
    echo "  Audit output: $result"
    exit 1
  fi
}

assert_audit_passes() {
  local file="$1"
  local description="$2"
  local result

  result="$(run_endgate_audit "$file")"

  if printf '%s' "$result" | jq -e 'all(.[]?; .status == "pass")' >/dev/null; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Unexpected leaks: $result"
    exit 1
  fi
}

assert_audit_passes_with_mode() {
  local file="$1"
  local expected_mode="$2"
  local description="$3"
  local result

  result="$(run_endgate_audit "$file")"

  if printf '%s' "$result" | jq -e --arg expected_mode "$expected_mode" '
    length > 0
    and all(.[]?; .status == "pass")
    and any(.[]?; .validation_mode == $expected_mode)
  ' >/dev/null; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Expected pass mode: $expected_mode"
    echo "  Audit output: $result"
    exit 1
  fi
}

write_inline_runtime_fixture() {
  local file="$1"
  local scenario="$2"

  case "$scenario" in
    duplicate_structured_with_visible_fallback)
      cat <<'EOF' > "$file"
{"timestamp":"2026-03-26T10:00:00.000Z","turn_id":"turn-duplicate-structured-visible-fallback","type":"response_item","payload":{"type":"message","role":"assistant","metadata":{"endgate":{"ENDGATE_PROTOCOL_VERSION":"1","ENDGATE_STATE":"TERMINAL_CHOICE","ENDGATE_STATE":"AUTO_CONTINUE","ENDGATE_CHOICE_KIND":"NONE","ENDGATE_NEXT_ACTION":"CONTINUE_WITH_TOOL"}},"content":[{"type":"output_text","text":"Malformed structured carrier should fall back to the visible tail block.\nENDGATE_PROTOCOL_VERSION: 1\nENDGATE_STATE: AUTO_CONTINUE\nENDGATE_CHOICE_KIND: NONE\nENDGATE_NEXT_ACTION: CONTINUE_WITH_TOOL"}]}}
{"timestamp":"2026-03-26T10:00:02.000Z","turn_id":"turn-duplicate-structured-visible-fallback","type":"response_item","payload":{"type":"function_call","name":"exec_command","arguments":"{\"cmd\":\"bash tests/codex/test-runtime-endgate-transcript-audit.sh\"}","call_id":"call_duplicate_structured_visible_fallback_exec"}}
{"timestamp":"2026-03-26T10:00:04.000Z","turn_id":"turn-duplicate-structured-visible-fallback","type":"response_item","payload":{"type":"function_call_output","call_id":"call_duplicate_structured_visible_fallback_exec","output":"PASS"}}
EOF
      ;;
    duplicate_structured_without_fallback)
      cat <<'EOF' > "$file"
{"timestamp":"2026-03-26T10:10:00.000Z","turn_id":"turn-duplicate-structured-no-fallback","type":"response_item","payload":{"type":"message","role":"assistant","metadata":{"endgate":{"ENDGATE_PROTOCOL_VERSION":"1","ENDGATE_STATE":"TERMINAL_CHOICE","ENDGATE_STATE":"AUTO_CONTINUE","ENDGATE_CHOICE_KIND":"NONE","ENDGATE_NEXT_ACTION":"CONTINUE_WITH_TOOL"}},"content":[{"type":"output_text","text":"Malformed structured carrier is present here, but there is no visible fallback block."}]}}
{"timestamp":"2026-03-26T10:10:02.000Z","turn_id":"turn-duplicate-structured-no-fallback","type":"response_item","payload":{"type":"function_call","name":"exec_command","arguments":"{\"cmd\":\"bash tests/codex/test-runtime-endgate-transcript-audit.sh\"}","call_id":"call_duplicate_structured_no_fallback_exec"}}
{"timestamp":"2026-03-26T10:10:04.000Z","turn_id":"turn-duplicate-structured-no-fallback","type":"response_item","payload":{"type":"function_call_output","call_id":"call_duplicate_structured_no_fallback_exec","output":"PASS"}}
EOF
      ;;
    *)
      echo "FAIL: unknown inline runtime fixture scenario: $scenario"
      exit 1
      ;;
  esac
}

assert_inline_runtime_fixture_passes_with_mode() {
  local scenario="$1"
  local expected_mode="$2"
  local description="$3"
  local fixture

  fixture="$(mktemp "${TMPDIR:-/tmp}/runtime-endgate-${scenario}.XXXXXX")"
  write_inline_runtime_fixture "$fixture" "$scenario"
  assert_audit_passes_with_mode "$fixture" "$expected_mode" "$description"
  rm -f "$fixture"
}

assert_inline_runtime_fixture_fails_with_mode() {
  local scenario="$1"
  local expected_mode="$2"
  local description="$3"
  local fixture

  fixture="$(mktemp "${TMPDIR:-/tmp}/runtime-endgate-${scenario}.XXXXXX")"
  write_inline_runtime_fixture "$fixture" "$scenario"
  assert_audit_fails_with_mode "$fixture" "$expected_mode" "$description"
  rm -f "$fixture"
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
assert_file_exists "$STRUCTURED_AUTOCONTINUE_FIXTURE" "structured autocontinue runtime fixture exists"
assert_file_exists "$STRUCTURED_NEEDS_USER_DECISION_FIXTURE" "structured needs-user-decision runtime fixture exists"
assert_file_exists "$STRUCTURED_TERMINAL_FIXTURE" "structured terminal-choice runtime fixture exists"
assert_file_exists "$PACKET_AUTOCONTINUE_FIXTURE" "packet autocontinue runtime fixture exists"
assert_file_exists "$ITEM_PACKET_AUTOCONTINUE_FIXTURE" "item-based packet autocontinue runtime fixture exists"
assert_file_exists "$PACKET_TERMINAL_FIXTURE" "packet terminal-choice runtime fixture exists"
assert_file_exists "$PACKET_UNFULFILLED_FIXTURE" "packet unfulfilled negative runtime fixture exists"
assert_file_exists "$ITEM_PACKET_UNFULFILLED_FIXTURE" "item-based packet unfulfilled negative runtime fixture exists"
assert_file_exists "$PACKET_MISSING_FIXTURE" "packet strict-mode missing-packet runtime fixture exists"
assert_file_exists "$STRICT_SESSION_MISSING_PACKET_FIXTURE" "strict-session missing-packet runtime fixture exists"

assert_audit_fails_with_mode "$NEGATIVE_FIXTURE" "legacy prose leak" "negative fixture is rejected for a legacy prose leak"
assert_audit_fails_with_mode "$FOLLOWUP_NEGATIVE_FIXTURE" "legacy prose leak" "followup-offer negative fixture is rejected for a legacy prose leak"
assert_audit_fails_with_mode "$PRIOR_TOOL_NEGATIVE_FIXTURE" "legacy prose leak" "prior-tool-call negative fixture is rejected for a legacy prose leak"
assert_audit_fails_with_mode "$RECOMMENDATION_NEGATIVE_FIXTURE" "legacy prose leak" "recommendation-framed negative fixture is rejected for a legacy prose leak"
assert_audit_fails_with_mode "$SESSION_SHAPED_RECOMMENDATION_NEGATIVE_FIXTURE" "legacy prose leak" "session-shaped recommendation negative fixture is rejected for a legacy prose leak"
assert_audit_fails_with_mode "$VALUE_FRAMED_NEGATIVE_FIXTURE" "legacy prose leak" "value-framed negative fixture is rejected for a legacy prose leak"
assert_audit_passes "$REQUEST_USER_INPUT_FIXTURE" "request_user_input repair fixture clears the runtime prose-endgate audit"
assert_audit_passes "$AUTOCONTINUE_FIXTURE" "autocontinue repair fixture clears the runtime prose-endgate audit"
assert_audit_passes_with_mode "$STRUCTURED_AUTOCONTINUE_FIXTURE" "valid structured carrier" "structured autocontinue fixture validates the structured carrier path first"
assert_audit_passes_with_mode "$STRUCTURED_NEEDS_USER_DECISION_FIXTURE" "valid structured carrier" "structured needs-user-decision fixture validates the structured carrier path first"
assert_audit_passes_with_mode "$STRUCTURED_TERMINAL_FIXTURE" "valid structured carrier" "structured terminal-choice fixture validates the structured carrier path first"
assert_audit_passes_with_mode "$PACKET_AUTOCONTINUE_FIXTURE" "valid tail block fallback" "packet autocontinue fixture still validates the visible tail block fallback"
assert_audit_passes_with_mode "$ITEM_PACKET_AUTOCONTINUE_FIXTURE" "valid tail block fallback" "item-based packet autocontinue fixture still validates the visible tail block fallback"
assert_audit_passes_with_mode "$PACKET_TERMINAL_FIXTURE" "valid tail block fallback" "packet terminal-choice fixture still validates the visible tail block fallback"
assert_audit_fails_with_mode "$PACKET_UNFULFILLED_FIXTURE" "missing post-carrier action" "packet unfulfilled fixture is rejected when no post-carrier continuation happens"
assert_audit_fails_with_mode "$ITEM_PACKET_UNFULFILLED_FIXTURE" "missing post-carrier action" "item-based packet unfulfilled fixture is rejected when no post-carrier continuation happens"
assert_audit_fails_with_mode "$PACKET_MISSING_FIXTURE" "missing canonical carrier" "packet strict-mode fixture is rejected when the canonical carrier is missing"
assert_audit_fails_with_mode "$STRICT_SESSION_MISSING_PACKET_FIXTURE" "missing canonical carrier" "strict-session transcript is rejected when the canonical carrier is missing"
assert_inline_runtime_fixture_passes_with_mode "duplicate_structured_with_visible_fallback" "valid tail block fallback" "duplicate structured carrier falls back to the visible tail block instead of passing as structured"
assert_inline_runtime_fixture_fails_with_mode "duplicate_structured_without_fallback" "missing canonical carrier" "duplicate structured carrier without a valid fallback is rejected"

echo "All runtime endgate transcript audit checks passed."
