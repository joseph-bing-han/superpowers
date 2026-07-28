#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

normalize_stream() {
  tr '\r\n\t' '   ' | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//'
}

extract_section() {
  local file="$1"
  local heading="$2"
  local stop_pattern="${3:-^(##|###) }"

  awk -v heading="$heading" -v stop_pattern="$stop_pattern" '
    $0 == heading {
      in_section = 1
      next
    }

    in_section && $0 ~ stop_pattern {
      exit
    }

    in_section {
      print
    }
  ' "$file"
}

assert_section_contains() {
  local file="$1"
  local heading="$2"
  local pattern="$3"
  local description="$4"
  local stop_pattern="${5:-^(##|###) }"
  local content

  content="$(extract_section "$REPO_ROOT/$file" "$heading" "$stop_pattern")"

  if [[ -z "$content" ]]; then
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Missing section: $heading"
    exit 1
  fi

  if printf '%s' "$content" | normalize_stream | rg -qi -- "$pattern"; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Section: $heading"
    echo "  Pattern: $pattern"
    exit 1
  fi
}

assert_section_not_contains() {
  local file="$1"
  local heading="$2"
  local pattern="$3"
  local description="$4"
  local stop_pattern="${5:-^(##|###) }"
  local content

  content="$(extract_section "$REPO_ROOT/$file" "$heading" "$stop_pattern")"

  if [[ -z "$content" ]]; then
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Missing section: $heading"
    exit 1
  fi

  if printf '%s' "$content" | normalize_stream | rg -qi -- "$pattern"; then
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Section: $heading"
    echo "  Forbidden pattern: $pattern"
    exit 1
  else
    echo "PASS: $description"
  fi
}

assert_section_contains "skills/using-superpowers/SKILL.md" "## Autonomous Continuation" 'if the user asked for end-to-end completion.*no clarification.*keep advancing the workflow according to the turn-end gate|keep advancing the workflow according to the turn-end gate.*end-to-end completion.*no clarification' "global contract keeps advancing end-to-end work through the turn-end gate when no clarification is needed" '^## '
assert_section_contains "skills/using-superpowers/SKILL.md" "## Autonomous Continuation" 'do not stop after summaries.*continue|do not stop at phase boundaries just to ask whether to continue|summaries are progress updates, not approval gates' "global contract forbids turning summaries into continue gates" '^## '
assert_section_contains "skills/using-superpowers/SKILL.md" "## Autonomous Continuation" 'only ask when.*missing information|only ask when.*destructive|only ask when.*material tradeoff|missing information.*destructive.*material tradeoff' "global contract restricts pauses to real clarification, confirmation, or tradeoff cases" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "## Presenting the design:" 'if the user already asked for end-to-end execution and the design is straightforward.*continue without waiting|continue without waiting.*if the user already asked for end-to-end execution and the design is straightforward' "brainstorming can continue after a concise design checkpoint when no real review gate remains" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "## User Review Gate:" 'do not stop just to ask whether to continue when the original request already authorizes end-to-end execution|when the original request already authorizes end-to-end execution.*do not stop just to ask whether to continue' "brainstorming artifact review gate skips redundant continue prompts" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Execution Handoff" 'if the execution path is already clear.*continue automatically|continue automatically.*if the execution path is already clear|if the user asked for end-to-end completion.*continue automatically' "writing-plans auto-selects the known execution path instead of always pausing for a handoff choice" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Execution Handoff" 'do not pause after saving the plan just to ask whether to continue|saving the plan is not a reason by itself to stop' "writing-plans treats plan completion as a transition, not an automatic stop" '^## '
assert_section_contains "skills/executing-plans/SKILL.md" "## The Process" 'do not stop at routine summaries, checkpoints, or batch boundaries|routine summaries.*not human approval gates|checkpoints are internal progress markers, not stop points' "executing-plans keeps running across routine checkpoints" '^## '
assert_section_contains "docs/README.codex.md" "## Autonomous Continuation" 'end-to-end completion.*keep advancing the workflow according to the turn-end gate.*no clarification|keep advancing the workflow according to the turn-end gate.*end-to-end completion.*no clarification' "Codex README documents the turn-end-gate autonomous continuation contract" '^## '
assert_section_contains "docs/README.codex.md" "## Autonomous Continuation" 'do not stop after summaries, checkpoints, or phase completions just to ask whether to continue|summaries, checkpoints, and phase completions are not automatic stop points' "Codex README documents that summaries are not continue gates" '^## '
assert_section_not_contains "docs/README.codex.md" "## Autonomous Continuation" 'always stop after each phase|must ask to continue after every summary|require the user to type continue after each checkpoint' "Codex README autonomous continuation section does not preserve the old stop-after-summary behavior" '^## '

echo "All autonomous-continuation prompt contract checks passed."
