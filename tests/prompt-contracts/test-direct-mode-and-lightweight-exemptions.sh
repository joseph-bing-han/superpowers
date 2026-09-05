#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
rg -qi -- 'Direct Mode is the default' "$ROOT/.codex/instruction.md"
rg -qi -- 'Ordinary questions, translation' "$ROOT/skills/using-superpowers/SKILL.md"
rg -qi -- 'lightweight subtask stays direct' "$ROOT/skills/using-superpowers/SKILL.md"
echo 'Direct-mode checks passed.'
