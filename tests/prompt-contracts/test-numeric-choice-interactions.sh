#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "$REPO_ROOT/tests/shared/prompt-contract-helpers.sh"
BOOTSTRAP="skills/using-superpowers/SKILL.md"
FINISHING="skills/finishing-a-development-branch/SKILL.md"

assert_section_contains "$BOOTSTRAP" '## User Choice Formatting' 'Ask only when the answer changes the work' 'a decision must affect the task'
assert_section_contains "$BOOTSTRAP" '## User Choice Formatting' 'request_user_input is available and permitted' 'choice tools must be both available and permitted'
assert_section_contains "$BOOTSTRAP" '## User Choice Formatting' 'unavailable or prohibited.*plain-text question' 'missing or prohibited choice tools have a text fallback'
assert_section_contains "$BOOTSTRAP" '## User Choice Formatting' "client.s free-text fallback" 'client free input is not duplicated'
assert_section_contains "$BOOTSTRAP" '## User Choice Formatting' 'safe exit first and final execution second' 'irreversible confirmation keeps the safe option first'
assert_section_contains "$BOOTSTRAP" '## User Choice Formatting' 'Editing is not permission to commit, push, create a PR, merge' 'editing does not authorize external outcomes'
assert_section_contains skills/brainstorming/SKILL.md '## Presenting the design:' 'available and permitted.*otherwise.*plain-text question' 'design decisions honor host capabilities'
assert_section_contains skills/writing-plans/SKILL.md '## Execution Handoff' 'unavailable or prohibited' 'plan handoff does not invent a choice tool'

assert_file_contains "$FINISHING" 'two-stage destructive confirmation' 'discard still requires two confirmation stages'
assert_file_contains "$FINISHING" '1\. Cancel and return to the previous step.*2\. Confirm discard now' 'the final discard confirmation keeps safe return first'
assert_file_contains "$FINISHING" 'invalid token or submits empty input.*do not execute or cancel' 'invalid input cannot trigger discard'
assert_file_contains "$FINISHING" 'feedback or a help request.*without executing or canceling' 'free input is not destructive authorization'
assert_file_contains "$FINISHING" 'cleanup is authorized.*uncommitted or unrelated work' 'cleanup checks authority and unrelated changes'
assert_section_contains docs/README.codex.md '## Choice-Based Interaction' 'available and permitted.*otherwise.*plain-text question' 'Codex documents the permitted interaction fallback'
echo 'Choice interaction checks passed.'
