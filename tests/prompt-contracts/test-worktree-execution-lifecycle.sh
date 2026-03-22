#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

normalize_stream() {
  tr '\r\n\t' '   ' | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//'
}

extract_section() {
  local file="$1"
  local heading="$2"
  local stop_pattern="${3:-^(##|###) }"

  awk -v heading="$heading" -v stop_pattern="$stop_pattern" '
    $0 == heading {
      in_section = 1
      next
    }

    in_section && $0 ~ stop_pattern {
      exit
    }

    in_section {
      print
    }
  ' "$file"
}

assert_section_contains() {
  local file="$1"
  local heading="$2"
  local pattern="$3"
  local description="$4"
  local stop_pattern="${5:-^(##|###) }"
  local content

  content="$(extract_section "$REPO_ROOT/$file" "$heading" "$stop_pattern")"

  if [[ -z "$content" ]]; then
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Missing section: $heading"
    exit 1
  fi

  if printf '%s' "$content" | normalize_stream | rg -qi -- "$pattern"; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Section: $heading"
    echo "  Pattern: $pattern"
    exit 1
  fi
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if normalize_stream < "$REPO_ROOT/$file" | rg -qi -- "$pattern"; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Pattern: $pattern"
    exit 1
  fi
}

assert_section_contains "skills/brainstorming/SKILL.md" "## Checklist" 'using-git-worktrees|isolated workspace|dedicated worktree' "brainstorming checklist explicitly routes implementation into an isolated worktree before planning" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "**Implementation:**" 'using-git-worktrees.*before.*writing-plans|invoke `using-git-worktrees`.*then.*`writing-plans`' "brainstorming implementation handoff invokes using-git-worktrees before writing-plans" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Overview" 'if you are not already in a dedicated worktree.*invoke `using-git-worktrees` first|invoke `using-git-worktrees` first if you are not already in a dedicated worktree' "writing-plans has a defensive worktree guard instead of only assuming brainstorming already created one" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Overview" 'if you are already in a dedicated worktree.*reuse it|reuse the existing dedicated worktree' "writing-plans reuses an existing dedicated worktree instead of nesting another one" '^## '
assert_section_contains "skills/executing-plans/SKILL.md" "## The Process" 'before executing tasks, ensure you are already inside a dedicated worktree|if not already in a dedicated worktree, invoke `using-git-worktrees`' "executing-plans explicitly requires entering a dedicated worktree before task execution" '^## '
assert_section_contains "skills/executing-plans/SKILL.md" "## The Process" 'do not create a nested worktree if one is already active|reuse the current dedicated worktree' "executing-plans avoids nested worktree creation" '^## '
assert_section_contains "skills/subagent-driven-development/SKILL.md" "## The Process" 'before dispatching implementation subagents, ensure you are already inside a dedicated worktree|if not already in a dedicated worktree, invoke `using-git-worktrees`' "subagent-driven-development explicitly requires entering a dedicated worktree before dispatching implementers" '^## '
assert_section_contains "skills/subagent-driven-development/SKILL.md" "## The Process" 'do not create a nested worktree if one is already active|reuse the current dedicated worktree' "subagent-driven-development avoids nested worktree creation" '^## '
assert_section_contains "skills/finishing-a-development-branch/SKILL.md" "### Step 5: Cleanup Worktree" 'For Options 1 and 4' "finishing flow cleans up worktrees for merge and discard outcomes" '^### '
assert_section_contains "skills/finishing-a-development-branch/SKILL.md" "### Step 5: Cleanup Worktree" 'For Options 2 and 3.*Keep worktree|Keep worktree.*Options 2 and 3' "finishing flow preserves worktrees for PR and keep-as-is outcomes" '^### '
assert_contains "docs/README.codex.md" 'worktree' "Codex README documents worktree lifecycle and execution isolation somewhere in the install or usage guide"

echo "All worktree execution lifecycle prompt contract checks passed."
