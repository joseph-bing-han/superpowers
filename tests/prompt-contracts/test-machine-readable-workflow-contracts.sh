#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
rg -qi 'Machine-readable|machine-readable|carrier' "$ROOT/openspec/specs/workflow-protocol-contracts/spec.md"
rg -qi 'explicitly enabled.*legacy|普通 workflow 默认' "$ROOT/openspec/specs/endgate-state-packet/spec.md"
rg -qi 'DONE.*直接交付|Completed requests' "$ROOT/skills/using-superpowers/SKILL.md" "$ROOT/.codex/instruction.md"
rg -qi 'review.*uncommitted|untracked' "$ROOT/skills/requesting-code-review/SKILL.md"
echo "Task-scoped machine contract checks passed."
