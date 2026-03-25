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

assert_file_empty() {
  local file="$1"
  local description="$2"

  if [[ ! -s "$file" ]]; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  Expected empty file: $file"
    echo "  Actual contents:"
    cat "$file"
    exit 1
  fi
}

assert_file_exact_text() {
  local file="$1"
  local expected="$2"
  local description="$3"
  local actual=""

  actual="$(cat "$file")"

  if [[ "$actual" == "$expected" ]]; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  Expected:"
    printf '%s\n' "$expected"
    echo "  Actual:"
    printf '%s\n' "$actual"
    echo "  Actual hex:"
    od -An -tx1 -v "$file"
    exit 1
  fi
}

assert_file_exact_text_after_cr_to_lf() {
  local file="$1"
  local expected="$2"
  local description="$3"
  local actual=""

  actual="$(tr '\r' '\n' < "$file")"

  if [[ "$actual" == "$expected" ]]; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  Expected:"
    printf '%s\n' "$expected"
    echo "  Actual after CR->LF normalization:"
    printf '%s\n' "$actual"
    echo "  Actual hex:"
    od -An -tx1 -v "$file"
    exit 1
  fi
}

assert_pid_not_running_within() {
  local pid="$1"
  local description="$2"
  local timeout_ticks="${3:-20}"
  local tick=0

  if [[ -z "$pid" ]]; then
    echo "FAIL: $description"
    echo "  Missing pid"
    exit 1
  fi

  for ((tick = 0; tick < timeout_ticks; tick++)); do
    if ! kill -0 "$pid" >/dev/null 2>&1; then
      echo "PASS: $description"
      return 0
    fi

    sleep 0.1
  done

  echo "FAIL: $description"
  echo "  PID still alive after timeout: $pid"
  exit 1
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

assert_process_exits_quickly_with_status() {
  local pid="$1"
  local expected_status="$2"
  local description="$3"
  local timeout_ticks="${4:-20}"
  local tick=0
  local status=""

  for ((tick = 0; tick < timeout_ticks; tick++)); do
    if ! kill -0 "$pid" >/dev/null 2>&1; then
      if wait "$pid"; then
        status=0
      else
        status=$?
      fi
      break
    fi

    sleep 0.1
  done

  if [[ -z "$status" ]]; then
    echo "FAIL: $description"
    echo "  Process did not exit within $((timeout_ticks / 10)) seconds"
    kill "$pid" >/dev/null 2>&1 || true
    wait "$pid" >/dev/null 2>&1 || true
    exit 1
  fi

  if [[ "$status" == "$expected_status" ]]; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  Expected status: $expected_status"
    echo "  Actual status: $status"
    exit 1
  fi
}

assert_file_nonempty_within() {
  local file="$1"
  local description="$2"
  local timeout_ticks="${3:-20}"
  local tick=0

  for ((tick = 0; tick < timeout_ticks; tick++)); do
    if [[ -s "$file" ]]; then
      echo "PASS: $description"
      return 0
    fi

    sleep 0.1
  done

  echo "FAIL: $description"
  echo "  File stayed empty: $file"
  exit 1
}

assert_file_contains_within() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  local timeout_ticks="${4:-20}"
  local tick=0

  for ((tick = 0; tick < timeout_ticks; tick++)); do
    if [[ -f "$file" ]] && rg -q --fixed-strings "$pattern" "$file"; then
      echo "PASS: $description"
      return 0
    fi

    sleep 0.1
  done

  echo "FAIL: $description"
  echo "  Missing pattern within timeout: $pattern"
  echo "  File: $file"
  if [[ -f "$file" ]]; then
    echo "  Current contents:"
    cat "$file"
    echo "  Current hex:"
    od -An -tx1 -v "$file"
  fi
  exit 1
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
    if [ -t 1 ]; then
      printf 'stdout_tty=yes\n'
    else
      printf 'stdout_tty=no\n'
    fi

    if [ -t 2 ]; then
      printf 'stderr_tty=yes\n'
    else
      printf 'stderr_tty=no\n'
    fi

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
  partial_single_line)
    printf 'Visible before partial block\n'
    printf 'ENDGATE_STATE: AUTO_CONTINUE\n'
    printf 'Visible after partial block\n'
    ;;
  partial_three_line)
    printf 'Visible before three-line partial block\n'
    printf '%s\n' \
      'ENDGATE_PROTOCOL_VERSION: 1' \
      'ENDGATE_STATE: AUTO_CONTINUE' \
      'ENDGATE_CHOICE_KIND: NONE'
    printf 'Visible after three-line partial block\n'
    ;;
  malformed_extra_key)
    printf 'Visible before malformed block\n'
    printf '%s\n' \
      'ENDGATE_PROTOCOL_VERSION: 1' \
      'ENDGATE_STATE: AUTO_CONTINUE' \
      'ENDGATE_CHOICE_KIND: NONE' \
      'ENDGATE_NEXT_ACTION: CONTINUE_WITH_TOOL' \
      'ENDGATE_DEBUG: should stay visible'
    printf 'Visible after malformed block\n'
    ;;
  prompt_before_input)
    printf 'Prompt> '
    IFS= read -r answer
    printf '\nReceived: %s\n' "$answer"
    ;;
  carriage_refresh)
    printf 'step1\rstep2\rfinal\n'
    ;;
  long_running_until_signal)
    trap 'printf "child_term_signal\n" >> "${MOCK_SIGNAL_FILE:?}"; exit 143' TERM INT
    printf '%s\n' "$$" > "${MOCK_CHILD_PID_FILE:?}"
    while true; do
      sleep 0.2
    done
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

if ! command -v expect >/dev/null 2>&1; then
  echo "FAIL: expect is required for PTY-backed wrapper prompt checks"
  exit 1
fi

assert_file_exists "$WRAPPER" "wrapper script exists"
assert_file_exists "$MISSING_PACKET_FIXTURE" "missing-packet fixture exists"

mock_codex="$(mktemp "${TMPDIR:-/tmp}/mock-codex.XXXXXX")"
stdout_file="$(mktemp "${TMPDIR:-/tmp}/wrapper-stdout.XXXXXX")"
stderr_file="$(mktemp "${TMPDIR:-/tmp}/wrapper-stderr.XXXXXX")"
runtime_dir="$(mktemp -d "${TMPDIR:-/tmp}/wrapper-runtime.XXXXXX")"
no_packet_runtime_dir="$(mktemp -d "${TMPDIR:-/tmp}/wrapper-runtime-empty.XXXXXX")"
prompt_stdout_file="$(mktemp "${TMPDIR:-/tmp}/wrapper-prompt-stdout.XXXXXX")"
prompt_stderr_file="$(mktemp "${TMPDIR:-/tmp}/wrapper-prompt-stderr.XXXXXX")"
failure_stdout_file="$(mktemp "${TMPDIR:-/tmp}/wrapper-failure-stdout.XXXXXX")"
failure_stderr_file="$(mktemp "${TMPDIR:-/tmp}/wrapper-failure-stderr.XXXXXX")"
refresh_stdout_file="$(mktemp "${TMPDIR:-/tmp}/wrapper-refresh-stdout.XXXXXX")"
refresh_stderr_file="$(mktemp "${TMPDIR:-/tmp}/wrapper-refresh-stderr.XXXXXX")"
partial_stdout_file="$(mktemp "${TMPDIR:-/tmp}/wrapper-partial-stdout.XXXXXX")"
partial_stderr_file="$(mktemp "${TMPDIR:-/tmp}/wrapper-partial-stderr.XXXXXX")"
partial_runtime_dir="$(mktemp -d "${TMPDIR:-/tmp}/wrapper-partial-runtime.XXXXXX")"
term_stdout_file="$(mktemp "${TMPDIR:-/tmp}/wrapper-term-stdout.XXXXXX")"
term_stderr_file="$(mktemp "${TMPDIR:-/tmp}/wrapper-term-stderr.XXXXXX")"
term_signal_file="$(mktemp "${TMPDIR:-/tmp}/wrapper-term-signal.XXXXXX")"
term_child_pid_file="$(mktemp "${TMPDIR:-/tmp}/wrapper-term-child-pid.XXXXXX")"
prompt_expect_script="$(mktemp "${TMPDIR:-/tmp}/wrapper-prompt-expect.XXXXXX")"
trap 'rm -f "$mock_codex" "$stdout_file" "$stderr_file" "$prompt_stdout_file" "$prompt_stderr_file" "$failure_stdout_file" "$failure_stderr_file" "$refresh_stdout_file" "$refresh_stderr_file" "$partial_stdout_file" "$partial_stderr_file" "$term_stdout_file" "$term_stderr_file" "$term_signal_file" "$term_child_pid_file" "$prompt_expect_script"; rm -rf "$runtime_dir" "$no_packet_runtime_dir" "$partial_runtime_dir"' EXIT

create_mock_codex "$mock_codex"

CODEX_BIN="$mock_codex" bash "$WRAPPER" redact_stdout_and_stderr >"$stdout_file" 2>"$stderr_file"
assert_contains "$stdout_file" "stdout_tty=yes" "wrapper keeps the underlying stdout attached to a PTY"
assert_contains "$stdout_file" "stderr_tty=yes" "wrapper keeps the underlying stderr attached to a PTY"
assert_contains "$stdout_file" "Visible stdout before packet" "wrapper keeps normal stdout text before packet lines"
assert_contains "$stdout_file" "Visible stdout after packet" "wrapper keeps normal stdout text after packet lines"
assert_contains "$stdout_file" "Visible stderr before packet" "wrapper keeps normal stderr text before packet lines in the terminal render"
assert_contains "$stdout_file" "Visible stderr after packet" "wrapper keeps normal stderr text after packet lines in the terminal render"
assert_not_contains_regex "$stdout_file" '^ENDGATE_[A-Z_]+: ' "wrapper removes packet lines from visible stdout"
assert_file_exact_text_after_cr_to_lf \
  "$stdout_file" \
  "$(cat <<'TEXT'
stdout_tty=yes
stderr_tty=yes
Visible stdout before packet
Visible stdout after packet
Visible stderr before packet
Visible stderr after packet
TEXT
)" \
  "wrapper does not prepend ^D\\b\\b or other dirty prefix bytes to normal terminal text"
assert_file_empty "$stderr_file" "wrapper does not leak filtered terminal render to stderr"

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
assert_contains "$stdout_file" "Visible stderr without protocol lines" "wrapper keeps ordinary stderr text when no packet exists"
assert_not_exists "$no_packet_runtime_dir/endgate-state.jsonl" "wrapper does not generate a debug mirror when no packet block exists"
assert_not_exists "$no_packet_runtime_dir/latest-endgate.json" "wrapper does not create a latest snapshot when no packet block exists"
assert_not_contains_regex "$stdout_file" '^ENDGATE_[A-Z_]+: ' "wrapper never invents canonical packet lines in stdout"
assert_file_exact_text_after_cr_to_lf \
  "$stdout_file" \
  "$(cat <<'TEXT'
Visible stdout without protocol lines
Visible stderr without protocol lines
TEXT
)" \
  "wrapper keeps ordinary stdout and stderr text byte-clean when no packet exists"
assert_file_empty "$stderr_file" "wrapper keeps the visible render on the PTY-backed terminal stream when no packet exists"

CODEX_BIN="$mock_codex" bash "$WRAPPER" carriage_refresh >"$refresh_stdout_file" 2>"$refresh_stderr_file"
assert_file_exact_text \
  "$refresh_stdout_file" \
  $'step1\rstep2\rfinal\r' \
  "wrapper preserves carriage-return refresh semantics instead of expanding refresh history into multiple lines"
assert_file_empty "$refresh_stderr_file" "carriage-refresh scenario does not leak terminal render to stderr"

CODEX_BIN="$mock_codex" bash "$WRAPPER" partial_single_line >"$partial_stdout_file" 2>"$partial_stderr_file"
assert_file_exact_text_after_cr_to_lf \
  "$partial_stdout_file" \
  "$(cat <<'TEXT'
Visible before partial block
Visible after partial block
TEXT
)" \
  "single-line ENDGATE_STATE content may be hidden even without a full 4-line packet"
assert_file_empty "$partial_stderr_file" "single-line partial block scenario does not leak terminal render to stderr"

CODEX_BIN="$mock_codex" \
CODEX_ENDGATE_WRITE_DEBUG_MIRROR=1 \
CODEX_ENDGATE_RUNTIME_DIR="$partial_runtime_dir" \
bash "$WRAPPER" partial_three_line >"$partial_stdout_file" 2>"$partial_stderr_file"
assert_file_exact_text_after_cr_to_lf \
  "$partial_stdout_file" \
  "$(cat <<'TEXT'
Visible before three-line partial block
ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_CHOICE_KIND: NONE
Visible after three-line partial block
TEXT
)" \
  "three-line partial block keeps non-state lines visible while allowing ENDGATE_STATE to be hidden"
assert_not_exists "$partial_runtime_dir/endgate-state.jsonl" "partial three-line block does not produce a debug mirror"
assert_not_exists "$partial_runtime_dir/latest-endgate.json" "partial three-line block does not update latest endgate snapshot"
assert_file_empty "$partial_stderr_file" "partial three-line block scenario does not leak terminal render to stderr"

CODEX_BIN="$mock_codex" bash "$WRAPPER" malformed_extra_key >"$partial_stdout_file" 2>"$partial_stderr_file"
assert_file_exact_text_after_cr_to_lf \
  "$partial_stdout_file" \
  "$(cat <<'TEXT'
Visible before malformed block
ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_CHOICE_KIND: NONE
ENDGATE_NEXT_ACTION: CONTINUE_WITH_TOOL
ENDGATE_DEBUG: should stay visible
Visible after malformed block
TEXT
)" \
  "malformed extra-key block does not get treated as canonical, but ENDGATE_STATE may still be hidden on its own"
assert_file_empty "$partial_stderr_file" "malformed extra-key block scenario does not leak terminal render to stderr"

exit_code=0
if CODEX_BIN="$mock_codex" bash "$WRAPPER" exit_code_27 >"$stdout_file" 2>"$stderr_file"; then
  echo "FAIL: wrapper should propagate non-zero exit codes from the underlying codex command"
  exit 1
else
  exit_code="$?"
fi
assert_equals "$exit_code" "27" "wrapper preserves the underlying codex exit code"

SCRIPT_BIN=false CODEX_BIN="$mock_codex" bash "$WRAPPER" no_packet_text >"$failure_stdout_file" 2>"$failure_stderr_file" &
failure_pid="$!"
assert_process_exits_quickly_with_status \
  "$failure_pid" \
  "1" \
  "wrapper fails fast when the PTY launcher cannot start instead of hanging"

cat >"$prompt_expect_script" <<'EXPECT'
log_user 0
set timeout 3
set wrapper [lindex $argv 0]
set mock_bin [lindex $argv 1]

spawn -noecho env CODEX_BIN=$mock_bin bash $wrapper prompt_before_input
expect {
  -re {Prompt> } {
    puts "PROMPT_SEEN"
    send -- "blue\r"
    sleep 0.2
  }
  timeout {
    puts "PROMPT_TIMEOUT"
    exit 1
  }
}
EXPECT

if expect "$prompt_expect_script" "$WRAPPER" "$mock_codex" >"$prompt_stdout_file" 2>"$prompt_stderr_file"; then
  prompt_status=0
else
  prompt_status=$?
fi
assert_equals "$prompt_status" "0" "prompt scenario exits successfully after receiving input"
assert_file_exact_text \
  "$prompt_stdout_file" \
  "$(cat <<'TEXT'
PROMPT_SEEN
TEXT
)" \
  "wrapper shows a no-newline prompt before input and still exits after the reply is sent"
assert_file_empty "$prompt_stderr_file" "prompt scenario does not leak terminal render to stderr"

MOCK_SIGNAL_FILE="$term_signal_file" \
MOCK_CHILD_PID_FILE="$term_child_pid_file" \
CODEX_BIN="$mock_codex" \
bash "$WRAPPER" long_running_until_signal >"$term_stdout_file" 2>"$term_stderr_file" &
term_wrapper_pid="$!"
assert_file_nonempty_within \
  "$term_child_pid_file" \
  "term cleanup scenario writes the child pid"
term_child_pid="$(cat "$term_child_pid_file")"
kill -TERM "$term_wrapper_pid"
assert_process_exits_quickly_with_status \
  "$term_wrapper_pid" \
  "143" \
  "wrapper exits promptly when it receives TERM"
assert_pid_not_running_within \
  "$term_child_pid" \
  "TERM cleanup stops the underlying child instead of leaving it running"
assert_file_empty "$term_stdout_file" "term cleanup scenario does not leak terminal render to stdout"
assert_file_empty "$term_stderr_file" "term cleanup scenario does not leak terminal render to stderr"

cat > "$runtime_dir/endgate-state.jsonl" <<'JSONL'
{"debug_mirror":true,"source":"codex-endgate-wrapper","carrier":{"ENDGATE_PROTOCOL_VERSION":"1","ENDGATE_STATE":"TERMINAL_CHOICE","ENDGATE_CHOICE_KIND":"CONTINUE_OR_STOP","ENDGATE_NEXT_ACTION":"REQUEST_USER_INPUT"}}
JSONL
cat > "$runtime_dir/latest-endgate.json" <<'JSON'
{"debug_mirror":true,"source":"codex-endgate-wrapper","carrier":{"ENDGATE_PROTOCOL_VERSION":"1","ENDGATE_STATE":"TERMINAL_CHOICE","ENDGATE_CHOICE_KIND":"CONTINUE_OR_STOP","ENDGATE_NEXT_ACTION":"REQUEST_USER_INPUT"}}
JSON

assert_empty "$(extract_endgate_carrier_kind "$MISSING_PACKET_FIXTURE")" "sidecar debug mirror does not become a transcript carrier"
assert_empty "$(extract_endgate_carrier_field "$MISSING_PACKET_FIXTURE" "ENDGATE_STATE")" "sidecar debug mirror cannot satisfy the missing canonical carrier fixture"

echo "PASS"
