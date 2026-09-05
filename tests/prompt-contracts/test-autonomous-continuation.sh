#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
assert() { rg -qi -- "$2" "$ROOT/$1" || { echo "FAIL: $3"; exit 1; }; echo "PASS: $3"; }
assert skills/using-superpowers/SKILL.md 'end-to-end completion and no clarification' 'authorized end-to-end work continues'
assert skills/using-superpowers/SKILL.md 'approval gates' 'summaries are not gates'
assert skills/using-superpowers/SKILL.md 'DONE: the requested deliverable' 'done state exists'
assert skills/using-superpowers/SKILL.md 'Do not require an end/continue popup' 'no redundant popup'
echo 'Autonomous continuation checks passed.'
