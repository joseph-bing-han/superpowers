#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "$REPO_ROOT/tests/shared/prompt-contract-helpers.sh"

# 保留旧文件名供现有调用方使用；旧协议仅适用于显式启用的集成或历史回放。
assert_section_contains skills/using-superpowers/SKILL.md '## Autonomous Continuation' 'Completed requests are delivered directly' 'normal completed requests do not need an endgate popup'
assert_section_contains skills/using-superpowers/SKILL.md '## Legacy Endgate Compatibility' 'explicitly enabled legacy runtime.*compatible consumer.*request_user_input support' 'legacy mode requires explicit activation and compatible capabilities'
assert_section_contains skills/using-superpowers/SKILL.md '## Legacy Endgate Compatibility' 'Loading this bootstrap.*does not enable it' 'loading instructions alone cannot activate legacy mode'
assert_file_contains .codex/instruction.md 'A wrapper that hides packet text does not enable packet mode' 'render filtering cannot activate legacy mode'

for path in "$REPO_ROOT"/skills/*/SKILL.md; do
  file="skills/$(basename "$(dirname "$path")")/SKILL.md"
  if [[ "$file" != skills/using-superpowers/SKILL.md ]]; then
    assert_file_contains "$file" 'using-superpowers' "$file inherits the shared completion rules"
    assert_file_contains "$file" 'directly|直接交付' "$file permits completed requests to be delivered"
  fi
  assert_file_not_contains "$file" 'must not end the conversation directly|Route true completion through|Every workflow boundary in this repository uses' "$file has no unconditional legacy terminal gate"
done

PACKET="openspec/specs/endgate-state-packet/spec.md"
assert_section_contains "$PACKET" '## Applicability' '显式启用.*legacy integration.*历史 fixture 回放' 'the version 1 specification is explicitly scoped'
assert_section_contains "$PACKET" '## Applicability' 'DONE.*不是 version 1 枚举' 'normal completion does not extend the version 1 enum'
for field in ENDGATE_PROTOCOL_VERSION ENDGATE_STATE ENDGATE_CHOICE_KIND ENDGATE_NEXT_ACTION; do
  assert_file_contains "$PACKET" "$field" "legacy packets retain $field"
done
assert_file_contains "$PACKET" '最后一份 packet.*事件窗口' 'legacy validation retains last-declaration event windows'
assert_file_contains "$PACKET" 'terminal_choice' 'legacy terminal decisions retain their canonical question identifier'
assert_file_contains openspec/specs/transcript-based-validation/spec.md 'Normal completion does not require a terminal popup' 'validation covers normal direct completion'
assert_file_not_contains openspec/specs/transcript-based-validation/spec.md 'Validation audits universal terminal-choice inheritance' 'validation no longer imposes legacy mode on all skills'
echo 'Legacy compatibility and shared completion checks passed.'
