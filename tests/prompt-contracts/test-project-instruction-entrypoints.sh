#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "$REPO_ROOT/tests/shared/prompt-contract-helpers.sh"

assert_file_exists AGENTS.md 'shared project instructions exist'
assert_file_exists CLAUDE.md 'Claude has an automatic project instruction entrypoint'
if ! rg -qx '@AGENTS\.md' "$REPO_ROOT/CLAUDE.md"; then
  echo 'FAIL: Claude must import the shared project rules'
  exit 1
fi
assert_file_not_contains AGENTS.md '@CLAUDE\.md' 'project instruction imports do not form a cycle'
echo 'Project instruction entrypoint checks passed.'
