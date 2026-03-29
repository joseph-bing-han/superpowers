# Imported Skill Endgate Override Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 防止 assistant 在读取 imported / lower-priority explore guidance 后，被“no required ending / just provide clarity / continue later”一类自由收尾语义带偏，重新出现 prose-only recommendation + `task_complete` 的 endgate 漏口。

**Architecture:** 先用一条贴近真实事故的 session-shaped transcript fixture 把问题钉成失败测试，再最小修改 repo-managed bootstrap、核心入口 skill 与 Codex 使用文档，显式声明 imported skill ending guidance 不能削弱 strict packet mode。最后扩展 prompt-contract 与 runtime audit，使这条覆盖关系既有 guidance 断言，也有 transcript 级回归证据。

**Tech Stack:** Bash, jq, ripgrep, OpenSpec markdown artifacts, repo-managed Codex instruction bootstrap

---

**OpenSpec Change:** harden-imported-skill-endgate-overrides

### Task 1: Add the failing incident-shaped transcript coverage

**Files:**
- Create: `tests/codex/fixtures/runtime-prose-endgate-imported-explore-skill-negative.jsonl`
- Modify: `tests/codex/test-runtime-endgate-transcript-audit.sh`
- Test: `tests/codex/test-runtime-endgate-transcript-audit.sh`

**Execution Metadata:**
- Depends on: none
- Write Set:
  - `tests/codex/fixtures/runtime-prose-endgate-imported-explore-skill-negative.jsonl`
  - `tests/codex/test-runtime-endgate-transcript-audit.sh`
- Conflict Group: `runtime-endgate-audit`
- Risk Level: low
- Parallelizable: no

- [ ] **Step 1: Write the new negative transcript fixture first**

Create `tests/codex/fixtures/runtime-prose-endgate-imported-explore-skill-negative.jsonl` with a minimal session-shaped transcript that includes:
- strict packet mode evidence from repo-managed instruction
- imported explore guidance text containing `There's no required ending`, `Just provide clarity`, and `Continue later`
- a final assistant report containing recommendation-style closeout text
- a trailing `task_complete`
- no canonical carrier and no `request_user_input`

- [ ] **Step 2: Wire the fixture into the audit script as a failing expectation**

Modify `tests/codex/test-runtime-endgate-transcript-audit.sh` to:
- declare the new fixture path near the other negative fixtures
- assert the file exists
- add an `assert_audit_fails` check with a description tied to imported-skill drift

- [ ] **Step 3: Run the targeted audit test and verify RED**

Run:
```bash
bash tests/codex/test-runtime-endgate-transcript-audit.sh
```

Expected:
- FAIL because the new fixture is missing from the script or fails the new imported-skill drift assertion until the script is updated correctly

- [ ] **Step 4: Re-run after script wiring and confirm the suite still fails for the right reason if fixture content is wrong**

Run:
```bash
bash tests/codex/test-runtime-endgate-transcript-audit.sh
```

Expected:
- The suite passes only when the fixture is audit-negative for the imported-skill leak shape

- [ ] **Step 5: Commit**

```bash
git add tests/codex/fixtures/runtime-prose-endgate-imported-explore-skill-negative.jsonl tests/codex/test-runtime-endgate-transcript-audit.sh
git commit -m "test: cover imported skill endgate drift"
```

### Task 2: Harden repo-managed override guidance

**Files:**
- Modify: `.codex/instruction.md`
- Modify: `skills/using-superpowers/SKILL.md`
- Modify: `docs/README.codex.md`
- Test: `tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`

**Execution Metadata:**
- Depends on: Task 1
- Write Set:
  - `.codex/instruction.md`
  - `skills/using-superpowers/SKILL.md`
  - `docs/README.codex.md`
  - `tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`
- Conflict Group: `imported-skill-override-guidance`
- Risk Level: medium
- Parallelizable: no

- [ ] **Step 1: Extend the prompt-contract test with a failing imported-skill override assertion**

Modify `tests/prompt-contracts/test-machine-readable-workflow-contracts.sh` so it fails unless:
- `.codex/instruction.md` explicitly says imported / lower-priority skills cannot relax strict packet mode
- `skills/using-superpowers/SKILL.md` mirrors that rule
- `docs/README.codex.md` documents the same override for Codex users
- the wording references `no required ending`, `just provide clarity`, and `continue later` as overridden examples

- [ ] **Step 2: Run the prompt-contract test and verify RED**

Run:
```bash
bash tests/prompt-contracts/test-machine-readable-workflow-contracts.sh
```

Expected:
- FAIL because the new imported-skill override assertions are not yet satisfied

- [ ] **Step 3: Apply the minimal guidance changes**

Update:
- `.codex/instruction.md` with the highest-priority override rule
- `skills/using-superpowers/SKILL.md` with the workflow-entry equivalent
- `docs/README.codex.md` with user-facing explanation that repo-managed bootstrap overrides imported ending stances

Constraints:
- do not claim the repo modifies upstream OpenSpec skills
- do not change canonical packet semantics
- keep the new wording concise and specific to strict packet mode conflicts

- [ ] **Step 4: Re-run the prompt-contract test and verify GREEN**

Run:
```bash
bash tests/prompt-contracts/test-machine-readable-workflow-contracts.sh
```

Expected:
- PASS with the new imported-skill override assertions satisfied

- [ ] **Step 5: Commit**

```bash
git add .codex/instruction.md skills/using-superpowers/SKILL.md docs/README.codex.md tests/prompt-contracts/test-machine-readable-workflow-contracts.sh
git commit -m "fix: override imported skill endgate drift"
```

### Task 3: Run integrated verification and sync the OpenSpec change

**Files:**
- Modify: `openspec/changes/harden-imported-skill-endgate-overrides/tasks.md`
- Test: `tests/codex/test-runtime-endgate-transcript-audit.sh`
- Test: `tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`
- Test: `tests/prompt-contracts/test-universal-terminal-endgate-protocol.sh`

**Execution Metadata:**
- Depends on: Task 2
- Write Set:
  - `openspec/changes/harden-imported-skill-endgate-overrides/tasks.md`
- Conflict Group: `verification-and-openspec-sync`
- Risk Level: low
- Parallelizable: preflight-only

- [ ] **Step 1: Run the full targeted verification set**

Run:
```bash
bash tests/codex/test-runtime-endgate-transcript-audit.sh
bash tests/prompt-contracts/test-machine-readable-workflow-contracts.sh
bash tests/prompt-contracts/test-universal-terminal-endgate-protocol.sh
openspec validate harden-imported-skill-endgate-overrides
```

Expected:
- all scripts PASS
- `openspec validate` reports success

- [ ] **Step 2: If any verification fails, fix only the smallest cause and re-run the same command set**

Do not widen scope. Keep fixes inside:
- imported-skill override guidance
- the new incident-shaped fixture
- the related prompt-contract expectations

- [ ] **Step 3: Mark completed OpenSpec tasks**

Update `openspec/changes/harden-imported-skill-endgate-overrides/tasks.md`:
- mark 1.1–3.2 complete after verification succeeds
- leave nothing unchecked if implementation is fully done

- [ ] **Step 4: Commit**

```bash
git add openspec/changes/harden-imported-skill-endgate-overrides/tasks.md
git commit -m "docs: sync imported skill endgate hardening tasks"
```
