#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# 检查入口契约；真实事件序列由 tests/codex 中的 fixture 套件验证。
require() {
  if ! rg -qi -- "$2" "$REPO_ROOT/$1"; then
    echo "FAIL: $1: $3"
    exit 1
  fi
  echo "PASS: $3"
}

require skills/using-superpowers/SKILL.md 'completed requests.*directly|completed request.*directly' 'completed requests can finish directly'
require skills/using-superpowers/SKILL.md 'explicitly enabled' 'legacy packets require explicit enablement'
require skills/using-superpowers/SKILL.md 'host.*instruction.*hierarchy' 'host priority is preserved'
require skills/using-superpowers/SKILL.md 'unchanged.*reuse|reuse.*unchanged' 'unchanged context can be reused'
require skills/using-superpowers/SKILL.md 'unavailable.*plain|plain.*unavailable' 'missing choice tools have a plain-text fallback'
require .codex/instruction.md 'completed.*directly|complete.*directly' 'Codex bootstrap allows direct completion'

if rg -n 'skills override default system|follow the stricter one|must not end the conversation directly|Route true completion through' \
  "$REPO_ROOT/skills"/*/SKILL.md "$REPO_ROOT/.codex/instruction.md"; then
  echo 'FAIL: unconditional priority or completion gate remains'
  exit 1
fi
echo 'Task-scoped completion contracts passed.'
