#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CURSOR_TOOLS_REFERENCE="skills/using-superpowers/references/cursor-tools.md"

normalize_stream() {
  tr '\r\n\t' '   ' | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//'
}

assert_file_contains() {
  local relative_file="$1"
  local pattern="$2"
  local description="$3"
  local target_file="$REPO_ROOT/$relative_file"

  if [[ ! -f "$target_file" ]]; then
    echo "FAIL: $description"
    echo "  Missing file: $relative_file"
    exit 1
  fi

  if normalize_stream < "$target_file" | rg -qi -- "$pattern"; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $relative_file"
    echo "  Pattern: $pattern"
    exit 1
  fi
}

assert_frontmatter_field() {
  local relative_file="$1"
  local field="$2"
  local expected_value="$3"
  local description="$4"
  local target_file="$REPO_ROOT/$relative_file"

  if [[ ! -f "$target_file" ]]; then
    echo "FAIL: $description"
    echo "  Missing file: $relative_file"
    exit 1
  fi

  local actual_value
  actual_value="$(
    awk -v field="$field" '
      NR == 1 && $0 == "---" { in_frontmatter = 1; next }
      in_frontmatter && $0 == "---" { exit }
      in_frontmatter {
        separator_index = index($0, ":")
        if (separator_index == 0) { next }

        key = substr($0, 1, separator_index - 1)
        value = substr($0, separator_index + 1)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)

        if (key == field) { print value; exit }
      }
    ' "$target_file"
  )"

  if [[ "$actual_value" == "$expected_value" ]]; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $relative_file"
    echo "  Field: $field"
    echo "  Expected: $expected_value"
    echo "  Actual: ${actual_value:-<missing>}"
    exit 1
  fi
}

# The tier table is what keeps reviewer dispatch off the default general-purpose agent.
assert_file_contains "$CURSOR_TOOLS_REFERENCE" \
  'reviewer model routing|## Reviewer Model Routing' \
  "cursor-tools reference documents reviewer model routing"

assert_file_contains "$CURSOR_TOOLS_REFERENCE" \
  'strong reviewer-grade model.*highest thinking budget|highest thinking budget.*Opus' \
  "tier 1 runs strong conversation models at their highest thinking budget"

assert_file_contains "$CURSOR_TOOLS_REFERENCE" \
  'gpt-5\.6-sol.*xhigh' \
  "tier 2 runs gpt-5.6-sol at xhigh"

assert_file_contains "$CURSOR_TOOLS_REFERENCE" \
  'fall back to `general-purpose`|general-purpose rather than a fast' \
  "tier 3 keeps general-purpose as the fallback rather than a fast/small model"

# The reviewers must NOT use inherit — it cannot raise a low-effort parent.
assert_file_contains "$CURSOR_TOOLS_REFERENCE" \
  'do NOT use `model: inherit`|not use `model: inherit`' \
  "cursor-tools reference explicitly rejects inherit for reviewers"

# Preset files are mandatory because inline dispatch is capped by the parent's effort.
assert_file_contains "$CURSOR_TOOLS_REFERENCE" \
  'caps the reasoning effort of subagents spawned on the fly|preset subagent file, never by negotiating a model' \
  "cursor-tools reference explains why preset subagent files are mandatory"

assert_file_contains "$CURSOR_TOOLS_REFERENCE" \
  'never dispatch a reviewer through `explore`' \
  "cursor-tools reference forbids dispatching reviewers through the explore subagent"

assert_file_contains "$CURSOR_TOOLS_REFERENCE" \
  'legacy request-based plan|max mode' \
  "cursor-tools reference records the plan and Max Mode conditions that force the fallback tier"

# Preset reviewer agents must exist and stay read-only.
for reviewer in plan-reviewer spec-reviewer code-reviewer; do
  assert_frontmatter_field "agents/${reviewer}.md" "name" "$reviewer" \
    "agents/${reviewer}.md declares a matching subagent name"
  assert_frontmatter_field "agents/${reviewer}.md" "readonly" "true" \
    "agents/${reviewer}.md runs read-only"
  assert_frontmatter_field "agents/${reviewer}.md" "model" "gpt-5.6-sol" \
    "agents/${reviewer}.md pins a concrete strong slug instead of inherit"

  # inherit must not reappear — it cannot raise a low-effort parent to reviewer grade.
  if normalize_stream < "$REPO_ROOT/agents/${reviewer}.md" | rg -qi -- 'model: inherit'; then
    echo "FAIL: agents/${reviewer}.md still uses model: inherit for reviewer dispatch"
    exit 1
  else
    echo "PASS: agents/${reviewer}.md does not fall back to model: inherit"
  fi

  # Each reviewer body must carry the thinking-budget guidance that follows the conversation model.
  assert_file_contains "agents/${reviewer}.md" \
    'highest thinking level available to the current conversation model|highest thinking budget' \
    "agents/${reviewer}.md instructs the reviewer to run at the conversation model's highest thinking budget"

  assert_file_contains "agents/${reviewer}.md" \
    'never run this review on a fast preset|fail-closed violation' \
    "agents/${reviewer}.md fail-closes against fast/explore presets"

  assert_file_contains "$CURSOR_TOOLS_REFERENCE" \
    "agents/${reviewer}\\.md" \
    "cursor-tools reference maps the ${reviewer} preset file"
done

# Reviewer prompt templates must point at the tier table instead of hardcoding general-purpose.
REVIEWER_TEMPLATES=(
  "skills/writing-plans/plan-document-reviewer-prompt.md"
  "skills/brainstorming/spec-document-reviewer-prompt.md"
  "skills/requesting-code-review/code-reviewer.md"
)

for template in "${REVIEWER_TEMPLATES[@]}"; do
  assert_file_contains "$template" \
    'using-superpowers/references/cursor-tools\.md' \
    "$template points at the Cursor reviewer model tiers"

  assert_file_contains "$template" \
    'never dispatch a reviewer through `explore`' \
    "$template warns against dispatching through the explore subagent"

  if normalize_stream < "$REPO_ROOT/$template" | rg -qi -- 'Task tool \(general-purpose\)'; then
    echo "FAIL: $template still hardcodes Task tool (general-purpose) for reviewer dispatch"
    exit 1
  else
    echo "PASS: $template no longer hardcodes general-purpose reviewer dispatch"
  fi
done

# using-superpowers must route Cursor sessions to the reference before dispatching.
assert_file_contains "skills/using-superpowers/SKILL.md" \
  'references/cursor-tools\.md' \
  "using-superpowers lists the Cursor tool mapping reference"

assert_file_contains "skills/using-superpowers/SKILL.md" \
  'cursor users must read `references/cursor-tools\.md` before dispatching a reviewer' \
  "using-superpowers requires reading the Cursor reference before reviewer dispatch"

echo "All Cursor reviewer model routing checks passed."
