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
assert_section_contains "skills/using-superpowers/SKILL.md" "## Autonomous Continuation" '`auto-continue`, `needs-user-decision`, or `terminal-choice`|classify the turn as `auto-continue`, `needs-user-decision`, or `terminal-choice`' "global contract defines the three-state turn-end gate" '^## '
assert_section_contains "skills/using-superpowers/SKILL.md" "## Autonomous Continuation" 'either continue automatically.*or use `request_user_input`.*when a real decision remains|use `request_user_input`.*when a real decision remains.*otherwise continue automatically' "global contract forces the branch between auto-continuation and request_user_input" '^## '
assert_section_contains "skills/using-superpowers/SKILL.md" "## Autonomous Continuation" '`terminal-choice`|1\. 结束|2\. 继续|3\. 自由输入' "global contract requires a request_user_input terminal-choice popup instead of direct completion" '^## '
assert_section_contains "skills/using-superpowers/SKILL.md" "## Autonomous Continuation" 'declarative prose-only next-step proposal|the next best step is|next i would do x|i can directly prepare x next' "global contract also forbids declarative prose-only next-step proposals" '^## '
assert_section_contains "skills/using-superpowers/SKILL.md" "## Autonomous Continuation" 'judgment-framed|comparative|recommendation-framed|判断式|比较式|推荐式' "global contract explicitly covers judgment-framed, comparative, and recommendation-framed non-terminal endings" '^## '
assert_section_contains "skills/using-superpowers/SKILL.md" "## Autonomous Continuation" 'summary, recommendation, judgment, comparison, or suggestion about what to do next|recommendation, judgment, comparison, or suggestion' "global contract forbids ending a non-terminal turn after only narrating what should happen next" '^## '
assert_section_contains "skills/using-superpowers/SKILL.md" "## Autonomous Continuation" 'if you can already describe the next safe step concretely, perform it|perform it instead of narrating it and stopping|do it instead of narrating it and stopping' "global contract requires executing a concretely known safe next step instead of merely proposing it" '^## '

assert_section_contains "skills/brainstorming/SKILL.md" "## Presenting the design:" 'Do not end a design checkpoint with prose-only follow-up text like `if you agree`|prose-only follow-up text like `if you agree`.*Do not end a design checkpoint' "brainstorming bans prose-only design checkpoint endings" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "## Presenting the design:" '`auto-continue`, `needs-user-decision`, or `terminal-choice`|classify the checkpoint as `auto-continue`, `needs-user-decision`, or `terminal-choice`' "brainstorming defines the three-state checkpoint gate" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "## Presenting the design:" 'Either continue automatically into the next workflow step or use `request_user_input` for a real review gate|use `request_user_input` for a real review gate.*otherwise continue automatically' "brainstorming forces either auto-continue or request_user_input after a checkpoint" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "## Presenting the design:" '`terminal-choice`|1\. 结束|2\. 继续|3\. 自由输入' "brainstorming requires a request_user_input terminal-choice popup instead of direct completion" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "## Presenting the design:" 'prose-only next-step invitations|prose-only optional next-step invitation' "brainstorming bans prose-only optional next-step invitations" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "## Presenting the design:" 'next artifact choices are enumerable.*request_user_input|request_user_input.*next artifact choices are enumerable' "brainstorming routes optional next-step choices through request_user_input" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "## Presenting the design:" 'declarative prose-only next-step proposal|the next best step is x|i can directly prepare x next' "brainstorming bans declarative next-step proposals that stop the workflow" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "## Presenting the design:" 'judgment-framed|comparative|recommendation-framed|判断式|比较式|推荐式' "brainstorming explicitly covers judgment-framed, comparative, and recommendation-framed next-step proposals" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "## Presenting the design:" 'summary, recommendation, judgment, comparison, or suggestion about the next artifact step|recommendation, judgment, comparison, or suggestion about the next artifact step' "brainstorming forbids ending a non-terminal checkpoint after only narrating the next artifact step" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "## Presenting the design:" 'if you can already name the next safe artifact step, take it|take it instead of narrating it and stopping' "brainstorming requires taking a concretely known safe artifact step instead of narrating it" '^## '

assert_section_contains "skills/brainstorming/SKILL.md" "## Visual Companion" 'When `request_user_input` is available, use it for the visual companion consent question instead of a prose-only yes/no prompt|use `request_user_input`.*visual companion consent question.*instead of a prose-only yes/no prompt' "visual companion consent uses request_user_input when available" '^## '

assert_section_contains "skills/writing-plans/SKILL.md" "## Execution Handoff" 'Do not end this handoff with prose-only follow-up text like `if you want me to execute next`|prose-only follow-up text like `if you want me to execute next`.*Do not end this handoff' "writing-plans bans prose-only execution handoff endings" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Execution Handoff" '`auto-continue`, `needs-user-decision`, or `terminal-choice`|classify the handoff as `auto-continue`, `needs-user-decision`, or `terminal-choice`' "writing-plans defines the three-state execution handoff gate" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Execution Handoff" 'Either continue automatically on the already-implied execution path or use `request_user_input` when a real execution choice remains|use `request_user_input` when a real execution choice remains.*otherwise continue automatically' "writing-plans forces either auto-continue or request_user_input at handoff" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Execution Handoff" '`terminal-choice`|1\. 结束|2\. 继续|3\. 自由输入' "writing-plans requires a request_user_input terminal-choice popup instead of direct completion" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Execution Handoff" 'declarative prose-only next-step proposal|the next step is for me to execute|the next best step is to execute' "writing-plans bans declarative execution handoff proposals that still stop the turn" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Execution Handoff" 'judgment-framed|comparative|recommendation-framed|判断式|比较式|推荐式' "writing-plans explicitly covers judgment-framed, comparative, and recommendation-framed execution handoff endings" '^## '

assert_section_contains "skills/executing-plans/SKILL.md" "## The Process" 'Do not stop with prose-only follow-up text like `if you want me to continue`|prose-only follow-up text like `if you want me to continue`.*Do not stop' "executing-plans bans prose-only continue prompts in routine execution" '^## '
assert_section_contains "skills/executing-plans/SKILL.md" "## The Process" '`auto-continue`, `needs-user-decision`, or `terminal-choice`|classify the batch boundary as `auto-continue`, `needs-user-decision`, or `terminal-choice`' "executing-plans defines the three-state routine checkpoint gate" '^## '
assert_section_contains "skills/executing-plans/SKILL.md" "## When to Stop and Ask for Help" 'If a real blocker requires input and the choices are enumerable, use `request_user_input`; otherwise continue automatically once the path is clear|continue automatically once the path is clear.*use `request_user_input`.*if a real blocker requires input' "executing-plans ties blockers to request_user_input and otherwise continues automatically" '^## '
assert_section_contains "skills/executing-plans/SKILL.md" "## The Process" '`terminal-choice`|1\. 结束|2\. 继续|3\. 自由输入' "executing-plans requires a request_user_input terminal-choice popup instead of direct completion" '^## '
assert_section_contains "skills/executing-plans/SKILL.md" "## The Process" 'declarative prose-only next-step proposal|the next best step is to continue with task|next i would continue with task' "executing-plans bans declarative next-step proposals after routine checkpoints" '^## '
assert_section_contains "skills/executing-plans/SKILL.md" "## The Process" 'judgment-framed|comparative|recommendation-framed|判断式|比较式|推荐式' "executing-plans explicitly covers judgment-framed, comparative, and recommendation-framed routine checkpoint endings" '^## '

assert_section_contains "skills/subagent-driven-development/SKILL.md" "## The Process" 'Do not end a reviewed task update with prose-only follow-up text like `if you want me to continue`|prose-only follow-up text like `if you want me to continue`.*Do not end a reviewed task update' "subagent-driven-development bans prose-only continue prompts after reviewed tasks" '^## '
assert_section_contains "skills/subagent-driven-development/SKILL.md" "## The Process" '`auto-continue`, `needs-user-decision`, or `terminal-choice`|classify the reviewed task boundary as `auto-continue`, `needs-user-decision`, or `terminal-choice`' "subagent-driven-development defines the three-state reviewed task gate" '^## '
assert_section_contains "skills/subagent-driven-development/SKILL.md" "## The Process" 'Either move directly to the next task or use `request_user_input` when a real user decision remains|use `request_user_input` when a real user decision remains.*otherwise move directly to the next task' "subagent-driven-development forces direct continuation unless a real decision remains" '^## '
assert_section_contains "skills/subagent-driven-development/SKILL.md" "## The Process" '`terminal-choice`|1\. 结束|2\. 继续|3\. 自由输入' "subagent-driven-development requires a request_user_input terminal-choice popup instead of direct completion" '^## '
assert_section_contains "skills/subagent-driven-development/SKILL.md" "## The Process" 'declarative prose-only next-task proposal|the next task is for me to|the next best step is task' "subagent-driven-development bans declarative next-task proposals that still stop the turn" '^## '
assert_section_contains "skills/subagent-driven-development/SKILL.md" "## The Process" 'judgment-framed|comparative|recommendation-framed|判断式|比较式|推荐式' "subagent-driven-development explicitly covers judgment-framed, comparative, and recommendation-framed reviewed task endings" '^## '

assert_section_contains "spec-governed-development/SKILL.md" "## Handoff Guidance" '如果后续路径已经明确，就直接进入对应下一个 skill|直接进入对应下一个 skill.*如果后续路径已经明确' "spec-governed-development auto-hands off when the next lane step is clear" '^## '
assert_section_contains "spec-governed-development/SKILL.md" "## Handoff Guidance" '`auto-continue`、`needs-user-decision`、`terminal-choice`|`auto-continue`, `needs-user-decision`, or `terminal-choice`|三种状态' "spec-governed-development defines the three-state handoff gate" '^## '
assert_section_contains "spec-governed-development/SKILL.md" "## Handoff Guidance" '如果确实还存在可枚举的用户决策，再使用 `request_user_input`|使用 `request_user_input`.*如果确实还存在可枚举的用户决策' "spec-governed-development only asks through request_user_input for real enumerable decisions" '^## '
assert_section_contains "spec-governed-development/SKILL.md" "## Handoff Guidance" '`terminal-choice`|1\. 结束|2\. 继续|3\. 自由输入' "spec-governed-development requires a request_user_input terminal-choice popup instead of direct completion" '^## '
assert_section_not_contains "spec-governed-development/SKILL.md" "## Handoff Guidance" '如果用户确认继续' "spec-governed-development no longer waits on a generic user confirmation phrase" '^## '
assert_section_contains "spec-governed-development/SKILL.md" "## Handoff Guidance" '声明式下一步提议|下一步最合适的是我直接|接下来我会先' "spec-governed-development bans declarative next-step proposals that end the turn" '^## '
assert_section_contains "spec-governed-development/SKILL.md" "## Handoff Guidance" '判断式|比较式|推荐式' "spec-governed-development explicitly covers judgment-framed, comparative, and recommendation-framed next-step proposals" '^## '

assert_section_contains "docs/README.codex.md" "## Autonomous Continuation" 'Non-terminal workflow stages must not end with a prose-only follow-up|prose-only follow-up.*must not end.*Non-terminal workflow stages' "Codex README mirrors the no prose-only follow-up contract" '^## '
assert_section_contains "docs/README.codex.md" "## Autonomous Continuation" '`auto-continue`, `needs-user-decision`, or `terminal-choice`|classify the turn as `auto-continue`, `needs-user-decision`, or `terminal-choice`' "Codex README mirrors the three-state turn-end gate" '^## '
assert_section_contains "docs/README.codex.md" "## Autonomous Continuation" 'either continue automatically or use `request_user_input` when a real decision remains|use `request_user_input` when a real decision remains.*otherwise continue automatically' "Codex README mirrors the auto-continue vs request_user_input split" '^## '
assert_section_contains "docs/README.codex.md" "## Autonomous Continuation" '`terminal-choice`|1\. 结束|2\. 继续|3\. 自由输入' "Codex README requires a request_user_input terminal-choice popup instead of direct completion" '^## '
assert_section_contains "docs/README.codex.md" "## Autonomous Continuation" 'declarative prose-only next-step proposal|the next best step is|i can directly prepare x next' "Codex README mirrors the ban on declarative prose-only next-step proposals" '^## '
assert_section_contains "docs/README.codex.md" "## Autonomous Continuation" 'judgment-framed|comparative|recommendation-framed|判断式|比较式|推荐式' "Codex README mirrors the ban on judgment-framed, comparative, and recommendation-framed next-step proposals" '^## '
assert_section_contains "docs/README.codex.md" "## Autonomous Continuation" 'summary, recommendation, judgment, comparison, or suggestion about what to do next|recommendation, judgment, comparison, or suggestion' "Codex README mirrors the ban on ending a non-terminal turn after only narrating what should happen next" '^## '
assert_section_contains "docs/README.codex.md" "## Autonomous Continuation" 'if the assistant can already describe the next safe step concretely, it should do it|do it rather than narrating and stopping' "Codex README mirrors the requirement to execute a concretely known safe next step" '^## '

echo "All nonterminal-workflow-gate prompt contract checks passed."
