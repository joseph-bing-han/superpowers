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
assert_section_contains "skills/using-superpowers/SKILL.md" "## User Choice Formatting" 'use two-stage confirmation by default: a numbered choice first, then a second numbered confirmation step' "dangerous actions default to two-stage numeric confirmation" '^## '
assert_section_contains "skills/using-superpowers/SKILL.md" "## User Choice Formatting" 'put the final destructive confirmation in slot `2` of the second step' "global rule protects the final destructive confirmation behind slot 2 in Stage 2" '^## '
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
assert_section_contains "skills/finishing-a-development-branch/SKILL.md" "### Step 3: Present Options" 'Reply with `1`, `2`, or `3`\.' "finishing flow uses explicit numeric replies for non-destructive options" '^### '
assert_section_contains "skills/finishing-a-development-branch/SKILL.md" "### Step 3: Present Options" 'Reply with `4` to enter the discard confirmation flow\.' "finishing flow explicitly routes option 4 into the discard confirmation flow" '^### '
assert_section_contains "skills/finishing-a-development-branch/SKILL.md" "### Step 3: Present Options" 'When `request_user_input` is available and the choices are enumerable, use it for the main menu and both destructive confirmation stages instead of a prose-only reply prompt\.' "finishing flow prefers request_user_input for enumerable stages" '^### '
assert_section_contains "skills/finishing-a-development-branch/SKILL.md" "#### Option 4: Discard" 'Use a two-stage destructive confirmation state machine: both stages use numbered choices\.' "finishing flow documents two-stage numeric destructive confirmation" '^(###|####) '
assert_section_contains "skills/finishing-a-development-branch/SKILL.md" "#### Option 4: Discard" '1\. Continue toward the final discard confirmation step' "finishing flow Stage 1 includes the continue option text" '^(###|####) '
assert_section_contains "skills/finishing-a-development-branch/SKILL.md" "#### Option 4: Discard" '2\. Cancel' "finishing flow Stage 1 includes the cancel option text" '^(###|####) '
assert_section_contains "skills/finishing-a-development-branch/SKILL.md" "#### Option 4: Discard" '3\. Input other feedback or requirements' "finishing flow Stage 1 includes the free-input option text" '^(###|####) '
assert_section_contains "skills/finishing-a-development-branch/SKILL.md" "#### Option 4: Discard" 'Text fallback for Stage 1: Reply with `1`, `2`, or `3`\.' "finishing flow Stage 1 fallback is explicitly locked to 1/2/3" '^(###|####) '
assert_section_contains "skills/finishing-a-development-branch/SKILL.md" "#### Option 4: Discard" '1\. Cancel and return to the previous step' "finishing flow Stage 2 includes the safe-return option text" '^(###|####) '
assert_section_contains "skills/finishing-a-development-branch/SKILL.md" "#### Option 4: Discard" '2\. Confirm discard now' "finishing flow Stage 2 includes the confirm option text" '^(###|####) '
assert_section_contains "skills/finishing-a-development-branch/SKILL.md" "#### Option 4: Discard" '3\. Input other feedback or requirements' "finishing flow Stage 2 includes the free-input option text" '^(###|####) '
assert_section_contains "skills/finishing-a-development-branch/SKILL.md" "#### Option 4: Discard" 'Text fallback for Stage 2: Reply with `1`, `2`, or `3`\.' "finishing flow keeps the second destructive stage numeric as well" '^(###|####) '
assert_section_contains "skills/finishing-a-development-branch/SKILL.md" "#### Option 4: Discard" 'If Stage 2 `2` is chosen:' "finishing flow exposes a single explicit execution entry point" '^(###|####) '
assert_not_contains "skills/finishing-a-development-branch/SKILL.md" '((type|reply( with)?|enter) [^[:alnum:]]{0,2}discard[^[:alnum:]]{0,2}((to|and) )?(confirm|continue|proceed))' "finishing flow no longer exposes typed discard confirmation semantics"
assert_section_contains "skills/finishing-a-development-branch/SKILL.md" "#### Option 4: Discard" 'Choosing Stage 1 `2` returns to the parent flow; if there is no parent flow, it safely ends the destructive subflow without making changes\.' "Stage 1 cancel safely exits the destructive subflow" '^(###|####) '
assert_section_contains "skills/finishing-a-development-branch/SKILL.md" "#### Option 4: Discard" 'Choosing Stage 2 `1` returns to Stage 1\.' "Stage 2 slot 1 safely returns to the previous step" '^(###|####) '
assert_section_contains "skills/finishing-a-development-branch/SKILL.md" "#### Option 4: Discard" 'Choosing Stage 1 `3` or Stage 2 `3` treats the input as additional feedback or a help request, then returns to the same step without executing or canceling anything\.' "free-input path never executes or cancels the destructive flow" '^(###|####) '
assert_section_contains "skills/finishing-a-development-branch/SKILL.md" "#### Option 4: Discard" 'If the user enters an invalid token or submits empty input in the text fallback, stay on the current step, show the valid tokens again, and do not execute or cancel anything\.' "invalid or empty fallback input does not advance or cancel the destructive flow" '^(###|####) '
assert_section_contains "skills/finishing-a-development-branch/SKILL.md" "#### Option 4: Discard" 'Only valid tokens move the state machine forward\.' "only valid tokens move the destructive state machine forward" '^(###|####) '
assert_section_not_contains "skills/finishing-a-development-branch/SKILL.md" "#### Option 4: Discard" 'a\.|b\.|c\.' "finishing flow no longer uses lettered options in the second destructive stage" '^(###|####) '
assert_section_not_contains "skills/finishing-a-development-branch/SKILL.md" "#### Option 4: Discard" 'Review impact' "finishing flow no longer exposes the review-impact branch" '^(###|####) '
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
assert_section_contains "docs/README.codex.md" "## Choice-Based Interaction" 'use two-stage confirmation by default: a numbered choice first, then a second numbered confirmation step' "Codex docs default dangerous enumerable choices to two-stage numeric confirmation"
assert_section_contains "docs/README.codex.md" "## Choice-Based Interaction" 'put the final destructive confirmation in slot `2` of the second step' "Codex docs keep the final destructive confirmation behind slot 2"
assert_section_contains "docs/README.codex.md" "## Choice-Based Interaction" 'show the exact text as copyable text' "Codex docs require exact copyable typed confirmation text"
assert_section_not_contains "docs/README.codex.md" "## Choice-Based Interaction" 'optional|plain text is fine|avoid two-stage|when convenient' "Codex docs section does not weaken the contract"
assert_section_contains "docs/README.codex.md" "## Choice-Based Interaction" "raw single-key submit.*depends on the Codex input layer|depends on the Codex input layer.*raw single-key submit" "Codex docs mention the raw single-key input boundary"
assert_section_contains "docs/testing.md" "## Numeric Choice Smoke Tests" 'These smoke tests must be run in a real session because the choice UI only appears when the assistant actually calls `request_user_input`\.' "testing docs require real request_user_input-backed smoke sessions" '^## '
assert_section_contains "docs/testing.md" "## Numeric Choice Smoke Tests" 'Smoke Test A: A non-dangerous final-step or next-step prompt must trigger `request_user_input` for real instead of falling back to a prose-only numbered reply\.' "testing docs cover the non-dangerous request_user_input smoke test" '^## '
assert_section_contains "docs/testing.md" "## Numeric Choice Smoke Tests" 'Smoke Test B: A multi-question interaction must keep the choice UI across consecutive questions and must not degrade into plain text prompts\.' "testing docs cover the multi-question choice UI smoke test" '^## '
assert_section_contains "docs/testing.md" "## Numeric Choice Smoke Tests" 'Smoke Test C: A dangerous two-stage confirmation must use numbered choices in both stages, with the final confirmation in slot `2` of Stage 2\.' "testing docs cover the dangerous two-stage numeric confirmation smoke test" '^## '
assert_section_contains "docs/testing.md" "### Required Evidence" 'Transcript / tool call record is required evidence for every numeric-choice smoke test run\.' "testing docs require transcript or tool call record evidence" '^(##|###) '
assert_section_contains "docs/testing.md" "### Optional Evidence" 'Screenshot / operator notes are optional evidence when they help explain UI state or operator observations\.' "testing docs describe optional screenshot and operator notes evidence" '^(##|###) '
assert_section_contains "docs/testing.md" "### Acceptance Mapping" 'skills/using-superpowers/SKILL\.md' "testing docs map using-superpowers into numeric-choice smoke coverage" '^(##|###) '
assert_section_contains "docs/testing.md" "### Acceptance Mapping" 'skills/brainstorming/SKILL\.md' "testing docs map brainstorming into numeric-choice smoke coverage" '^(##|###) '
assert_section_contains "docs/testing.md" "### Acceptance Mapping" 'skills/writing-plans/SKILL\.md' "testing docs map writing-plans into numeric-choice smoke coverage" '^(##|###) '
assert_section_contains "docs/testing.md" "### Acceptance Mapping" 'skills/executing-plans/SKILL\.md' "testing docs map executing-plans into numeric-choice smoke coverage" '^(##|###) '
assert_section_contains "docs/testing.md" "### Acceptance Mapping" 'skills/finishing-a-development-branch/SKILL\.md' "testing docs map finishing-a-development-branch into numeric-choice smoke coverage" '^(##|###) '
assert_section_contains "docs/testing.md" "### Latest Numeric Choice Smoke Evidence" 'A \| .*request_user_input.* \| [^|]+' "testing docs include a populated evidence row for smoke test A" '^(##|###) '
assert_section_contains "docs/testing.md" "### Latest Numeric Choice Smoke Evidence" 'B \| .*consecutive choice UI questions.* \| [^|]+' "testing docs include a populated evidence row for smoke test B" '^(##|###) '
assert_section_contains "docs/testing.md" "### Latest Numeric Choice Smoke Evidence" 'C \| .*numeric Stage 1 and numeric Stage 2 confirmation.* \| [^|]+' "testing docs include a populated evidence row for smoke test C" '^(##|###) '

echo "All numeric-choice prompt contract checks passed."
