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

assert_file_exists() {
  local relative_file="$1"
  local description="$2"

  if [[ -f "$REPO_ROOT/$relative_file" ]]; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  Missing file: $relative_file"
    exit 1
  fi
}

assert_files_identical() {
  local relative_a="$1"
  local relative_b="$2"
  local description="$3"

  if cmp -s "$REPO_ROOT/$relative_a" "$REPO_ROOT/$relative_b"; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  Files differ:"
    echo "    - $relative_a"
    echo "    - $relative_b"
    exit 1
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

assert_file_exists \
  "skills/spec-governed-development/SKILL.md" \
  "spec-governed-development is shipped inside the installable skills directory"

assert_section_contains \
  "skills/using-superpowers/SKILL.md" \
  "## Governance Routing" \
  'request_user_input.*OpenSpec proposal|OpenSpec proposal.*request_user_input|在生成.*plans.*specs.*前.*询问.*OpenSpec' \
  "using-superpowers asks about creating an OpenSpec proposal before ordinary plan/spec docs are written for important changes" \
  '^## '

assert_section_contains \
  "skills/spec-governed-development/SKILL.md" \
  "## Lane Confirmation" \
  'request_user_input.*创建 OpenSpec 提案|创建 OpenSpec 提案.*request_user_input|OpenSpec proposal.*before creating.*plan|before creating.*spec' \
  "spec-governed-development requires a tool-backed confirmation before falling back to ordinary plan/spec docs" \
  '^## '

assert_section_contains \
  "skills/spec-governed-development/SKILL.md" \
  "## Lane Confirmation" \
  '1\..*创建 OpenSpec 提案.*Recommended.*2\..*(继续仅生成常规设计/计划文档|continue with regular design/plan docs)' \
  "spec-governed-development offers a recommended OpenSpec proposal path and an explicit ordinary-docs fallback" \
  '^## '

assert_section_contains \
  "skills/brainstorming/SKILL.md" \
  "## Document Path Selection" \
  'docs/specs|docs/superpowers/specs' \
  "brainstorming prefers a structured spec directory instead of bare docs root" \
  '^## '

assert_section_contains \
  "skills/brainstorming/SKILL.md" \
  "## Document Path Selection" \
  'do not infer bare `docs/`|不要把 bare `docs/` 根目录当成默认落点|legacy docs.*does not override' \
  "brainstorming forbids treating legacy docs in bare docs root as a spec-path override" \
  '^## '

assert_section_contains \
  "skills/brainstorming/SKILL.md" \
  "## Document Path Selection" \
  'OpenSpec lane.*do not create a parallel design doc|不要再额外创建平行设计文档' \
  "brainstorming blocks duplicate design docs outside OpenSpec artifacts by default in OpenSpec lane" \
  '^## '

assert_section_contains \
  "skills/writing-plans/SKILL.md" \
  "## Document Path Selection" \
  'docs/plans|docs/superpowers/plans' \
  "writing-plans prefers a structured plan directory instead of bare docs root" \
  '^## '

assert_section_contains \
  "skills/writing-plans/SKILL.md" \
  "## Document Path Selection" \
  'do not infer bare `docs/`|不要把 bare `docs/` 根目录当成默认落点|legacy docs.*does not override' \
  "writing-plans forbids treating legacy docs in bare docs root as a plan-path override" \
  '^## '

assert_section_contains \
  "docs/README.codex.md" \
  "## Usage" \
  'OpenSpec proposal.*before ordinary design/plan docs|important change.*request_user_input.*OpenSpec' \
  "Codex README documents the upfront OpenSpec proposal confirmation for important changes" \
  '^## '

assert_section_contains \
  ".codex/INSTALL.md" \
  "## Installation" \
  'discoverable skills.*including `spec-governed-development`.*`skills/`|all discoverable skills.*`~/.codex/superpowers/skills`' \
  "install guide documents that discoverable skills, including spec-governed-development, live under skills/" \
  '^## '

assert_section_contains \
  "docs/README.codex.md" \
  "## How It Works" \
  'discoverable skills.*including `spec-governed-development`.*`skills/`|all discoverable skills.*`~/.codex/superpowers/skills`' \
  "Codex README documents that discoverable skills, including spec-governed-development, live under skills/" \
  '^## '

echo "All OpenSpec entry and document-path prompt contract checks passed."
