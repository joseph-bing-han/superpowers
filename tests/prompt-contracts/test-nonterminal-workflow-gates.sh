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

assert_section_contains "skills/using-superpowers/SKILL.md" "## Autonomous Continuation" 'non-terminal workflow stages must not end with a prose-only follow-up|prose-only follow-up.*must not end.*non-terminal workflow stages' "global contract forbids prose-only follow-up endings in non-terminal workflow stages" '^## '
assert_section_contains "skills/using-superpowers/SKILL.md" "## Autonomous Continuation" 'either continue automatically.*or use `request_user_input`.*when a real decision remains|use `request_user_input`.*when a real decision remains.*otherwise continue automatically' "global contract forces the branch between auto-continuation and request_user_input" '^## '

assert_section_contains "skills/brainstorming/SKILL.md" "## Presenting the design:" 'Do not end a design checkpoint with prose-only follow-up text like `if you agree`|prose-only follow-up text like `if you agree`.*Do not end a design checkpoint' "brainstorming bans prose-only design checkpoint endings" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "## Presenting the design:" 'Either continue automatically into the next workflow step or use `request_user_input` for a real review gate|use `request_user_input` for a real review gate.*otherwise continue automatically' "brainstorming forces either auto-continue or request_user_input after a checkpoint" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "## Presenting the design:" 'prose-only next-step invitations|prose-only optional next-step invitation' "brainstorming bans prose-only optional next-step invitations" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "## Presenting the design:" 'next artifact choices are enumerable.*request_user_input|request_user_input.*next artifact choices are enumerable' "brainstorming routes optional next-step choices through request_user_input" '^## '

assert_section_contains "skills/brainstorming/SKILL.md" "## Visual Companion" 'When `request_user_input` is available, use it for the visual companion consent question instead of a prose-only yes/no prompt|use `request_user_input`.*visual companion consent question.*instead of a prose-only yes/no prompt' "visual companion consent uses request_user_input when available" '^## '

assert_section_contains "skills/writing-plans/SKILL.md" "## Execution Handoff" 'Do not end this handoff with prose-only follow-up text like `if you want me to execute next`|prose-only follow-up text like `if you want me to execute next`.*Do not end this handoff' "writing-plans bans prose-only execution handoff endings" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Execution Handoff" 'Either continue automatically on the already-implied execution path or use `request_user_input` when a real execution choice remains|use `request_user_input` when a real execution choice remains.*otherwise continue automatically' "writing-plans forces either auto-continue or request_user_input at handoff" '^## '

assert_section_contains "skills/executing-plans/SKILL.md" "## The Process" 'Do not stop with prose-only follow-up text like `if you want me to continue`|prose-only follow-up text like `if you want me to continue`.*Do not stop' "executing-plans bans prose-only continue prompts in routine execution" '^## '
assert_section_contains "skills/executing-plans/SKILL.md" "## When to Stop and Ask for Help" 'If a real blocker requires input and the choices are enumerable, use `request_user_input`; otherwise continue automatically once the path is clear|continue automatically once the path is clear.*use `request_user_input`.*if a real blocker requires input' "executing-plans ties blockers to request_user_input and otherwise continues automatically" '^## '

assert_section_contains "skills/subagent-driven-development/SKILL.md" "## The Process" 'Do not end a reviewed task update with prose-only follow-up text like `if you want me to continue`|prose-only follow-up text like `if you want me to continue`.*Do not end a reviewed task update' "subagent-driven-development bans prose-only continue prompts after reviewed tasks" '^## '
assert_section_contains "skills/subagent-driven-development/SKILL.md" "## The Process" 'Either move directly to the next task or use `request_user_input` when a real user decision remains|use `request_user_input` when a real user decision remains.*otherwise move directly to the next task' "subagent-driven-development forces direct continuation unless a real decision remains" '^## '

assert_section_contains "spec-governed-development/SKILL.md" "## Handoff Guidance" '如果后续路径已经明确，就直接进入对应下一个 skill|直接进入对应下一个 skill.*如果后续路径已经明确' "spec-governed-development auto-hands off when the next lane step is clear" '^## '
assert_section_contains "spec-governed-development/SKILL.md" "## Handoff Guidance" '如果确实还存在可枚举的用户决策，再使用 `request_user_input`|使用 `request_user_input`.*如果确实还存在可枚举的用户决策' "spec-governed-development only asks through request_user_input for real enumerable decisions" '^## '
assert_section_not_contains "spec-governed-development/SKILL.md" "## Handoff Guidance" '如果用户确认继续' "spec-governed-development no longer waits on a generic user confirmation phrase" '^## '

assert_section_contains "docs/README.codex.md" "## Autonomous Continuation" 'Non-terminal workflow stages must not end with a prose-only follow-up|prose-only follow-up.*must not end.*Non-terminal workflow stages' "Codex README mirrors the no prose-only follow-up contract" '^## '
assert_section_contains "docs/README.codex.md" "## Autonomous Continuation" 'either continue automatically or use `request_user_input` when a real decision remains|use `request_user_input` when a real decision remains.*otherwise continue automatically' "Codex README mirrors the auto-continue vs request_user_input split" '^## '

echo "All nonterminal-workflow-gate prompt contract checks passed."
