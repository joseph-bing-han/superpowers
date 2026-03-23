## Why

当前 `superpowers` 与 `OpenSpec` 的桥接已经解决了“新功能/跨模块/多阶段”
进入治理 lane 的主路径，但真实使用中仍暴露出两个明显缺口：

1. **bug 分析与修复阶段不会自动回看既有 OpenSpec 设计资产**
   当用户是在一个已存在的 OpenSpec change 上继续修 bug 时，
   workflow 仍可能直接进入 `systematic-debugging` / `test-driven-development`
   的局部排障路径，而没有先读取该 change 的 `proposal.md`、`design.md`、
   `specs/*`、`tasks.md`。结果就是修复容易只对准当前 symptom，
   丢失原有设计边界和全局目标。
2. **OpenSpec lane 很难自然走到自动归档**
   当前仓库虽然已经增加了 archive handoff 文案，但更多时候 workflow 会在
   “已知下一步仍然明确”的节点停在泛化的 `继续/结束` 选择，或者只输出
   “ready to archive” 一类建议，而不是把 `openspec-archive-change`
   视作已隐含授权的下一条 lane。

2026-03-23 的真实 Codex transcript 进一步说明这不是理论问题：

- 在 `rollout-2026-03-23T19-54-43-019d1979-75b9-7d01-a48a-30f850f58a4e.jsonl`
  中，assistant 已经读取了 `openspec status` 与 `openspec instructions apply`
  的结果，知道当前 change、剩余任务和下一步实现入口，却仍在后续用
  泛化 `request_user_input` 询问“下一步怎么做”，没有把 OpenSpec 既有
  lane 视作已明确的自动续跑路径。

这说明当前治理规则缺少两条正式协议语义：

- governed bugfix 必须先恢复既有 OpenSpec 上下文
- 当 OpenSpec lane 的下一步已知且安全时，应该 auto-continue 到
  `openspec-apply-change` 或 `openspec-archive-change`

## What Changes

- 正式定义“**governed bugfix context recovery**”协议：
  如果 bug 落在既有 OpenSpec change 的范围内，bug 分析和修复前
  MUST 先读取该 change 的 `proposal.md`、`design.md`、`specs/*`、`tasks.md`。
- 正式定义“**OpenSpec next-step auto-continuation**”协议：
  当当前 lane 已经知道下一步是继续 apply 还是进入 archive 时，
  workflow MUST 直接进入对应 skill，而不是退化成泛化的继续/结束提示。
- 把上述协议落到 `using-superpowers`、`systematic-debugging`、
  `spec-governed-development`、`finishing-a-development-branch`
  与 `docs/README.codex.md`。
- 增加 prompt-contract 回归测试，分别锁定：
  - bugfix 会恢复既有 OpenSpec 上下文
  - 已知的 OpenSpec apply/archive 下一步会被视为 `auto-continue`

## Capabilities

### New Capabilities

- 无

### Modified Capabilities

- `workflow-protocol-contracts`
  - 增加 governed bugfix context recovery requirement
  - 增加 OpenSpec next-step auto-continuation requirement
- `transcript-based-validation`
  - 增加对上述两类协议的 prompt-contract 审计

## Impact

- Affected code:
  - `skills/using-superpowers/SKILL.md`
  - `skills/systematic-debugging/SKILL.md`
  - `skills/finishing-a-development-branch/SKILL.md`
  - `spec-governed-development/SKILL.md`
  - `docs/README.codex.md`
  - `tests/prompt-contracts/*.sh`
- Affected specs:
  - `openspec/specs/workflow-protocol-contracts/spec.md`
  - `openspec/specs/transcript-based-validation/spec.md`
- Affected systems:
  - governed bugfix routing
  - OpenSpec lane continuation
  - archive handoff behavior
