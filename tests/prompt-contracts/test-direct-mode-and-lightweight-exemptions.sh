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

assert_file_contains() {
  local relative_file="$1"
  local pattern="$2"
  local description="$3"
  local content

  content="$(cat "$REPO_ROOT/$relative_file")"

  if printf '%s' "$content" | normalize_stream | rg -qi -- "$pattern"; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $relative_file"
    echo "  Pattern: $pattern"
    exit 1
  fi
}

assert_file_not_contains() {
  local relative_file="$1"
  local pattern="$2"
  local description="$3"
  local content

  content="$(cat "$REPO_ROOT/$relative_file")"

  if printf '%s' "$content" | normalize_stream | rg -qi -- "$pattern"; then
    echo "FAIL: $description"
    echo "  File: $relative_file"
    echo "  Forbidden pattern: $pattern"
    exit 1
  else
    echo "PASS: $description"
  fi
}

assert_section_contains() {
  local relative_file="$1"
  local heading="$2"
  local pattern="$3"
  local description="$4"
  local stop_pattern="${5:-^(##|###) }"
  local content

  content="$(extract_section "$REPO_ROOT/$relative_file" "$heading" "$stop_pattern")"

  if [[ -z "$content" ]]; then
    echo "FAIL: $description"
    echo "  File: $relative_file"
    echo "  Missing section: $heading"
    exit 1
  fi

  if printf '%s' "$content" | normalize_stream | rg -qi -- "$pattern"; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $relative_file"
    echo "  Section: $heading"
    echo "  Pattern: $pattern"
    exit 1
  fi
}

assert_file_contains \
  ".codex/instruction.md" \
  'Direct Mode.*default|default.*Direct Mode|workflow keyword' \
  "Codex bootstrap defines Direct Mode as the default unless explicit workflow intent is present"

assert_file_contains \
  ".codex/instruction.md" \
  'terminal-choice.*workflow mode|workflow-mode.*terminal-choice|direct replies.*must not.*request_user_input|轻量子任务.*不得.*request_user_input' \
  "Codex bootstrap limits terminal-choice to workflow-mode boundaries"

assert_section_contains \
  "skills/using-superpowers/SKILL.md" \
  "## Direct Mode and Lightweight Exemptions" \
  'explicit skill name|workflow keyword|Direct Mode|默认.*Direct Mode' \
  "using-superpowers requires explicit workflow intent before entering workflow mode" \
  '^## '

assert_section_contains \
  "skills/using-superpowers/SKILL.md" \
  "## Direct Mode and Lightweight Exemptions" \
  'simple question|translation|text-only|copy-only|文案修改|文本修改|注释|文档' \
  "using-superpowers lists lightweight tasks that bypass workflow" \
  '^## '

assert_section_contains \
  "skills/using-superpowers/SKILL.md" \
  "## Direct Mode and Lightweight Exemptions" \
  'downgrade|direct handling|降级|workflow.*子任务' \
  "using-superpowers allows active workflows to downgrade lightweight subtasks to direct handling" \
  '^## '

assert_section_contains \
  "skills/brainstorming/SKILL.md" \
  "## Lightweight Task Bypass" \
  'ordinary question|translation|text-only|copy-only|普通问答|翻译|文本修改|文案修改' \
  "brainstorming explicitly skips lightweight direct-mode tasks" \
  '^## '

assert_section_contains \
  "skills/test-driven-development/SKILL.md" \
  "## When to Use" \
  'text-only|copy-only|translation|docs-comments|注释|文档|不改变行为' \
  "TDD exemptions include non-behavioral text changes" \
  '^## '

assert_section_contains \
  "docs/README.codex.md" \
  "## Usage" \
  'explicit skill|workflow keyword|Direct Mode|普通问答.*不.*workflow|简单问答.*不.*workflow' \
  "Codex README documents explicit workflow entry and direct-mode defaults" \
  '^## '

assert_file_not_contains \
  "README.md" \
  'skills trigger automatically|automatically invoke the relevant superpowers skill' \
  "README no longer promises universal automatic skill triggering"

echo "All direct-mode and lightweight-exemption prompt contract checks passed."
