# Decouple Prose From Workflow Protocols Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the most brittle prose-coupled workflow and test assertions with machine-readable protocol signals across reviewer outputs, workflow checkpoints, execution handoffs, terminal-choice flows, and the highest-risk Claude/OpenCode validations.

**Architecture:** Execute this change in six passes. First freeze the branch-local OpenSpec context, coverage map, and source-of-truth priority in docs plus a new prompt-contract suite. Next wire checkpoint/handoff/terminal-choice files to declare that tool events and transcript events are the contract for those nodes, while reviewer/implementer prompts emit stable tail blocks for text-heavy flows. Then add shared shell helpers, migrate the brittle Claude tests to transcript- or tail-block-based assertions, reduce OpenCode’s dependence on launcher wording, and finish with a drift matrix that covers language, style, and a second runner or model path when available.

**Tech Stack:** Markdown skill prompts, Bash integration tests, `rg`, `jq`, Claude/OpenCode headless CLI output, session transcripts, OpenSpec artifacts

---

**OpenSpec Change:** `decouple-prose-from-workflow-protocols`

**OpenSpec Artifacts (branch-local):**
- `openspec/changes/decouple-prose-from-workflow-protocols/proposal.md`
- `openspec/changes/decouple-prose-from-workflow-protocols/design.md`
- `openspec/changes/decouple-prose-from-workflow-protocols/specs/workflow-protocol-contracts/spec.md`
- `openspec/changes/decouple-prose-from-workflow-protocols/specs/transcript-based-validation/spec.md`
- `openspec/changes/decouple-prose-from-workflow-protocols/tasks.md`

**Coverage Map:**
- Reviewer / implementer text-heavy nodes → machine-readable tail blocks in prompt templates + transcript/tail-block assertions in tests
- Workflow checkpoint / execution handoff / terminal-choice nodes → `request_user_input` calls and transcript events are the contract, not surrounding prose
- Claude behavior tests → session transcript assertions, not skill self-description prose
- OpenCode tool-loading tests → raw marker or tool payload assertions, not launcher wording
- Drift verification → Chinese / English / concise / verbose prompt variants, plus a second runner or model path when locally available

**Repository Audit and Scope Boundary:**
- P0 runtime prose-coupled assertions to migrate in this change:
  - `tests/claude-code/test-document-review-system.sh` currently decides success from reviewer prose like `Issues Found`, `Approved`, and emoji markers
  - `tests/claude-code/test-subagent-driven-development.sh` currently interviews the skill and matches explanatory wording instead of observing real workflow behavior
  - `tests/opencode/test-tools.sh` still accepts launcher wording such as `Launching skill` / `skill loaded`
- P1 workflow-node contract docs to freeze in this change:
  - `skills/using-superpowers/SKILL.md`
  - `skills/brainstorming/SKILL.md`
  - `skills/writing-plans/SKILL.md`
  - `skills/executing-plans/SKILL.md`
  - `spec-governed-development/SKILL.md`
  - `docs/README.codex.md`
- P2 audited but explicitly out of scope for this change:
  - `tests/skill-triggering/*.sh` already assert `Skill` tool events in stream-json rather than assistant prose, so this change records them in the audit and leaves their behavior unchanged

**Workflow Node / Contract Carrier / Verification Matrix:**

| Workflow node | Current brittle spot(s) | Contract carrier | Verification artifact / test | Scope |
| --- | --- | --- | --- | --- |
| reviewer / plan-review verdicts | `tests/claude-code/test-document-review-system.sh` greps reviewer prose like `Issues Found`, `Approved`, and emoji | fixed machine-readable tail block fields (`REVIEW_VERDICT`, `BLOCKING_ISSUE_COUNT`, `NEXT_ACTION`) | `tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`, `tests/claude-code/test-document-review-system.sh` | In |
| checkpoint / design review gates | skill and README text explain the gate, and the runtime evidence path is now frozen on this branch | `request_user_input` call + transcript event | `tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`, `tests/codex/test-request-user-input-transcript-fixtures.sh` | In |
| execution handoff | non-terminal handoff wording may vary across models or languages | `request_user_input` call + transcript event from a real execution-handoff transcript | `tests/codex/fixtures/request-user-input-execution-handoff.jsonl`, `tests/codex/test-request-user-input-transcript-fixtures.sh` | In |
| terminal-choice | prose around the final popup may drift | `request_user_input` call + transcript event from a real terminal-choice transcript | `tests/codex/fixtures/request-user-input-terminal-choice.jsonl`, `tests/codex/test-request-user-input-transcript-fixtures.sh` | In |
| SDD execution / reporting | `tests/claude-code/test-subagent-driven-development.sh` interviews the skill instead of verifying a real run | transcript `Skill` / `Task` / `TodoWrite` events + mandatory implementer tail fields (`TASK_STATUS`, `TEST_STATUS`, `NEXT_ACTION`) | `tests/claude-code/test-subagent-driven-development.sh` | In |
| OpenCode skill/tool loading | `tests/opencode/test-tools.sh` allows launcher-wording fallbacks | raw skill marker / tool payload | `tests/opencode/test-tools.sh` | In |
| skill-triggering discovery | `tests/skill-triggering/run-test.sh` already keys off stream-json `Skill` events | existing `Skill` event transcript | existing `tests/skill-triggering/*.sh` | Audited, out of scope |

### Task 1: Freeze the Repository Audit, Coverage Map, and Source-of-Truth Priority in Docs and a New Contract Test

**Files:**
- Create: `tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`
- Modify: `docs/testing.md`

- [ ] **Step 1: Create a new prompt-contract test that locks the branch-local coverage map**

Create `tests/prompt-contracts/test-machine-readable-workflow-contracts.sh` with assertions like:

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

assert_contains() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if rg -q -- "$pattern" "$REPO_ROOT/$file"; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Pattern: $pattern"
    exit 1
  fi
}

assert_contains "docs/testing.md" "tool events > transcript events > fixed machine-readable tail blocks > prose" "testing doc freezes source-of-truth priority"
assert_contains "docs/testing.md" "decouple-prose-from-workflow-protocols" "testing doc references the current OpenSpec change"
assert_contains "docs/testing.md" "checkpoint / handoff / terminal-choice" "testing doc covers non-review workflow nodes"
assert_contains "docs/testing.md" "Chinese / English / concise / verbose" "testing doc freezes the first drift matrix"
assert_contains "docs/testing.md" "Workflow Node / Contract Carrier / Verification Matrix" "testing doc includes the workflow mapping table"
assert_contains "docs/testing.md" "skill-triggering discovery" "testing doc records the audited skill-triggering slice"
assert_contains "docs/testing.md" "out-of-scope for this change" "testing doc records the explicit scope boundary"
```

- [ ] **Step 2: Run the new prompt-contract test to verify it fails before the doc update**

Run: `bash tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`  
Expected: FAIL because `docs/testing.md` does not yet contain the new machine-readable workflow contract section.

- [ ] **Step 3: Update `docs/testing.md` with the new machine-readable contract section**

Add a concise section with this exact structure:

```markdown
## Machine-Readable Workflow Contracts

Source-of-truth priority:
1. tool events
2. transcript events
3. fixed machine-readable tail blocks
4. prose

Repository audit and fragility tiers:
- P0: prose-coupled runtime assertions
- P1: workflow-node contract documents
- P2: audited but already event-based

Current OpenSpec change:
- decouple-prose-from-workflow-protocols

Covered node families:
- reviewer / implementer reports
- checkpoint / handoff / terminal-choice flows
- Claude transcript-backed behavior tests
- OpenCode raw marker / tool-payload tests

Workflow Node / Contract Carrier / Verification Matrix:
| Workflow node | Contract carrier | Verification artifact / test | Scope |
| --- | --- | --- | --- |
| reviewer / implementer reports | fixed machine-readable tail blocks + transcript events | tests/prompt-contracts/test-machine-readable-workflow-contracts.sh; tests/claude-code/test-document-review-system.sh; tests/claude-code/test-subagent-driven-development.sh | in |
| checkpoint / handoff / terminal-choice flows | request_user_input call + transcript event | tests/prompt-contracts/test-machine-readable-workflow-contracts.sh; tests/codex/test-request-user-input-transcript-fixtures.sh | in |
| OpenCode tool loading | raw marker / tool payload | tests/opencode/test-tools.sh | in |
| skill-triggering discovery | existing Skill tool event transcript | tests/skill-triggering/*.sh | out-of-scope for this change because they already assert Skill tool events |

First drift matrix:
- Chinese
- English
- concise
- verbose
```

- [ ] **Step 4: Re-run the new prompt-contract test**

Run: `bash tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`  
Expected: PASS for the new `docs/testing.md` assertions.

- [ ] **Step 5: Commit**

```bash
git add tests/prompt-contracts/test-machine-readable-workflow-contracts.sh docs/testing.md
git commit -m "docs: freeze workflow protocol coverage map"
```

### Task 2: Lock Checkpoint, Handoff, and Terminal-Choice Files to Tool/Transcript Contracts

**Files:**
- Modify: `skills/using-superpowers/SKILL.md`
- Modify: `skills/brainstorming/SKILL.md`
- Modify: `skills/writing-plans/SKILL.md`
- Modify: `skills/executing-plans/SKILL.md`
- Modify: `spec-governed-development/SKILL.md`
- Modify: `docs/README.codex.md`
- Modify: `tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`
- Create: `tests/codex/fixtures/request-user-input-terminal-choice.jsonl`
- Create: `tests/codex/fixtures/request-user-input-execution-handoff.jsonl`
- Create: `tests/codex/test-request-user-input-transcript-fixtures.sh`

- [x] **Step 1: Extend the contract test with checkpoint/handoff assertions**

Append assertions like:

```bash
assert_contains "skills/using-superpowers/SKILL.md" "request_user_input call and its transcript event are the machine contract" "global guidance freezes checkpoint contract"
assert_contains "skills/brainstorming/SKILL.md" "request_user_input call and its transcript event are the machine contract" "brainstorming freezes review-gate contract"
assert_contains "skills/writing-plans/SKILL.md" "request_user_input call and its transcript event are the machine contract" "writing-plans freezes handoff contract"
assert_contains "skills/executing-plans/SKILL.md" "request_user_input call and its transcript event are the machine contract" "executing-plans freezes blocker contract"
assert_contains "spec-governed-development/SKILL.md" "request_user_input call and its transcript event are the machine contract" "spec-governed-development freezes lane handoff contract"
assert_contains "docs/README.codex.md" "request_user_input call and its transcript event are the machine contract" "Codex README mirrors the contract"
```

- [x] **Step 2: Run the contract test and verify the new assertions fail**

Ran: `bash tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`  
Observed: FAIL on the newly added checkpoint/handoff assertions before the workflow files were updated.

- [x] **Step 3: Add the canonical sentence to the five workflow files and the Codex README**

Under the relevant sections in each file, add the same sentence verbatim:

```markdown
For checkpoint, handoff, and terminal-choice nodes driven by `request_user_input`, the `request_user_input` call and its transcript event are the machine contract; surrounding prose is explanatory only.
```

Place it where the surrounding section already discusses `request_user_input`, checkpoint gates, or terminal-choice behavior.

- [x] **Step 4: Re-run the new contract test**

Ran: `bash tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`  
Observed: PASS for the new checkpoint/handoff assertions after the workflow files and README were updated.

- [x] **Step 5: Capture a real terminal-choice transcript fixture**

Added a branch-local Codex transcript fixture captured from a real run at:

```text
tests/codex/fixtures/request-user-input-terminal-choice.jsonl
```

This landed fixture contains:

```bash
rg -q '"request_user_input"' tests/codex/fixtures/request-user-input-terminal-choice.jsonl
rg -q '"questions"' tests/codex/fixtures/request-user-input-terminal-choice.jsonl
rg -q '"answers"' tests/codex/fixtures/request-user-input-terminal-choice.jsonl
rg -q '结束|继续|自由输入' tests/codex/fixtures/request-user-input-terminal-choice.jsonl
```

Use a real terminal-choice flow so the transcript proves the popup and selected token were both recorded.

- [x] **Step 6: Capture a separate real non-terminal execution-handoff transcript fixture**

Added an independent fixture captured from a real non-terminal handoff flow at:

```text
tests/codex/fixtures/request-user-input-execution-handoff.jsonl
```

This landed fixture contains:

```bash
rg -q '"request_user_input"' tests/codex/fixtures/request-user-input-execution-handoff.jsonl
rg -q 'questions' tests/codex/fixtures/request-user-input-execution-handoff.jsonl
rg -q 'answers' tests/codex/fixtures/request-user-input-execution-handoff.jsonl
rg -q 'execution_path' tests/codex/fixtures/request-user-input-execution-handoff.jsonl
rg -q 'Subagent-Driven' tests/codex/fixtures/request-user-input-execution-handoff.jsonl
rg -q 'Inline Execution' tests/codex/fixtures/request-user-input-execution-handoff.jsonl
rg -q '先停在这里' tests/codex/fixtures/request-user-input-execution-handoff.jsonl
! rg -q '结束|继续|自由输入' tests/codex/fixtures/request-user-input-execution-handoff.jsonl
```

This proves a non-terminal handoff can be parsed without falling back to terminal-choice wording.

- [x] **Step 7: Create the transcript-fixture smoke test for both fixtures**

Created `tests/codex/test-request-user-input-transcript-fixtures.sh` to assert both fixtures separately, with one block for terminal-choice evidence and one block for execution-handoff evidence.

- [x] **Step 8: Run the new transcript-fixture smoke**

Ran: `bash tests/codex/test-request-user-input-transcript-fixtures.sh`  
Observed: PASS, proving both a real terminal-choice transcript and a real non-terminal execution-handoff transcript remain parseable as structured evidence.

- [ ] **Step 9: Commit**

```bash
git add \
  skills/using-superpowers/SKILL.md \
  skills/brainstorming/SKILL.md \
  skills/writing-plans/SKILL.md \
  skills/executing-plans/SKILL.md \
  spec-governed-development/SKILL.md \
  docs/README.codex.md \
  tests/prompt-contracts/test-machine-readable-workflow-contracts.sh \
  tests/codex/fixtures/request-user-input-terminal-choice.jsonl \
  tests/codex/fixtures/request-user-input-execution-handoff.jsonl \
  tests/codex/test-request-user-input-transcript-fixtures.sh
git commit -m "docs: lock checkpoint and handoff machine contracts"
```

### Task 3: Add Stable Tail Blocks to Reviewer and Implementer Prompts

**Files:**
- Modify: `skills/brainstorming/spec-document-reviewer-prompt.md`
- Modify: `skills/writing-plans/plan-document-reviewer-prompt.md`
- Modify: `skills/subagent-driven-development/spec-reviewer-prompt.md`
- Modify: `skills/subagent-driven-development/implementer-prompt.md`
- Modify: `tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`

- [ ] **Step 1: Extend the contract test with reviewer/implementer field assertions**

Append assertions like:

```bash
assert_contains "skills/brainstorming/spec-document-reviewer-prompt.md" "REVIEW_VERDICT: APPROVED \\| CHANGES_REQUIRED" "spec document reviewer exposes stable verdict field"
assert_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "REVIEW_VERDICT: APPROVED \\| CHANGES_REQUIRED" "plan reviewer exposes stable verdict field"
assert_contains "skills/subagent-driven-development/spec-reviewer-prompt.md" "REVIEW_VERDICT: APPROVED \\| CHANGES_REQUIRED" "spec reviewer exposes stable verdict field"
assert_contains "skills/subagent-driven-development/implementer-prompt.md" "TASK_STATUS: DONE \\| DONE_WITH_CONCERNS \\| BLOCKED \\| NEEDS_CONTEXT" "implementer exposes stable task status field"
assert_contains "skills/subagent-driven-development/implementer-prompt.md" "TEST_STATUS: PASS \\| FAIL \\| NOT_RUN" "implementer exposes stable test status field"
```

- [ ] **Step 2: Run the contract test and verify these field assertions fail**

Run: `bash tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`  
Expected: FAIL on the newly added reviewer/implementer field assertions.

- [ ] **Step 3: Update the two document reviewers and the SDD spec reviewer with exact tail blocks**

Append a final machine-readable block to the reviewer output instructions. Use this exact shape for the two document reviewers:

```text
REVIEW_VERDICT: APPROVED | CHANGES_REQUIRED
BLOCKING_ISSUE_COUNT: non-negative integer
NEXT_ACTION: CONTINUE | REVISE | STOP
```

For `skills/subagent-driven-development/spec-reviewer-prompt.md`, use:

```text
REVIEW_VERDICT: APPROVED | CHANGES_REQUIRED
BLOCKING_ISSUE_COUNT: non-negative integer
NEXT_ACTION: CONTINUE | REVISE
```

- [ ] **Step 4: Tighten `implementer-prompt.md` so the tail block is mandatory**

Keep the current report prose, but end the prompt with an exact trailer:

```text
TASK_STATUS: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
TEST_STATUS: PASS | FAIL | NOT_RUN
NEXT_ACTION: REVIEW | NEEDS_CONTEXT | STOP
```

Add one sentence that says these keys must appear verbatim even if the surrounding report prose changes.

- [ ] **Step 5: Re-run the contract test**

Run: `bash tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`  
Expected: PASS for the reviewer/implementer field assertions.

- [ ] **Step 6: Commit**

```bash
git add \
  skills/brainstorming/spec-document-reviewer-prompt.md \
  skills/writing-plans/plan-document-reviewer-prompt.md \
  skills/subagent-driven-development/spec-reviewer-prompt.md \
  skills/subagent-driven-development/implementer-prompt.md \
  tests/prompt-contracts/test-machine-readable-workflow-contracts.sh
git commit -m "docs: add stable reviewer and implementer tail blocks"
```

### Task 4: Add Shared Bash Helpers and Migrate the Document Review Integration Test

**Files:**
- Create: `tests/shared/workflow-contract-helpers.sh`
- Modify: `tests/claude-code/test-helpers.sh`
- Modify: `tests/claude-code/test-document-review-system.sh`
- Test: `tests/claude-code/test-document-review-system.sh`

- [ ] **Step 1: Create a shared helper for tail-block fields and transcript file discovery**

Create `tests/shared/workflow-contract-helpers.sh` with helpers like:

```bash
#!/usr/bin/env bash

assert_named_field() {
    local file="$1"
    local key="$2"
    local pattern="$3"
    local test_name="$4"

    if rg -q "^${key}: ${pattern}$" "$file"; then
        echo "  [PASS] $test_name"
    else
        echo "  [FAIL] $test_name"
        echo "  Missing: ^${key}: ${pattern}$"
        return 1
    fi
}

extract_named_field() {
    local file="$1"
    local key="$2"
    rg -o "^${key}: .*" "$file" | head -1 | sed -E "s/^${key}: //"
}
```

- [ ] **Step 2: Source the helper from `tests/claude-code/test-helpers.sh`**

Add near the top:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../shared/workflow-contract-helpers.sh"
```

Leave the existing `run_claude`, `assert_contains`, and `assert_order` helpers available for tests that have not yet migrated.

- [ ] **Step 3: Replace the prose-driven verdict logic in `test-document-review-system.sh`**

Keep the fixture and prompt setup, but replace the verdict assertions with:

```bash
assert_named_field "$OUTPUT_FILE" "REVIEW_VERDICT" "CHANGES_REQUIRED" "Reviewer returns stable failing verdict"
assert_named_field "$OUTPUT_FILE" "NEXT_ACTION" "REVISE|STOP" "Reviewer returns stable next action"

issue_count=$(extract_named_field "$OUTPUT_FILE" "BLOCKING_ISSUE_COUNT")
if [ -n "$issue_count" ] && [ "$issue_count" -ge 1 ]; then
    echo "  [PASS] Blocking issue count is non-zero"
else
    echo "  [FAIL] Blocking issue count missing or zero"
    FAILED=$((FAILED + 1))
fi
```

Retain one sanity check for the fixture-specific content (`TODO` and `specified later`) so the test still proves the reviewer caught the intended flaws, but do not use prose to determine the verdict anymore.

- [ ] **Step 4: Run the document review integration test**

Run: `bash tests/claude-code/test-document-review-system.sh`  
Expected: PASS with `REVIEW_VERDICT: CHANGES_REQUIRED` and `BLOCKING_ISSUE_COUNT >= 1`.

- [ ] **Step 5: Commit**

```bash
git add \
  tests/shared/workflow-contract-helpers.sh \
  tests/claude-code/test-helpers.sh \
  tests/claude-code/test-document-review-system.sh
git commit -m "test: parse document reviewer contracts instead of prose"
```

### Task 5: Replace the SDD Interview Test with a Reproducible Transcript-Backed Behavior Smoke Test

**Files:**
- Create: `tests/claude-code/fixtures/sdd-smoke-prompt.template.txt`
- Modify: `tests/claude-code/test-helpers.sh`
- Modify: `tests/claude-code/test-subagent-driven-development.sh`
- Test: `tests/claude-code/test-subagent-driven-development.sh`

- [ ] **Step 1: Add transcript-session helpers and a deterministic SDD smoke bootstrap helper to `tests/claude-code/test-helpers.sh`**

Add helpers like:

```bash
find_latest_session_file() {
    local working_dir="$1"
    local escaped
    escaped=$(echo "$working_dir" | sed 's/\//-/g' | sed 's/^-//')
    find "$HOME/.claude/projects/$escaped" -name "*.jsonl" -type f -mmin -60 2>/dev/null | sort -r | head -1
}

assert_session_contains() {
    local session_file="$1"
    local pattern="$2"
    local test_name="$3"

    if rg -q -- "$pattern" "$session_file"; then
        echo "  [PASS] $test_name"
    else
        echo "  [FAIL] $test_name"
        echo "  Pattern: $pattern"
        return 1
    fi
}

assert_session_not_contains() {
    local session_file="$1"
    local pattern="$2"
    local test_name="$3"

    if rg -q -- "$pattern" "$session_file"; then
        echo "  [FAIL] $test_name"
        echo "  Unexpected pattern: $pattern"
        return 1
    else
        echo "  [PASS] $test_name"
    fi
}

bootstrap_sdd_smoke_project() {
    local project_dir="$1"

    mkdir -p "$project_dir/src" "$project_dir/test" "$project_dir/docs/superpowers/plans"

    cat > "$project_dir/package.json" <<'EOF'
{
  "name": "sdd-smoke-project",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "test": "node --test"
  }
}
EOF

    cat > "$project_dir/docs/superpowers/plans/implementation-plan.md" <<'EOF'
# SDD Smoke Plan

## Task 1: Add the math helper

Create `src/math.js` with one exported `add(a, b)` function and `test/math.test.js` with one passing `node --test` case for `add(2, 3) === 5`.

Verification: `npm test`
EOF

    git -C "$project_dir" init --quiet
    git -C "$project_dir" config user.email "test@test.com"
    git -C "$project_dir" config user.name "Test User"
    git -C "$project_dir" add .
    git -C "$project_dir" commit -m "Initial smoke fixture" --quiet
}
```

- [ ] **Step 2: Add a fixed smoke prompt template with explicit session-scoped subagent consent**

Create `tests/claude-code/fixtures/sdd-smoke-prompt.template.txt` with exact text like:

```text
Change to directory __TEST_PROJECT__ and execute docs/superpowers/plans/implementation-plan.md using the subagent-driven-development skill.

You have explicit permission to use subagents in this session.
Do not ask for additional permission to use subagents.
This is a behavior smoke test. Keep the run minimal, execute the plan, and preserve the machine-readable status lines required by the active prompts.
```

The test script should render this template into a concrete prompt before calling Claude.

- [ ] **Step 3: Rewrite `test-subagent-driven-development.sh` into a small behavior smoke with explicit subagent consent**

Replace the current “ask Claude what the skill means” prompts with:

1. create a temporary project using `create_test_project`
2. call `bootstrap_sdd_smoke_project "$TEST_PROJECT"`
3. render the fixed prompt template with the concrete temp-project path
4. run the prompt in headless mode with `--output-format stream-json`
5. find the session transcript with `find_latest_session_file`
6. assert real behavior from the session transcript

Use transcript assertions like:

```bash
assert_session_contains "$SESSION_FILE" '"name":"Skill".*"skill":"superpowers:subagent-driven-development"' "SDD skill invoked"
assert_session_contains "$SESSION_FILE" '"name":"Task"' "Subagent task dispatch recorded"
assert_session_contains "$SESSION_FILE" '"name":"TodoWrite"' "Task tracking recorded"
assert_session_not_contains "$SESSION_FILE" '"name":"request_user_input".*("subagent use"|permission to use subagents|may use subagents in this session|allow subagent use)' "Smoke run does not re-enter the subagent consent gate"
```

- [ ] **Step 4: Assert the full machine-readable protocol set needed by the smoke**

After execution completes, assert the captured output or transcript contains all of the following:

```bash
assert_session_contains "$SESSION_FILE" 'TASK_STATUS: (DONE|DONE_WITH_CONCERNS|BLOCKED|NEEDS_CONTEXT)' "Implementer task status recorded"
assert_session_contains "$SESSION_FILE" 'TEST_STATUS: (PASS|FAIL|NOT_RUN)' "Implementer test status recorded"
assert_session_contains "$SESSION_FILE" 'NEXT_ACTION: (REVIEW|NEEDS_CONTEXT|STOP)' "Implementer next action recorded"
```

- [ ] **Step 5: Run the SDD behavior smoke**

Run: `bash tests/claude-code/test-subagent-driven-development.sh`  
Expected: PASS with real `Skill`, `Task`, and `TodoWrite` events recorded, the full `TASK_STATUS` / `TEST_STATUS` / `NEXT_ACTION` field set observed, and no second `request_user_input` trip through the subagent-consent gate.

- [ ] **Step 6: Commit**

```bash
git add \
  tests/claude-code/fixtures/sdd-smoke-prompt.template.txt \
  tests/claude-code/test-helpers.sh \
  tests/claude-code/test-subagent-driven-development.sh
git commit -m "test: replace sdd interview checks with behavior smoke"
```

### Task 6: Remove OpenCode Launcher Wording Dependencies and Add the Drift Matrix

**Files:**
- Modify: `tests/opencode/test-tools.sh`
- Create: `tests/claude-code/test-reviewer-contract-drift.sh`
- Modify: `docs/testing.md`
- Test: `tests/opencode/test-tools.sh`
- Test: `tests/claude-code/test-reviewer-contract-drift.sh`
- Test: `tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`
- Test: `tests/claude-code/test-document-review-system.sh`
- Test: `tests/claude-code/test-subagent-driven-development.sh`

- [ ] **Step 1: Remove launcher-wording fallbacks from `tests/opencode/test-tools.sh`**

Replace checks like:

```bash
grep -qi "PERSONAL_SKILL_MARKER_12345\|Personal Test Skill\|Launching skill"
```

with stable-marker checks like:

```bash
grep -qi "PERSONAL_SKILL_MARKER_12345"
grep -qi "superpowers:brainstorming\|superpowers:using-superpowers"
```

If a `Launching skill` / `skill loaded` fallback branch remains, remove it.

- [ ] **Step 2: Create a drift-matrix test for reviewer contracts**

Create `tests/claude-code/test-reviewer-contract-drift.sh` that reuses the same broken-spec fixture and runs the reviewer under four prompt variants:

1. Chinese
2. English
3. concise
4. verbose

For each run, extract and compare:

```text
REVIEW_VERDICT
BLOCKING_ISSUE_COUNT
NEXT_ACTION
```

Require:
- all four runs return `REVIEW_VERDICT: CHANGES_REQUIRED`
- all four runs return `BLOCKING_ISSUE_COUNT` as an integer greater than zero
- all four runs return the same `NEXT_ACTION`

- [ ] **Step 3: Add a second-runner or second-model branch when locally available**

In the same drift test, add one optional branch:

- if a second runner is available locally (`opencode`), run one matching reviewer case there and assert the same verdict fields
- else if the local Claude runner supports selecting a second model, run the English case on that model and assert the same verdict fields
- else print a documented `SKIP` message explaining that the second-runner / second-model path is unavailable locally

This step is required in the script structure even if the local machine ends up taking the `SKIP` branch during one run.

- [ ] **Step 4: Update `docs/testing.md` with the drift-matrix protocol and evidence ledger**

Add a subsection that explicitly says the drift matrix covers:

```markdown
- Chinese
- English
- concise
- verbose
- second runner or second model when available
```

and that prose may vary while the machine-readable fields must remain stable.

In the same doc update, add a `Latest Machine-Readable Contract Evidence` subsection that includes placeholders for:
- `tests/codex/fixtures/request-user-input-terminal-choice.jsonl`
- `tests/codex/fixtures/request-user-input-execution-handoff.jsonl`
- `tests/claude-code/test-subagent-driven-development.sh`
- `tests/claude-code/test-reviewer-contract-drift.sh`

- [ ] **Step 5: Run the OpenCode tools test**

Run: `bash tests/opencode/test-tools.sh`  
Expected:
- PASS if OpenCode is installed locally
- SKIP with the existing dependency message if OpenCode is unavailable

- [ ] **Step 6: Run the drift-matrix test**

Run: `bash tests/claude-code/test-reviewer-contract-drift.sh`  
Expected: PASS for the four style/language variants, plus PASS or documented SKIP for the second-runner / second-model branch.

- [ ] **Step 7: Run the full verification set**

Run:

```bash
bash tests/prompt-contracts/test-machine-readable-workflow-contracts.sh
bash tests/claude-code/test-document-review-system.sh
bash tests/claude-code/test-subagent-driven-development.sh
bash tests/opencode/test-tools.sh
bash tests/claude-code/test-reviewer-contract-drift.sh
```

Expected:
- prompt-contract test PASS
- Claude document-review test PASS
- SDD behavior smoke PASS
- OpenCode tools test PASS or documented SKIP
- drift-matrix test PASS

- [ ] **Step 8: Record the evidence paths and latest results in `docs/testing.md`**

After the verification run, fill the evidence ledger with:
- the two transcript fixture paths captured in Task 2
- the latest result of `tests/claude-code/test-subagent-driven-development.sh`, including whether the subagent-consent negative assertion passed
- the latest result of `tests/claude-code/test-reviewer-contract-drift.sh`, including whether the second-runner / second-model branch passed or skipped

- [ ] **Step 9: Commit**

```bash
git add \
  tests/opencode/test-tools.sh \
  tests/claude-code/test-reviewer-contract-drift.sh \
  docs/testing.md
git commit -m "test: add workflow contract drift matrix"
```
