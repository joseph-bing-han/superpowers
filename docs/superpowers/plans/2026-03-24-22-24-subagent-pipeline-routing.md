# Subagent Pipeline Routing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the approved subagent pipeline routing design by adding planner metadata, pipeline execution contracts, routing documentation, and regression tests.

**Architecture:** Start with a new prompt-contract regression test that freezes the desired routing and metadata semantics. Then update `writing-plans` and `subagent-driven-development` to express the new schema and pipeline state machine, extend the global routing/docs layer, and finish with focused regression suites that prove the new contracts without changing the Codex runtime itself.

**Tech Stack:** Markdown skill specs, Markdown docs, Bash prompt-contract tests, ripgrep-based assertions

---

### Task 1: Add a failing routing-contract regression test

**Files:**
- Create: `tests/prompt-contracts/test-subagent-pipeline-routing.sh`

- [ ] **Step 1: Create the new regression test file**

Create `tests/prompt-contracts/test-subagent-pipeline-routing.sh` with the same helper structure used by the existing prompt-contract tests:

```bash
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
```

- [ ] **Step 2: Add the exact assertions for pipeline routing semantics**

Append these assertions:

```bash
assert_section_contains "skills/writing-plans/SKILL.md" "## Task Structure" 'Execution Metadata' "writing-plans defines the execution metadata block" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Task Structure" 'Depends on' "writing-plans includes Depends on in task metadata" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Task Structure" 'Write Set' "writing-plans includes Write Set in task metadata" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Task Structure" 'Conflict Group' "writing-plans includes Conflict Group in task metadata" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Task Structure" 'Risk Level' "writing-plans includes Risk Level in task metadata" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Task Structure" 'Parallelizable' "writing-plans includes Parallelizable in task metadata" '^## '
assert_section_contains "skills/writing-plans/SKILL.md" "## Task Structure" 'Parallelizable.*no \| preflight-only \| yes|no \| preflight-only \| yes.*Parallelizable' "writing-plans freezes the Parallelizable enum" '^## '
assert_section_contains "skills/subagent-driven-development/SKILL.md" "## The Process" 'Pipeline SDD' "subagent-driven-development names Pipeline SDD" '^## '
assert_section_contains "skills/subagent-driven-development/SKILL.md" "## The Process" 'queued.*preflight.*ready.*implementing.*spec_review.*quality_review.*done.*blocked|blocked.*queued.*preflight.*ready.*implementing.*spec_review.*quality_review.*done' "subagent-driven-development defines the full pipeline state machine" '^## '
assert_section_contains "skills/subagent-driven-development/SKILL.md" "## The Process" 'implementer \+ preflight' "subagent-driven-development requires implementer plus preflight overlap" '^## '
assert_section_contains "skills/subagent-driven-development/SKILL.md" "## The Process" 'reviewer \+ preflight' "subagent-driven-development requires reviewer plus preflight overlap" '^## '
assert_section_contains "skills/subagent-driven-development/SKILL.md" "## The Process" 'Risk Level.*Depends on.*Conflict Group.*Write Set.*Parallelizable|Parallelizable.*Write Set.*Conflict Group.*Depends on.*Risk Level' "subagent-driven-development documents routing priority" '^## '
assert_contains "skills/using-superpowers/SKILL.md" 'Serial SDD' "using-superpowers documents Serial SDD"
assert_contains "skills/using-superpowers/SKILL.md" 'Pipeline SDD' "using-superpowers documents Pipeline SDD"
assert_contains "skills/using-superpowers/SKILL.md" 'Parallel Dispatch' "using-superpowers documents Parallel Dispatch"
assert_contains "skills/dispatching-parallel-agents/SKILL.md" 'execution[- ]time' "dispatching-parallel-agents mentions execution-time routing"
assert_contains "skills/dispatching-parallel-agents/SKILL.md" 'independent lane' "dispatching-parallel-agents mentions independent lanes"
assert_contains "skills/dispatching-parallel-agents/SKILL.md" 'Write Set' "dispatching-parallel-agents mentions Write Set boundaries"
assert_contains "skills/dispatching-parallel-agents/SKILL.md" 'Conflict Group' "dispatching-parallel-agents mentions Conflict Group boundaries"
assert_contains "docs/README.codex.md" 'Pipeline SDD' "Codex README documents Pipeline SDD"
assert_contains "docs/README.codex.md" 'Execution Metadata' "Codex README documents Execution Metadata"
assert_contains "docs/README.codex.md" 'Parallel Dispatch' "Codex README documents Parallel Dispatch"

echo "All subagent pipeline routing prompt contract checks passed."
```

- [ ] **Step 3: Run the new test to capture the expected failing baseline**

Run:

```bash
bash tests/prompt-contracts/test-subagent-pipeline-routing.sh
```

Expected: FAIL, because none of the new routing contract wording exists yet.

- [ ] **Step 4: Commit the failing test scaffold**

```bash
git add tests/prompt-contracts/test-subagent-pipeline-routing.sh
git commit -m "test: add subagent pipeline routing contract checks"
```

### Task 2: Add execution metadata schema to writing-plans

**Files:**
- Modify: `skills/writing-plans/SKILL.md`

- [ ] **Step 1: Extend the Task Structure section with execution metadata**

Update the `## Task Structure` example so every task includes this exact metadata block before the checklist steps:

```md
**Execution Metadata:**
- Depends on: none
- Write Set:
  - `path/to/file`
- Conflict Group: `example-group`
- Risk Level: low
- Parallelizable: preflight-only
```

- [ ] **Step 2: Add explicit schema rules below the task example**

Add exact bullet rules for:

```md
- `Depends on`: `none` or comma-separated task references; gates `ready` / `implementing`
- `Write Set`: exact paths or `/**` directory prefixes; no bare `*`
- `Conflict Group`: one slug only
- `Risk Level`: `low | medium | high`
- `Parallelizable`: `no | preflight-only | yes`
```

Also add planner constraints that:

```md
1. Every task must include `Execution Metadata`
2. Prefer exact paths in `Write Set`
3. Reuse one consistent `Conflict Group` vocabulary per plan
4. If `Parallelizable: yes` is not clearly justified, downgrade to `preflight-only` or `no`
```

- [ ] **Step 3: Re-run the new routing contract test**

Run:

```bash
bash tests/prompt-contracts/test-subagent-pipeline-routing.sh
```

Expected: The `writing-plans` assertions pass, while the test still fails on missing execution-mode and pipeline wording elsewhere.

- [ ] **Step 4: Commit the schema update**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "feat: add execution metadata schema to writing plans"
```

### Task 3: Upgrade subagent-driven-development to Pipeline SDD

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`

- [ ] **Step 1: Add the three-mode execution framing**

Near the overview or process framing, explicitly introduce:

```md
- `Serial SDD`
- `Pipeline SDD`
- `Parallel Dispatch`
```

Make `Pipeline SDD` the default same-session execution mode.

- [ ] **Step 2: Rewrite the process section to include pipeline state and gating**

Add wording that freezes:

```md
- task states: `queued`, `preflight`, `ready`, `implementing`, `spec_review`, `quality_review`, `done`, `blocked`
- `Depends on` only gates `ready` / `implementing`
- `preflight` may start early only when unresolved dependencies do not change file scope, requirement meaning, or acceptance
- if an unresolved dependency would change those boundaries, the task stays `blocked`
```

- [ ] **Step 3: Replace the blanket no-parallel rule with conflict-aware rules**

In `## Red Flags` and the main process wording, change the current absolute “never dispatch multiple implementation subagents in parallel” into the more precise contract:

```md
- Never allow multiple implementation subagents to write within the same `Conflict Group`
- Require both `implementer + preflight` and `reviewer + preflight` overlap in Pipeline SDD
- Allow only read-only overlap unless the plan explicitly qualifies for `Parallel Dispatch`
```

- [ ] **Step 4: Add a routing-priority sentence**

Insert wording equivalent to:

```md
Routing priority is:
`Risk Level` > dependency changes task boundary > `Conflict Group` / `Write Set` > `Parallelizable`
```

- [ ] **Step 5: Run the routing contract test again**

Run:

```bash
bash tests/prompt-contracts/test-subagent-pipeline-routing.sh
```

Expected: The `subagent-driven-development` assertions now pass; remaining failures should be in `using-superpowers`, `dispatching-parallel-agents`, or `docs/README.codex.md`.

- [ ] **Step 6: Commit the pipeline execution update**

```bash
git add skills/subagent-driven-development/SKILL.md
git commit -m "feat: define pipeline sdd execution contract"
```

### Task 4: Document routing globally and reposition parallel dispatch

**Files:**
- Modify: `skills/using-superpowers/SKILL.md`
- Modify: `skills/dispatching-parallel-agents/SKILL.md`
- Modify: `docs/README.codex.md`
- Modify: `docs/testing.md`

- [ ] **Step 1: Add the global routing explanation to using-superpowers**

Add a concise section or paragraph that distinguishes:

```md
- `Serial SDD` for high-risk or tightly coupled work
- `Pipeline SDD` as the default same-session execution model
- `Parallel Dispatch` for disjoint write sets and independent lanes
```

- [ ] **Step 2: Reposition dispatching-parallel-agents as an execution-time lane upgrade**

Update `skills/dispatching-parallel-agents/SKILL.md` so it no longer reads as “debugging only”. Make it explicitly mention:

```md
- execution-time independent lanes
- disjoint `Write Set`
- disjoint `Conflict Group`
- safe upgrade path from `Pipeline SDD`
```

- [ ] **Step 3: Update Codex-facing docs**

In `docs/README.codex.md`, document:

```md
- the three execution modes
- `Execution Metadata`
- Pipeline SDD as the default behavior when subagents are available
- Parallel Dispatch as a conditional upgrade, not a default promise
```

- [ ] **Step 4: Add the new regression test to the testing guide**

In `docs/testing.md`, add both of these commands to the documented regression list:

```bash
bash tests/prompt-contracts/test-subagent-pipeline-routing.sh
bash tests/codex/test-subagent-pipeline-routing-fixtures.sh
```

Describe the first as the routing/metadata prompt-contract regression, and the second as the transcript/fixture evidence check for Pipeline overlap and conflict guard semantics.

- [ ] **Step 5: Run the routing contract test**

Run:

```bash
bash tests/prompt-contracts/test-subagent-pipeline-routing.sh
```

Expected: PASS, with all routing, metadata, and documentation assertions green.

- [ ] **Step 6: Commit the global documentation updates**

```bash
git add skills/using-superpowers/SKILL.md \
        skills/dispatching-parallel-agents/SKILL.md \
        docs/README.codex.md \
        docs/testing.md
git commit -m "docs: document subagent pipeline routing"
```

### Task 5: Add transcript fixtures for pipeline overlap and conflict guards

**Files:**
- Create: `tests/codex/fixtures/pipeline-sdd-overlap-positive.jsonl`
- Create: `tests/codex/fixtures/pipeline-sdd-conflict-group-negative.jsonl`
- Create: `tests/codex/test-subagent-pipeline-routing-fixtures.sh`

- [ ] **Step 1: Create the fixture audit script**

Create `tests/codex/test-subagent-pipeline-routing-fixtures.sh` with `bash` + `jq` assertions that:

```bash
1. load `pipeline-sdd-overlap-positive.jsonl`
2. require evidence that the positive fixture separately proves:
   - `implementer + preflight` overlap
   - `reviewer + preflight` overlap
3. load `pipeline-sdd-conflict-group-negative.jsonl`
4. reject the negative fixture when it contains two overlapping implementation events in the same `Conflict Group`
5. return overall PASS only when:
   - the positive fixture satisfies both overlap checks
   - the negative fixture is correctly rejected
```

Use explicit PASS / FAIL output per fixture, and end with:

```bash
echo "All subagent pipeline routing fixture checks passed."
```

- [ ] **Step 2: Add the positive and negative fixtures**

Create minimal JSONL fixtures that encode:

```text
Positive fixture:
- one implementer lane
- one preflight lane that overlaps the implementing window
- one reviewer window with overlapping preflight evidence
- no duplicate implementer in the same Conflict Group

Negative fixture:
- two implementation lanes
- same Conflict Group
- overlapping write window
```

Keep the fixtures minimal and deterministic so the parser only needs to prove the new contracts, not re-simulate the whole runtime.

- [ ] **Step 3: Run the fixture audit**

Run:

```bash
bash tests/codex/test-subagent-pipeline-routing-fixtures.sh
```

Expected: PASS once the positive fixture proves both required overlap contracts and the negative fixture is correctly rejected by the audit script.

- [ ] **Step 4: Commit the transcript-fixture coverage**

```bash
git add tests/codex/fixtures/pipeline-sdd-overlap-positive.jsonl \
        tests/codex/fixtures/pipeline-sdd-conflict-group-negative.jsonl \
        tests/codex/test-subagent-pipeline-routing-fixtures.sh
git commit -m "test: add subagent pipeline routing fixtures"
```

### Task 6: Run the focused regression suite

**Files:**
- Test: `tests/prompt-contracts/test-subagent-pipeline-routing.sh`
- Test: `tests/codex/test-subagent-pipeline-routing-fixtures.sh`
- Test: `tests/prompt-contracts/test-subagent-session-consent.sh`
- Test: `tests/prompt-contracts/test-worktree-execution-lifecycle.sh`
- Test: `tests/prompt-contracts/test-autonomous-continuation.sh`
- Test: `tests/prompt-contracts/test-universal-terminal-endgate-protocol.sh`
- Test: `tests/prompt-contracts/test-nonterminal-workflow-gates.sh`
- Test: `tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`

- [ ] **Step 1: Run the new routing regression**

Run:

```bash
bash tests/prompt-contracts/test-subagent-pipeline-routing.sh
```

Expected: PASS

- [ ] **Step 2: Re-run the existing workflow contract suites**

Run:

```bash
bash tests/codex/test-subagent-pipeline-routing-fixtures.sh
bash tests/prompt-contracts/test-subagent-session-consent.sh
bash tests/prompt-contracts/test-worktree-execution-lifecycle.sh
bash tests/prompt-contracts/test-autonomous-continuation.sh
bash tests/prompt-contracts/test-universal-terminal-endgate-protocol.sh
bash tests/prompt-contracts/test-nonterminal-workflow-gates.sh
bash tests/prompt-contracts/test-machine-readable-workflow-contracts.sh
```

Expected: PASS across all suites, proving the new routing model did not regress existing workflow contracts and now has both prompt-contract and fixture-level evidence.

- [ ] **Step 3: Inspect git status for unintended changes**

Run:

```bash
git status --short
```

Expected: clean working tree, because all code, docs, and fixture changes were already committed in Tasks 1-5.
