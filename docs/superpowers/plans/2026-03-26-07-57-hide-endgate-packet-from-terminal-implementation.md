# Hide Endgate Packet from Terminal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在保留 strict endgate 协议可验证性的前提下，把 `ENDGATE_*` packet 从用户可见终端输出中移走，并为结构化 carrier 与显式 opt-in 的 wrapper 过渡路径提供可落地实现。

**Architecture:** 先定义唯一的 structured carrier transcript schema，并让 fixture / helper / runtime audit 共用它，避免实现期各自发明格式。接着把 carrier-first 语义扩展到所有受本仓库管理的本地 workflow skills、README、instruction bootstrap 与 prompt-contract 套件，确保“canonical carrier”取代“用户可见四行 tail block”成为统一契约。最后补一个显式 opt-in 的 wrapper 过渡方案：它不会替换用户的 `codex` 入口，只在手动调用时隐藏终端中的 `ENDGATE_*` 行，并把 `.codex/.runtime/` 明确限定为 debug mirror。

**Tech Stack:** Bash, jq, Markdown, JSONL transcript fixtures, shell wrapper, OpenSpec

---

**OpenSpec Change:** `hide-endgate-packet-from-terminal`

## Canonical Structured Carrier Schema

本计划第一阶段只允许**一套**结构化 carrier 表示，所有新 fixture、helper 与 runtime audit 都必须共用它：

```json
{
  "payload": {
    "metadata": {
      "endgate": {
        "ENDGATE_PROTOCOL_VERSION": "1",
        "ENDGATE_STATE": "AUTO_CONTINUE | NEEDS_USER_DECISION | TERMINAL_CHOICE",
        "ENDGATE_CHOICE_KIND": "NONE | SPECIFIC_NEXT_STEP | CONTINUE_OR_STOP",
        "ENDGATE_NEXT_ACTION": "CONTINUE_WITH_TOOL | REQUEST_USER_INPUT"
      }
    }
  }
}
```

规则：

- `response_item` 事件读取 `payload.metadata.endgate`
- `item.*` 事件读取 `item.metadata.endgate`
- helper 与 runtime audit 必须先把两种路径归一化为同一 carrier object，再继续判定
- 本阶段**不允许**再引入第三套 schema

状态覆盖要求：

- 至少一条 structured-carrier fixture 覆盖 `AUTO_CONTINUE`
- 至少一条 structured-carrier fixture 覆盖 `NEEDS_USER_DECISION`
- 至少一条 structured-carrier fixture 覆盖 `TERMINAL_CHOICE`

### Task 1: Add structured-carrier fixtures and shared parsers

**Files:**
- Modify: `tests/shared/workflow-contract-helpers.sh`
- Modify: `tests/shared/test-workflow-contract-helpers.sh`
- Create: `tests/codex/fixtures/runtime-endgate-structured-carrier-autocontinue-positive.jsonl`
- Create: `tests/codex/fixtures/runtime-endgate-structured-carrier-needs-user-decision-positive.jsonl`
- Create: `tests/codex/fixtures/runtime-endgate-structured-carrier-terminal-choice-positive.jsonl`

**Execution Metadata:**
- Depends on: none
- Write Set:
  - `tests/shared/workflow-contract-helpers.sh`
  - `tests/shared/test-workflow-contract-helpers.sh`
  - `tests/codex/fixtures/runtime-endgate-structured-carrier-autocontinue-positive.jsonl`
  - `tests/codex/fixtures/runtime-endgate-structured-carrier-needs-user-decision-positive.jsonl`
  - `tests/codex/fixtures/runtime-endgate-structured-carrier-terminal-choice-positive.jsonl`
- Conflict Group: `endgate-carrier-runtime`
- Risk Level: medium
- Parallelizable: preflight-only

- [ ] **Step 1: 按 canonical schema 写 3 条 structured-carrier fixture**

每条 fixture 都必须：

- 使用上面的统一 JSON 路径
- 不再依赖用户可见 `ENDGATE_*` tail block
- 分别覆盖 `AUTO_CONTINUE`、`NEEDS_USER_DECISION`、`TERMINAL_CHOICE`

- [ ] **Step 2: 给 shared helper 增加 carrier 归一化函数**

在 `tests/shared/workflow-contract-helpers.sh` 增加面向 carrier 的抽取函数，例如：

```bash
extract_endgate_carrier_field <file> <key>
extract_endgate_carrier_kind <file>
```

要求：

- 优先读取 structured carrier
- structured carrier 缺失时才回退到现有 visible tail block
- 不破坏既有 `extract_endgate_packet_field*` 调用方

- [ ] **Step 3: 更新 shared helper 测试**

让 `tests/shared/test-workflow-contract-helpers.sh` 同时验证：

- structured carrier 抽取成功
- visible tail block fallback 仍可工作
- 两者都存在时 structured carrier 优先

- [ ] **Step 4: 运行 helper 回归**

Run:

```bash
bash tests/shared/test-workflow-contract-helpers.sh
```

Expected: PASS

- [ ] **Step 5: 提交 Task 1**

```bash
git add tests/shared/workflow-contract-helpers.sh tests/shared/test-workflow-contract-helpers.sh tests/codex/fixtures/runtime-endgate-structured-carrier-autocontinue-positive.jsonl tests/codex/fixtures/runtime-endgate-structured-carrier-needs-user-decision-positive.jsonl tests/codex/fixtures/runtime-endgate-structured-carrier-terminal-choice-positive.jsonl
git commit -m "test: add structured endgate carrier fixtures and helpers"
```

### Task 2: Upgrade runtime audit from packet-text-first to carrier-first

**Files:**
- Modify: `tests/codex/test-runtime-endgate-transcript-audit.sh`

**Execution Metadata:**
- Depends on: Task 1
- Write Set:
  - `tests/codex/test-runtime-endgate-transcript-audit.sh`
- Conflict Group: `endgate-carrier-runtime`
- Risk Level: high
- Parallelizable: no

- [ ] **Step 1: 先接入 structured-carrier 正向样本**

让 runtime audit 脚本首先对 3 条 structured-carrier fixture 断言：

- `AUTO_CONTINUE` structured carrier 必须通过
- `NEEDS_USER_DECISION` structured carrier 必须通过
- `TERMINAL_CHOICE` structured carrier 必须通过

- [ ] **Step 2: 保持现有 missing-carrier negative 作为 transcript 级负样本**

不要新增“sidecar-only jsonl transcript fixture”。继续使用现有
`missing packet / missing carrier` 负样本证明 transcript 缺少 canonical carrier
时必须失败。

- [ ] **Step 3: 实现 carrier-first 解析顺序**

把审计逻辑调整为：

```text
structured carrier > visible tail block > legacy prose safety net
```

并保留“最后一份声明生效、只看 post-carrier window”的现有模型。

- [ ] **Step 4: 明确 failure modes**

让脚本至少区分：

- valid structured carrier
- valid tail block fallback
- missing canonical carrier
- legacy prose leak

- [ ] **Step 5: 运行 Codex transcript 回归**

Run:

```bash
bash tests/codex/test-runtime-endgate-transcript-audit.sh
```

Expected: PASS

- [ ] **Step 6: 提交 Task 2**

```bash
git add tests/codex/test-runtime-endgate-transcript-audit.sh
git commit -m "test: validate endgate carriers before visible tail blocks"
```

### Task 3: Migrate all local workflow skills and docs to canonical-carrier wording

**Files:**
- Modify: `skills/using-superpowers/SKILL.md`
- Modify: `skills/brainstorming/SKILL.md`
- Modify: `skills/writing-plans/SKILL.md`
- Modify: `skills/executing-plans/SKILL.md`
- Modify: `skills/subagent-driven-development/SKILL.md`
- Modify: `skills/spec-governed-development/SKILL.md`
- Modify: `skills/dispatching-parallel-agents/SKILL.md`
- Modify: `skills/verification-before-completion/SKILL.md`
- Modify: `skills/using-git-worktrees/SKILL.md`
- Modify: `skills/finishing-a-development-branch/SKILL.md`
- Modify: `skills/requesting-code-review/SKILL.md`
- Modify: `skills/receiving-code-review/SKILL.md`
- Modify: `skills/test-driven-development/SKILL.md`
- Modify: `skills/systematic-debugging/SKILL.md`
- Modify: `skills/writing-skills/SKILL.md`
- Modify: `docs/README.codex.md`
- Modify: `docs/testing.md`
- Modify: `.codex/instruction.md`
- Modify: `tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`
- Modify: `tests/prompt-contracts/test-nonterminal-workflow-gates.sh`
- Modify: `tests/prompt-contracts/test-universal-terminal-endgate-protocol.sh`

**Execution Metadata:**
- Depends on: Task 2
- Write Set:
  - `skills/using-superpowers/SKILL.md`
  - `skills/brainstorming/SKILL.md`
  - `skills/writing-plans/SKILL.md`
  - `skills/executing-plans/SKILL.md`
  - `skills/subagent-driven-development/SKILL.md`
  - `skills/spec-governed-development/SKILL.md`
  - `skills/dispatching-parallel-agents/SKILL.md`
  - `skills/verification-before-completion/SKILL.md`
  - `skills/using-git-worktrees/SKILL.md`
  - `skills/finishing-a-development-branch/SKILL.md`
  - `skills/requesting-code-review/SKILL.md`
  - `skills/receiving-code-review/SKILL.md`
  - `skills/test-driven-development/SKILL.md`
  - `skills/systematic-debugging/SKILL.md`
  - `skills/writing-skills/SKILL.md`
  - `docs/README.codex.md`
  - `docs/testing.md`
  - `.codex/instruction.md`
  - `tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`
  - `tests/prompt-contracts/test-nonterminal-workflow-gates.sh`
  - `tests/prompt-contracts/test-universal-terminal-endgate-protocol.sh`
- Conflict Group: `endgate-carrier-contracts`
- Risk Level: high
- Parallelizable: preflight-only

- [ ] **Step 1: 先把 prompt-contract 断言改成覆盖“所有本地 workflow skills”**

新增/收紧断言，明确检查：

- strict packet mode = canonical machine-readable carrier
- structured carrier 优先
- visible tail block 只是 fallback
- 不允许仍把“最后 4 行必须对用户可见”写成唯一路径

- [ ] **Step 2: 批量迁移所有本地 workflow skills wording**

把上述 skills 中仍写死“最后 4 行必须可见”的 guidance 改成：

```text
在下一个机器动作前必须存在 canonical carrier；
若运行时支持 structured carrier，则不强制用户可见 tail block。
```

保持现有 `AUTO_CONTINUE / NEEDS_USER_DECISION / TERMINAL_CHOICE` 配对不变。

- [ ] **Step 3: 同步 README、testing 文档与 instruction bootstrap**

让 `docs/README.codex.md`、`docs/testing.md`、`.codex/instruction.md`
与新的 carrier-first 规则保持一致。

- [ ] **Step 4: 运行 contract 文档回归**

Run:

```bash
bash tests/prompt-contracts/test-machine-readable-workflow-contracts.sh
bash tests/prompt-contracts/test-nonterminal-workflow-gates.sh
bash tests/prompt-contracts/test-universal-terminal-endgate-protocol.sh
```

Expected: PASS

- [ ] **Step 5: 提交 Task 3**

```bash
git add skills/using-superpowers/SKILL.md skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md skills/subagent-driven-development/SKILL.md skills/spec-governed-development/SKILL.md skills/dispatching-parallel-agents/SKILL.md skills/verification-before-completion/SKILL.md skills/using-git-worktrees/SKILL.md skills/finishing-a-development-branch/SKILL.md skills/requesting-code-review/SKILL.md skills/receiving-code-review/SKILL.md skills/test-driven-development/SKILL.md skills/systematic-debugging/SKILL.md skills/writing-skills/SKILL.md docs/README.codex.md docs/testing.md .codex/instruction.md tests/prompt-contracts/test-machine-readable-workflow-contracts.sh tests/prompt-contracts/test-nonterminal-workflow-gates.sh tests/prompt-contracts/test-universal-terminal-endgate-protocol.sh
git commit -m "docs: redefine strict packet mode around canonical carriers"
```

### Task 4: Add an explicit opt-in wrapper and prove sidecar is only a debug mirror

**Files:**
- Create: `.codex/codex-endgate-wrapper.sh`
- Modify: `.codex/INSTALL.md`
- Modify: `.gitignore`
- Create: `tests/codex/test-endgate-wrapper-filter.sh`

**Execution Metadata:**
- Depends on: Task 3
- Write Set:
  - `.codex/codex-endgate-wrapper.sh`
  - `.codex/INSTALL.md`
  - `.gitignore`
  - `tests/codex/test-endgate-wrapper-filter.sh`
- Conflict Group: `endgate-carrier-wrapper`
- Risk Level: high
- Parallelizable: no

- [ ] **Step 1: 先定义显式 opt-in 激活模型**

本任务只接受一种激活模型：

- 用户**手动**运行 `.codex/codex-endgate-wrapper.sh`
- wrapper 内部再调用底层 `codex`
- 不修改 `install-codex.sh`
- 不替换用户默认的 `codex` 入口

- [ ] **Step 2: 先写 wrapper 测试，并允许 mock 底层命令**

新增 `tests/codex/test-endgate-wrapper-filter.sh`，通过可注入的底层命令
（例如 `CODEX_BIN` 环境变量）验证：

- wrapper 会从用户可见 stdout/stderr 里移除连续 `ENDGATE_*` 行
- wrapper 不会吞掉普通说明文本
- wrapper 可选写入 `.codex/.runtime/endgate-state.jsonl`
- wrapper 只过滤 terminal render，本身不得生成 canonical carrier
- sidecar 存在时，如果 transcript 侧缺少 canonical carrier，仍不得把它当成合法 contract
- 用户显式放宽后，单独出现的一行 `ENDGATE_*: ...` 也允许隐藏，不再强制必须是完整 4 行 canonical packet 才可隐藏

- [ ] **Step 3: 实现最小 wrapper 与 runtime 目录策略**

创建 `.codex/codex-endgate-wrapper.sh`，实现：

- 调用底层 Codex CLI
- 过滤连续或单独出现的 `ENDGATE_*` 行的终端显示
- 可选写入 `.codex/.runtime/endgate-state.jsonl`
- 更新 `.codex/.runtime/latest-endgate.json`

同时在 `.gitignore` 中加入 `.codex/.runtime/`，避免 sidecar 被误跟踪。

- [ ] **Step 4: 在安装文档里写清激活方式与边界**

更新 `.codex/INSTALL.md`，明确：

- wrapper 是显式 opt-in 的过渡方案
- 原生 structured carrier 仍是长期标准
- sidecar 只是 debug mirror，不是 canonical contract

- [ ] **Step 5: 运行 wrapper 回归**

Run:

```bash
bash tests/codex/test-endgate-wrapper-filter.sh
```

Expected: PASS

- [ ] **Step 6: 提交 Task 4**

```bash
git add .codex/codex-endgate-wrapper.sh .codex/INSTALL.md .gitignore tests/codex/test-endgate-wrapper-filter.sh
git commit -m "feat: add explicit opt-in endgate redaction wrapper"
```

### Task 5: Final verification and OpenSpec sync

**Files:**
- Modify: `docs/testing.md`
- Modify: `openspec/changes/hide-endgate-packet-from-terminal/tasks.md`

**Execution Metadata:**
- Depends on: Task 4
- Write Set:
  - `docs/testing.md`
  - `openspec/changes/hide-endgate-packet-from-terminal/tasks.md`
- Conflict Group: `endgate-carrier-verification`
- Risk Level: medium
- Parallelizable: preflight-only

- [ ] **Step 1: 运行完整相关回归**

Run:

```bash
bash tests/shared/test-workflow-contract-helpers.sh
bash tests/codex/test-runtime-endgate-transcript-audit.sh
bash tests/codex/test-endgate-wrapper-filter.sh
bash tests/prompt-contracts/test-machine-readable-workflow-contracts.sh
bash tests/prompt-contracts/test-nonterminal-workflow-gates.sh
bash tests/prompt-contracts/test-universal-terminal-endgate-protocol.sh
openspec validate hide-endgate-packet-from-terminal --type change --json
```

Expected: 全部 PASS，且 OpenSpec 校验输出成功状态。

- [ ] **Step 2: 把验证证据写回文档**

更新 `docs/testing.md`，记录：

- structured carrier 对 3 种 `ENDGATE_STATE` 的覆盖
- wrapper-hidden 终端隐藏 evidence
- sidecar mirror 存在但不被当作 canonical contract 的负向 evidence

- [ ] **Step 3: 勾选已完成的 OpenSpec tasks**

仅在对应实现和验证都完成后，把 `openspec/changes/hide-endgate-packet-from-terminal/tasks.md`
里的复选框从 `- [ ]` 改为 `- [x]`。

- [ ] **Step 4: 提交 Task 5**

```bash
git add docs/testing.md openspec/changes/hide-endgate-packet-from-terminal/tasks.md
git commit -m "test: verify hidden endgate carrier rollout"
```
