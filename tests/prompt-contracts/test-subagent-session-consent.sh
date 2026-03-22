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

assert_section_contains "skills/using-superpowers/SKILL.md" "## Session-Scoped Subagent Consent" 'session-scoped consent state.*unknown.*granted.*denied|unknown.*granted.*denied.*session-scoped consent state' "session-scoped consent model defines unknown, granted, and denied states" '^## '
assert_section_contains "skills/using-superpowers/SKILL.md" "## Session-Scoped Subagent Consent" 'when subagents would materially help.*state is unknown.*request_user_input.*ask once|request_user_input.*ask once.*when subagents would materially help.*state is unknown' "unknown state requires a one-time request_user_input prompt when subagents would materially help" '^## '
assert_section_contains "skills/using-superpowers/SKILL.md" "## Session-Scoped Subagent Consent" 'do not silently downgrade before asking|never silently downgrade before asking' "contract forbids silently downgrading before the first consent request" '^## '
assert_section_contains "skills/using-superpowers/SKILL.md" "## Session-Scoped Subagent Consent" 'do not downgrade first and explain later|never downgrade first and explain later' "contract forbids downgrading first and explaining later" '^## '
assert_section_contains "skills/using-superpowers/SKILL.md" "## Session-Scoped Subagent Consent" 'after granted or denied.*reuse that state for the rest of the session|reuse that state for the rest of the session.*after granted or denied' "granted or denied consent is reused for the rest of the session" '^## '
assert_section_not_contains "skills/using-superpowers/SKILL.md" "## Session-Scoped Subagent Consent" 'optional|when convenient|if you prefer|may silently downgrade' "session-scoped consent section does not weaken the contract" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "**Design Artifact Review Loop:**" 'if a reviewer subagent would materially help and the session consent state is unknown, use `request_user_input` to ask once before dispatching it' "brainstorming review loop asks once before dispatching a helpful reviewer subagent when consent is unknown" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "**Design Artifact Review Loop:**" 'if the state is `granted`, dispatch the reviewer subagent' "brainstorming review loop dispatches reviewer subagent after consent is granted" '^## '
assert_section_contains "skills/brainstorming/SKILL.md" "**Design Artifact Review Loop:**" 'if the state is `denied`, review inline and do not ask again in the same session' "brainstorming review loop falls back to inline review without re-asking after denial" '^## '
assert_section_not_contains "skills/brainstorming/SKILL.md" "**Design Artifact Review Loop:**" 'because you did not explicitly authorize subagents|because subagents were not explicitly authorized' "brainstorming review loop avoids post-hoc missing-authorization explanations" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Plan Review Loop" 'if a reviewer subagent would materially help and the session consent state is unknown, use `request_user_input` to ask once before dispatching it' "writing-plans review loop asks once before dispatching a helpful reviewer subagent when consent is unknown" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Plan Review Loop" 'if the state is `granted`, dispatch the reviewer subagent' "writing-plans review loop dispatches reviewer subagent after consent is granted" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Plan Review Loop" 'if the state is `denied`, review inline and do not ask again in the same session' "writing-plans review loop falls back to inline review without re-asking after denial" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Execution Handoff" 'Choosing `Subagent-Driven` counts as explicit session-scoped consent to use implementation subagents for the rest of the session' "writing-plans treats Subagent-Driven handoff as explicit session consent" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Execution Handoff" 'Treat that choice as setting the shared session consent state to `granted` for implementation subagents' "writing-plans promotes Subagent-Driven into a shared session consent state transition" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Execution Handoff" 'Do not immediately ask again for the same subagent consent after that choice' "writing-plans forbids re-asking after Subagent-Driven consent" '^## '
assert_section_contains "docs/README.codex.md" "## Session-Scoped Subagent Consent" 'session-scoped subagent consent as `unknown`, `granted`, or `denied`' "Codex README documents the unknown/granted/denied session consent states" '^## '
assert_section_contains "docs/README.codex.md" "## Session-Scoped Subagent Consent" 'when a reviewer or implementer subagent would materially help and the state is `unknown`, the workflow should ask once through `request_user_input` before dispatching it' "Codex README documents the ask-once trigger for unknown consent state" '^## '
assert_section_contains "docs/README.codex.md" "## Session-Scoped Subagent Consent" 'It should not silently downgrade first or explain the missing authorization after the fact' "Codex README forbids downgrade-first missing-authorization behavior" '^## '
assert_section_contains "docs/README.codex.md" "## Session-Scoped Subagent Consent" 'If that session-level consent is `granted`, those workflows can keep using helpful subagents without asking again for the rest of the session' "Codex README says granted consent is reused for the rest of the session" '^## '
assert_section_contains "docs/README.codex.md" "## Session-Scoped Subagent Consent" 'If it is `denied`, the workflow stays inline for the rest of the session unless the user explicitly reopens the choice' "Codex README says denied consent keeps the workflow inline for the rest of the session" '^## '
assert_section_contains "docs/README.codex.md" "## Session-Scoped Subagent Consent" 'choosing `Subagent-Driven` sets the shared session consent state to `granted` for implementation subagents in the rest of the session' "Codex README documents that Subagent-Driven performs the granted state transition" '^## '

echo "All subagent session-consent prompt contract checks passed."
