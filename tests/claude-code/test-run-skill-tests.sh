#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
mkdir -p "$TEST_DIR/bin" "$TEST_DIR/suite"
cp "$SCRIPT_DIR/run-skill-tests.sh" "$TEST_DIR/suite/"
printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_DIR/bin/claude"
chmod +x "$TEST_DIR/bin/claude"
printf '#!/usr/bin/env bash\nshift\nexec "$@"\n' > "$TEST_DIR/bin/timeout"
chmod +x "$TEST_DIR/bin/timeout"
printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_DIR/suite/test-pass.sh"
printf '#!/usr/bin/env bash\nexit 1\n' > "$TEST_DIR/suite/test-fail.sh"
printf '#!/usr/bin/env bash\nexit 77\n' > "$TEST_DIR/suite/test-skip.sh"
export PATH="$TEST_DIR/bin:$PATH"

failed=0
check() {
    local expected="$1" label="$2"
    shift 2
    local output status=0
    output=$(bash "$TEST_DIR/suite/run-skill-tests.sh" "$@" 2>&1) || status=$?
    if { [ "$expected" = pass ] && [ "$status" -eq 0 ]; } ||
       { [ "$expected" = fail ] && [ "$status" -ne 0 ] && ! [[ "$output" == *"STATUS: PASSED"* ]]; }; then
        echo "PASS: $label"
    else
        echo "FAIL: $label (exit $status)"
        echo "$output"
        failed=$((failed + 1))
    fi
}

check fail "empty selection is not success"
check fail "missing selected test is not success" --test test-missing.sh
check pass "successful selected test" --test test-pass.sh
check fail "failed selected test" --test test-fail.sh
check fail "skipped selected test is not success" --test test-skip.sh
check fail "missing argument is rejected" --test
check fail "invalid timeout is rejected" --timeout nope --test test-pass.sh

cp "$TEST_DIR/suite/test-pass.sh" "$TEST_DIR/suite/test-requesting-code-review.sh"
check fail "partial integration selection cannot pass" --integration
cp "$TEST_DIR/suite/test-pass.sh" "$TEST_DIR/suite/test-document-review-system.sh"
cp "$TEST_DIR/suite/test-pass.sh" "$TEST_DIR/suite/test-reviewer-contract-drift.sh"
check pass "complete integration selection" --integration

printf '#!/usr/bin/env bash\nexit 124\n' > "$TEST_DIR/bin/timeout"
check fail "timed out selected test" --test test-pass.sh

export RUNNER_CLI_MARKER="$TEST_DIR/cli-invoked"
printf '#!/usr/bin/env bash\ntouch "$RUNNER_CLI_MARKER"\nexit 1\n' > "$TEST_DIR/bin/claude"
help_output=$(bash "$TEST_DIR/suite/run-skill-tests.sh" --help 2>&1) || failed=$((failed + 1))
if [ -e "$RUNNER_CLI_MARKER" ]; then
    echo "FAIL: help invoked Claude"
    failed=$((failed + 1))
else
    echo "PASS: help does not invoke Claude"
fi

[ "$failed" -eq 0 ]
