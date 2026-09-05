#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "$REPO_ROOT/tests/shared/prompt-contract-helpers.sh"
GOVERNANCE="skills/spec-governed-development/SKILL.md"
PROTOCOL="openspec/specs/workflow-protocol-contracts/spec.md"
VALIDATION="openspec/specs/transcript-based-validation/spec.md"

assert_file_contains "$PROTOCOL" 'Request completion and change archive are separate' 'request completion is distinct from archive'
assert_file_contains "$PROTOCOL" 'MUST NOT 自动实现无关任务或提前归档' 'partial completion preserves unrelated work'
assert_file_contains "$PROTOCOL" '授权包含完整收尾.*所需审查、合并和规范同步已满足' 'archive requires authority and completed prerequisites'
assert_section_contains "$GOVERNANCE" '## Completion and Archive' '保留其开放状态' 'a larger change stays open after a scoped fix'
assert_section_contains "$GOVERNANCE" '## Completion and Archive' '创建 proposal 不自动授权归档，更不授权 merge' 'creating a proposal grants no archive or merge authority'
assert_section_contains "$GOVERNANCE" '## Completion and Archive' '完整收尾且条件已满足.*openspec-archive-change.*不再问' 'authorized closure auto-continues when ready'
assert_file_contains skills/finishing-a-development-branch/SKILL.md 'A PR awaiting merge is not ready for archive' 'an unmerged PR cannot satisfy final integration'
assert_file_contains "$VALIDATION" 'Partial completion leaves the change open' 'validation covers partial request completion'
assert_file_contains "$VALIDATION" 'Authorized closure continues to archive' 'validation covers authorized complete closure'
assert_file_not_contains "$VALIDATION" '没有把“创建过 proposal 后未归档”判定为测试失败' 'validation does not force archive merely because a proposal exists'
echo 'OpenSpec archive scope checks passed.'
