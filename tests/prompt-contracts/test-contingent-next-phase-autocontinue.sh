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
  "## Autonomous Continuation" \
  '如果没问题就继续下一阶段|如果设计合理就开始实现|if this is sound, continue to phase 2|positive judgment counts as prior authorization|contingent authorization' \
  "global autonomous-continuation contract handles contingent next-phase authorization" \
  '^## '

assert_section_contains \
  "skills/using-superpowers/SKILL.md" \
  "## Autonomous Continuation" \
  '最终判断|现在可以把结论更新为|项目现在可以稳妥进入|do not stop after announcing that judgment' \
  "global autonomous-continuation contract forbids free-text conclusion blocks after contingent authorization" \
  '^## '

assert_section_contains \
  "skills/brainstorming/SKILL.md" \
  "## Presenting the design:" \
  '如果没问题就继续下一阶段|如果设计合理就开始实现|positive judgment counts as auto-continue|contingent authorization means auto-continue' \
  "brainstorming treats contingent next-phase authorization as auto-continue" \
  '^## '

assert_section_contains \
  "skills/brainstorming/SKILL.md" \
  "## Presenting the design:" \
  '最终判断|现在可以把结论更新为|可以进入下一阶段|do not end that checkpoint with headings like' \
  "brainstorming forbids final-judgment prose endings when the next phase is already authorized" \
  '^## '

assert_section_contains \
  "docs/README.codex.md" \
  "## Autonomous Continuation" \
  '如果没问题就继续下一阶段|如果设计合理就开始实现|if this is sound, continue to phase 2|positive judgment counts as prior authorization|contingent authorization' \
  "Codex README mirrors contingent next-phase authorization handling" \
  '^## '

assert_section_contains \
  "docs/README.codex.md" \
  "## Autonomous Continuation" \
  '最终判断|现在可以把结论更新为|项目现在可以稳妥进入|do not stop after announcing that judgment' \
  "Codex README mirrors the ban on free-text final-judgment endings after contingent authorization" \
  '^## '

echo "All contingent next-phase auto-continue checks passed."
