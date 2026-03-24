# Close Runtime Prose Endgate Leaks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the real Codex runtime prose-endgate leak path and align tool-backed terminal-choice with the client-provided free-form `Other/notes` fallback.

**Architecture:** First update the human guidance and static contracts so every terminal-endgate file stops hardcoding `3. 自由输入` and explicitly forbids prose-only next-step invitations. Then add transcript-level runtime auditing with incident-based fixtures, and finally update docs plus verification so future releases prove both the documented contract and the real event sequence behavior.

**Tech Stack:** Markdown skill specs, OpenSpec artifacts, shell-based prompt-contract tests, jq-based Codex transcript checks

---

**OpenSpec Change:** `close-runtime-prose-endgate-leaks`

### Task 1: Update terminal-endgate guidance and static contract wording

**Files:**
- Modify: `skills/using-superpowers/SKILL.md`
- Modify: `skills/brainstorming/SKILL.md`
- Modify: `skills/systematic-debugging/SKILL.md`
- Modify: `skills/executing-plans/SKILL.md`
- Modify: `skills/subagent-driven-development/SKILL.md`
- Modify: `skills/writing-plans/SKILL.md`
- Modify: `skills/using-git-worktrees/SKILL.md`
- Modify: `skills/requesting-code-review/SKILL.md`
- Modify: `skills/receiving-code-review/SKILL.md`
- Modify: `skills/test-driven-development/SKILL.md`
- Modify: `skills/verification-before-completion/SKILL.md`
- Modify: `skills/dispatching-parallel-agents/SKILL.md`
- Modify: `skills/finishing-a-development-branch/SKILL.md`
- Modify: `skills/writing-skills/SKILL.md`
- Modify: `spec-governed-development/SKILL.md`
- Modify: `docs/README.codex.md`

- [ ] **Step 1: Inventory every fixed `1/2/3` terminal-choice block**

```bash
rg -n '1\. 结束|2\. 继续|3\. 自由输入|fixed terminal-choice options|终局选择' \
  skills spec-governed-development docs/README.codex.md
```

Expected: hits in every terminal-endgate protocol block plus the Codex README autonomous-continuation section.

- [ ] **Step 2: Patch the global contract first**

Use `apply_patch` to update `skills/using-superpowers/SKILL.md` and `docs/README.codex.md` so they say:

```md
- In tool-backed terminal-choice popups, author only:
  1. 结束
  2. 继续
- Treat free-form requirements as the client-provided `Other` / notes path instead of adding an explicit `3. 自由输入`.
```

Expected: the global contract becomes the canonical wording other files can mirror.

- [ ] **Step 3: Patch every local skill terminal-endgate section**

For each file listed above, replace the old terminal block:

```md
1. 结束
2. 继续
3. 自由输入
```

with wording that keeps explicit authored options to `结束 / 继续` and tells the assistant to rely on the client-provided free-form path for anything outside those options.

Run:

```bash
rg -n '3\. 自由输入' \
  skills spec-governed-development docs/README.codex.md
```

Expected: no remaining Codex tool-backed terminal-choice block still hardcodes explicit `3. 自由输入`.

- [ ] **Step 4: Add explicit prose-leak examples to the core guidance**

Patch `skills/using-superpowers/SKILL.md`, `skills/brainstorming/SKILL.md`, and `skills/systematic-debugging/SKILL.md` to include the concrete anti-pattern:

```text
如果你同意，我下一步可以直接按这个推荐方案 A 开始修。
```

and state that this path must resolve to either `request_user_input` or `auto-continue`, never `task_complete`.

- [ ] **Step 5: Record the stale-test baseline before Task 2 rewrites the assertions**

Run:

```bash
bash tests/prompt-contracts/test-universal-terminal-endgate-protocol.sh
```

Expected: FAIL first because the assertions still expect explicit `1/2/3`, proving Task 2 is required next.
Expected: PASS, because the current universal terminal-endgate test still uses an over-broad `1|2|3` regex and therefore cannot yet distinguish the new authored-options contract. Record this as stale-baseline evidence for Task 2.

### Task 2: Update prompt-contract tests and README/testing docs for the new terminal-choice shape

**Files:**
- Modify: `tests/prompt-contracts/test-universal-terminal-endgate-protocol.sh`
- Modify: `tests/prompt-contracts/test-nonterminal-workflow-gates.sh`
- Modify: `tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`
- Modify: `tests/prompt-contracts/test-numeric-choice-interactions.sh`
- Modify: `docs/testing.md`

- [ ] **Step 1: Find every assertion that hardcodes `1/2/3` as the authored popup payload**

```bash
rg -n '1\\\. 结束|2\\\. 继续|3\\\. 自由输入|mandatory 1/2/3|fixed terminal-choice options' \
  tests/prompt-contracts docs/testing.md
```

Expected: direct hits in universal terminal-endgate tests, nonterminal workflow gate tests, and testing docs.

- [ ] **Step 2: Update prompt-contract expectations**

Patch the test files so they assert:

- terminal completion still requires `request_user_input`
- tool-backed terminal-choice explicitly authors `结束` and `继续`
- free-form input is handled by the client-provided `Other` / notes path rather than an authored slot `3`

Use wording like:

```bash
'结束.*继续|continue.*stop'
'client-provided Other|自动追加的 Other|notes path'
```

- [ ] **Step 3: Update `docs/testing.md` smoke-test language**

Change the terminal-choice evidence description from:

```md
1. 结束
2. 继续
3. 自由输入
```

to language that distinguishes:

- assistant-authored options: `结束 (Recommended)`, `继续`
- client UI fallback: automatic `Other/notes`

- [ ] **Step 4: Run prompt-contract suites**

Run:

```bash
bash tests/prompt-contracts/test-universal-terminal-endgate-protocol.sh
bash tests/prompt-contracts/test-nonterminal-workflow-gates.sh
bash tests/prompt-contracts/test-machine-readable-workflow-contracts.sh
bash tests/prompt-contracts/test-numeric-choice-interactions.sh
```

Expected: PASS after the assertions are updated to the new authored-options contract.

### Task 3: Add runtime transcript endgate auditing and incident-based fixtures

**Files:**
- Create: `tests/codex/test-runtime-endgate-transcript-audit.sh`
- Create: `tests/codex/fixtures/runtime-prose-endgate-leak-negative.jsonl`
- Create: `tests/codex/fixtures/runtime-prose-endgate-repaired-request-user-input.jsonl`
- Create: `tests/codex/fixtures/runtime-prose-endgate-repaired-autocontinue.jsonl`
- Modify: `tests/codex/fixtures/request-user-input-terminal-choice.jsonl`
- Modify: `tests/codex/test-request-user-input-transcript-fixtures.sh`

- [ ] **Step 1: Capture the minimal negative fixture from the 2026-03-24 incident**

Build `tests/codex/fixtures/runtime-prose-endgate-leak-negative.jsonl` from the real session sequence that includes:

- the assistant prose-only next-step invitation
- the immediate `task_complete`
- no `request_user_input`

Keep only the minimum turn-local records required for deterministic checking.

- [ ] **Step 2: Update the positive terminal-choice fixture**

Patch `tests/codex/fixtures/request-user-input-terminal-choice.jsonl` so its authored payload becomes:

```json
"options": [
  {"label": "结束 (Recommended)", "...": "..."},
  {"label": "继续", "...": "..."}
]
```

Do not try to serialize the client-added `Other/notes` option into the assistant-authored payload.

- [ ] **Step 3: Add the runtime endgate linter script**

Create `tests/codex/test-runtime-endgate-transcript-audit.sh` with `bash + jq` logic that:

```bash
1. groups records by turn
2. finds turns with task_complete
3. inspects the last assistant-authored message before task_complete
4. fails when the turn contains:
   - invitation prose pattern
   - task_complete
   - no request_user_input
   - no explicit auto-continue action evidence
```

Start with a minimal pattern set including:

- `如果你同意`
- `我下一步可以`
- `I can .* next if you agree`

- [ ] **Step 4: Extend fixture checks**

Patch `tests/codex/test-request-user-input-transcript-fixtures.sh` so the terminal-choice assertion changes from:

```bash
["结束 (Recommended)", "继续", "自由输入"]
```

to:

```bash
["结束 (Recommended)", "继续"]
```

Add a note in the assertion description that free-form fallback is client-provided.

- [ ] **Step 5: Run the Codex transcript checks**

Run:

```bash
bash tests/codex/test-request-user-input-transcript-fixtures.sh
bash tests/codex/test-runtime-endgate-transcript-audit.sh
```

Expected:
- the positive fixture test passes with two authored options
- the negative incident fixture is rejected
- the repaired fixtures pass

### Task 4: Close the loop with docs, OpenSpec validation, and final verification

**Files:**
- Modify: `docs/testing.md`
- Modify: `openspec/changes/close-runtime-prose-endgate-leaks/tasks.md`

- [ ] **Step 1: Mark the OpenSpec team tasks that implementation has satisfied**

After finishing the code and tests above, check off the completed items in:

```md
openspec/changes/close-runtime-prose-endgate-leaks/tasks.md
```

- [ ] **Step 2: Re-run OpenSpec validation**

Run:

```bash
openspec validate close-runtime-prose-endgate-leaks --type change
```

Expected: `Change 'close-runtime-prose-endgate-leaks' is valid`

- [ ] **Step 3: Re-run the combined regression set**

Run:

```bash
bash tests/prompt-contracts/test-universal-terminal-endgate-protocol.sh
bash tests/prompt-contracts/test-nonterminal-workflow-gates.sh
bash tests/prompt-contracts/test-machine-readable-workflow-contracts.sh
bash tests/prompt-contracts/test-numeric-choice-interactions.sh
bash tests/codex/test-request-user-input-transcript-fixtures.sh
bash tests/codex/test-runtime-endgate-transcript-audit.sh
```

Expected: all PASS.

- [ ] **Step 4: Capture the final git state and summarize**

Run:

```bash
git status --short
```

Expected: only the intentional change files are modified or added.

- [ ] **Step 5: Commit**

```bash
git add skills spec-governed-development docs tests openspec/changes/close-runtime-prose-endgate-leaks
git commit -m "fix: harden codex terminal endgate runtime behavior"
```

Expected: one clean commit covering guidance, tests, fixtures, and OpenSpec task updates for this change.
