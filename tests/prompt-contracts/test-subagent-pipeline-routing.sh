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

assert_section_contains "skills/writing-plans/SKILL.md" "## Task Structure" 'Execution Metadata' "writing-plans defines the execution metadata block" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Task Structure" 'Depends on' "writing-plans includes Depends on in task metadata" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Task Structure" 'Write Set' "writing-plans includes Write Set in task metadata" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Task Structure" 'Conflict Group' "writing-plans includes Conflict Group in task metadata" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Task Structure" 'Risk Level' "writing-plans includes Risk Level in task metadata" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Task Structure" 'Parallelizable' "writing-plans includes Parallelizable in task metadata" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Task Structure" 'Parallelizable.*no \| preflight-only \| yes|no \| preflight-only \| yes.*Parallelizable' "writing-plans freezes the Parallelizable enum" '^## '
assert_section_contains "skills/subagent-driven-development/SKILL.md" "## The Process" 'Pipeline SDD' "subagent-driven-development names Pipeline SDD" '^## '
assert_section_contains "skills/subagent-driven-development/SKILL.md" "## The Process" 'queued.*preflight.*ready.*implementing.*spec_review.*quality_review.*done.*blocked|blocked.*queued.*preflight.*ready.*implementing.*spec_review.*quality_review.*done' "subagent-driven-development defines the full pipeline state machine" '^## '
assert_section_contains "skills/subagent-driven-development/SKILL.md" "## The Process" 'implementer \+ preflight' "subagent-driven-development requires implementer plus preflight overlap" '^## '
assert_section_contains "skills/subagent-driven-development/SKILL.md" "## The Process" 'reviewer \+ preflight' "subagent-driven-development requires reviewer plus preflight overlap" '^## '
assert_section_contains "skills/subagent-driven-development/SKILL.md" "## The Process" 'Risk Level.*>.*dependency changes task boundary.*>.*Conflict Group.*Write Set.*>.*Parallelizable|Risk Level.*higher.*than.*dependency.*Conflict Group.*Write Set.*Parallelizable' "subagent-driven-development documents routing priority order" '^## '
assert_contains "skills/using-superpowers/SKILL.md" 'Serial SDD' "using-superpowers documents Serial SDD"
assert_contains "skills/using-superpowers/SKILL.md" 'Pipeline SDD' "using-superpowers documents Pipeline SDD"
assert_contains "skills/using-superpowers/SKILL.md" 'Parallel Dispatch' "using-superpowers documents Parallel Dispatch"
assert_section_contains "skills/dispatching-parallel-agents/SKILL.md" "## Overview" 'execution[- ]time' "dispatching-parallel-agents mentions execution-time routing in overview" '^## '
assert_section_contains "skills/dispatching-parallel-agents/SKILL.md" "## Overview" 'independent lane' "dispatching-parallel-agents mentions independent lanes in overview" '^## '
assert_section_contains "skills/dispatching-parallel-agents/SKILL.md" "## Overview" 'Write Set' "dispatching-parallel-agents mentions Write Set boundaries in overview" '^## '
assert_section_contains "skills/dispatching-parallel-agents/SKILL.md" "## Overview" 'Conflict Group' "dispatching-parallel-agents mentions Conflict Group boundaries in overview" '^## '
assert_section_contains "skills/dispatching-parallel-agents/SKILL.md" "## Overview" 'Pipeline SDD' "dispatching-parallel-agents mentions Pipeline SDD upgrade path in overview" '^## '
assert_contains "docs/README.codex.md" 'Pipeline SDD' "Codex README documents Pipeline SDD"
assert_contains "docs/README.codex.md" 'Execution Metadata' "Codex README documents Execution Metadata"
assert_contains "docs/README.codex.md" 'Parallel Dispatch' "Codex README documents Parallel Dispatch"

echo "All subagent pipeline routing prompt contract checks passed."
