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
  "openspec/specs/workflow-protocol-contracts/spec.md" \
  "## Requirements" \
  'proposal.*creates.*archive obligation|创建.*OpenSpec.*proposal.*必须.*归档|archive obligation.*OpenSpec change' \
  "workflow protocol spec defines that creating an OpenSpec proposal creates a mandatory archive obligation" \
  '^## '

assert_section_contains \
  "openspec/specs/transcript-based-validation/spec.md" \
  "## Requirements" \
  'skip.*archive.*after.*proposal|创建.*proposal.*后.*未归档.*测试.*失败|archive obligation' \
  "validation spec audits skipped archive after an OpenSpec proposal has been created" \
  '^## '

assert_section_contains \
  "skills/spec-governed-development/SKILL.md" \
  "## Lane Confirmation" \
  '创建 OpenSpec 提案.*后.*直到归档前都保持.*OpenSpec lane|proposal.*archive obligation|must be archived' \
  "spec-governed-development keeps a created OpenSpec change in the OpenSpec lane until archive" \
  '^## '

assert_section_contains \
  "skills/spec-governed-development/SKILL.md" \
  "## Handoff Guidance" \
  '不能跳过.*openspec-archive-change|must not skip `openspec-archive-change`|归档不是可选' \
  "spec-governed-development forbids skipping openspec-archive-change once an OpenSpec change reaches final completion" \
  '^## '

assert_section_contains \
  "skills/finishing-a-development-branch/SKILL.md" \
  "### Step 6: OpenSpec Archive Handoff" \
  'mandatory|required|必须进入 `openspec-archive-change`|不是可选' \
  "finishing flow treats archive follow-up as mandatory for a completed OpenSpec change" \
  '^### '

assert_section_contains \
  "skills/using-superpowers/SKILL.md" \
  "## Governance Routing" \
  'OpenSpec proposal.*archive obligation|创建 OpenSpec 提案.*归档义务|until archive' \
  "using-superpowers documents that a created OpenSpec proposal carries an archive obligation" \
  '^## '

assert_section_contains \
  "docs/README.codex.md" \
  "## Autonomous Continuation" \
  'created OpenSpec proposal.*must continue into `openspec-archive-change`|创建过 OpenSpec proposal.*必须.*openspec-archive-change|archive is not optional' \
  "Codex README documents that final completion of a created OpenSpec change must continue into archive" \
  '^## '

echo "All OpenSpec archive-obligation prompt contract checks passed."
