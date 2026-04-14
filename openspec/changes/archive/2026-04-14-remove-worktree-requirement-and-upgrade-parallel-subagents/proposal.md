## Why

当前 Superpowers 的现行工作流把 `using-git-worktrees` 作为规划与实现前的默认前置步骤，这会把大量正常场景强行导向额外工作区，增加执行成本，也与“直接在当前工作区完成任务”的实际使用偏好冲突。与此同时，子代理能力虽然已经定义了 `Parallel Dispatch`，但现行 guidance 仍偏保守，更多停留在“允许并行”而不是“在安全时主动并行”，导致多 lane 任务仍容易退化为串行协调。

## What Changes

- **BREAKING** 移除现行 workflow 对 `using-git-worktrees` 的默认依赖，不再把 worktree 作为规划、执行、收尾的必经步骤。
- 新增“默认在当前工作区执行”的 workspace contract，仅在用户明确要求隔离工作区时才允许进入额外 workspace 流程。
- 强化子代理执行 guidance：当计划已经证明 lane 之间 `Write Set` 与 `Conflict Group` 独立时，workflow 应主动升级到并行分发，而不是仅把并行视为少数例外。
- 对齐相关 skill、使用文档与 prompt-contract / fixture 测试，使无 worktree 前置与积极并行分发成为当前生效合同的一部分。

## Capabilities

### New Capabilities
- `workspace-execution-context`: 规范现行工作流默认在当前工作区执行，并限制 worktree 仅能作为显式请求下的可选隔离手段。

### Modified Capabilities
- `subagent-execution-routing`: 将 same-session 子代理路由从“默认 Pipeline、谨慎升级并行”收敛为“在安全条件满足时主动并行分发”。
- `transcript-based-validation`: 增加对“默认当前工作区执行”与“安全时主动并行分发”合同的验证要求，确保 prompt-contract 与 fixture 能锁定这两类行为。

## Impact

- Affected skills:
  - `skills/brainstorming/SKILL.md`
  - `skills/writing-plans/SKILL.md`
  - `skills/executing-plans/SKILL.md`
  - `skills/subagent-driven-development/SKILL.md`
  - `skills/dispatching-parallel-agents/SKILL.md`
  - `skills/finishing-a-development-branch/SKILL.md`
  - `skills/using-superpowers/SKILL.md`
- Affected docs/tests:
  - `docs/README.codex.md`
  - `tests/prompt-contracts/test-worktree-execution-lifecycle.sh`
  - `tests/prompt-contracts/test-subagent-pipeline-routing.sh`
  - 相关 transcript / fixture 验证脚本
- Potential cleanup:
  - `skills/using-git-worktrees/SKILL.md` 需要改为非默认能力或从现行流程中彻底脱钩
