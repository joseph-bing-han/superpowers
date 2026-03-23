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

assert_section_contains \
  "skills/using-superpowers/SKILL.md" \
  "## Governance Routing" \
  'bug.*existing OpenSpec|existing OpenSpec.*bug|active OpenSpec change.*bug|bugfix.*OpenSpec-governed work' \
  "using-superpowers routes governed bugfixes back through existing OpenSpec context before fixing" \
  '^## '

assert_section_contains \
  "skills/systematic-debugging/SKILL.md" \
  "### Phase 1: Root Cause Investigation" \
  'OpenSpec.*proposal\.md.*design\.md.*tasks\.md|proposal\.md.*design\.md.*tasks\.md.*OpenSpec|existing change.*proposal\.md.*design\.md.*tasks\.md' \
  "systematic-debugging restores existing OpenSpec proposal/design/tasks context before governed fixes" \
  '^### '

assert_section_contains \
  "spec-governed-development/SKILL.md" \
  "## Decision Rule" \
  'bug.*existing change|existing change.*bug|active OpenSpec change.*bug|bugfix.*inherits.*OpenSpec lane' \
  "spec-governed-development keeps bugfixes inside an existing OpenSpec change when they belong there" \
  '^## '

assert_section_contains \
  "spec-governed-development/SKILL.md" \
  "## Handoff Guidance" \
  'openspec-apply-change.*auto-continue|auto-continue.*openspec-apply-change|直接进入 `openspec-apply-change`' \
  "spec-governed-development auto-continues into openspec-apply-change when the active change still has work remaining" \
  '^## '

assert_section_contains \
  "spec-governed-development/SKILL.md" \
  "## Handoff Guidance" \
  'openspec-archive-change.*auto-continue|auto-continue.*openspec-archive-change|直接进入 `openspec-archive-change`' \
  "spec-governed-development auto-continues into openspec-archive-change when the active change is complete and archive-compatible" \
  '^## '

assert_section_contains \
  "skills/finishing-a-development-branch/SKILL.md" \
  "### Step 6: OpenSpec Archive Handoff" \
  'auto-continue.*openspec-archive-change|continue directly into `openspec-archive-change`|直接进入 `openspec-archive-change`' \
  "finishing flow escalates a completed OpenSpec merge result into direct archive follow-up instead of recommendation-only prose" \
  '^### '

assert_section_contains \
  "docs/README.codex.md" \
  "## Autonomous Continuation" \
  'OpenSpec.*openspec-apply-change.*openspec-archive-change|openspec-apply-change.*openspec-archive-change.*OpenSpec|active OpenSpec change.*apply.*archive' \
  "Codex README documents that known OpenSpec apply/archive steps are part of autonomous continuation" \
  '^## '

echo "All OpenSpec governed continuation prompt contract checks passed."
