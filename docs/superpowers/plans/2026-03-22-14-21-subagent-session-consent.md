# Session-Scoped Subagent Consent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 reviewer / implementer 子代理建立会话级一次性授权语义，避免“先 inline 降级、后解释没授权”，并补齐 assistant 自写编号统一为 ASCII `1. ` 的边界说明。

**Architecture:** 先在全局规则里锁定 `unknown / granted / denied` 三态与 ask-once 契约，再把该契约接入 `brainstorming` 和 `writing-plans` 两个高频 workflow，随后更新 Codex README，明确 `Subagent-Driven` 的授权含义，以及 assistant 自写编号可统一为 ASCII `1. `、但 `request_user_input` 弹窗自动编号属于 Codex UI / input-layer 边界，最后以 prompt-contract 测试固定这些约束。

**Tech Stack:** Markdown skill docs, Markdown product docs, Bash prompt-contract tests

---

### Task 1: 锁定全局会话级子代理授权契约

**Files:**
- Modify: `skills/using-superpowers/SKILL.md`
- Create: `tests/prompt-contracts/test-subagent-session-consent.sh`

- [x] **Step 1: 在全局 skill 中声明三态授权模型**

写入 `unknown / granted / denied`，并明确 ask-once 语义。

- [x] **Step 2: 锁定首次询问规则**

明确当子代理会明显有帮助且状态为 `unknown` 时，必须先通过 `request_user_input` 询问一次。

- [x] **Step 3: 锁定禁止退化规则**

明确禁止：

1. silently downgrade before asking  
2. downgrade first and explain later

- [x] **Step 4: 用 prompt-contract 测试锁定全局契约**

测试覆盖：

1. 三态存在
2. ask once
3. granted / denied 本会话复用
4. 不允许弱化措辞

---

### Task 2: 将会话级授权接入 workflow 入口

**Files:**
- Modify: `skills/brainstorming/SKILL.md`
- Modify: `skills/writing-plans/SKILL.md`
- Modify: `tests/prompt-contracts/test-subagent-session-consent.sh`

- [x] **Step 1: 接入 brainstorming reviewer 流程**

在 design artifact review loop 中增加：

1. `unknown` -> 先问一次
2. `granted` -> 派 reviewer
3. `denied` -> inline review，且本会话不再追问

- [x] **Step 2: 接入 writing-plans 执行路径交接**

明确写出：

1. 选择 `Subagent-Driven` 视为当前会话的显式授权
2. 后续实现阶段不应立刻再问一次相同授权

- [x] **Step 3: 用测试锁定 workflow 绑定点**

测试覆盖：

1. brainstorming reviewer 绑定
2. writing-plans 的 `Subagent-Driven` 授权语义

---

### Task 3: 补齐编号样式边界说明

**Files:**
- Modify: `skills/using-superpowers/SKILL.md`
- Modify: `docs/README.codex.md`
- Modify: `tests/prompt-contracts/test-numeric-choice-interactions.sh`
- Modify: `tests/prompt-contracts/test-subagent-session-consent.sh`

- [x] **Step 1: 锁定 assistant 自写编号使用 ASCII `1. `**

仅针对 prose-numbered options / text fallbacks。

- [x] **Step 2: 写清 `request_user_input` 弹窗自动编号边界**

README 必须明确：

1. 仓库无法直接控制弹窗自动编号前缀
2. `1。` 属于 Codex UI / input-layer boundary

- [x] **Step 3: 补充 `Subagent-Driven` 的 README 说明**

用户侧文档需要明确知道：

1. 有些 workflow 会先问一次是否允许本会话使用子代理
2. granted 会复用，denied 会保持 inline
3. 选择 `Subagent-Driven` 本身就等于实现子代理的会话级授权

---

### Task 4: 最终验证

**Files:**
- Test: `tests/prompt-contracts/test-subagent-session-consent.sh`
- Test: `tests/prompt-contracts/test-numeric-choice-interactions.sh`

- [x] **Step 1: 运行 session-consent prompt-contract 测试**

Run: `bash tests/prompt-contracts/test-subagent-session-consent.sh`  
Expected: PASS

- [x] **Step 2: 运行 numeric-choice prompt-contract 测试**

Run: `bash tests/prompt-contracts/test-numeric-choice-interactions.sh`  
Expected: PASS

- [ ] **Step 3: 审查 diff 与提交**

Run: `git diff -- docs/README.codex.md skills/using-superpowers/SKILL.md skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md tests/prompt-contracts/test-subagent-session-consent.sh tests/prompt-contracts/test-numeric-choice-interactions.sh`  
Expected: 仅包含本次授权契约、ASCII 编号规则与边界说明相关改动
