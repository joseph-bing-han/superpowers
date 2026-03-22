#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/test-helpers.sh"

run_with_timeout() {
    local seconds="$1"
    shift

    if command -v timeout >/dev/null 2>&1; then
        timeout "${seconds}s" "$@"
        return $?
    fi

    local timeout_flag
    timeout_flag="$(mktemp)"
    rm -f "$timeout_flag"

    "$@" &
    local command_pid=$!

    (
        sleep "$seconds"
        if kill -TERM "$command_pid" 2>/dev/null; then
            printf 'timeout\n' > "$timeout_flag"
        fi
    ) &
    local timer_pid=$!

    wait "$command_pid"
    local command_status=$?

    kill -TERM "$timer_pid" 2>/dev/null || true
    wait "$timer_pid" 2>/dev/null || true

    if [ -f "$timeout_flag" ]; then
        rm -f "$timeout_flag"
        return 124
    fi

    rm -f "$timeout_flag"
    return "$command_status"
}

create_broken_spec_fixture() {
    local project_dir="$1"
    local spec_file="$project_dir/docs/superpowers/specs/test-feature-design.md"

    mkdir -p "$(dirname "$spec_file")"

    cat > "$spec_file" <<'EOF'
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

    git -C "$project_dir" init --quiet
    git -C "$project_dir" config user.email "test@test.com"
    git -C "$project_dir" config user.name "Test User"
    git -C "$project_dir" add .
    git -C "$project_dir" commit -m "Initial reviewer drift fixture" --quiet

    printf '%s\n' "$spec_file"
}

build_variant_prompt() {
    local variant="$1"
    local spec_file="$2"
    local prose_instruction

    case "$variant" in
        chinese)
            prose_instruction="Write the prose sections in Simplified Chinese."
            ;;
        english)
            prose_instruction="Write the prose sections in English."
            ;;
        concise)
            prose_instruction="Write the prose sections in Simplified Chinese and keep them concise."
            ;;
        verbose)
            prose_instruction="Write the prose sections in English and make them more detailed."
            ;;
        *)
            echo "Unknown prompt variant: $variant" >&2
            return 1
            ;;
    esac

    cat <<EOF
You are testing reviewer contract drift resistance.

Read the spec-document-reviewer-prompt.md template in skills/brainstorming/ to understand the review format.

Then review the spec at $spec_file using the criteria from that template.

Look for:
- TODOs, placeholders, 'TBD', incomplete sections
- Sections saying 'to be defined later' or 'will spec when X is done'
- Sections noticeably less detailed than others

$prose_instruction

The prose may vary, but the machine-readable tail block must stay stable.
Keep the exact tail block keys, and use only the allowed single-token values for each field.
EOF
}

verify_machine_readable_fields() {
    local output_file="$1"
    local label="$2"
    local expected_next_action="${3:-}"
    local issue_count
    local next_action

    if assert_named_field "$output_file" "REVIEW_VERDICT" "CHANGES_REQUIRED" "$label returns CHANGES_REQUIRED" >&2; then
        :
    else
        return 1
    fi

    issue_count="$(extract_named_field "$output_file" "BLOCKING_ISSUE_COUNT")"
    if [[ "$issue_count" =~ ^[0-9]+$ ]] && [ "$issue_count" -gt 0 ]; then
        echo "  [PASS] $label returns a positive blocking issue count" >&2
    else
        echo "  [FAIL] $label returned an invalid blocking issue count" >&2
        echo "  Value: ${issue_count:-<empty>}" >&2
        return 1
    fi

    if assert_named_field "$output_file" "NEXT_ACTION" "CONTINUE|REVISE|STOP" "$label returns an allowed next action" >&2; then
        :
    else
        return 1
    fi

    next_action="$(extract_named_field "$output_file" "NEXT_ACTION")"

    if [ -n "$expected_next_action" ]; then
        if [ "$next_action" = "$expected_next_action" ]; then
            echo "  [PASS] $label matches the baseline next action" >&2
        else
            echo "  [FAIL] $label drifted on NEXT_ACTION" >&2
            echo "  Expected: $expected_next_action" >&2
            echo "  Actual:   $next_action" >&2
            return 1
        fi
    fi

    printf '%s\n' "$next_action"
}

run_claude_variant() {
    local variant="$1"
    local spec_file="$2"
    local output_dir="$3"
    local prompt_file="$output_dir/${variant}.prompt.txt"
    local output_file="$output_dir/${variant}.output.txt"
    local prompt
    local command_status

    prompt="$(build_variant_prompt "$variant" "$spec_file")"
    printf '%s\n' "$prompt" > "$prompt_file"

    set +e
    (
        cd "$REPO_ROOT" || exit 1
        run_with_timeout 180 claude -p "$prompt" --permission-mode bypassPermissions 2>&1
    ) | tee "$output_file"
    command_status=${PIPESTATUS[0]}
    set -e

    if [ "$command_status" -ne 0 ]; then
        echo "  [FAIL] Claude runner exited non-zero for $variant" >&2
        echo "  Exit code: $command_status" >&2
        return 1
    fi
}

run_opencode_second_runner_case() {
    local spec_file="$1"
    local output_dir="$2"
    local expected_next_action="$3"
    local prompt_file="$output_dir/opencode-english.prompt.txt"
    local output_file="$output_dir/opencode-english.output.txt"
    local prompt
    local command_status

    prompt="$(build_variant_prompt "english" "$spec_file")"
    printf '%s\n' "$prompt" > "$prompt_file"

    set +e
    (
        cd "$REPO_ROOT" || exit 1
        run_with_timeout 180 opencode run \
            --dir "$REPO_ROOT" \
            --file "$REPO_ROOT/skills/brainstorming/spec-document-reviewer-prompt.md" \
            --file "$spec_file" \
            "$prompt" 2>&1
    ) | tee "$output_file"
    command_status=${PIPESTATUS[0]}
    set -e

    if [ "$command_status" -ne 0 ]; then
        echo "  [FAIL] OpenCode second-runner case exited non-zero" >&2
        echo "  Exit code: $command_status" >&2
        return 1
    fi

    verify_machine_readable_fields "$output_file" "OpenCode second-runner case" "$expected_next_action" >/dev/null
}

run_second_model_case() {
    local spec_file="$1"
    local output_dir="$2"
    local expected_next_action="$3"
    local second_model="$4"
    local prompt_file="$output_dir/claude-second-model.prompt.txt"
    local output_file="$output_dir/claude-second-model.output.txt"
    local prompt
    local command_status

    prompt="$(build_variant_prompt "english" "$spec_file")"
    printf '%s\n' "$prompt" > "$prompt_file"

    set +e
    (
        cd "$REPO_ROOT" || exit 1
        run_with_timeout 180 claude -p "$prompt" \
            --model "$second_model" \
            --permission-mode bypassPermissions 2>&1
    ) | tee "$output_file"
    command_status=${PIPESTATUS[0]}
    set -e

    if [ "$command_status" -ne 0 ]; then
        echo "  [FAIL] Claude second-model case exited non-zero" >&2
        echo "  Exit code: $command_status" >&2
        return 1
    fi

    verify_machine_readable_fields "$output_file" "Claude second-model case" "$expected_next_action" >/dev/null
}

echo "========================================"
echo " Reviewer Contract Drift Matrix"
echo "========================================"
echo ""

if ! command -v claude >/dev/null 2>&1; then
    echo "[SKIP] Claude Code CLI is not installed locally"
    exit 0
fi

TEST_PROJECT="$(create_test_project)"
OUTPUT_DIR="$TEST_PROJECT/reviewer-drift"
SPEC_FILE="$(create_broken_spec_fixture "$TEST_PROJECT")"

mkdir -p "$OUTPUT_DIR"
trap 'cleanup_test_project "$TEST_PROJECT"' EXIT

echo "Test project: $TEST_PROJECT"
echo "Spec fixture: $SPEC_FILE"
echo ""

FAILED=0
BASELINE_NEXT_ACTION=""

echo "=== Prompt Variant Checks ==="
echo ""

for variant in chinese english concise verbose; do
    echo "Variant: $variant"

    output_file="$OUTPUT_DIR/${variant}.output.txt"

    if run_claude_variant "$variant" "$SPEC_FILE" "$OUTPUT_DIR"; then
        :
    else
        FAILED=$((FAILED + 1))
        echo ""
        continue
    fi

    if [ -z "$BASELINE_NEXT_ACTION" ]; then
        next_action="$(verify_machine_readable_fields "$output_file" "Variant $variant")" || {
            FAILED=$((FAILED + 1))
            echo ""
            continue
        }
        BASELINE_NEXT_ACTION="$next_action"
        echo "  [INFO] Baseline NEXT_ACTION: $BASELINE_NEXT_ACTION"
    else
        if verify_machine_readable_fields "$output_file" "Variant $variant" "$BASELINE_NEXT_ACTION" >/dev/null; then
            :
        else
            FAILED=$((FAILED + 1))
        fi
    fi

    echo ""
done

echo "=== Optional Cross-Runner Check ==="
echo ""

if [ "$FAILED" -eq 0 ]; then
    if command -v opencode >/dev/null 2>&1; then
        echo "Second branch: opencode"
        if run_opencode_second_runner_case "$SPEC_FILE" "$OUTPUT_DIR" "$BASELINE_NEXT_ACTION"; then
            echo "  [PASS] Optional second-runner branch matched the baseline contract"
        else
            FAILED=$((FAILED + 1))
        fi
    elif [ -n "${CLAUDE_SECOND_MODEL:-}" ]; then
        echo "Second branch: claude --model $CLAUDE_SECOND_MODEL"
        if run_second_model_case "$SPEC_FILE" "$OUTPUT_DIR" "$BASELINE_NEXT_ACTION" "$CLAUDE_SECOND_MODEL"; then
            echo "  [PASS] Optional second-model branch matched the baseline contract"
        else
            FAILED=$((FAILED + 1))
        fi
    else
        echo "  [SKIP] No second runner or second model available locally"
    fi
else
    echo "  [SKIP] Optional cross-runner check skipped because the primary drift cases failed"
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
echo "Failed $FAILED verification check(s)"
exit 1
