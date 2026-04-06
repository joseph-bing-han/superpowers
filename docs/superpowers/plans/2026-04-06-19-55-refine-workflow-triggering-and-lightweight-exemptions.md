# Workflow Trigger Governance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 Superpowers 的默认入口改为 Direct Mode，只在显式 skill 名或宽松 workflow 关键词出现时拉起流程，并为简单问答、翻译、文本修改、UI copy-only 建立强制豁免，尤其禁止这类任务误触发 TDD 或被 terminal-choice 弹窗拦截结果。

**Architecture:** 先用 prompt-contract 把“默认不自动拉起 + 轻量任务跳过 workflow/TDD + direct reply 不走 terminal popup”钉成失败断言，再最小修改 bootstrap、核心 skills 与 README 文案。随后补一组 Codex transcript 正向 fixture 证明 Direct Mode 与 workflow 内轻量子任务降级的边界成立，最后再补 skill-triggering 提示词与负向 runner，覆盖“该压住时必须压住”的真实入口场景。

**Tech Stack:** Bash, jq, ripgrep, OpenSpec markdown artifacts, repo-managed Codex instruction bootstrap, skill prompt-contract tests, Codex transcript fixtures

---

**OpenSpec Change:** refine-workflow-triggering-and-lightweight-exemptions

### Task 1: Lock the new direct-mode contract in prompt-contract tests and update the guidance

**Files:**
- Create: `tests/prompt-contracts/test-direct-mode-and-lightweight-exemptions.sh`
- Modify: `.codex/instruction.md`
- Modify: `skills/using-superpowers/SKILL.md`
- Modify: `skills/brainstorming/SKILL.md`
- Modify: `skills/test-driven-development/SKILL.md`
- Modify: `docs/README.codex.md`
- Modify: `README.md`
- Test: `tests/prompt-contracts/test-direct-mode-and-lightweight-exemptions.sh`

**Execution Metadata:**
- Depends on: none
- Write Set:
  - `tests/prompt-contracts/test-direct-mode-and-lightweight-exemptions.sh`
  - `.codex/instruction.md`
  - `skills/using-superpowers/SKILL.md`
  - `skills/brainstorming/SKILL.md`
  - `skills/test-driven-development/SKILL.md`
  - `docs/README.codex.md`
  - `README.md`
- Conflict Group: `direct-mode-guidance`
- Risk Level: medium
- Parallelizable: no

- [ ] **Step 1: Write the failing prompt-contract test first**

Create `tests/prompt-contracts/test-direct-mode-and-lightweight-exemptions.sh` with assertions that fail unless the guidance explicitly states:

```bash
assert_section_contains "skills/using-superpowers/SKILL.md" "## The Rule" \
  'explicit skill name|workflow keyword|Direct Mode|默认.*不自动拉起' \
  "using-superpowers requires explicit entry into workflow mode"

assert_section_contains "skills/test-driven-development/SKILL.md" "## When to Use" \
  'text-only|copy-only|translation|docs-comments|文案修改|文本修改' \
  "TDD exempts non-behavioral text changes"

assert_section_contains "docs/README.codex.md" "## Usage" \
  'explicit skill|workflow keyword|Direct Mode|普通问答.*不.*workflow' \
  "Codex README documents the new direct-mode default"

assert_section_not_contains "README.md" "## How it works" \
  'skills trigger automatically|automatically invoke the relevant' \
  "README no longer promises universal automatic triggering"
```

- [ ] **Step 2: Run the new contract test and verify RED**

Run:
```bash
bash tests/prompt-contracts/test-direct-mode-and-lightweight-exemptions.sh
```

Expected:
- FAIL because current guidance still contains “simple question 也要 check skill / overkill 也要用”
- FAIL because `README.md` 仍然承诺自动触发
- FAIL because TDD 还没有 text-only / copy-only 豁免

- [ ] **Step 3: Apply the minimal guidance changes**

Update the guidance files with these exact behavior changes:

- `.codex/instruction.md`
  - 增加 “Direct Mode is the default unless explicit skill names or allowed workflow keywords are present”
  - 增加 “direct replies and downgraded lightweight subtasks are outside workflow terminal-choice scope”
- `skills/using-superpowers/SKILL.md`
  - 删除或改写 `This is just a simple question` / `The skill is overkill` 两条红旗
  - 新增显式入口规则：只在显式 skill 名或允许的 workflow 关键词下进入 workflow
  - 新增轻量任务 taxonomy：问答、翻译、总结/改写、text-only、UI copy-only、注释/文档修改
  - 新增 workflow 中轻量子任务的 direct handling 降级规则
- `skills/brainstorming/SKILL.md`
  - 增加“普通问答/翻译/文本修改/UI copy-only 不进入 brainstorming”
- `skills/test-driven-development/SKILL.md`
  - 在 `## When to Use` 加入非行为文本改动的硬性豁免
- `docs/README.codex.md` 与 `README.md`
  - 把 “skills trigger automatically” 改为 “显式 skill 或 workflow 关键词拉起”
  - 说明普通问答必须直接输出结果，不应被 terminal popup 拦截

- [ ] **Step 4: Re-run the contract test and verify GREEN**

Run:
```bash
bash tests/prompt-contracts/test-direct-mode-and-lightweight-exemptions.sh
```

Expected:
- PASS with direct-mode default, lightweight exemptions, TDD suppression, and README wording all aligned

- [ ] **Step 5: Commit**

```bash
git add tests/prompt-contracts/test-direct-mode-and-lightweight-exemptions.sh \
  .codex/instruction.md \
  skills/using-superpowers/SKILL.md \
  skills/brainstorming/SKILL.md \
  skills/test-driven-development/SKILL.md \
  docs/README.codex.md \
  README.md
git commit -m "fix: tighten workflow triggering defaults"
```

### Task 2: Add Codex transcript coverage for direct replies and downgraded lightweight subtasks

**Files:**
- Create: `tests/codex/fixtures/runtime-direct-mode-plain-answer-positive.jsonl`
- Create: `tests/codex/fixtures/runtime-direct-mode-lightweight-subtask-positive.jsonl`
- Create: `tests/codex/test-direct-mode-transcript-boundaries.sh`
- Test: `tests/codex/test-direct-mode-transcript-boundaries.sh`

**Execution Metadata:**
- Depends on: Task 1
- Write Set:
  - `tests/codex/fixtures/runtime-direct-mode-plain-answer-positive.jsonl`
  - `tests/codex/fixtures/runtime-direct-mode-lightweight-subtask-positive.jsonl`
  - `tests/codex/test-direct-mode-transcript-boundaries.sh`
- Conflict Group: `direct-mode-transcripts`
- Risk Level: low
- Parallelizable: no

- [ ] **Step 1: Write the boundary test before creating the fixtures**

Create `tests/codex/test-direct-mode-transcript-boundaries.sh` so it fails unless two fixtures prove:

```bash
assert_jq_true "$DIRECT_FIXTURE" '
  map(select(.payload.type == "function_call" and .payload.name == "request_user_input")) | length == 0
' "plain direct-mode answer never opens request_user_input"

assert_jq_true "$DIRECT_FIXTURE" '
  map(select(.payload.type == "message"))[0].payload.content[0].text | test("翻译结果|答案|结果")
' "plain direct-mode answer emits the user-facing result first"

assert_jq_true "$LIGHTWEIGHT_SUBTASK_FIXTURE" '
  map(select(.payload.type == "function_call" and .payload.name == "request_user_input")) | length == 0
' "downgraded lightweight subtask does not inherit workflow popup behavior"
```

- [ ] **Step 2: Run the boundary test and verify RED**

Run:
```bash
bash tests/codex/test-direct-mode-transcript-boundaries.sh
```

Expected:
- FAIL because the fixtures do not exist yet

- [ ] **Step 3: Create the positive fixtures**

Create:

- `tests/codex/fixtures/runtime-direct-mode-plain-answer-positive.jsonl`
  - assistant 直接输出普通问答/翻译结果
  - 无 `request_user_input`
  - 无 terminal-choice metadata
- `tests/codex/fixtures/runtime-direct-mode-lightweight-subtask-positive.jsonl`
  - turn 前半段可包含 workflow context
  - 当前子任务被描述为 translation / copy-only / text-only
  - assistant 直接给出该子任务结果
  - 无 terminal popup

- [ ] **Step 4: Re-run the boundary test and verify GREEN**

Run:
```bash
bash tests/codex/test-direct-mode-transcript-boundaries.sh
```

Expected:
- PASS and clearly distinguish direct replies from workflow terminal-choice behavior

- [ ] **Step 5: Commit**

```bash
git add tests/codex/fixtures/runtime-direct-mode-plain-answer-positive.jsonl \
  tests/codex/fixtures/runtime-direct-mode-lightweight-subtask-positive.jsonl \
  tests/codex/test-direct-mode-transcript-boundaries.sh
git commit -m "test: cover direct mode transcript boundaries"
```

### Task 3: Extend the skill-triggering suite with negative direct-mode prompts and a workflow-keyword positive prompt

**Files:**
- Create: `tests/skill-triggering/prompts/direct-mode-plain-question.txt`
- Create: `tests/skill-triggering/prompts/direct-mode-translation.txt`
- Create: `tests/skill-triggering/prompts/direct-mode-copy-only-edit.txt`
- Create: `tests/skill-triggering/prompts/workflow-keyword-plan.txt`
- Create: `tests/skill-triggering/run-negative-test.sh`
- Modify: `tests/skill-triggering/run-all.sh`
- Test: `tests/skill-triggering/run-negative-test.sh`
- Test: `tests/skill-triggering/run-all.sh`

**Execution Metadata:**
- Depends on: Task 1
- Write Set:
  - `tests/skill-triggering/prompts/direct-mode-plain-question.txt`
  - `tests/skill-triggering/prompts/direct-mode-translation.txt`
  - `tests/skill-triggering/prompts/direct-mode-copy-only-edit.txt`
  - `tests/skill-triggering/prompts/workflow-keyword-plan.txt`
  - `tests/skill-triggering/run-negative-test.sh`
  - `tests/skill-triggering/run-all.sh`
- Conflict Group: `skill-triggering-suite`
- Risk Level: medium
- Parallelizable: preflight-only

- [ ] **Step 1: Add negative prompts and a dedicated negative runner**

Create prompts for:

- `direct-mode-plain-question.txt` → 纯问答，不含 workflow 关键词
- `direct-mode-translation.txt` → 纯翻译
- `direct-mode-copy-only-edit.txt` → 明确说明“只改 UI 文案，不改逻辑”
- `workflow-keyword-plan.txt` → 明确使用 “plan / 规划 / implementation plan” 一类 workflow 关键词

Create `tests/skill-triggering/run-negative-test.sh` so it fails when any run logs:

```bash
grep -q '"name":"Skill"' "$LOG_FILE"
```

for the three negative prompts, and requires at least one expected workflow skill for the positive prompt.

- [ ] **Step 2: Wire the new prompts into the suite**

Modify `tests/skill-triggering/run-all.sh` to:
- keep the existing positive suite
- add the three negative prompts
- include the new workflow-keyword positive prompt
- print a clear SKIP note instead of a failure when `claude` is unavailable on this machine

- [ ] **Step 3: Verify the shell harness itself**

Run:
```bash
bash -n tests/skill-triggering/run-negative-test.sh
bash -n tests/skill-triggering/run-all.sh
```

Expected:
- both scripts exit cleanly with no syntax errors

- [ ] **Step 4: Run live prompting only when the environment supports it**

Run:
```bash
if command -v claude >/dev/null; then
  bash tests/skill-triggering/run-all.sh
else
  echo "SKIP: claude CLI unavailable on this machine"
fi
```

Expected:
- On machines with Claude CLI: the negative prompts do not trigger workflow skills, and the workflow-keyword prompt still does
- On this Codex-only machine: explicit `SKIP: claude CLI unavailable on this machine`

- [ ] **Step 5: Commit**

```bash
git add tests/skill-triggering/prompts/direct-mode-plain-question.txt \
  tests/skill-triggering/prompts/direct-mode-translation.txt \
  tests/skill-triggering/prompts/direct-mode-copy-only-edit.txt \
  tests/skill-triggering/prompts/workflow-keyword-plan.txt \
  tests/skill-triggering/run-negative-test.sh \
  tests/skill-triggering/run-all.sh
git commit -m "test: cover direct mode skill triggering"
```

### Task 4: Run final verification and sync the OpenSpec tasks

**Files:**
- Modify: `openspec/changes/refine-workflow-triggering-and-lightweight-exemptions/tasks.md`
- Test: `tests/prompt-contracts/test-direct-mode-and-lightweight-exemptions.sh`
- Test: `tests/codex/test-direct-mode-transcript-boundaries.sh`
- Test: `tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`
- Test: `tests/codex/test-runtime-endgate-transcript-audit.sh`
- Test: `tests/skill-triggering/run-all.sh`

**Execution Metadata:**
- Depends on: Task 2, Task 3
- Write Set:
  - `openspec/changes/refine-workflow-triggering-and-lightweight-exemptions/tasks.md`
- Conflict Group: `verification-and-sync`
- Risk Level: low
- Parallelizable: preflight-only

- [ ] **Step 1: Run the full targeted verification set**

Run:
```bash
bash tests/prompt-contracts/test-direct-mode-and-lightweight-exemptions.sh
bash tests/codex/test-direct-mode-transcript-boundaries.sh
bash tests/prompt-contracts/test-machine-readable-workflow-contracts.sh
bash tests/codex/test-runtime-endgate-transcript-audit.sh
if command -v claude >/dev/null; then
  bash tests/skill-triggering/run-all.sh
else
  echo "SKIP: claude CLI unavailable on this machine"
fi
openspec validate refine-workflow-triggering-and-lightweight-exemptions
```

Expected:
- 所有本地可运行脚本 PASS
- 若 `claude` 不可用，则出现明确 SKIP 提示而不是失败
- `openspec validate` reports success

- [ ] **Step 2: If anything fails, fix the smallest cause and re-run the same command set**

Keep fixes scoped to:
- direct-mode entry guidance
- lightweight-task / TDD exemptions
- direct-mode transcript fixtures
- skill-triggering negative suite wiring

- [ ] **Step 3: Mark the OpenSpec implementation tasks complete**

Update `openspec/changes/refine-workflow-triggering-and-lightweight-exemptions/tasks.md`:
- mark 1.1–3.3 complete only after verification succeeds
- leave nothing unchecked when the change is fully implemented

- [ ] **Step 4: Commit**

```bash
git add openspec/changes/refine-workflow-triggering-and-lightweight-exemptions/tasks.md
git commit -m "docs: sync workflow triggering refinement tasks"
```
