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

if ! command -v jq >/dev/null 2>&1; then
  echo "FAIL: jq is required for structured carrier helper checks"
  exit 1
fi

assert_file_exists "$AUTOCONTINUE_FIXTURE" "structured autocontinue fixture exists"
assert_file_exists "$NEEDS_USER_DECISION_FIXTURE" "structured needs-user-decision fixture exists"
assert_file_exists "$TERMINAL_CHOICE_FIXTURE" "structured terminal-choice fixture exists"

assert_equals \
  "$(extract_endgate_carrier_field "$AUTOCONTINUE_FIXTURE" "ENDGATE_STATE")" \
  "AUTO_CONTINUE" \
  "structured response_item carrier exposes AUTO_CONTINUE"
assert_equals \
  "$(extract_endgate_packet_field "$AUTOCONTINUE_FIXTURE" "ENDGATE_NEXT_ACTION")" \
  "CONTINUE_WITH_TOOL" \
  "existing packet helper reads structured response_item carrier first"
assert_equals \
  "$(extract_endgate_carrier_kind "$AUTOCONTINUE_FIXTURE")" \
  "structured" \
  "carrier kind reports structured for response_item metadata"

assert_equals \
  "$(extract_endgate_carrier_field "$NEEDS_USER_DECISION_FIXTURE" "ENDGATE_STATE")" \
  "NEEDS_USER_DECISION" \
  "structured item carrier exposes NEEDS_USER_DECISION"
assert_equals \
  "$(extract_endgate_packet_field "$NEEDS_USER_DECISION_FIXTURE" "ENDGATE_CHOICE_KIND")" \
  "SPECIFIC_NEXT_STEP" \
  "existing packet helper reads structured item carrier first"
assert_equals \
  "$(extract_endgate_carrier_kind "$NEEDS_USER_DECISION_FIXTURE")" \
  "structured" \
  "carrier kind reports structured for item metadata"

assert_equals \
  "$(extract_endgate_carrier_field "$TERMINAL_CHOICE_FIXTURE" "ENDGATE_STATE")" \
  "TERMINAL_CHOICE" \
  "structured carrier exposes TERMINAL_CHOICE"
assert_equals \
  "$(extract_endgate_packet_field "$TERMINAL_CHOICE_FIXTURE" "ENDGATE_NEXT_ACTION")" \
  "REQUEST_USER_INPUT" \
  "existing packet helper reads structured terminal-choice carrier first"

sample_text="$(cat <<'EOF'
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
EOF
)"

expected_block="$(cat <<'EOF'
ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: TERMINAL_CHOICE
ENDGATE_CHOICE_KIND: CONTINUE_OR_STOP
ENDGATE_NEXT_ACTION: REQUEST_USER_INPUT
EOF
)"

actual_block="$(printf '%s\n' "$sample_text" | print_endgate_packet_block_from_text)"
actual_state="$(printf '%s\n' "$sample_text" | extract_endgate_packet_field_from_text "ENDGATE_STATE")"
actual_action="$(printf '%s\n' "$sample_text" | extract_endgate_packet_field_from_text "ENDGATE_NEXT_ACTION")"

assert_equals "$actual_block" "$expected_block" "endgate packet helper extracts the last contiguous packet block"
assert_equals "$actual_state" "TERMINAL_CHOICE" "endgate packet helper extracts ENDGATE_STATE"
assert_equals "$actual_action" "REQUEST_USER_INPUT" "endgate packet helper extracts ENDGATE_NEXT_ACTION"

tail_fallback_file="$(mktemp)"
priority_file="$(mktemp)"
trap 'rm -f "$tail_fallback_file" "$priority_file"' EXIT

cat > "$tail_fallback_file" <<'EOF'
Human-readable paragraph.

ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: TERMINAL_CHOICE
ENDGATE_CHOICE_KIND: CONTINUE_OR_STOP
ENDGATE_NEXT_ACTION: REQUEST_USER_INPUT
EOF

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

cat > "$priority_file" <<'EOF'
{"timestamp":"2026-03-26T09:00:00.000Z","turn_id":"turn-priority","type":"response_item","payload":{"type":"message","role":"assistant","metadata":{"endgate":{"ENDGATE_PROTOCOL_VERSION":"1","ENDGATE_STATE":"NEEDS_USER_DECISION","ENDGATE_CHOICE_KIND":"SPECIFIC_NEXT_STEP","ENDGATE_NEXT_ACTION":"REQUEST_USER_INPUT"}},"content":[{"type":"output_text","text":"Structured carrier should win over visible tail text."}]}}
ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: TERMINAL_CHOICE
ENDGATE_CHOICE_KIND: CONTINUE_OR_STOP
ENDGATE_NEXT_ACTION: REQUEST_USER_INPUT
EOF

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
