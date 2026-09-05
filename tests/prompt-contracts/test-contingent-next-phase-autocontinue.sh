#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
rg -qi -- 'Conditional authorization' "$ROOT/skills/using-superpowers/SKILL.md"
rg -qi -- 'end-to-end execution is already authorized|continue without waiting' "$ROOT/skills/brainstorming/SKILL.md"
echo 'Contingent continuation checks passed.'
