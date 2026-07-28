#!/usr/bin/env bash
# Run all skill triggering tests
# Usage: ./run-all.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="$SCRIPT_DIR/prompts"

if [[ "${SUPERPOWERS_SKIP_CLAUDE:-0}" == "1" ]]; then
    echo "SKIP: claude CLI verification disabled for this environment"
    exit 0
fi

if ! command -v claude >/dev/null 2>&1; then
    echo "SKIP: claude CLI unavailable on this machine"
    exit 0
fi

SKILLS=(
    "systematic-debugging"
    "test-driven-development"
    "writing-plans"
    "executing-plans"
    "requesting-code-review"
)

echo "=== Running Skill Triggering Tests ==="
echo ""

PASSED=0
FAILED=0
RESULTS=()
NEGATIVE_PROMPTS=(
    "direct-mode-plain-question"
    "direct-mode-translation"
    "direct-mode-copy-only-edit"
)

for skill in "${SKILLS[@]}"; do
    prompt_file="$PROMPTS_DIR/${skill}.txt"

    if [ ! -f "$prompt_file" ]; then
        echo "⚠️  SKIP: No prompt file for $skill"
        continue
    fi

    echo "Testing: $skill"

    if bash "$SCRIPT_DIR/run-test.sh" "$skill" "$prompt_file" 3 2>&1 | tee /tmp/skill-test-$skill.log; then
        PASSED=$((PASSED + 1))
        RESULTS+=("✅ $skill")
    else
        FAILED=$((FAILED + 1))
        RESULTS+=("❌ $skill")
    fi

    echo ""
    echo "---"
    echo ""
done

echo "=== Running Negative Direct-Mode Triggering Tests ==="
echo ""

for prompt_name in "${NEGATIVE_PROMPTS[@]}"; do
    prompt_file="$PROMPTS_DIR/${prompt_name}.txt"

    if [ ! -f "$prompt_file" ]; then
        echo "⚠️  SKIP: No prompt file for $prompt_name"
        continue
    fi

    echo "Testing negative prompt: $prompt_name"

    if bash "$SCRIPT_DIR/run-negative-test.sh" "$prompt_file" 3 2>&1 | tee /tmp/skill-test-negative-$prompt_name.log; then
        PASSED=$((PASSED + 1))
        RESULTS+=("✅ $prompt_name")
    else
        FAILED=$((FAILED + 1))
        RESULTS+=("❌ $prompt_name")
    fi

    echo ""
    echo "---"
    echo ""
done

echo "=== Running Explicit Workflow-Keyword Positive Test ==="
echo ""

WORKFLOW_KEYWORD_PROMPT="$PROMPTS_DIR/workflow-keyword-plan.txt"
if [ -f "$WORKFLOW_KEYWORD_PROMPT" ]; then
    echo "Testing positive prompt: workflow-keyword-plan"
    if bash "$SCRIPT_DIR/run-test.sh" "writing-plans" "$WORKFLOW_KEYWORD_PROMPT" 3 2>&1 | tee /tmp/skill-test-workflow-keyword-plan.log; then
        PASSED=$((PASSED + 1))
        RESULTS+=("✅ workflow-keyword-plan")
    else
        FAILED=$((FAILED + 1))
        RESULTS+=("❌ workflow-keyword-plan")
    fi

    echo ""
    echo "---"
    echo ""
else
    echo "⚠️  SKIP: No prompt file for workflow-keyword-plan"
fi

echo ""
echo "=== Summary ==="
for result in "${RESULTS[@]}"; do
    echo "  $result"
done
echo ""
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [ $FAILED -gt 0 ]; then
    exit 1
fi
