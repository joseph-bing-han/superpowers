# Numeric Choice Tool-Backed Confirmations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make non-dangerous enumerable choices trigger `request_user_input` by default, replace destructive typed confirmations with a two-stage numeric confirmation flow, standardize assistant-authored prose numbering on ASCII `1. ` / `2. ` / `3. `, and add durable prompt-contract plus smoke-test coverage.

**Architecture:** The change stays in the skill-and-doc lane. First encode the new contract in prompt-contract tests, then update the global guidance and the workflow skills that ask for user choices, then replace the destructive branch-discard flow with a two-stage numeric confirmation model where the final destructive action lives in slot `2` of Stage 2, and finally document and execute the smoke-test protocol that proves the last step really triggers `request_user_input`. Assistant-authored prose-numbered options and text fallbacks use ASCII `1. ` / `2. ` / `3. `, while the automatic numbering shown by a `request_user_input` popup is documented as a Codex UI / input-layer boundary rather than a repository-controlled behavior.

**Tech Stack:** Markdown skill docs, Bash prompt-contract tests, Codex `request_user_input` interaction flow

---

### Task 1: Lock the New Global Contract in Tests and Shared Guidance

**Files:**
- Modify: `docs/README.codex.md` (`## Choice-Based Interaction`)
- Modify: `skills/using-superpowers/SKILL.md` (`## User Choice Formatting`)
- Modify: `tests/prompt-contracts/test-numeric-choice-interactions.sh`

- [ ] **Step 1: Extend the prompt-contract test with the new global assertions**

Add assertions that express the new contract directly. The script should check for patterns equivalent to:

```bash
assert_contains "skills/using-superpowers/SKILL.md" "request_user_input" "global rule requires tool-backed choice UI"
assert_contains "skills/using-superpowers/SKILL.md" "two-stage|two stage" "global rule documents two-stage confirmation for dangerous actions"
assert_contains "skills/using-superpowers/SKILL.md" "exact text|precise text|copy" "global rule requires copyable fallback text"
assert_contains "skills/using-superpowers/SKILL.md" "free-text fallback|free text fallback" "global rule still preserves a fallback option when the scene allows it"
assert_not_contains "skills/using-superpowers/SKILL.md" "only when the choice cannot be fully enumerated" "global rule removes the old restrictive fallback wording"
assert_not_contains "skills/using-superpowers/SKILL.md" "Keep typed confirmations for dangerous or destructive actions" "global rule no longer defaults to typed confirmation"
assert_contains "docs/README.codex.md" "request_user_input|tool-backed choice UI" "README describes tool-backed choice UI"
```

- [ ] **Step 2: Run the prompt-contract test to verify it fails before the doc updates**

Run: `bash tests/prompt-contracts/test-numeric-choice-interactions.sh`  
Expected: FAIL on the new `request_user_input`, two-stage confirmation, or copyable fallback assertions.

- [ ] **Step 3: Update `skills/using-superpowers/SKILL.md` to satisfy the new contract**

Update `skills/using-superpowers/SKILL.md` so the “User Choice Formatting” section says, in substance:

```markdown
- For non-dangerous, enumerable choices, prefer actually calling `request_user_input` instead of only writing `1 / 2 / 3` in plain text.
- Do not end with text-only prompts like "reply 1/2/3" when the tool-backed choice UI is available.
- When the scene allows it, keep a final free-text fallback option instead of forcing enumeration only.
- For dangerous or destructive actions, prefer a two-stage confirmation flow: first a numbered confirmation step, then a second numbered confirmation step.
- When you write prose-numbered options or text fallbacks yourself, use ASCII `1. `, `2. `, and `3. ` numbering.
- If text input is still required, show the exact text in the prompt so the user can copy it.
```

- [ ] **Step 4: Update `docs/README.codex.md` to describe the new interaction contract**

Update `docs/README.codex.md` so the “Choice-Based Interaction” section says, in substance:

```markdown
Superpowers now aims for tool-backed choice UI when Codex tools are available, not just numbered prose.
Non-dangerous enumerable choices should use `request_user_input`.
Dangerous enumerable choices should use a two-stage confirmation flow.
Assistant-authored prose-numbered options and text fallbacks should use ASCII `1. `, `2. `, and `3. ` numbering.
True raw single-key submit still depends on the Codex input layer.
The automatic numbering shown inside a `request_user_input` popup belongs to the Codex UI / input-layer boundary.
```

- [ ] **Step 5: Re-run the prompt-contract test**

Run: `bash tests/prompt-contracts/test-numeric-choice-interactions.sh`  
Expected: PASS for the currently injected Task 1 assertions.

- [ ] **Step 6: Commit**

```bash
git add docs/README.codex.md skills/using-superpowers/SKILL.md tests/prompt-contracts/test-numeric-choice-interactions.sh
git commit -m "test: lock tool-backed numeric choice contract"
```

### Task 2: Update Non-Dangerous Workflow Skills to Require Real Choice UI

**Files:**
- Modify: `skills/brainstorming/SKILL.md` (`Presenting the design`, `User Review Gate`)
- Modify: `skills/writing-plans/SKILL.md` (`## Execution Handoff`)
- Modify: `skills/executing-plans/SKILL.md` (`## The Process`, blocker example)
- Test: `tests/prompt-contracts/test-numeric-choice-interactions.sh`

- [ ] **Step 1: Add targeted failing assertions for the three workflow skills**

Extend the prompt-contract script with checks like:

```bash
assert_contains "skills/brainstorming/SKILL.md" "request_user_input" "brainstorming requires tool-backed approvals when choices are enumerable"
assert_contains "skills/writing-plans/SKILL.md" "request_user_input" "writing-plans handoff prefers tool-backed execution choice"
assert_contains "skills/executing-plans/SKILL.md" "request_user_input" "executing-plans blocker prompts prefer tool-backed choice UI"
assert_not_contains "skills/brainstorming/SKILL.md" "Reply with `1`, `2`, or `3`\\.|If you agree, reply" "brainstorming avoids text-only reply prompts"
```

- [ ] **Step 2: Run the prompt-contract test and verify these new checks fail**

Run: `bash tests/prompt-contracts/test-numeric-choice-interactions.sh`  
Expected: FAIL on at least one of the new brainstorming / writing-plans / executing-plans assertions.

- [ ] **Step 3: Update `skills/brainstorming/SKILL.md`**

Replace guidance that only says “use numbered approvals” with wording that explicitly requires real tool-backed choice UI when available. The updated guidance should include text equivalent to:

```markdown
For approval gates and other enumerable choices, prefer `request_user_input` so the user gets a real choice UI instead of only prose numbers.
Do not end a section with plain text like "reply 1/2/3" when the tool is available.
```

- [ ] **Step 4: Update `skills/writing-plans/SKILL.md`**

Make the execution-handoff section explicitly require `request_user_input` for enumerable non-dangerous choices. The updated wording should include text equivalent to:

```markdown
When offering execution-path choices, use `request_user_input` when available.
Do not fall back to prose-only "reply 1/2/3" if the tool-backed choice UI is available.
```

- [ ] **Step 5: Update `skills/executing-plans/SKILL.md`**

Make the blocker-choice sections explicitly require `request_user_input` for enumerable non-dangerous choices. The updated wording should include text equivalent to:

```markdown
When raising blockers or plan concerns with known next actions, use tool-backed choice UI instead of text-only numbered replies.
```

- [ ] **Step 6: Re-run the prompt-contract test**

Run: `bash tests/prompt-contracts/test-numeric-choice-interactions.sh`  
Expected: PASS for the currently injected Task 1 and Task 2 assertions.

- [ ] **Step 7: Commit**

```bash
git add skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md tests/prompt-contracts/test-numeric-choice-interactions.sh
git commit -m "docs: require tool-backed choice UI in workflow skills"
```

### Task 3: Replace Typed Destructive Confirmation with a Two-Stage Model

**Files:**
- Modify: `skills/finishing-a-development-branch/SKILL.md` (`### Step 3: Present Options`, `#### Option 4: Discard`, `Common Mistakes`)
- Test: `tests/prompt-contracts/test-numeric-choice-interactions.sh`

- [ ] **Step 1: Add failing destructive-flow assertions**

Update the prompt-contract script with checks such as:

```bash
assert_contains "skills/finishing-a-development-branch/SKILL.md" "both stages use numbered choices|second numbered confirmation step" "finishing flow documents two-stage numeric destructive confirmation"
assert_contains "skills/finishing-a-development-branch/SKILL.md" "slot `2`|slot 2" "finishing flow keeps the final destructive action behind Stage 2 slot 2"
assert_not_contains "skills/finishing-a-development-branch/SKILL.md" "Type 'discard' to confirm\\.|type `discard`" "finishing flow no longer requires discard typing by default"
assert_contains "skills/finishing-a-development-branch/SKILL.md" "feedback or a help request|补充反馈|求助" "free-input path returns to the same confirmation step"
assert_contains "skills/finishing-a-development-branch/SKILL.md" "invalid token|empty input|stay on the same step" "invalid fallback input does not advance destructive state"
assert_contains "skills/finishing-a-development-branch/SKILL.md" "Stage 1 `2` returns to the parent flow|第.*2.*父流程" "Stage 1 cancel returns to the parent flow or exits safely"
assert_contains "skills/finishing-a-development-branch/SKILL.md" "Stage 2 `1` returns to Stage 1|第.*1.*返回.*第一步" "Stage 2 slot 1 returns to the previous confirmation step"
assert_contains "skills/finishing-a-development-branch/SKILL.md" "only valid token|只有.*合法 token" "only valid tokens can advance the destructive state"
assert_contains "skills/finishing-a-development-branch/SKILL.md" "no parent.*end the destructive subflow|若无父流程.*结束.*不执行" "no-parent branches end safely without executing changes"
```

- [ ] **Step 2: Run the prompt-contract test to verify the destructive-flow checks fail**

Run: `bash tests/prompt-contracts/test-numeric-choice-interactions.sh`  
Expected: FAIL on the `discard`-based assertions.

- [ ] **Step 3: Update `skills/finishing-a-development-branch/SKILL.md`**

Change the destructive option flow so it explicitly uses:

```text
Step 1:
1. Confirm and continue
2. Cancel
3. Input other feedback or requirements

Step 2:
1. Cancel and return to the previous step
2. Confirm discard
3. Input other feedback or requirements
```

The updated skill must also say:

```markdown
- The first and second confirmation steps should use `request_user_input` when available.
- If the tool is unavailable, preserve the same two-step semantics with typed `1/2/3` in both stages.
- Put the final destructive confirmation in slot `2` of Stage 2, and keep slot `1` as the safe return path.
- If a unique confirmation token is still required, show the exact token in the prompt so it can be copied.
- Free-input branches must return to the same confirmation layer they came from.
- Stage 1 cancel must return to the parent flow or end the destructive subflow without executing, and Stage 2 slot `1` must return to Stage 1.
- Invalid fallback input must stay on the current step, re-show legal options, and never auto-cancel or auto-execute.
```

- [ ] **Step 4: Add the explicit state-machine wording to `skills/finishing-a-development-branch/SKILL.md`**

Add prose equivalent to:

```markdown
If the user chooses the free-input path from either step, treat it as feedback or a help request and then re-ask the same step.
If the user chooses Stage 1 cancel, return to the parent flow when it still exists; otherwise end the destructive subflow without making changes.
If the user chooses Stage 2 slot `1`, return to Stage 1.
In text fallback mode, only valid tokens move the state forward; invalid or empty input re-shows the current step.
```

- [ ] **Step 5: Re-run the prompt-contract test**

Run: `bash tests/prompt-contracts/test-numeric-choice-interactions.sh`  
Expected: PASS for all destructive-flow assertions.

- [ ] **Step 6: Commit**

```bash
git add skills/finishing-a-development-branch/SKILL.md tests/prompt-contracts/test-numeric-choice-interactions.sh
git commit -m "docs: use two-stage destructive confirmations"
```

### Task 4: Add Smoke-Test Protocol and Verify the Real Choice UI

**Files:**
- Modify: `docs/testing.md` (`## Numeric Choice Smoke Tests`, evidence appendix)
- Modify: `tests/prompt-contracts/test-numeric-choice-interactions.sh`
- Test: `tests/prompt-contracts/test-numeric-choice-interactions.sh`

- [ ] **Step 1: Extend the prompt-contract test to cover the testing docs and evidence mapping**

Add assertions such as:

```bash
assert_contains "docs/testing.md" "request_user_input" "testing doc requires tool-call evidence"
assert_contains "docs/testing.md" "multi-question|multi question" "testing doc covers multi-question smoke test"
assert_contains "docs/testing.md" "dangerous two-stage|two-stage confirmation" "testing doc covers destructive smoke test"
assert_contains "docs/testing.md" "skills/using-superpowers/SKILL.md" "testing doc includes the global-rule mapping row"
assert_contains "docs/testing.md" "skills/brainstorming/SKILL.md" "testing doc includes the brainstorming mapping row"
assert_contains "docs/testing.md" "skills/writing-plans/SKILL.md" "testing doc includes the writing-plans mapping row"
assert_contains "docs/testing.md" "skills/executing-plans/SKILL.md" "testing doc includes the executing-plans mapping row"
assert_contains "docs/testing.md" "skills/finishing-a-development-branch/SKILL.md" "testing doc includes the finishing-flow mapping row"
assert_contains "docs/testing.md" "transcript|tool call record" "testing doc defines the evidence location"
```

- [ ] **Step 2: Run the prompt-contract test and verify it fails before the testing doc update**

Run: `bash tests/prompt-contracts/test-numeric-choice-interactions.sh`  
Expected: FAIL on the new `docs/testing.md` assertions.

- [ ] **Step 3: Document the smoke-test protocol and evidence requirements**

Update `docs/testing.md` with a dedicated section for numeric-choice verification that lists:

```markdown
1. One non-dangerous final-step prompt that must call `request_user_input`
2. One multi-question prompt that must keep the choice UI across multiple questions
3. One dangerous two-stage confirmation prompt that must use numbers in both stages and place the final confirmation in Stage 2 slot `2`

Required evidence:
- Tool call record or transcript showing `request_user_input`

Recommended evidence:
- Screenshot or operator observation notes
```

Also include a simple mapping table with rows for:

```markdown
| File | Scenario | Assertion Type |
| --- | --- | --- |
| skills/using-superpowers/SKILL.md | global user-choice contract | prompt-contract |
| skills/brainstorming/SKILL.md | approval gate | prompt-contract + smoke |
| skills/writing-plans/SKILL.md | execution handoff | prompt-contract |
| skills/executing-plans/SKILL.md | blocker choice | prompt-contract |
| skills/finishing-a-development-branch/SKILL.md | discard flow | prompt-contract + smoke |
```

Under the same section, add a small evidence log template that names the storage location explicitly:

```markdown
## Latest Numeric Choice Smoke Evidence

- Environment: current Codex interactive session

### Smoke Test A
- Transcript / tool record location: <fill in after running smoke test A>
- Optional screenshot / notes location: <fill in after running smoke test A>

### Smoke Test B
- Transcript / tool record location: <fill in after running smoke test B>
- Optional screenshot / notes location: <fill in after running smoke test B>

### Smoke Test C
- Transcript / tool record location: <fill in after running smoke test C>
- Optional screenshot / notes location: <fill in after running smoke test C>
```

- [ ] **Step 4: Re-run the prompt-contract test and verify it now passes**

Run: `bash tests/prompt-contracts/test-numeric-choice-interactions.sh`  
Expected: PASS for the new testing-doc assertions.

- [ ] **Step 5: Perform the three smoke tests in the live session**

Use `request_user_input` to run these exact interaction categories:

```text
Smoke Test A: One non-dangerous "next step" choice
Smoke Test B: One multi-question numbered-choice interaction
Smoke Test C: One dangerous two-stage confirmation with numeric first step and numeric second step, with the final confirmation in Stage 2 slot `2`
```

Capture the `request_user_input` tool events from the current Codex interactive session as the required evidence. After each smoke test, append the transcript or tool-record location to the `Latest Numeric Choice Smoke Evidence` section in `docs/testing.md`. If possible, also append a screenshot path or operator note.

- [ ] **Step 6: Re-run the prompt-contract test and verify it passes cleanly**

Run: `bash tests/prompt-contracts/test-numeric-choice-interactions.sh`  
Expected: PASS with all numeric-choice assertions satisfied.

- [ ] **Step 7: Commit**

```bash
git add docs/testing.md tests/prompt-contracts/test-numeric-choice-interactions.sh
git commit -m "docs: add numeric choice smoke test protocol"
```
