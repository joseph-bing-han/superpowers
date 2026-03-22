#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROMPT_TEMPLATE="$SCRIPT_DIR/fixtures/sdd-smoke-prompt.template.txt"

source "$SCRIPT_DIR/test-helpers.sh"

run_with_timeout() {
    local seconds="$1"
    shift

    if command -v timeout >/dev/null 2>&1; then
        timeout "$seconds" "$@"
        return $?
    fi

    "$@" &
    local command_pid=$!

    (
        sleep "$seconds"
        kill -TERM "$command_pid" 2>/dev/null || true
    ) &
    local timer_pid=$!

    wait "$command_pid"
    local command_status=$?

    kill -TERM "$timer_pid" 2>/dev/null || true
    wait "$timer_pid" 2>/dev/null || true

    return $command_status
}

echo "========================================"
echo " Behavior Smoke: subagent-driven-development"
echo "========================================"
echo ""

TEST_PROJECT=$(create_test_project)
OUTPUT_FILE="$TEST_PROJECT/claude-output.json"
PROMPT_FILE="$TEST_PROJECT/prompt.txt"

trap 'cleanup_test_project "$TEST_PROJECT"' EXIT

echo "Test project: $TEST_PROJECT"
bootstrap_sdd_smoke_project "$TEST_PROJECT"

PROMPT=$(sed "s|__TEST_PROJECT__|$TEST_PROJECT|g" "$PROMPT_TEMPLATE")
printf '%s\n' "$PROMPT" > "$PROMPT_FILE"

if printf '%s\n' "$PROMPT" | rg -q "__TEST_PROJECT__"; then
    echo "ERROR: Prompt template was not rendered correctly"
    exit 1
fi

echo ""
echo "Running Claude behavior smoke..."
echo "Output file: $OUTPUT_FILE"
echo ""

TEST_RUN_STARTED_AT=$(date +%s)

set +e
(
    cd "$REPO_ROOT" || exit 1
    run_with_timeout 1800 claude -p "$PROMPT" \
        --output-format stream-json \
        --add-dir "$TEST_PROJECT" \
        --permission-mode bypassPermissions 2>&1
) | tee "$OUTPUT_FILE"
command_status=${PIPESTATUS[0]}
set -e

if [ "$command_status" -ne 0 ]; then
    echo ""
    echo "========================================"
    echo "EXECUTION FAILED (exit code: $command_status)"
    exit 1
fi

SESSION_FILE=$(find_latest_session_file "$REPO_ROOT" "$TEST_RUN_STARTED_AT" || true)

if [ -z "$SESSION_FILE" ]; then
    echo ""
    echo "ERROR: Could not find session transcript file"
    exit 1
fi

echo ""
echo "Analyzing session transcript: $(basename "$SESSION_FILE")"
echo ""

FAILED=0

echo "=== Verification Tests ==="
echo ""

if assert_session_contains "$SESSION_FILE" '"name":"Skill".*"skill":"superpowers:subagent-driven-development"' "SDD skill invoked"; then
    :
else
    FAILED=$((FAILED + 1))
fi
echo ""

if assert_session_contains "$SESSION_FILE" '"name":"Task"' "Subagent task dispatch recorded"; then
    :
else
    FAILED=$((FAILED + 1))
fi
echo ""

if assert_session_contains "$SESSION_FILE" '"name":"TodoWrite"' "Task tracking recorded"; then
    :
else
    FAILED=$((FAILED + 1))
fi
echo ""

if assert_session_not_contains "$SESSION_FILE" '(?i)"name":"request_user_input".*("subagent use"|permission to use subagents|may use subagents in this session|allow subagent use)' "Smoke run does not re-enter the subagent consent gate"; then
    :
else
    FAILED=$((FAILED + 1))
fi
echo ""

if assert_session_contains_literal "$SESSION_FILE" "$TEST_PROJECT" "Session transcript bound to this smoke project"; then
    :
else
    FAILED=$((FAILED + 1))
fi
echo ""

if assert_session_contains_exact_line "$SESSION_FILE" 'TASK_STATUS: (DONE|DONE_WITH_CONCERNS|BLOCKED|NEEDS_CONTEXT)' "Implementer task status recorded"; then
    :
else
    FAILED=$((FAILED + 1))
fi
echo ""

if assert_session_contains_exact_line "$SESSION_FILE" 'TEST_STATUS: (PASS|FAIL|NOT_RUN)' "Implementer test status recorded"; then
    :
else
    FAILED=$((FAILED + 1))
fi
echo ""

if assert_session_contains_exact_line "$SESSION_FILE" 'NEXT_ACTION: (REVIEW|NEEDS_CONTEXT|STOP)' "Implementer next action recorded"; then
    :
else
    FAILED=$((FAILED + 1))
fi
echo ""

echo "========================================"
echo " Test Summary"
echo "========================================"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo "STATUS: PASSED"
    exit 0
fi

echo "STATUS: FAILED"
echo "Failed $FAILED verification tests"
echo "Output saved to: $OUTPUT_FILE"
exit 1
