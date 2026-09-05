#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "$REPO_ROOT/tests/shared/prompt-contract-helpers.sh"

assert_file_exists skills/spec-governed-development/SKILL.md 'governance ships in the discoverable skills directory'
assert_file_exists .codex/instruction.md 'Codex instruction bootstrap exists'
assert_file_exists .codex/install-codex.sh 'Codex installer exists'
assert_section_contains skills/using-superpowers/SKILL.md '## Governance Routing' 'explicit OpenSpec requests, existing governed changes, project-mandated governance, or material risk' 'governance follows authority, ownership, and material risk'
assert_section_contains skills/using-superpowers/SKILL.md '## Governance Routing' 'do not ask again for a lane.*already authorized' 'known governance lanes do not need repeated approval'
assert_section_contains skills/spec-governed-development/SKILL.md '## Lane Decision' '不先创建可能重复的设计文档.*继续相关只读调查' 'unresolved record ownership blocks only conflicting writes'
assert_section_contains skills/spec-governed-development/SKILL.md '## When To Use' '新功能、跨两个模块、多个步骤本身都不是强制治理条件' 'module or step count alone does not force governance'
assert_section_contains skills/brainstorming/SKILL.md '## OpenSpec Lane Safety Gate' 'Ask only when an unresolved lane choice materially changes' 'design asks only about material unresolved governance'
assert_section_contains skills/writing-plans/SKILL.md '## OpenSpec Lane Safety Gate' 'ask only when the choice materially changes scope, authority, or the required durable record' 'planning retains the material lane-decision guard'
assert_section_contains skills/writing-plans/SKILL.md '## OpenSpec Lane Safety Gate' 'An existing governed change remains canonical' 'planning preserves the existing authorized governance lane'
assert_section_contains skills/brainstorming/SKILL.md '## Document Path Selection' '1\. A concrete path explicitly named.*2\. An existing structured spec directory.*3\. If no structured spec directory' 'design artifact paths retain explicit-path priority'
assert_section_contains skills/brainstorming/SKILL.md '## Document Path Selection' 'do not create a parallel design doc outside OpenSpec' 'governed design has one canonical record'
assert_file_contains skills/writing-plans/SKILL.md 'docs/plans.*docs/superpowers/plans|docs/superpowers/plans.*docs/plans' 'plans retain structured document paths'
assert_file_contains skills/writing-plans/SKILL.md 'execution-only|execution details|执行' 'governed plans do not replace design artifacts'
assert_file_contains .codex/INSTALL.md 'spec-governed-development.*skills/' 'Codex installation includes the governance skill'
assert_file_contains docs/README.codex.md 'current request can finish while a larger change remains open' 'Codex documents scoped completion'
echo 'OpenSpec entry and document-path checks passed.'
