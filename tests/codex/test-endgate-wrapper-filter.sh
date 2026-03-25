#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE="${BASH_SOURCE[0]-$PWD/tests/codex/test-endgate-wrapper-filter.sh}"
REPO_ROOT="$(cd "$(dirname "$SCRIPT_SOURCE")/../.." && pwd)"
WRAPPER="$REPO_ROOT/.codex/codex-endgate-wrapper.sh"
MISSING_PACKET_FIXTURE="$REPO_ROOT/tests/codex/fixtures/runtime-endgate-packet-missing-packet-negative.jsonl"

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

assert_not_exists() {
  local file="$1"
  local description="$2"

  if [[ ! -e "$file" ]]; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  Unexpected path exists: $file"
    exit 1
  fi
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if rg -q --fixed-strings "$pattern" "$file"; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  Missing pattern: $pattern"
    echo "  File: $file"
    exit 1
  fi
}

assert_not_contains_regex() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if rg -q "$pattern" "$file"; then
    echo "FAIL: $description"
    echo "  Unexpected pattern: $pattern"
    echo "  File: $file"
    exit 1
  else
    echo "PASS: $description"
  fi
}

assert_jq_true() {
  local file="$1"
  local expression="$2"
  local description="$3"

  if jq -e "$expression" "$file" >/dev/null; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Expression: $expression"
    exit 1
  fi
}

assert_jsonl_jq_true() {
  local file="$1"
  local expression="$2"
  local description="$3"

  if jq -s -e "$expression" "$file" >/dev/null; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Expression: $expression"
    exit 1
  fi
}

create_mock_codex() {
  local file="$1"

  cat > "$file" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail

scenario="${1:-}"
shift || true

case "$scenario" in
  redact_stdout_and_stderr)
    printf 'Visible stdout before packet\n'
    printf '%s\n' \
      'ENDGATE_PROTOCOL_VERSION: 1' \
      'ENDGATE_STATE: AUTO_CONTINUE' \
      'ENDGATE_CHOICE_KIND: NONE' \
      'ENDGATE_NEXT_ACTION: CONTINUE_WITH_TOOL'
    printf 'Visible stdout after packet\n'

    printf 'Visible stderr before packet\n' >&2
    printf '%s\n' \
      'ENDGATE_PROTOCOL_VERSION: 1' \
      'ENDGATE_STATE: TERMINAL_CHOICE' \
      'ENDGATE_CHOICE_KIND: CONTINUE_OR_STOP' \
      'ENDGATE_NEXT_ACTION: REQUEST_USER_INPUT' >&2
    printf 'Visible stderr after packet\n' >&2
    ;;
  mirror_auto_continue)
    printf 'Readable intro before mirror packet\n'
    printf '%s\n' \
      'ENDGATE_PROTOCOL_VERSION: 1' \
      'ENDGATE_STATE: AUTO_CONTINUE' \
      'ENDGATE_CHOICE_KIND: NONE' \
      'ENDGATE_NEXT_ACTION: CONTINUE_WITH_TOOL'
    printf 'Readable outro after mirror packet\n'
    ;;
  mirror_terminal_choice)
    printf 'Readable intro before second mirror packet\n'
    printf '%s\n' \
      'ENDGATE_PROTOCOL_VERSION: 1' \
      'ENDGATE_STATE: TERMINAL_CHOICE' \
      'ENDGATE_CHOICE_KIND: CONTINUE_OR_STOP' \
      'ENDGATE_NEXT_ACTION: REQUEST_USER_INPUT'
    printf 'Readable outro after second mirror packet\n'
    ;;
  no_packet_text)
    printf 'Visible stdout without protocol lines\n'
    printf 'Visible stderr without protocol lines\n' >&2
    ;;
  exit_code_27)
    printf 'Command exits with a non-zero code\n'
    exit 27
    ;;
  *)
    printf 'Unknown mock scenario: %s\n' "$scenario" >&2
    exit 99
    ;;
 esac
MOCK

  chmod +x "$file"
}

if ! command -v jq >/dev/null 2>&1; then
  echo "FAIL: jq is required for wrapper checks"
  exit 1
fi

assert_file_exists "$WRAPPER" "wrapper script exists"
assert_file_exists "$MISSING_PACKET_FIXTURE" "missing-packet fixture exists"

mock_codex="$(mktemp "${TMPDIR:-/tmp}/mock-codex.XXXXXX")"
stdout_file="$(mktemp "${TMPDIR:-/tmp}/wrapper-stdout.XXXXXX")"
stderr_file="$(mktemp "${TMPDIR:-/tmp}/wrapper-stderr.XXXXXX")"
runtime_dir="$(mktemp -d "${TMPDIR:-/tmp}/wrapper-runtime.XXXXXX")"
no_packet_runtime_dir="$(mktemp -d "${TMPDIR:-/tmp}/wrapper-runtime-empty.XXXXXX")"
trap 'rm -f "$mock_codex" "$stdout_file" "$stderr_file"; rm -rf "$runtime_dir" "$no_packet_runtime_dir"' EXIT

create_mock_codex "$mock_codex"

CODEX_BIN="$mock_codex" bash "$WRAPPER" redact_stdout_and_stderr >"$stdout_file" 2>"$stderr_file"
assert_contains "$stdout_file" "Visible stdout before packet" "wrapper keeps normal stdout text before packet lines"
assert_contains "$stdout_file" "Visible stdout after packet" "wrapper keeps normal stdout text after packet lines"
assert_contains "$stderr_file" "Visible stderr before packet" "wrapper keeps normal stderr text before packet lines"
assert_contains "$stderr_file" "Visible stderr after packet" "wrapper keeps normal stderr text after packet lines"
assert_not_contains_regex "$stdout_file" '^ENDGATE_[A-Z_]+: ' "wrapper removes packet lines from visible stdout"
assert_not_contains_regex "$stderr_file" '^ENDGATE_[A-Z_]+: ' "wrapper removes packet lines from visible stderr"

CODEX_BIN="$mock_codex" \
CODEX_ENDGATE_WRITE_DEBUG_MIRROR=1 \
CODEX_ENDGATE_RUNTIME_DIR="$runtime_dir" \
bash "$WRAPPER" mirror_auto_continue >"$stdout_file" 2>"$stderr_file"
CODEX_BIN="$mock_codex" \
CODEX_ENDGATE_WRITE_DEBUG_MIRROR=1 \
CODEX_ENDGATE_RUNTIME_DIR="$runtime_dir" \
bash "$WRAPPER" mirror_terminal_choice >"$stdout_file" 2>"$stderr_file"

assert_file_exists "$runtime_dir/endgate-state.jsonl" "debug mirror jsonl is written when explicitly enabled"
assert_file_exists "$runtime_dir/latest-endgate.json" "latest endgate snapshot is written when debug mirror is enabled"
assert_jsonl_jq_true \
  "$runtime_dir/endgate-state.jsonl" \
  'length == 2 and .[0].debug_mirror == true and .[0].source == "codex-endgate-wrapper" and .[0].carrier.ENDGATE_STATE == "AUTO_CONTINUE" and .[1].debug_mirror == true and .[1].source == "codex-endgate-wrapper" and .[1].carrier.ENDGATE_STATE == "TERMINAL_CHOICE"' \
  "debug mirror jsonl appends captured packet blocks without changing their state"
assert_jq_true \
  "$runtime_dir/latest-endgate.json" \
  '.debug_mirror == true and .source == "codex-endgate-wrapper" and .carrier.ENDGATE_STATE == "TERMINAL_CHOICE" and .carrier.ENDGATE_NEXT_ACTION == "REQUEST_USER_INPUT"' \
  "latest endgate snapshot tracks the last mirrored packet"
assert_not_contains_regex "$stdout_file" '^ENDGATE_[A-Z_]+: ' "wrapper still hides packet lines when debug mirror is enabled"

CODEX_BIN="$mock_codex" \
CODEX_ENDGATE_WRITE_DEBUG_MIRROR=1 \
CODEX_ENDGATE_RUNTIME_DIR="$no_packet_runtime_dir" \
bash "$WRAPPER" no_packet_text >"$stdout_file" 2>"$stderr_file"
assert_contains "$stdout_file" "Visible stdout without protocol lines" "wrapper keeps ordinary stdout text when no packet exists"
assert_contains "$stderr_file" "Visible stderr without protocol lines" "wrapper keeps ordinary stderr text when no packet exists"
assert_not_exists "$no_packet_runtime_dir/endgate-state.jsonl" "wrapper does not generate a debug mirror when no packet block exists"
assert_not_exists "$no_packet_runtime_dir/latest-endgate.json" "wrapper does not create a latest snapshot when no packet block exists"
assert_not_contains_regex "$stdout_file" '^ENDGATE_[A-Z_]+: ' "wrapper never invents canonical packet lines in stdout"
assert_not_contains_regex "$stderr_file" '^ENDGATE_[A-Z_]+: ' "wrapper never invents canonical packet lines in stderr"

exit_code=0
if CODEX_BIN="$mock_codex" bash "$WRAPPER" exit_code_27 >"$stdout_file" 2>"$stderr_file"; then
  echo "FAIL: wrapper should propagate non-zero exit codes from the underlying codex command"
  exit 1
else
  exit_code="$?"
fi
assert_equals "$exit_code" "27" "wrapper preserves the underlying codex exit code"

cat > "$runtime_dir/endgate-state.jsonl" <<'JSONL'
{"debug_mirror":true,"source":"codex-endgate-wrapper","carrier":{"ENDGATE_PROTOCOL_VERSION":"1","ENDGATE_STATE":"TERMINAL_CHOICE","ENDGATE_CHOICE_KIND":"CONTINUE_OR_STOP","ENDGATE_NEXT_ACTION":"REQUEST_USER_INPUT"}}
JSONL
cat > "$runtime_dir/latest-endgate.json" <<'JSON'
{"debug_mirror":true,"source":"codex-endgate-wrapper","carrier":{"ENDGATE_PROTOCOL_VERSION":"1","ENDGATE_STATE":"TERMINAL_CHOICE","ENDGATE_CHOICE_KIND":"CONTINUE_OR_STOP","ENDGATE_NEXT_ACTION":"REQUEST_USER_INPUT"}}
JSON

assert_empty "$(extract_endgate_carrier_kind "$MISSING_PACKET_FIXTURE")" "sidecar debug mirror does not become a transcript carrier"
assert_empty "$(extract_endgate_carrier_field "$MISSING_PACKET_FIXTURE" "ENDGATE_STATE")" "sidecar debug mirror cannot satisfy the missing canonical carrier fixture"

echo "PASS"
