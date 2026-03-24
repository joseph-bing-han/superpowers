## Why

当前 `superpowers` 已经落地了一轮关于子代理流水线调度与能力路由的重要改动，
但最初没有进入 OpenSpec lane，导致实现、设计稿与执行计划已经存在，
而正式的 proposal/design/spec/tasks 工件缺位。现在需要把这次变更补回
OpenSpec 轨道，建立长期可追溯的 canonical record。

## What Changes

- 为子代理执行引入明确的三模式语义：`Serial SDD`、`Pipeline SDD`、`Parallel Dispatch`
- 为 `writing-plans` 增加 `Execution Metadata` schema，用于表达 `Depends on`、`Write Set`、`Conflict Group`、`Risk Level`、`Parallelizable`
- 为 `subagent-driven-development` 增加 `Pipeline SDD` 状态机、`preflight` overlap 契约和 conflict-aware routing guidance
- 将 `dispatching-parallel-agents` 重新定位为 execution-time lane upgrade，而不再只是调试期技巧
- 为新路由补充 prompt-contract regression 与 codex fixture audit，证明 overlap 与 conflict guard 语义
- 把上述已合并实现补建为正式 OpenSpec change，作为后续 archive 与团队交接的治理基线

## Capabilities

### New Capabilities
- `subagent-execution-routing`: 定义子代理执行模式、Execution Metadata schema、Pipeline SDD 状态机与并发边界

### Modified Capabilities
- `workflow-protocol-contracts`: 增加子代理路由、状态机与 conflict-aware guidance 的规范要求
- `transcript-based-validation`: 增加针对 Pipeline overlap 与 Conflict Group guard 的 fixture-level 验证要求

## Impact

- 受影响代码与文档：
  - `skills/writing-plans/SKILL.md`
  - `skills/subagent-driven-development/SKILL.md`
  - `skills/using-superpowers/SKILL.md`
  - `skills/dispatching-parallel-agents/SKILL.md`
  - `docs/README.codex.md`
  - `docs/testing.md`
- 受影响测试：
  - `tests/prompt-contracts/test-subagent-pipeline-routing.sh`
  - `tests/codex/test-subagent-pipeline-routing-fixtures.sh`
  - `tests/codex/fixtures/pipeline-sdd-overlap-positive.jsonl`
  - `tests/codex/fixtures/pipeline-sdd-conflict-group-negative.jsonl`
- 受影响系统：
  - Superpowers 本地 skill 合同
  - Codex-facing 文档与验证入口
