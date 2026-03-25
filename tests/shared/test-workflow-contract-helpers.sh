#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/tests/shared/workflow-contract-helpers.sh"

AUTOCONTINUE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-endgate-structured-carrier-autocontinue-positive.jsonl"
NEEDS_USER_DECISION_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-endgate-structured-carrier-needs-user-decision-positive.jsonl"
TERMINAL_CHOICE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-endgate-structured-carrier-terminal-choice-positive.jsonl"

assert_equals() {
  local actual="$1"
  local expected="$2"
  local description="$3"

  if [[ "$actual" == "$expected" ]]; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  Expected: $expected"
    echo "  Actual: $actual"
    exit 1
  fi
}

assert_empty() {
  local actual="$1"
  local description="$2"

  if [[ -z "$actual" ]]; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  Expected empty value"
    echo "  Actual: $actual"
    exit 1
  fi
}

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

assert_fixture_endgate_field() {
  local file="$1"
  local key="$2"
  local expected="$3"
  local description_prefix="$4"

  assert_equals \
    "$(extract_endgate_carrier_field "$file" "$key")" \
    "$expected" \
    "$description_prefix exposes $key via carrier helper"
  assert_equals \
    "$(extract_endgate_packet_field "$file" "$key")" \
    "$expected" \
    "$description_prefix exposes $key via packet helper"
}

assert_complete_structured_fixture() {
  local file="$1"
  local description_prefix="$2"
  local expected_state="$3"
  local expected_choice_kind="$4"
  local expected_next_action="$5"

  assert_equals \
    "$(extract_endgate_carrier_kind "$file")" \
    "structured" \
    "$description_prefix reports structured carrier kind"
  assert_fixture_endgate_field "$file" "ENDGATE_PROTOCOL_VERSION" "1" "$description_prefix"
  assert_fixture_endgate_field "$file" "ENDGATE_STATE" "$expected_state" "$description_prefix"
  assert_fixture_endgate_field "$file" "ENDGATE_CHOICE_KIND" "$expected_choice_kind" "$description_prefix"
  assert_fixture_endgate_field "$file" "ENDGATE_NEXT_ACTION" "$expected_next_action" "$description_prefix"
}

if ! command -v jq >/dev/null 2>&1; then
  echo "FAIL: jq is required for structured carrier helper checks"
  exit 1
fi

assert_file_exists "$AUTOCONTINUE_FIXTURE" "structured autocontinue fixture exists"
assert_file_exists "$NEEDS_USER_DECISION_FIXTURE" "structured needs-user-decision fixture exists"
assert_file_exists "$TERMINAL_CHOICE_FIXTURE" "structured terminal-choice fixture exists"

assert_complete_structured_fixture \
  "$AUTOCONTINUE_FIXTURE" \
  "structured response_item fixture" \
  "AUTO_CONTINUE" \
  "NONE" \
  "CONTINUE_WITH_TOOL"
assert_complete_structured_fixture \
  "$NEEDS_USER_DECISION_FIXTURE" \
  "structured item fixture" \
  "NEEDS_USER_DECISION" \
  "SPECIFIC_NEXT_STEP" \
  "REQUEST_USER_INPUT"
assert_complete_structured_fixture \
  "$TERMINAL_CHOICE_FIXTURE" \
  "structured terminal-choice fixture" \
  "TERMINAL_CHOICE" \
  "CONTINUE_OR_STOP" \
  "REQUEST_USER_INPUT"

sample_text="$(cat <<'TEXT'
Human-readable paragraph.

ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: AUTO_CONTINUE
ENDGATE_CHOICE_KIND: NONE
ENDGATE_NEXT_ACTION: CONTINUE_WITH_TOOL

Later explanation that should not be parsed as packet.

ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: TERMINAL_CHOICE
ENDGATE_CHOICE_KIND: CONTINUE_OR_STOP
ENDGATE_NEXT_ACTION: REQUEST_USER_INPUT
TEXT
)"

expected_block="$(cat <<'TEXT'
ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: TERMINAL_CHOICE
ENDGATE_CHOICE_KIND: CONTINUE_OR_STOP
ENDGATE_NEXT_ACTION: REQUEST_USER_INPUT
TEXT
)"

actual_block="$(printf '%s\n' "$sample_text" | print_endgate_packet_block_from_text)"
actual_state="$(printf '%s\n' "$sample_text" | extract_endgate_packet_field_from_text "ENDGATE_STATE")"
actual_action="$(printf '%s\n' "$sample_text" | extract_endgate_packet_field_from_text "ENDGATE_NEXT_ACTION")"

assert_equals "$actual_block" "$expected_block" "endgate packet helper extracts the last contiguous packet block"
assert_equals "$actual_state" "TERMINAL_CHOICE" "endgate packet helper extracts ENDGATE_STATE"
assert_equals "$actual_action" "REQUEST_USER_INPUT" "endgate packet helper extracts ENDGATE_NEXT_ACTION"

tail_fallback_file="$(mktemp)"
partial_structured_fallback_file="$(mktemp)"
duplicate_structured_fallback_file="$(mktemp)"
duplicate_visible_tail_file="$(mktemp)"
trailing_prose_after_tail_file="$(mktemp)"
trailing_extra_endgate_after_tail_file="$(mktemp)"
priority_file="$(mktemp)"
trap 'rm -f "$tail_fallback_file" "$partial_structured_fallback_file" "$duplicate_structured_fallback_file" "$duplicate_visible_tail_file" "$trailing_prose_after_tail_file" "$trailing_extra_endgate_after_tail_file" "$priority_file"' EXIT

cat > "$tail_fallback_file" <<'TEXT'
Human-readable paragraph.

ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: TERMINAL_CHOICE
ENDGATE_CHOICE_KIND: CONTINUE_OR_STOP
ENDGATE_NEXT_ACTION: REQUEST_USER_INPUT
TEXT

assert_equals \
  "$(extract_endgate_carrier_kind "$tail_fallback_file")" \
  "visible_tail_block" \
  "carrier kind falls back to visible tail block when structured carrier is absent"
assert_equals \
  "$(extract_endgate_carrier_field "$tail_fallback_file" "ENDGATE_STATE")" \
  "TERMINAL_CHOICE" \
  "shared carrier extraction falls back to visible tail block state"
assert_equals \
  "$(extract_endgate_packet_field "$tail_fallback_file" "ENDGATE_NEXT_ACTION")" \
  "REQUEST_USER_INPUT" \
  "existing packet helper still works with visible tail block fallback"

cat > "$partial_structured_fallback_file" <<'TEXT'
{"timestamp":"2026-03-26T09:30:00.000Z","turn_id":"turn-partial-structured","type":"response_item","payload":{"type":"message","role":"assistant","metadata":{"endgate":{"ENDGATE_PROTOCOL_VERSION":"1","ENDGATE_STATE":"NEEDS_USER_DECISION","ENDGATE_NEXT_ACTION":"REQUEST_USER_INPUT"}},"content":[{"type":"output_text","text":"This structured carrier is intentionally incomplete."}]}}
ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: TERMINAL_CHOICE
ENDGATE_CHOICE_KIND: CONTINUE_OR_STOP
ENDGATE_NEXT_ACTION: REQUEST_USER_INPUT
TEXT

assert_equals \
  "$(extract_endgate_carrier_kind "$partial_structured_fallback_file")" \
  "visible_tail_block" \
  "partial structured carrier falls back to visible tail block"
assert_equals \
  "$(extract_endgate_carrier_field "$partial_structured_fallback_file" "ENDGATE_STATE")" \
  "TERMINAL_CHOICE" \
  "shared carrier extraction ignores incomplete structured carrier"
assert_equals \
  "$(extract_endgate_packet_field "$partial_structured_fallback_file" "ENDGATE_CHOICE_KIND")" \
  "CONTINUE_OR_STOP" \
  "packet helper falls back when structured carrier is incomplete"

cat > "$duplicate_structured_fallback_file" <<'TEXT'
{"timestamp":"2026-03-26T09:40:00.000Z","turn_id":"turn-duplicate-structured","type":"response_item","payload":{"type":"message","role":"assistant","metadata":{"endgate":{"ENDGATE_PROTOCOL_VERSION":"1","ENDGATE_STATE":"NEEDS_USER_DECISION","ENDGATE_STATE":"AUTO_CONTINUE","ENDGATE_CHOICE_KIND":"SPECIFIC_NEXT_STEP","ENDGATE_NEXT_ACTION":"REQUEST_USER_INPUT"}},"content":[{"type":"output_text","text":"This structured carrier is malformed because ENDGATE_STATE is duplicated."}]}}
ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: TERMINAL_CHOICE
ENDGATE_CHOICE_KIND: CONTINUE_OR_STOP
ENDGATE_NEXT_ACTION: REQUEST_USER_INPUT
TEXT

assert_equals \
  "$(extract_endgate_carrier_kind "$duplicate_structured_fallback_file")" \
  "visible_tail_block" \
  "duplicate structured carrier falls back to visible tail block"
assert_equals \
  "$(extract_endgate_carrier_field "$duplicate_structured_fallback_file" "ENDGATE_STATE")" \
  "TERMINAL_CHOICE" \
  "shared carrier extraction ignores duplicate structured canonical key"
assert_equals \
  "$(extract_endgate_packet_field "$duplicate_structured_fallback_file" "ENDGATE_NEXT_ACTION")" \
  "REQUEST_USER_INPUT" \
  "packet helper falls back when structured canonical key is duplicated"

cat > "$duplicate_visible_tail_file" <<'TEXT'
Human-readable paragraph.

ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: TERMINAL_CHOICE
ENDGATE_STATE: AUTO_CONTINUE
ENDGATE_CHOICE_KIND: CONTINUE_OR_STOP
ENDGATE_NEXT_ACTION: REQUEST_USER_INPUT
TEXT

assert_empty \
  "$(extract_endgate_carrier_kind "$duplicate_visible_tail_file")" \
  "duplicate visible tail key does not produce a legal carrier kind"
assert_empty \
  "$(extract_endgate_carrier_field "$duplicate_visible_tail_file" "ENDGATE_STATE")" \
  "duplicate visible tail key invalidates carrier extraction"
assert_empty \
  "$(extract_endgate_packet_field "$duplicate_visible_tail_file" "ENDGATE_NEXT_ACTION")" \
  "duplicate visible tail key invalidates packet fallback"

cat > "$trailing_prose_after_tail_file" <<'TEXT'
Human-readable paragraph.

ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: TERMINAL_CHOICE
ENDGATE_CHOICE_KIND: CONTINUE_OR_STOP
ENDGATE_NEXT_ACTION: REQUEST_USER_INPUT

Trailing prose should invalidate visible tail fallback.
TEXT

assert_empty \
  "$(extract_endgate_carrier_kind "$trailing_prose_after_tail_file")" \
  "prose after canonical packet invalidates visible tail carrier kind"
assert_empty \
  "$(extract_endgate_packet_field "$trailing_prose_after_tail_file" "ENDGATE_STATE")" \
  "prose after canonical packet invalidates visible tail packet extraction"

cat > "$trailing_extra_endgate_after_tail_file" <<'TEXT'
Human-readable paragraph.

ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: TERMINAL_CHOICE
ENDGATE_CHOICE_KIND: CONTINUE_OR_STOP
ENDGATE_NEXT_ACTION: REQUEST_USER_INPUT
ENDGATE_DEBUG: tail should be invalidated by extra endgate lines
TEXT

assert_empty \
  "$(extract_endgate_carrier_kind "$trailing_extra_endgate_after_tail_file")" \
  "extra endgate line after canonical packet invalidates visible tail carrier kind"
assert_empty \
  "$(extract_endgate_packet_field "$trailing_extra_endgate_after_tail_file" "ENDGATE_NEXT_ACTION")" \
  "extra endgate line after canonical packet invalidates visible tail packet extraction"

cat > "$priority_file" <<'TEXT'
{"timestamp":"2026-03-26T09:00:00.000Z","turn_id":"turn-priority","type":"response_item","payload":{"type":"message","role":"assistant","metadata":{"endgate":{"ENDGATE_PROTOCOL_VERSION":"1","ENDGATE_STATE":"NEEDS_USER_DECISION","ENDGATE_CHOICE_KIND":"SPECIFIC_NEXT_STEP","ENDGATE_NEXT_ACTION":"REQUEST_USER_INPUT"}},"content":[{"type":"output_text","text":"Structured carrier should win over visible tail text."}]}}
ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: TERMINAL_CHOICE
ENDGATE_CHOICE_KIND: CONTINUE_OR_STOP
ENDGATE_NEXT_ACTION: REQUEST_USER_INPUT
TEXT

assert_equals \
  "$(extract_endgate_carrier_kind "$priority_file")" \
  "structured" \
  "carrier kind prefers structured carrier when both sources exist"
assert_equals \
  "$(extract_endgate_carrier_field "$priority_file" "ENDGATE_STATE")" \
  "NEEDS_USER_DECISION" \
  "structured carrier wins over visible tail block for shared extraction"
assert_equals \
  "$(extract_endgate_packet_field "$priority_file" "ENDGATE_STATE")" \
  "NEEDS_USER_DECISION" \
  "existing packet helper prefers structured carrier when both sources exist"

echo "All workflow contract helper checks passed."
