#!/usr/bin/env bash
# Integration Test: Document Review System
# Actually runs spec/plan review and verifies reviewers catch issues
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
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
echo " Integration Test: Document Review System"
echo "========================================"
echo ""
echo "This test verifies the document review system by:"
echo "  1. Creating a spec with intentional errors"
echo "  2. Running the spec document reviewer"
echo "  3. Verifying the reviewer catches the errors"
echo ""

# Create test project
TEST_PROJECT=$(create_test_project)
echo "Test project: $TEST_PROJECT"

# Trap to cleanup
trap "cleanup_test_project $TEST_PROJECT" EXIT

cd "$TEST_PROJECT"

# Create directory structure
mkdir -p docs/superpowers/specs

# Create a spec document WITH INTENTIONAL ERRORS for the reviewer to catch
cat > docs/superpowers/specs/test-feature-design.md <<'EOF'
# Test Feature Design

## Overview

This is a test feature that does something useful.

## Requirements

1. The feature should work correctly
2. It should be fast
3. TODO: Add more requirements here

## Architecture

The feature will use a simple architecture with:
- A frontend component
- A backend service
- Error handling will be specified later once we understand the failure modes better

## Data Flow

Data flows from the frontend to the backend.

## Testing Strategy

Tests will be written to cover the main functionality.
EOF

# Initialize git repo
git init --quiet
git config user.email "test@test.com"
git config user.name "Test User"
git add .
git commit -m "Initial commit with test spec" --quiet

echo ""
echo "Created test spec with intentional errors:"
echo "  - TODO placeholder in Requirements section"
echo "  - 'specified later' deferral in Architecture section"
echo ""
echo "Running spec document reviewer..."
echo ""

# Run Claude to review the spec
OUTPUT_FILE="$TEST_PROJECT/claude-output.txt"

PROMPT="You are testing the spec document reviewer.

Read the spec-document-reviewer-prompt.md template in skills/brainstorming/ to understand the review format.

Then review the spec at $TEST_PROJECT/docs/superpowers/specs/test-feature-design.md using the criteria from that template.

Look for:
- TODOs, placeholders, 'TBD', incomplete sections
- Sections saying 'to be defined later' or 'will spec when X is done'
- Sections noticeably less detailed than others

Output your review in the format specified in the template."

echo "================================================================================"
set +e
(
    cd "$SCRIPT_DIR/../.." || exit 1
    run_with_timeout 120 claude -p "$PROMPT" --permission-mode bypassPermissions 2>&1
) | tee "$OUTPUT_FILE"
command_status=${PIPESTATUS[0]}
set -e

if [ "$command_status" -ne 0 ]; then
    echo ""
    echo "================================================================================"
    echo "EXECUTION FAILED (exit code: $command_status)"
    exit 1
fi
echo "================================================================================"

echo ""
echo "Analyzing reviewer output..."
echo ""

# Verification tests
FAILED=0

echo "=== Verification Tests ==="
echo ""

# Test 1: Reviewer found the TODO
echo "Test 1: Reviewer found TODO..."
if grep -qi "TODO" "$OUTPUT_FILE" && grep -qi "requirements\|Requirements" "$OUTPUT_FILE"; then
    echo "  [PASS] Reviewer identified TODO in Requirements section"
else
    echo "  [FAIL] Reviewer did not identify TODO"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 2: Reviewer found the "specified later" deferral
echo "Test 2: Reviewer found 'specified later' deferral..."
if grep -qi "specified later\|later\|defer\|incomplete\|error handling" "$OUTPUT_FILE"; then
    echo "  [PASS] Reviewer identified deferred content"
else
    echo "  [FAIL] Reviewer did not identify deferred content"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 3: Reviewer returns a stable verdict field
echo "Test 3: Stable review verdict field..."
if assert_named_field "$OUTPUT_FILE" "REVIEW_VERDICT" "CHANGES_REQUIRED" "Reviewer returns stable failing verdict"; then
    :
else
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 4: Reviewer returns a stable next action field
echo "Test 4: Stable next action field..."
if assert_named_field "$OUTPUT_FILE" "NEXT_ACTION" "REVISE|STOP" "Reviewer returns stable next action"; then
    :
else
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 5: Reviewer returns a non-zero blocking issue count
echo "Test 5: Blocking issue count..."
issue_count=$(extract_named_field "$OUTPUT_FILE" "BLOCKING_ISSUE_COUNT")
if [ -n "$issue_count" ] && [ "$issue_count" -ge 1 ]; then
    echo "  [PASS] Blocking issue count is non-zero"
else
    echo "  [FAIL] Blocking issue count missing or zero"
    FAILED=$((FAILED + 1))
fi
echo ""

# Summary
echo "========================================"
echo " Test Summary"
echo "========================================"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "STATUS: PASSED"
    echo "All verification tests passed!"
    echo ""
    echo "The spec document reviewer correctly:"
    echo "  ✓ Found TODO placeholder"
    echo "  ✓ Found 'specified later' deferral"
    echo "  ✓ Returned stable review verdict fields"
    echo "  ✓ Reported a non-zero blocking issue count"
    exit 0
else
    echo "STATUS: FAILED"
    echo "Failed $FAILED verification tests"
    echo ""
    echo "Output saved to: $OUTPUT_FILE"
    echo ""
    echo "Review the output to see what went wrong."
    exit 1
fi
