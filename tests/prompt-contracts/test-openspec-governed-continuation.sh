#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "$REPO_ROOT/tests/shared/prompt-contract-helpers.sh"
GOVERNANCE="skills/spec-governed-development/SKILL.md"

assert_section_contains skills/using-superpowers/SKILL.md '## Governance Routing' 'existing governed changes.*Reuse the identified change as the canonical record' 'continuation restores existing ownership'
assert_file_contains skills/systematic-debugging/SKILL.md 'Identify the relevant change.*Read the affected requirements and tasks.*relevant proposal/design sections as needed' 'governed debugging restores only relevant context'
assert_section_contains "$GOVERNANCE" '## OpenSpec Workflow' 'proposal.md.*design.md.*specs/.*tasks.md' 'governance maps requirements to canonical artifacts'
assert_section_contains "$GOVERNANCE" '## OpenSpec Workflow' '已完整读取且未变化的上下文可复用' 'unchanged context does not need repeated loading'
assert_section_contains "$GOVERNANCE" '## OpenSpec Workflow' '本次授权范围内执行.*openspec-apply-change' 'apply remains within current authorization'
assert_section_contains "$GOVERNANCE" '## Capabilities and Fallback' '不要默认安装依赖、修改全局设置，或虚构外部 skill 调用' 'missing OpenSpec tools do not authorize installation'
assert_section_contains "$GOVERNANCE" '## Completion and Archive' '完整收尾且条件已满足.*自动继续到.*openspec-archive-change' 'ready authorized closure continues without another gate'
assert_file_not_contains openspec/specs/transcript-based-validation/spec.md '文案没有明确要求.*读取.*proposal.md.*design.md.*specs/.*tasks.md.*测试 MUST 失败' 'validation no longer mandates reading every artifact'
echo 'OpenSpec governed continuation checks passed.'
