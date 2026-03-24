## 1. 补建治理资产

- [ ] 1.1 将 proposal/design/specs/tasks 与已合并实现、设计稿、执行计划对齐
- [ ] 1.2 确认 OpenSpec capability 划分为 `subagent-execution-routing` 新增能力，以及 `workflow-protocol-contracts`、`transcript-based-validation` 的 modified delta

## 2. 对齐实现与验证证据

- [ ] 2.1 确认 `writing-plans`、`subagent-driven-development`、`using-superpowers`、`dispatching-parallel-agents`、`docs/README.codex.md`、`docs/testing.md` 的已合并改动与 OpenSpec 工件一致
- [ ] 2.2 确认 `tests/prompt-contracts/test-subagent-pipeline-routing.sh` 与 `tests/codex/test-subagent-pipeline-routing-fixtures.sh` 作为本 change 的验证证据
- [ ] 2.3 记录已通过的验证命令，作为 change 的 branch-level evidence

## 3. 归档准备

- [ ] 3.1 判断这次补建后的 change 是否已经满足 archive compatibility
- [ ] 3.2 如果满足 archive 条件，则进入 `openspec-archive-change`
