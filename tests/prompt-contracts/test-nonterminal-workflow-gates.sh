#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "$REPO_ROOT/tests/shared/prompt-contract-helpers.sh"
BOOTSTRAP="skills/using-superpowers/SKILL.md"

assert_section_contains "$BOOTSTRAP" '## Autonomous Continuation' 'AUTO_CONTINUE: necessary work remains within scope and authority; do it' 'remaining authorized work actually continues'
assert_section_contains "$BOOTSTRAP" '## Autonomous Continuation' 'NEEDS_USER_DECISION:.*missing information.*material tradeoff.*new authority' 'only material blockers require a decision'
assert_section_contains "$BOOTSTRAP" '## Autonomous Continuation' 'continue independent work' 'a blocked task does not stop independent work'
assert_section_contains "$BOOTSTRAP" '## Autonomous Continuation' 'Summaries are progress updates, not approval gates' 'summaries do not create fresh approval gates'
assert_section_contains "$BOOTSTRAP" '## Autonomous Continuation' 'plan before changes, deliver the plan and wait' 'plan-first requests do not authorize implementation'
assert_section_contains skills/brainstorming/SKILL.md '## Presenting the design:' 'execution is already authorized.*continue without waiting' 'authorized design handoff continues'
assert_section_contains skills/writing-plans/SKILL.md '## Execution Handoff' 'execution is already authorized.*executing-plans' 'authorized plans hand off to execution'
assert_section_contains skills/writing-plans/SKILL.md '## Execution Handoff' 'plan only or review before implementation.*wait' 'plan-only handoff waits for authorization'
assert_section_contains skills/executing-plans/SKILL.md '## The Process' 'Continue clear authorized work' 'execution does not stop at routine checkpoints'
assert_section_contains skills/spec-governed-development/SKILL.md '## Handoff Guidance' '请求范围内继续安全、已授权的下一步' 'governed continuation remains within the request'
assert_section_contains docs/README.codex.md '## Autonomous Continuation' 'Conditional authorization becomes effective once its condition is satisfied' 'Codex preserves conditional authorization'

VALIDATION="openspec/specs/transcript-based-validation/spec.md"
assert_file_contains "$VALIDATION" '授权条件成立且仍有安全、获准的后续工作.*验证 MUST 要求继续执行' 'satisfied conditions continue remaining authorized work'
assert_file_contains "$VALIDATION" '本次授权任务及相称验证均已完成.*验证 MUST 接受直接交付' 'completed conditional requests can finish directly'
assert_file_contains "$VALIDATION" '条件不成立.*MUST 确认系统未执行依赖该条件的步骤' 'unmet conditions do not grant continuation authority'

for file in "$BOOTSTRAP" .codex/instruction.md skills/executing-plans/SKILL.md; do
  assert_file_not_contains "$file" 'Every workflow boundary in this repository uses|Every workflow boundary in this repository is carrier-backed' "$file does not enable legacy packets at every checkpoint"
done
echo 'Nonterminal workflow checks passed.'
