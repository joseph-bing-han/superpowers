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

assert_section_not_contains() {
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
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Section: $heading"
    echo "  Unexpected pattern: $pattern"
    exit 1
  else
    echo "PASS: $description"
  fi
}

assert_not_contains() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if normalize_stream < "$REPO_ROOT/$file" | rg -qi -- "$pattern"; then
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Unexpected pattern: $pattern"
    exit 1
  else
    echo "PASS: $description"
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

assert_section_contains "skills/brainstorming/SKILL.md" "## Checklist" 'current workspace|current working tree|current working directory' "brainstorming checklist keeps implementation planning in the current workspace by default" '^## '
assert_section_not_contains "skills/brainstorming/SKILL.md" "## Checklist" 'using-git-worktrees|isolated workspace|dedicated worktree' "brainstorming checklist no longer routes implementation into a dedicated worktree before planning" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "**Implementation:**" 'current workspace.*writing-plans|writing-plans.*current workspace|directly.*writing-plans' "brainstorming implementation handoff goes directly into writing-plans in the current workspace" '^## '
assert_section_not_contains "skills/brainstorming/SKILL.md" "**Implementation:**" 'using-git-worktrees.*before.*writing-plans|using-git-worktrees.*then.*writing-plans' "brainstorming implementation handoff no longer requires using-git-worktrees before writing-plans" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Overview" 'current workspace|current working tree|current working directory' "writing-plans documents current-workspace planning as the default context" '^## '
assert_section_not_contains "skills/writing-plans/SKILL.md" "## Overview" 'dedicated worktree|using-git-worktrees' "writing-plans overview no longer requires a dedicated worktree precondition" '^## '
assert_section_contains "skills/executing-plans/SKILL.md" "## The Process" 'current workspace|current working tree|current working directory' "executing-plans allows execution directly in the current workspace" '^## '
assert_section_not_contains "skills/executing-plans/SKILL.md" "## The Process" 'dedicated worktree|using-git-worktrees' "executing-plans process no longer requires entering a dedicated worktree first" '^## '
assert_section_contains "skills/subagent-driven-development/SKILL.md" "## The Process" 'current workspace|current working tree|current working directory' "subagent-driven-development allows same-session execution in the current workspace" '^## '
assert_section_not_contains "skills/subagent-driven-development/SKILL.md" "## The Process" 'dedicated worktree|using-git-worktrees' "subagent-driven-development process no longer requires a dedicated worktree precondition" '^## '
assert_section_contains "skills/finishing-a-development-branch/SKILL.md" "### Step 5: Cleanup Worktree" 'if an isolated workspace or worktree was used|only when an isolated workspace or worktree was used|if a worktree was actually used' "finishing flow treats worktree cleanup as conditional context instead of the default path" '^### '
assert_section_not_contains "skills/finishing-a-development-branch/SKILL.md" "### Step 5: Cleanup Worktree" 'For Options 1 and 4|For Options 2 and 3.*Keep worktree|Keep worktree.*Options 2 and 3' "finishing flow no longer assumes every implementation used a worktree" '^### '
assert_contains "docs/README.codex.md" 'Execution Workspace|current workspace' "Codex README documents current-workspace execution as the default path"
assert_contains "docs/README.codex.md" 'explicit opt-in|explicitly requested' "Codex README documents isolated workspaces as explicit opt-in only"
assert_not_contains "docs/README.codex.md" 'Implementation-oriented Superpowers flows should run inside a dedicated git worktree for isolation' "Codex README no longer presents dedicated worktrees as the default execution model"

echo "All worktree execution lifecycle prompt contract checks passed."
