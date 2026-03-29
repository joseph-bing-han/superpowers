#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CANONICAL_SENTENCE='For checkpoint, handoff, and terminal-choice nodes driven by `request_user_input`, the `request_user_input` call and its transcript event are the machine contract; surrounding prose is explanatory only.'
CANONICAL_CARRIER_PATTERN='canonical machine-readable carrier|canonical carrier'
STRUCTURED_CARRIER_PRIORITY_PATTERN='prefer (a )?structured carrier|structured carrier.*优先|优先.*structured carrier'
VISIBLE_TAIL_FALLBACK_PATTERN='visible tail block.*fallback|tail block.*only a fallback|用户可见.*tail block.*fallback|用户可见.*tail block.*回退'
LEGACY_VISIBLE_TAIL_ONLY_DRIFT_PATTERN='final four lines|visible to the user|must still appear in the tail|最后[[:space:]]*4 行|对用户可见|必须显示在末尾|last 4 non-empty lines before the next machine action must be (the|that) canonical `ENDGATE_\*` packet'

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

extract_matching_line() {
  local file="$1"
  local pattern="$2"
  rg -F -- "$pattern" "$file" | head -n 1
}

assert_section_contains() {
  local heading="$1"
  local pattern="$2"
  local description="$3"
  local stop_pattern="${4:-^(##|###) }"
  assert_file_section_contains "docs/testing.md" "$heading" "$pattern" "$description" "$stop_pattern"
}

assert_section_not_contains() {
  local heading="$1"
  local pattern="$2"
  local description="$3"
  local stop_pattern="${4:-^(##|###) }"
  local target_file="$REPO_ROOT/docs/testing.md"
  local content

  content="$(extract_section "$target_file" "$heading" "$stop_pattern")"

  if [[ -z "$content" ]]; then
    echo "FAIL: $description"
    echo "  File: docs/testing.md"
    echo "  Missing section: $heading"
    exit 1
  fi

  if printf '%s' "$content" | normalize_stream | rg -qi -- "$pattern"; then
    echo "FAIL: $description"
    echo "  File: docs/testing.md"
    echo "  Section: $heading"
    echo "  Forbidden pattern: $pattern"
    exit 1
  else
    echo "PASS: $description"
  fi
}

assert_file_section_contains() {
  local relative_file="$1"
  local heading="$2"
  local pattern="$3"
  local description="$4"
  local stop_pattern="${5:-^(##|###) }"
  local target_file="$REPO_ROOT/$relative_file"
  local content

  content="$(extract_section "$target_file" "$heading" "$stop_pattern")"

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

assert_file_section_not_contains() {
  local relative_file="$1"
  local heading="$2"
  local pattern="$3"
  local description="$4"
  local stop_pattern="${5:-^(##|###) }"
  local target_file="$REPO_ROOT/$relative_file"
  local content

  content="$(extract_section "$target_file" "$heading" "$stop_pattern")"

  if [[ -z "$content" ]]; then
    echo "FAIL: $description"
    echo "  File: $relative_file"
    echo "  Missing section: $heading"
    exit 1
  fi

  if printf '%s' "$content" | normalize_stream | rg -qi -- "$pattern"; then
    echo "FAIL: $description"
    echo "  File: $relative_file"
    echo "  Section: $heading"
    echo "  Forbidden pattern: $pattern"
    exit 1
  else
    echo "PASS: $description"
  fi
}

assert_file_section_contains_literal() {
  local relative_file="$1"
  local heading="$2"
  local literal="$3"
  local description="$4"
  local stop_pattern="${5:-^(##|###) }"
  local target_file="$REPO_ROOT/$relative_file"
  local content

  content="$(extract_section "$target_file" "$heading" "$stop_pattern")"

  if [[ -z "$content" ]]; then
    echo "FAIL: $description"
    echo "  File: $relative_file"
    echo "  Missing section: $heading"
    exit 1
  fi

  if printf '%s' "$content" | normalize_stream | rg -Fq -- "$literal"; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $relative_file"
    echo "  Section: $heading"
    echo "  Literal: $literal"
    exit 1
  fi
}

assert_file_line_contains_literal() {
  local relative_file="$1"
  local line_pattern="$2"
  local literal="$3"
  local description="$4"
  local target_file="$REPO_ROOT/$relative_file"
  local line

  line="$(extract_matching_line "$target_file" "$line_pattern")"

  if [[ -z "$line" ]]; then
    echo "FAIL: $description"
    echo "  File: $relative_file"
    echo "  Missing line containing: $line_pattern"
    exit 1
  fi

  if printf '%s' "$line" | normalize_stream | rg -Fq -- "$literal"; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $relative_file"
    echo "  Line pattern: $line_pattern"
    echo "  Literal: $literal"
    exit 1
  fi
}

assert_file_has_exact_line() {
  local relative_file="$1"
  local literal="$2"
  local description="$3"
  local target_file="$REPO_ROOT/$relative_file"

  if awk -v literal="$literal" '
    {
      line = $0
      sub(/^[[:space:]]+/, "", line)
      sub(/[[:space:]]+$/, "", line)

      if (line == literal) {
        found = 1
      }
    }

    END {
      exit(found ? 0 : 1)
    }
  ' "$target_file"; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $relative_file"
    echo "  Missing exact line: $literal"
    exit 1
  fi
}

normalize_literal_block() {
  awk '
    {
      line = $0
      sub(/^[[:space:]]+/, "", line)
      sub(/[[:space:]]+$/, "", line)
      lines[++count] = line
    }

    END {
      while (count > 0 && lines[count] == "") {
        count--
      }

      for (i = 1; i <= count; i++) {
        print lines[i]
      }
    }
  '
}

assert_file_has_exact_tail_block() {
  local relative_file="$1"
  local literal_block="$2"
  local description="$3"
  local target_file="$REPO_ROOT/$relative_file"

  local normalized_expected_block
  local expected_line_count
  local normalized_actual_tail

  normalized_expected_block="$(printf '%s' "$literal_block" | normalize_literal_block)"
  expected_line_count="$(printf '%s\n' "$normalized_expected_block" | wc -l | tr -d '[:space:]')"

  if normalized_actual_tail="$(
    awk -v count="$expected_line_count" '
      {
        line = $0
        sub(/^[[:space:]]+/, "", line)
        sub(/[[:space:]]+$/, "", line)
        lines[++line_count] = line
      }

      END {
        while (line_count > 0 && lines[line_count] == "") {
          line_count--
        }

        if (line_count < count) {
          exit 1
        }

        start = line_count - count + 1

        for (i = start; i <= line_count; i++) {
          print lines[i]
        }
      }
    ' "$target_file"
  )" && [[ "$normalized_actual_tail" == "$normalized_expected_block" ]]; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $relative_file"
    echo "  Missing exact tail block:"
    printf '%s\n' "$literal_block"
    exit 1
  fi
}

assert_file_contains_pattern() {
  local relative_file="$1"
  local pattern="$2"
  local description="$3"
  local target_file="$REPO_ROOT/$relative_file"

  if rg -qi -- "$pattern" "$target_file"; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $relative_file"
    echo "  Pattern: $pattern"
    exit 1
  fi
}

assert_file_not_contains_pattern() {
  local relative_file="$1"
  local pattern="$2"
  local description="$3"
  local target_file="$REPO_ROOT/$relative_file"

  if rg -qi -- "$pattern" "$target_file"; then
    echo "FAIL: $description"
    echo "  File: $relative_file"
    echo "  Forbidden pattern: $pattern"
    exit 1
  else
    echo "PASS: $description"
  fi
}

assert_section_contains "## Machine-Readable Workflow Contracts" \
  'branch-local contract snapshot|rollout snapshot' \
  "machine-readable contract section is explicitly framed as a branch-local or rollout snapshot" \
  '^## '

assert_section_contains "## Machine-Readable Workflow Contracts" \
  'hide-endgate-packet-from-terminal' \
  "machine-readable contract section names the current change scope" \
  '^## '

assert_section_contains "### Source-of-truth priority" \
  'tool events > transcript events > canonical machine-readable carriers > prose' \
  "source-of-truth priority preserves the carrier-first ordering"

assert_section_not_contains "### Source-of-truth priority" \
  'tool events > transcript events > fixed machine-readable tail blocks > prose' \
  "source-of-truth priority no longer treats visible tail blocks as the only canonical layer"

assert_section_contains "### Source-of-truth priority" \
  "$CANONICAL_CARRIER_PATTERN" \
  "source-of-truth priority declares the canonical carrier layer"

assert_section_contains "### Source-of-truth priority" \
  "$STRUCTURED_CARRIER_PRIORITY_PATTERN" \
  "source-of-truth priority documents structured-carrier priority"

assert_section_contains "### Source-of-truth priority" \
  "$VISIBLE_TAIL_FALLBACK_PATTERN" \
  "source-of-truth priority documents visible tail fallback"

assert_section_not_contains "### Source-of-truth priority" \
  "$LEGACY_VISIBLE_TAIL_ONLY_DRIFT_PATTERN" \
  "source-of-truth priority rejects legacy visible-tail-only drift"

assert_section_contains "### Source-of-truth priority" \
  'canonical carrier.*其后的事件窗口|post-carrier event window|packet declaration.*其后的事件窗口|优先于 invitation prose|优先于.*句式推断' \
  "source-of-truth priority documents carrier-first endgate validation inside transcript evidence"

assert_section_contains "### Repository audit and fragility tiers" \
  'P0.*P1.*P2|P0 / P1 / P2' \
  "repository audit section defines the three fragility tiers"

assert_section_contains "## Machine-Readable Workflow Contracts" \
  'checkpoint / handoff / terminal-choice' \
  "machine-readable contract section covers checkpoint, handoff, and terminal-choice flows" \
  '^## '

assert_section_contains "## Machine-Readable Workflow Contracts" \
  'all local workflow skills|所有本地 workflow skills' \
  "machine-readable contract section scopes the carrier-first rule across all local workflow skills" \
  '^## '

assert_section_contains "### Workflow Node / Contract Carrier / Verification Matrix" \
  'Workflow Node / Contract Carrier / Verification Matrix|Workflow Node.*Contract Carrier.*Verification.*Status' \
  "verification matrix heading is present in the scoped section"

assert_file_line_contains_literal "docs/testing.md" \
  '| checkpoint / handoff / terminal-choice flows |' \
  'prompt-contract + Codex fixture tests (`tests/codex/test-request-user-input-transcript-fixtures.sh`, `tests/codex/test-runtime-endgate-transcript-audit.sh`)' \
  "checkpoint, handoff, and terminal-choice row keeps both the current prompt-contract evidence and the Codex fixture evidence path"

assert_file_line_contains_literal "docs/testing.md" \
  '| checkpoint / handoff / terminal-choice flows |' \
  'canonical machine-readable carriers + request_user_input call + transcript event' \
  "checkpoint, handoff, and terminal-choice row records the canonical carrier plus transcript evidence path"

assert_file_line_contains_literal "docs/testing.md" \
  '| checkpoint / handoff / terminal-choice flows |' \
  'in scope; transcript fixture evidence landed on this branch' \
  "checkpoint, handoff, and terminal-choice row marks the Codex fixture path as landed branch evidence"

assert_file_line_contains_literal "docs/testing.md" \
  '| skill-triggering discovery |' \
  'audited, out-of-scope for this change because they already assert Skill tool events' \
  "skill-triggering discovery stays audited and explicitly out of scope for this change"

assert_section_contains "### First drift matrix" \
  'Chinese / English / concise / verbose' \
  "first drift matrix preserves the four required wording axes"

assert_file_section_contains_literal "skills/using-superpowers/SKILL.md" \
  "## Autonomous Continuation" \
  "$CANONICAL_SENTENCE" \
  "using-superpowers freezes the canonical machine-contract sentence in autonomous continuation guidance"

assert_file_section_contains_literal "skills/brainstorming/SKILL.md" \
  "## Presenting the design:" \
  "$CANONICAL_SENTENCE" \
  "brainstorming freezes the canonical machine-contract sentence in design-checkpoint guidance"

assert_file_section_contains_literal "skills/writing-plans/SKILL.md" \
  "## Execution Handoff" \
  "$CANONICAL_SENTENCE" \
  "writing-plans freezes the canonical machine-contract sentence in execution handoff guidance"

assert_file_section_contains_literal "skills/writing-plans/SKILL.md" \
  "## Execution Handoff" \
  "3. Stop here for now" \
  "writing-plans freezes slot 3 as the explicit stop-here choice"

assert_file_section_contains_literal "skills/writing-plans/SKILL.md" \
  "## Execution Handoff" \
  'Treat free-form requirements as the client-provided `Other` / notes path rather than authoring slot 3 for free text.' \
  "writing-plans freezes the client-provided Other/notes path for free-form execution input"

assert_file_section_contains_literal "skills/executing-plans/SKILL.md" \
  "## The Process" \
  "$CANONICAL_SENTENCE" \
  "executing-plans freezes the canonical machine-contract sentence in checkpoint guidance"

assert_file_section_contains_literal "skills/spec-governed-development/SKILL.md" \
  "## Handoff Guidance" \
  "$CANONICAL_SENTENCE" \
  "spec-governed-development freezes the canonical machine-contract sentence in governance handoff guidance"

assert_file_section_contains_literal "docs/README.codex.md" \
  "## Autonomous Continuation" \
  "$CANONICAL_SENTENCE" \
  "Codex README mirrors the canonical machine-contract sentence in workflow guidance"

assert_file_section_contains "docs/README.codex.md" \
  "## Autonomous Continuation" \
  'canonical carrier.*last canonical carrier forward|post-carrier event sequence|endgate-state-packet.*last packet forward|packet declaration.*primary runtime contract' \
  "Codex README documents carrier-first runtime endgate handling" \
  '^## '

assert_file_section_contains_literal "docs/testing.md" \
  "### Required Evidence" \
  'assistant-authored payload 只包含 `结束 (Recommended)`、`继续`；客户端 UI 会自动追加 `Other` / notes path 作为自由输入兜底，不应把它记录成 assistant-authored `3`。' \
  "terminal-choice evidence guidance separates the authored popup payload from the client UI fallback"

assert_file_section_contains ".codex/instruction.md" \
  "## Carrier-First Strict Packet Mode" \
  "$CANONICAL_CARRIER_PATTERN" \
  "Codex instruction bootstrap defines strict packet mode around canonical machine-readable carriers" \
  '^## '

assert_file_section_contains ".codex/instruction.md" \
  "## Carrier-First Strict Packet Mode" \
  "$STRUCTURED_CARRIER_PRIORITY_PATTERN" \
  "Codex instruction bootstrap explicitly prefers structured carriers when available" \
  '^## '

assert_file_section_contains ".codex/instruction.md" \
  "## Carrier-First Strict Packet Mode" \
  "$VISIBLE_TAIL_FALLBACK_PATTERN" \
  "Codex instruction bootstrap explicitly limits visible tail blocks to fallback" \
  '^## '

assert_file_section_not_contains ".codex/instruction.md" \
  "## Carrier-First Strict Packet Mode" \
  "$LEGACY_VISIBLE_TAIL_ONLY_DRIFT_PATTERN" \
  "Codex instruction bootstrap rejects legacy visible-tail-only wording" \
  '^## '

assert_file_section_contains ".codex/instruction.md" \
  "## Carrier-First Strict Packet Mode" \
  'imported|lower-priority|external|foreign' \
  "Codex instruction bootstrap names imported or lower-priority skills as override targets" \
  '^## '

assert_file_section_contains ".codex/instruction.md" \
  "## Carrier-First Strict Packet Mode" \
  'no required ending|just provide clarity|continue later' \
  "Codex instruction bootstrap documents the imported free-ending drift phrases" \
  '^## '

assert_file_section_contains "skills/using-superpowers/SKILL.md" \
  "## Autonomous Continuation" \
  'imported|lower-priority|external|foreign' \
  "using-superpowers autonomous continuation names imported or lower-priority skills as override targets" \
  '^## '

assert_file_section_contains "skills/using-superpowers/SKILL.md" \
  "## Autonomous Continuation" \
  'no required ending|just provide clarity|continue later' \
  "using-superpowers autonomous continuation documents the imported free-ending drift phrases" \
  '^## '

assert_file_section_contains "docs/README.codex.md" \
  "## Autonomous Continuation" \
  'imported|lower-priority|external|foreign' \
  "Codex README names imported or lower-priority skills as override targets" \
  '^## '

assert_file_section_contains "docs/README.codex.md" \
  "## Autonomous Continuation" \
  'no required ending|just provide clarity|continue later' \
  "Codex README documents the imported free-ending drift phrases" \
  '^## '

assert_file_has_exact_tail_block "skills/brainstorming/spec-document-reviewer-prompt.md" \
  $'Keep the field names exactly as written.\nFor `REVIEW_VERDICT` and `NEXT_ACTION`, choose exactly one allowed token and do not repeat the pipe-delimited schema.\nReplace `BLOCKING_ISSUE_COUNT` with digits only.\nREVIEW_VERDICT: APPROVED | CHANGES_REQUIRED\nBLOCKING_ISSUE_COUNT: non-negative integer\nNEXT_ACTION: CONTINUE | REVISE | STOP\n```' \
  "spec document reviewer exposes the stable reviewer tail-block semantics at file end"

assert_file_has_exact_tail_block "skills/writing-plans/plan-document-reviewer-prompt.md" \
  $'Keep the field names exactly as written.\nFor `REVIEW_VERDICT` and `NEXT_ACTION`, choose exactly one allowed token and do not repeat the pipe-delimited schema.\nReplace `BLOCKING_ISSUE_COUNT` with digits only.\nREVIEW_VERDICT: APPROVED | CHANGES_REQUIRED\nBLOCKING_ISSUE_COUNT: non-negative integer\nNEXT_ACTION: CONTINUE | REVISE | STOP\n```' \
  "plan document reviewer exposes the stable reviewer tail-block semantics at file end"

assert_file_has_exact_tail_block "skills/subagent-driven-development/spec-reviewer-prompt.md" \
  $'Keep the field names exactly as written.\nFor `REVIEW_VERDICT` and `NEXT_ACTION`, choose exactly one allowed token and do not repeat the pipe-delimited schema.\nReplace `BLOCKING_ISSUE_COUNT` with digits only.\nREVIEW_VERDICT: APPROVED | CHANGES_REQUIRED\nBLOCKING_ISSUE_COUNT: non-negative integer\nNEXT_ACTION: CONTINUE | REVISE\n```' \
  "spec compliance reviewer exposes the stable reviewer tail-block semantics at file end"

assert_file_has_exact_tail_block "skills/subagent-driven-development/implementer-prompt.md" \
  $'The field names must remain unchanged and appear verbatim.\n`TASK_STATUS`, `TEST_STATUS`, and `NEXT_ACTION` must each use exactly one allowed token and must not repeat the pipe-delimited schema.\nTASK_STATUS: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT\nTEST_STATUS: PASS | FAIL | NOT_RUN\nNEXT_ACTION: REVIEW | NEEDS_CONTEXT | STOP\n```' \
  "implementer prompt exposes the stable machine-readable trailer semantics at file end"

echo "All machine-readable workflow contract checks passed."
