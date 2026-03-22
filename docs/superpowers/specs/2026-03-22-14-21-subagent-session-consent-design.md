# 会话级子代理授权设计

**日期：** 2026-03-22 14:21  
**线路：** Superpowers-only  
**状态：** 设计已确认并已落地

---

## 1. 背景

本轮使用中暴露出两个直接影响体验的问题：

1. 当 reviewer 或 implementer 子代理本来会明显提升质量时，系统没有先主动询问用户是否允许启用子代理，而是直接退回 inline 执行，随后再解释“没有显式授权”。
2. 数字化选择交互虽然已经大量改为 `request_user_input`，但用户仍会在真实弹窗里看到 `1。` 这种中文句号样式，观感不佳，也容易误以为仓库可以直接改掉这个 UI 前缀。

第一类问题的核心约束不是技能文案能力不足，而是当前平台规则要求：`spawn_agent` 必须建立在显式用户授权之上。  
第二类问题则存在边界：仓库可以统一 **assistant 自己写出的 prose-numbered options / text fallback**，但无法直接控制 Codex `request_user_input` 弹窗的自动编号前缀。

因此，本次设计需要同时解决：

- 如何在不突破平台授权边界的前提下，让子代理启用体验更顺滑；
- 如何统一仓库可控的编号样式，并明确哪些部分不在本仓库控制范围内。

---

## 2. 目标

### 2.1 本次设计目标

1. 为子代理使用建立会话级一次性授权模型，避免“先降级、后解释”。
2. 当子代理会明显带来收益且当前状态未知时，优先通过 `request_user_input` 询问一次是否允许本会话使用子代理。
3. 一旦用户在本会话中授权，后续可继续使用合适的 reviewer / implementer 子代理，而不再重复询问。
4. 一旦用户在本会话中拒绝，后续保持 inline 执行，不再重复追问，除非用户主动重新开启该选择。
5. 在 `writing-plans` 的执行路径交接中，若用户选择 `Subagent-Driven`，这次选择应直接视为当前会话对子代理的显式授权。
6. 所有由 assistant 自己写出的编号文本与文本回退提示，统一使用 ASCII `1. `、`2. `、`3. `。
7. 明确声明：`request_user_input` 弹窗中的自动编号前缀属于 Codex UI / input-layer 边界，不承诺由本仓库直接修改。

### 2.2 非目标

1. 不默认静默启用子代理。
2. 不绕过平台对 `spawn_agent` 的显式授权要求。
3. 不承诺修复 Codex `request_user_input` 弹窗中自动显示的 `1。` 前缀。
4. 不修改 Codex 本体的 TUI / input-layer 实现。

---

## 3. 设计决策

### 3.1 会话级授权状态机

子代理授权状态采用三态：

- `unknown`
- `granted`
- `denied`

状态迁移规则如下：

```text
Session Start
  └─> unknown
        ├─ 用户同意使用子代理 -> granted
        ├─ 用户拒绝使用子代理 -> denied
        └─ 用户尚未被询问 -> 保持 unknown

granted
  └─ 后续本会话中，遇到确实有帮助的子代理时可直接使用，不再重复询问

denied
  └─ 后续本会话中保持 inline，不再重复询问
     除非用户明确重新打开该选择
```

### 3.2 触发规则

当满足以下条件时，需要触发一次授权判断：

1. 当前 workflow 中使用 reviewer 或 implementer 子代理会明显提升质量或效率；
2. 当前会话的授权状态仍是 `unknown`。

此时必须：

1. 先通过 `request_user_input` 发起一次明确选择；
2. 禁止先 inline 降级，再在解释里补一句“因为没授权”；
3. 禁止跳过询问直接静默不用子代理。

### 3.3 workflow 绑定点

本次明确绑定两个高频入口：

1. `brainstorming`
   - 在 design artifact review loop 中，如果 reviewer subagent 明显有帮助且会话授权状态未知，则先问一次。
   - `granted` 时直接派 reviewer。
   - `denied` 时 inline review，且本会话不再追问。

2. `writing-plans`
   - 在 plan review loop 中，如果 reviewer subagent 明显有帮助且会话授权状态未知，则先问一次。
   - `granted` 时直接派 reviewer。
   - `denied` 时 inline review，且本会话不再追问。
   - 在执行路径交接中，用户选择 `Subagent-Driven` 时，直接视为当前会话对子代理的显式授权。
   - 既然已经授权，后续实现阶段不应立刻再问一次同样的问题。

### 3.4 编号样式边界

本次对编号样式的设计边界明确如下：

1. **仓库可控部分**
   - assistant 自己写的 prose-numbered options
   - assistant 自己写的 text fallback 提示
   - 上述内容必须统一为 ASCII `1. `、`2. `、`3. `

2. **仓库不可控部分**
   - `request_user_input` 弹窗中由 Codex UI 自动绘制的编号前缀
   - 当前观察到的 `1。`、`2。`、`3。`

因此，本次只能承诺：

- 统一仓库可控文案的 ASCII 编号风格；
- 在 README 中明确写出 UI / input-layer 边界；
- 不对弹窗自动前缀做虚假承诺。

---

## 4. 影响范围

### 4.1 必改文件

- `skills/using-superpowers/SKILL.md`
- `skills/brainstorming/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `docs/README.codex.md`
- `tests/prompt-contracts/test-subagent-session-consent.sh`
- `tests/prompt-contracts/test-numeric-choice-interactions.sh`

### 4.2 预期行为变化

1. 当 workflow 首次真的需要子代理帮助时，会先出现一次带编号选项的授权询问，而不是直接退回 inline。
2. 同一会话内，授权与拒绝都具备复用性，不再反复追问。
3. 用户在执行路径中选了 `Subagent-Driven` 后，不会马上又被问一次是否允许子代理。
4. assistant 自己写出的 `1 / 2 / 3` 文本改为 ASCII `1. `、`2. `、`3. `。
5. 文档中不再暗示“本仓库已经修复了弹窗 UI 的 `1。`”。

---

## 5. 验收标准

本次设计验收以以下结果为准：

1. `skills/using-superpowers/SKILL.md` 明确写出 `unknown / granted / denied` 三态与 ask-once 规则。
2. `brainstorming` 的 reviewer 流程接入上述会话级授权语义。
3. `writing-plans` 同时接入 reviewer 授权分支与 `Subagent-Driven` 的会话授权语义，且不应立即重复询问。
4. `docs/README.codex.md` 同时说明：
   - 会话级子代理授权模型；
   - `Subagent-Driven` 的授权含义；
   - ASCII `1. ` 编号规则仅适用于 assistant 自写文案；
   - `request_user_input` 弹窗自动编号属于 Codex UI / input-layer 边界。
5. prompt-contract 测试锁定上述契约，避免未来退回“先降级后解释”或错误承诺“修好了弹窗前缀”。
