#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/tests/shared/workflow-contract-helpers.sh"

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

echo "All workflow contract helper checks passed."
