# Packet-First Endgate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the first production slice of `endgate-state-packet` so runtime endgate validation stops relying on prose-first inference.

**Architecture:** First add packet-shaped Codex transcript fixtures plus shared parsing helpers, so packet data becomes a stable input instead of ad-hoc jq logic. Then upgrade the runtime audit script to validate the last declared packet and its post-packet event window, while retaining legacy prose leak detection as a fallback. Finally update guidance and testing docs so packet-first becomes the repository contract rather than a hidden test detail.

**Tech Stack:** Bash, jq, Markdown, JSONL transcript fixtures, OpenSpec

---

**OpenSpec Change:** `protocolize-runtime-endgate-state`

### Task 1: Add packet fixtures and reusable packet parsers

**Files:**
- Modify: `tests/shared/workflow-contract-helpers.sh`
- Create: `tests/codex/fixtures/runtime-endgate-packet-autocontinue-positive.jsonl`
- Create: `tests/codex/fixtures/runtime-endgate-packet-terminal-choice-positive.jsonl`
- Create: `tests/codex/fixtures/runtime-endgate-packet-unfulfilled-negative.jsonl`

**Execution Metadata:**
- Depends on: none
- Write Set:
  - `tests/shared/workflow-contract-helpers.sh`
  - `tests/codex/fixtures/runtime-endgate-packet-autocontinue-positive.jsonl`
  - `tests/codex/fixtures/runtime-endgate-packet-terminal-choice-positive.jsonl`
  - `tests/codex/fixtures/runtime-endgate-packet-unfulfilled-negative.jsonl`
- Conflict Group: `endgate-packet-runtime`
- Risk Level: medium
- Parallelizable: preflight-only

- [ ] **Step 1: Define the canonical packet shape in transcript fixtures**

Create minimal JSONL fixtures whose assistant message tail contains:

```text
ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: ...
ENDGATE_CHOICE_KIND: ...
ENDGATE_NEXT_ACTION: ...
```

- [ ] **Step 2: Add shared helper functions to extract the last packet**

Extend `tests/shared/workflow-contract-helpers.sh` with helpers that can:

```bash
extract_endgate_packet_block <file>
extract_endgate_packet_field <file> <key>
```

The helpers should follow the repository’s existing “last tail block wins” behavior.

- [ ] **Step 3: Verify the fixtures are structurally parseable**

Run: `jq -e -s 'length > 0' tests/codex/fixtures/runtime-endgate-packet-autocontinue-positive.jsonl`

Expected: PASS

- [ ] **Step 4: Verify the helper does not break existing tail-block extraction**

Run: `bash tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`

Expected: PASS

### Task 2: Upgrade runtime endgate auditing to packet-first semantics

**Files:**
- Modify: `tests/codex/test-runtime-endgate-transcript-audit.sh`
- Modify: `tests/codex/test-request-user-input-transcript-fixtures.sh`

**Execution Metadata:**
- Depends on: Task 1
- Write Set:
  - `tests/codex/test-runtime-endgate-transcript-audit.sh`
  - `tests/codex/test-request-user-input-transcript-fixtures.sh`
- Conflict Group: `endgate-packet-runtime`
- Risk Level: high
- Parallelizable: no

- [ ] **Step 1: Write the failing packet-first assertions**

Update the runtime audit script expectations so packet-positive fixtures must pass and the unfulfilled packet fixture must fail before implementation is finished.

- [ ] **Step 2: Parse the last declared packet before validating the turn**

Implement logic that:

```text
1. finds the last packet in the turn
2. opens a validation window from that packet forward
3. checks packet-state / next-action fulfillment
4. falls back to legacy prose leak detection only if no packet exists
```

- [ ] **Step 3: Distinguish packet failure modes**

The script output should distinguish at least:

- missing packet path using legacy prose safety net
- declared-but-unfulfilled packet
- valid packet-driven terminal-choice / auto-continue

- [ ] **Step 4: Re-run the Codex transcript suites**

Run:

```bash
bash tests/codex/test-runtime-endgate-transcript-audit.sh
bash tests/codex/test-request-user-input-transcript-fixtures.sh
```

Expected: PASS

### Task 3: Migrate guidance and testing docs to the packet-first contract

**Files:**
- Modify: `skills/using-superpowers/SKILL.md`
- Modify: `docs/README.codex.md`
- Modify: `docs/testing.md`
- Modify: `tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`
- Modify: `tests/prompt-contracts/test-nonterminal-workflow-gates.sh`

**Execution Metadata:**
- Depends on: Task 2
- Write Set:
  - `skills/using-superpowers/SKILL.md`
  - `docs/README.codex.md`
  - `docs/testing.md`
  - `tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`
  - `tests/prompt-contracts/test-nonterminal-workflow-gates.sh`
- Conflict Group: `endgate-packet-contracts`
- Risk Level: medium
- Parallelizable: preflight-only

- [ ] **Step 1: Update global guidance to declare packet-first endgate handling**

Document that endgate validation now prefers:

```text
endgate-state-packet > request_user_input / transcript events > legacy prose safety net
```

- [ ] **Step 2: Update testing docs and prompt-contract expectations**

Make the prompt-contract suite assert the new packet-first wording without removing the existing `request_user_input` machine contract.

- [ ] **Step 3: Run the contract regression suites**

Run:

```bash
bash tests/prompt-contracts/test-machine-readable-workflow-contracts.sh
bash tests/prompt-contracts/test-nonterminal-workflow-gates.sh
openspec validate protocolize-runtime-endgate-state --type change --json
```

Expected: PASS
