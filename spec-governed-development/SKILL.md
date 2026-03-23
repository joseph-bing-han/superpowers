---
name: spec-governed-development
description: Use when starting a new feature, cross-module change, or multi-stage request that may require OpenSpec artifacts, durable change history, team handoff, or long-lived scope/design tracking before implementation.
---

# Spec Governed Development

## Overview

这个 skill 是一个**流程治理入口**。

它不负责直接实现功能，而是先判断当前工作应该进入哪条开发线路：

- **Superpowers-only lane**：轻量变更，沿用原有 Superpowers 流程
- **OpenSpec lane**：重要变更，先确认、选择或建立 OpenSpec change，再由 Superpowers 执行设计、计划、实现与验证

核心原则：

1. **先决定线路，再开始实现**
2. **重要变更必须有长期可追溯资产**
3. **OpenSpec 与 Superpowers 不得维护重复的设计真相源**

## Hard Gates

在做出线路判断之前：

- 不要开始实现
- 不要进入详细编码
- 不要创建平行且重复的设计文档

如果进入 **OpenSpec lane**：

- 不要再额外维护一份等价的 `docs/superpowers/specs/...`
- `proposal.md`、`design.md`、`specs/*`、`tasks.md` 必须视为正式变更资产
- Superpowers 产出的 plan 只负责执行，不负责替代 OpenSpec 的范围和设计定义

## When To Use

以下情况优先触发本 skill：

- 用户提出**新功能**
- 需求会影响**多个模块**
- 工作会拆成**多个阶段**
- 任务需要**团队协作、交接或长期追溯**
- 变更涉及**权限、数据结构、支付、核心流程、外部接口**等高风险区域
- 用户明确要求引入 **OpenSpec**、规范化变更记录、proposal/design/tasks 或归档能力

以下情况通常**不需要**进入 OpenSpec：

- 小 bug 修复
- 小范围重构
- 局部 UI 微调
- 文案修改
- 单点逻辑修补
- 不需要长期追溯的小改动

## Decision Rule

先判断当前需求是否属于下列任一情况：

1. 新 capability 或新业务流程
2. 跨两个及以上边界模块
3. 预计需要多人协作、后续交接或跨会话继续
4. 预计分阶段实施，而非一次性完成
5. 涉及高风险设计决策或核心业务约束
6. 用户明确要求走 OpenSpec

如果满足任意一条：

- 进入 **OpenSpec lane**

否则：

- 进入 **Superpowers-only lane**

如果用户已经明确指定线路：

- 优先遵从用户指定

## Required Output Format

做出判断后，始终先输出一段简短决策。

如果是 **OpenSpec lane**，先判断：

- 是否已经存在合适的 change
- 是否需要新建 change

对这两种情况使用不同的 next skills，避免默认给人“每次都要重新 propose”的印象。

```text
## Workflow Decision

Lane: OpenSpec

Change status: Existing change

Why:
- cross-module impact
- durable history needed

Canonical record:
- Scope/Design/Specs/Tasks -> OpenSpec
- Execution plan -> Superpowers

Next skills:
1. brainstorming
2. writing-plans
3. openspec-apply-change
```

或：

```text
## Workflow Decision

Lane: OpenSpec

Change status: New change needed

Why:
- new feature
- cross-module impact
- durable history needed

Canonical record:
- Scope/Design/Specs/Tasks -> OpenSpec
- Execution plan -> Superpowers

Next skills:
1. openspec-explore
2. openspec-propose
3. brainstorming
4. writing-plans
```

或：

```text
## Workflow Decision

Lane: Superpowers-only

Why:
- localized change
- no durable change history needed

Canonical record:
- Superpowers design/plan documents

Next skills:
1. brainstorming
2. writing-plans
```

不要在输出里长篇解释。
先明确线路、原因、真相源和后续 skill。

## Workflow

### Lane A: Superpowers-only

适用于局部、低风险、无需长期变更资产的工作。

顺序：

1. 使用 `brainstorming`
2. 设计获批后，使用 `writing-plans`
3. 执行时使用 `subagent-driven-development` 或 `executing-plans`
4. 完成前使用 `verification-before-completion`
5. 收尾时使用 `finishing-a-development-branch`

### Lane B: OpenSpec

适用于新功能、跨模块、多阶段、需要长期追溯或团队协作的工作。

顺序：

1. 如需确认现有 change，上下文检查可使用：
   ```bash
   openspec list --json
   ```
2. 如果已经存在合适的 change，直接基于该 change 继续后续设计、计划与实现流程
3. 如果还没有合适 change：
   - 先使用 `openspec-explore`
   - 再使用 `openspec-propose`
4. 随后使用 `brainstorming` 继续澄清需求、比较方案、收敛设计
5. 已确认的范围、设计、要求必须沉淀到 OpenSpec artifacts，而不是重复写入 `docs/superpowers/specs/...`
6. 使用 `writing-plans` 生成**执行级计划**，输入应优先来自 OpenSpec artifacts
7. 进入实现前，使用 `openspec-apply-change`
8. 执行时使用 `subagent-driven-development` 或 `executing-plans`
9. 若实现中发现设计或范围变化，先更新 OpenSpec artifacts，再继续实现
10. 完成前使用 `verification-before-completion`
11. 收尾时使用 `finishing-a-development-branch`
12. 当 change 真正完成后，再使用 `openspec-archive-change`

## Source of Truth Rules

### In OpenSpec Lane

以下内容以 OpenSpec 为唯一正式记录：

- `proposal.md`：为什么做、范围是什么
- `design.md`：设计方案、架构决策、关键约束
- `specs/*`：需求规则、行为定义、契约
- `tasks.md`：团队级任务拆分与进度主线

以下内容由 Superpowers 负责，但只能作为执行层资产：

- `docs/superpowers/plans/...`：agent 执行级计划

这意味着：

- OpenSpec 的 `tasks.md` 是**团队级任务**
- Superpowers plan 是**agent 级执行步骤**
- 二者不应保持相同粒度
- Superpowers plan 不得替代 OpenSpec 的范围与设计定义

### In Superpowers-only Lane

沿用现有 Superpowers 约定：

- 设计文档与计划文档按原生 Superpowers 流程处理

## Interaction With Other Skills

### with `using-superpowers`

- 本 skill 应作为新功能开发时的治理入口
- 如果任务明显属于新功能、跨模块或多阶段工作，应优先触发本 skill 再决定后续流程

### with `brainstorming`

- `brainstorming` 仍负责设计探索与方案收敛
- 但在 OpenSpec lane 中，设计载体必须是 OpenSpec artifacts，而不是平行 spec 文档

### with `writing-plans`

- `writing-plans` 负责编写执行级计划
- 在 OpenSpec lane 中，计划上下文应优先来自 OpenSpec artifacts

### with `openspec-apply-change`

- 在 OpenSpec lane 中，进入实现前必须确保 change 已明确
- 如果实现暴露出设计问题，应先回流更新 artifacts，再继续执行

### with `openspec-archive-change`

- 只在实现、验证、收尾均完成后才建议归档
- 不要因为“代码已写完”就立即归档

## Common Mistakes

### 1. 把所有需求都送进 OpenSpec

结果：

- 流程过重
- 小问题也要走完整治理链

修正：

- 只有重要变更才进入 OpenSpec lane

### 2. 同时维护两份设计文档

结果：

- 范围、设计、任务很快漂移

修正：

- OpenSpec lane 下只保留一份正式设计真相源

### 3. 把 OpenSpec tasks 和 Superpowers plan 写成一样的东西

结果：

- 不知道哪份是对团队说的
- 不知道哪份是给 agent 执行的

修正：

- OpenSpec tasks 保持团队级
- Superpowers plan 保持执行级

### 4. 过早归档 change

结果：

- PR 未完成、验证未完成、需求仍变化时，change 已被封存

修正：

- 先 verify
- 再 finish branch
- 确认 change 真正完成后再 archive

## Handoff Guidance

在结束这个治理入口的当前 turn 前，先把当前 handoff 归类为 `auto-continue`、`needs-user-decision`、`terminal-choice` 三种状态之一。

- `auto-continue`：下一条 lane 已经清晰且安全，直接进入对应 skill
- `needs-user-decision`：后续依赖用户在若干具体选项中做选择，必须用 `request_user_input`
- `terminal-choice`：当前请求看起来已经完成，但也不能直接结束，必须先用 `request_user_input` 弹出：
  1. 结束
  2. 继续
  3. 自由输入
- For checkpoint, handoff, and terminal-choice nodes driven by `request_user_input`, the `request_user_input` call and its transcript event are the machine contract; surrounding prose is explanatory only.

当 handoff 进入 `terminal-choice` 时，这个 turn 的直接下一个动作就是弹出 `request_user_input`，不能先写一段自由文本终稿再结束。

不要在 terminal-choice 弹窗前先输出“当前我建议的定稿”“就按这条落地”“最终建议一句话版”这类终局式总结。

即使已经形成稳定建议、最终定稿或最终摘要，也仍然不构成直接结束许可；在弹窗出现前，不要 `task_complete`，也不要用自由文本收尾。

如果后续路径已经明确，就直接进入对应下一个 skill，不要停在一句自由文本“如果你确认继续”或“如果你认同这个方向我就继续”。

也不要停在声明式下一步提议，例如“下一步最合适的是我直接……”“接下来我会先……”，然后结束当前 turn。

这同样包括判断式、比较式、推荐式的声明收尾，例如“如果按我的判断，下一步应该先……”“下一步最值得做的不是 A，而是 B”“接下来更值得做的是……”“我建议先……”。

如果唯一剩余选择真的只是继续还是结束，也要用 `request_user_input` 来问；否则应该询问更具体的下一步分支，而不是退化成笼统的继续/结束。

如果你已经能把下一个安全动作具体说出来，就直接执行，不要只描述动作然后停住。

如果确实还存在可枚举的用户决策，再使用 `request_user_input` 触发数字选项，不要使用笼统确认句。

- 对 **OpenSpec lane**：
  - 如果已经存在合适 change，直接基于该 change 进入后续 `brainstorming`、`writing-plans` 或实现流程
  - 如果还没有 change，但下一步明显应先做范围探索，直接进入 `openspec-explore`
  - 如果还没有 change，且已具备 proposal 输入，直接进入 `openspec-propose`
- 对 **Superpowers-only lane**：
  - 立即进入 `brainstorming`

这个 skill 不应停留在“做出判断”。
它的职责是：

1. 选线路
2. 定真相源
3. 指向下一个正确 skill

## Minimalism Rule

除非确实需要长期变更治理，否则优先保持流程轻量。

目标不是把每个需求都 OpenSpec 化。
目标是：

- 对小需求保持效率
- 对重要变更保留历史
- 对团队协作建立稳定主线

## Terminal Endgate Protocol

If this skill reaches a terminal boundary where the current request appears complete:
- This skill must not end the conversation directly with prose, `task_complete`, or a typed free-form prompt.
- Conditional approvals such as `如果没问题就继续下一阶段`, `如果设计合理就开始实现`, or `if this is sound, continue to phase 2` count as prior authorization. A positive judgment must auto-continue instead of ending with a conclusion block.
- Route true completion through `terminal-choice`.
- The very next action must be `request_user_input`.
- Use the fixed terminal-choice options:
  1. 结束
  2. 继续
  3. 自由输入
- Do not produce a plain final-answer-style closeout or any other prose-only closeout before the terminal-choice popup.
- If the next safe step is already implied, auto-continue instead of asking the user to type a free-form continuation or ending message.
