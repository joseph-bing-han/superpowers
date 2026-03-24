## Context

这次变更已经在 `openspec` 分支上完成实现并通过验证，但最初是沿着
`docs/superpowers/specs/...` 与 `docs/superpowers/plans/...` 的本地设计线推进，
没有先进入 OpenSpec lane。结果是：

- 代码、设计稿、执行计划都已经存在
- 相关 tests 与 docs 也已经落地
- 但 proposal / design / specs / tasks 这组正式治理资产缺位

因此，本设计文档的目标不是重新设计一套实现，而是把已落地的设计决策
抽象成 OpenSpec 的 canonical record。

## Goals / Non-Goals

**Goals:**

- 将这次子代理路由改动补建为正式 OpenSpec change
- 用 OpenSpec 统一记录三模式路由、Execution Metadata schema、Pipeline overlap 契约与 validation evidence
- 明确本次变更只涉及 skill/docs/tests 合同层，不宣称修改了 Codex runtime scheduler
- 为后续 archive、团队交接与跨会话回顾提供长期可追溯资产

**Non-Goals:**

- 不重做一轮新的功能实现
- 不回滚已合并代码后重新按 OpenSpec lane 走一遍实现
- 不把已有 `docs/superpowers/specs/...` 与 OpenSpec 长期并行维护为两个真相源
- 不新增 Codex 底层调度器能力

## Decisions

### 1. 用“一个新增 capability + 两个 modified capability”来表达本次范围

原因：

- `subagent-execution-routing` 是一个新的能力面，负责定义模式、状态机、schema 与并发边界
- `workflow-protocol-contracts` 已经是现有 workflow guidance 的规范载体，本次需要补入 routing-aware guidance
- `transcript-based-validation` 已经是现有验证协议的规范载体，本次需要补入 overlap / conflict fixture evidence

相比把所有内容塞进一个 modified capability，这种拆分更清楚地表达：
“新增执行能力”与“现有 contract / validation 的扩展”是两件不同的事。

### 2. 将 `Pipeline SDD` 作为默认 same-session mode 记录为正式决策

原因：

- 现有子代理默认体验的核心问题不是没有任何价值，而是只有串行质量门禁、没有明确的流水线语义
- 直接把默认模式升级成完全并行会过于激进，也不符合当前 skill/docs/tests 合同层的现实
- 因此采用：
  - `Serial SDD` 处理高风险或强耦合
  - `Pipeline SDD` 作为默认 same-session 模式
  - `Parallel Dispatch` 作为有明确边界条件时的升级路径

### 3. 将 `Execution Metadata` 作为 planner 侧最小 schema

原因：

- 没有 task-level 元数据，就无法稳定判断 preflight、ready、blocked、冲突域与并行资格
- 过于复杂的 schema 会让 `writing-plans` 失去可操作性
- 因此选用最小五字段：
  - `Depends on`
  - `Write Set`
  - `Conflict Group`
  - `Risk Level`
  - `Parallelizable`

### 4. 以双层验证收敛证据

本次把验证拆成两层：

- prompt-contract regression：验证 skill/docs wording contract 是否存在
- codex fixture audit：验证 `implementer + preflight`、`reviewer + preflight` 与同一 `Conflict Group` 双 implementer guard

原因：

- 只做文案断言会停留在“写出来了”而不是“能证明这层语义被审计”
- 只做 fixture 又会丢掉技能文档本身的 contract drift 保护

### 5. 以“补建治理”而不是“重复实现”为迁移策略

原因：

- 代码已经实现并合并
- 现阶段最重要的是补 canonical record，而不是人为制造第二套实现活动
- 因此 tasks 以治理补建、验证映射与 archive readiness 为主

## Risks / Trade-offs

- [风险：本地设计线与 OpenSpec 工件发生漂移] → 以本次已合并代码和验证结果为准回填 OpenSpec，并在后续工作中把 OpenSpec 作为唯一正式记录
- [风险：把 contract 层改动误表述为 runtime scheduler 能力] → 在 proposal、design、spec 中明确本次只改变 skill/docs/tests guidance 与 validation evidence
- [风险：retroactive change 让 tasks 与实际提交时间不完全同步] → 在 tasks 中明确这是“治理补建与归档准备”的任务，而不是重新执行一遍功能开发
- [风险：验证证据只停留在局部新增测试] → 同时引用已通过的 prompt-contract 与 fixture audit 套件，避免只拿单一新测试做证明

## Migration Plan

1. 创建并补齐 `add-subagent-pipeline-routing` 的 OpenSpec artifacts
2. 将已有设计稿、执行计划与已合并实现映射到 proposal/design/specs/tasks
3. 以当前已通过的验证命令作为 change 的证据基线
4. 在治理资产补齐后，视实际状态决定是否直接进入 archive

本次不涉及运行时部署迁移，也没有单独的 rollback 过程；如需撤销，
仍以 git revert / follow-up change 为准。

## Open Questions

- 这次补建完成后，是否立即进入 `openspec-archive-change`
- 是否需要把 `docs/superpowers/specs/...` 与 `docs/superpowers/plans/...` 中的相关说明显式标记为“非 canonical，只作历史执行资产”
