#!/usr/bin/env bash
# Test that lightweight direct-mode prompts do NOT trigger workflow skills.
# Usage: ./run-negative-test.sh <prompt-file>

set -euo pipefail

PROMPT_FILE="${1:-}"
MAX_TURNS="${2:-3}"

if [[ -z "$PROMPT_FILE" ]]; then
    echo "Usage: $0 <prompt-file> [max-turns]"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

TIMESTAMP="$(date +%s)"
PROMPT_NAME="$(basename "$PROMPT_FILE" .txt)"
OUTPUT_DIR="/tmp/superpowers-tests/${TIMESTAMP}/skill-triggering-negative/${PROMPT_NAME}"
mkdir -p "$OUTPUT_DIR"

PROMPT="$(cat "$PROMPT_FILE")"
LOG_FILE="$OUTPUT_DIR/claude-output.json"

echo "=== Negative Skill Triggering Test ==="
echo "Prompt file: $PROMPT_FILE"
echo "Max turns: $MAX_TURNS"
echo "Output dir: $OUTPUT_DIR"
echo ""

cp "$PROMPT_FILE" "$OUTPUT_DIR/prompt.txt"
cd "$OUTPUT_DIR"

timeout 300 claude -p "$PROMPT" \
    --plugin-dir "$PLUGIN_DIR" \
    --dangerously-skip-permissions \
    --max-turns "$MAX_TURNS" \
    --output-format stream-json \
    > "$LOG_FILE" 2>&1 || true

echo "=== Results ==="

if grep -q '"name":"Skill"' "$LOG_FILE"; then
    echo "❌ FAIL: A workflow skill was triggered for a direct-mode prompt"
    echo ""
    echo "Skills triggered in this run:"
    grep -o '"skill":"[^"]*"' "$LOG_FILE" 2>/dev/null | sort -u || echo "  (none)"
    echo ""
    echo "Full log: $LOG_FILE"
    exit 1
fi

echo "✅ PASS: No workflow skill was triggered"
echo ""
echo "Full log: $LOG_FILE"
