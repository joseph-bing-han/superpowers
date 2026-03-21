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

assert_not_contains() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if normalize_stream < "$REPO_ROOT/$file" | rg -qi -- "$pattern"; then
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Forbidden pattern: $pattern"
    exit 1
  else
    echo "PASS: $description"
  fi
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
    echo "  Forbidden pattern: $pattern"
    exit 1
  else
    echo "PASS: $description"
  fi
}

assert_section_contains "skills/using-superpowers/SKILL.md" "## User Choice Formatting" "use structured numbered choices by default" "global rule defaults to structured numbered choices" '^## '
assert_section_contains "skills/using-superpowers/SKILL.md" "## User Choice Formatting" 'Put the recommended option in slot `1`' "global rule reserves slot 1 for the recommendation" '^## '
assert_section_contains "skills/using-superpowers/SKILL.md" "## User Choice Formatting" 'use `request_user_input` by default when available' "global rule defaults non-dangerous enumerable choices to request_user_input" '^## '
assert_section_contains "skills/using-superpowers/SKILL.md" "## User Choice Formatting" 'tool-backed choice UI instead of a prose-only numbered reply prompt' "global rule rejects prose-only numbered replies when tool-backed UI is available" '^## '
assert_section_contains "skills/using-superpowers/SKILL.md" "## User Choice Formatting" 'Keep a final free-text fallback when the scenario allows additional input beyond the listed choices\.?' "global rule keeps a free-text fallback when allowed" '^## '
assert_section_contains "skills/using-superpowers/SKILL.md" "## User Choice Formatting" 'use two-stage confirmation by default: a numbered choice first, then a lettered confirmation step' "dangerous actions default to two-stage confirmation" '^## '
assert_section_contains "skills/using-superpowers/SKILL.md" "## User Choice Formatting" 'show the exact text as copyable text' "typed confirmations show exact copyable text" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "## Presenting the design:" 'When `request_user_input` is available and the approval choices are enumerable, use it instead of asking for a prose-only `reply 1/2/3` response\.' "brainstorming design approvals use request_user_input when available" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "## Presenting the design:" 'Keep a final free-text path only for new feedback that does not fit the listed approval choices\.' "brainstorming design approvals keep free-text only for extra feedback" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "## User Review Gate:" 'When `request_user_input` is available and the next steps are enumerable, use it for this review gate instead of a prose-only numbered reply prompt\.' "brainstorming artifact review gate uses request_user_input when available" '^## '
assert_section_not_contains "skills/brainstorming/SKILL.md" "## Presenting the design:" 'Reply with `1`, `2`, or `3`\.' "brainstorming design approvals do not fall back to prose-only reply 1/2/3 prompts" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Execution Handoff" 'When `request_user_input` is available, use it for this execution handoff because the choices are known and enumerable\.' "plan execution handoff uses request_user_input when available" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Execution Handoff" 'Keep a final free-text path only for requirements that do not fit the listed execution choices\.' "plan execution handoff keeps free-text only for extra requirements" '^## '
assert_section_not_contains "skills/writing-plans/SKILL.md" "## Execution Handoff" 'Reply with `1`, `2`, or `3`\.' "plan execution handoff does not degrade to prose-only reply 1/2/3 prompts" '^## '
assert_section_contains "skills/executing-plans/SKILL.md" "## When to Stop and Ask for Help" "If concerns or blockers need human input, present numbered options instead of open-ended questions\\." "executor guidance uses a section-scoped numbered-options contract"
assert_section_contains "skills/executing-plans/SKILL.md" "## The Process" 'If concerns need human input and the next actions are already known, use `request_user_input` when available instead of a prose-only numbered reply prompt\.' "executor plan review concerns use request_user_input when available" '^## '
assert_section_contains "skills/executing-plans/SKILL.md" "## When to Stop and Ask for Help" 'If concerns, blockers, or known next actions need human input and the choices are enumerable, use `request_user_input` when available\.' "executor blockers and next actions use request_user_input when available" '^## '
assert_section_contains "skills/executing-plans/SKILL.md" "## When to Stop and Ask for Help" 'Keep a final free-text path only for guidance that does not fit the listed options\.' "executor blocker flow keeps free-text only for additional guidance" '^## '
assert_section_not_contains "skills/executing-plans/SKILL.md" "## When to Stop and Ask for Help" 'Reply with `1`, `2`, or `3`\.' "executor blocker flow does not degrade to prose-only reply 1/2/3 prompts" '^## '
assert_contains "skills/finishing-a-development-branch/SKILL.md" 'Reply with `1`, `2`, or `3`\.' "finishing flow uses explicit numeric replies for non-destructive options"
assert_contains "skills/finishing-a-development-branch/SKILL.md" "Type 'discard' to confirm\\." "dangerous actions still require typed confirmation"
assert_not_contains "skills/finishing-a-development-branch/SKILL.md" "What would you like to do\\?" "finishing flow no longer uses open-ended completion prompt"
assert_not_contains "skills/finishing-a-development-branch/SKILL.md" "Which option\\?" "finishing flow no longer uses open-ended option prompt"
assert_not_contains "skills/using-superpowers/SKILL.md" "only when the choice cannot be fully enumerated" "global rule drops the old restrictive free-text wording"
assert_not_contains "skills/using-superpowers/SKILL.md" "Keep typed confirmations for dangerous or destructive actions" "global rule drops the old typed-confirmation wording"
assert_section_not_contains "skills/using-superpowers/SKILL.md" "## User Choice Formatting" 'optional|plain text is fine|avoid two-stage|when convenient' "global rule section does not weaken the contract" '^## '
assert_section_contains "docs/README.codex.md" "## Choice-Based Interaction" 'Put the recommended option in slot `1`' "Codex docs reserve slot 1 for the recommendation"
assert_section_contains "docs/README.codex.md" "## Choice-Based Interaction" 'Prefer 2-4 options' "Codex docs prefer 2-4 options"
assert_section_contains "docs/README.codex.md" "## Choice-Based Interaction" 'use `request_user_input` by default when available' "Codex docs default non-dangerous enumerable choices to request_user_input"
assert_section_contains "docs/README.codex.md" "## Choice-Based Interaction" 'tool-backed choice UI instead of a prose-only numbered reply prompt' "Codex docs reject prose-only numbered replies when tool-backed UI is available"
assert_section_contains "docs/README.codex.md" "## Choice-Based Interaction" 'Keep a final free-text fallback when the scenario allows additional input beyond the listed choices\.?' "Codex docs keep a free-text fallback when allowed"
assert_section_contains "docs/README.codex.md" "## Choice-Based Interaction" 'use two-stage confirmation by default: a numbered choice first, then a lettered confirmation step' "Codex docs default dangerous enumerable choices to two-stage confirmation"
assert_section_contains "docs/README.codex.md" "## Choice-Based Interaction" 'show the exact text as copyable text' "Codex docs require exact copyable typed confirmation text"
assert_section_not_contains "docs/README.codex.md" "## Choice-Based Interaction" 'optional|plain text is fine|avoid two-stage|when convenient' "Codex docs section does not weaken the contract"
assert_section_contains "docs/README.codex.md" "## Choice-Based Interaction" "raw single-key submit.*depends on the Codex input layer|depends on the Codex input layer.*raw single-key submit" "Codex docs mention the raw single-key input boundary"

echo "All numeric-choice prompt contract checks passed."
