#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
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

assert_section_has_endgate_packet_template() {
  local file="$1"
  local heading="$2"
  local description_prefix="$3"
  local stop_pattern="${4:-^(##|###) }"

  assert_section_contains "$file" "$heading" 'ENDGATE_PROTOCOL_VERSION: 1.*ENDGATE_STATE: TERMINAL_CHOICE.*ENDGATE_CHOICE_KIND: CONTINUE_OR_STOP.*ENDGATE_NEXT_ACTION: REQUEST_USER_INPUT' "$description_prefix includes the canonical terminal endgate packet template" "$stop_pattern"
  assert_section_contains "$file" "$heading" 'endgate-state-packet|strict packet mode|严格 packet 模式' "$description_prefix explicitly treats packetized endgate as mandatory" "$stop_pattern"
}

assert_section_uses_canonical_carrier_model() {
  local file="$1"
  local heading="$2"
  local description_prefix="$3"
  local stop_pattern="${4:-^(##|###) }"

  assert_section_contains "$file" "$heading" "$CANONICAL_CARRIER_PATTERN" "$description_prefix declares the canonical carrier requirement" "$stop_pattern"
  assert_section_contains "$file" "$heading" "$STRUCTURED_CARRIER_PRIORITY_PATTERN" "$description_prefix prefers structured carriers when available" "$stop_pattern"
  assert_section_contains "$file" "$heading" "$VISIBLE_TAIL_FALLBACK_PATTERN" "$description_prefix limits visible tail blocks to fallback-only status" "$stop_pattern"
  assert_section_not_contains "$file" "$heading" "$LEGACY_VISIBLE_TAIL_ONLY_DRIFT_PATTERN" "$description_prefix rejects legacy visible-tail-only wording" "$stop_pattern"
}

SKILL_FILES=(
  "skills/dispatching-parallel-agents/SKILL.md"
  "skills/executing-plans/SKILL.md"
  "skills/finishing-a-development-branch/SKILL.md"
  "skills/receiving-code-review/SKILL.md"
  "skills/requesting-code-review/SKILL.md"
  "skills/spec-governed-development/SKILL.md"
  "skills/subagent-driven-development/SKILL.md"
  "skills/systematic-debugging/SKILL.md"
  "skills/test-driven-development/SKILL.md"
  "skills/using-git-worktrees/SKILL.md"
  "skills/verification-before-completion/SKILL.md"
  "skills/writing-plans/SKILL.md"
  "skills/writing-skills/SKILL.md"
)

for file in "${SKILL_FILES[@]}"; do
  assert_section_contains \
    "$file" \
    "## Terminal Endgate Protocol" \
    'must not end the conversation directly|must never end the conversation directly|不得直接结束对话' \
    "$file declares that direct conversation endings are forbidden" \
    '^## '

  assert_section_contains \
    "$file" \
    "## Terminal Endgate Protocol" \
    '`terminal-choice`|terminal-choice' \
    "$file routes true completion through terminal-choice" \
    '^## '

  assert_section_contains \
    "$file" \
    "## Terminal Endgate Protocol" \
    '`request_user_input`|request_user_input' \
    "$file requires request_user_input for terminal completion" \
    '^## '

  assert_section_has_endgate_packet_template \
    "$file" \
    "## Terminal Endgate Protocol" \
    "$file terminal protocol" \
    '^## '

  assert_section_uses_canonical_carrier_model \
    "$file" \
    "## Terminal Endgate Protocol" \
    "$file terminal protocol" \
    '^## '

  assert_section_contains \
    "$file" \
    "## Terminal Endgate Protocol" \
    '1\. 结束 \(Recommended\).*2\. 继续' \
    "$file preserves the two assistant-authored terminal-choice options" \
    '^## '

  assert_section_contains \
    "$file" \
    "## Terminal Endgate Protocol" \
    'client-provided `Other` / notes path|客户端自动追加的 `Other` / notes 路径' \
    "$file routes terminal free-form input through the client-provided Other/notes path" \
    '^## '

  assert_section_not_contains \
    "$file" \
    "## Terminal Endgate Protocol" \
    '3\. 自由输入|显式.*自由输入|author(?:ed|ing).*自由输入' \
    "$file does not preserve a duplicate authored free-form terminal-choice option" \
    '^## '

  assert_section_contains \
    "$file" \
    "## Terminal Endgate Protocol" \
    'plain final-answer-style closeout|自由文本收口|prose-only closeout' \
    "$file forbids prose-only closeouts before terminal-choice" \
    '^## '

  assert_section_contains \
    "$file" \
    "## Terminal Endgate Protocol" \
    'completed assessment, audit, comparison, review, recommendation memo, or research report is still a terminal boundary|completed assessment.*terminal boundary|recommendation memo.*terminal boundary|research report.*terminal boundary|bare `结论`|bare `最终判断`|我的推荐' \
    "$file treats report-style deliverables as terminal boundaries that still require the popup" \
    '^## '
done

echo "All local skill terminal-endgate protocol checks passed."
