## 1. 收敛当前工作区执行合同

- [x] 1.1 更新 `skills/brainstorming/SKILL.md`，移除 `using-git-worktrees` 作为设计后默认交接步骤的要求
- [x] 1.2 更新 `skills/writing-plans/SKILL.md`，移除 dedicated worktree 前置与复用要求，改为默认当前工作区规划
- [x] 1.3 更新 `skills/executing-plans/SKILL.md` 与 `skills/subagent-driven-development/SKILL.md`，移除“必须位于 dedicated worktree”前提
- [x] 1.4 更新 `skills/finishing-a-development-branch/SKILL.md` 与 `docs/README.codex.md`，把 worktree 生命周期改为条件性上下文而非默认流程

## 2. 强化子代理主动并行路由

- [x] 2.1 更新 `skills/using-superpowers/SKILL.md`，把 same-session 路由顺序改为“高风险串行，安全 lane 并行，其余才 Pipeline”
- [x] 2.2 更新 `skills/subagent-driven-development/SKILL.md`，要求在满足独立 `Write Set` / `Conflict Group` 时主动进入 `Parallel Dispatch`
- [x] 2.3 更新 `skills/dispatching-parallel-agents/SKILL.md`，把该 skill 表述为安全 lane 的首选执行升级路径，而不是被动补充技巧

## 3. 对齐验证与文档

- [x] 3.1 重写 `tests/prompt-contracts/test-worktree-execution-lifecycle.sh`，改为校验“默认当前工作区执行”与“显式 opt-in 隔离”合同
- [x] 3.2 扩展 `tests/prompt-contracts/test-subagent-pipeline-routing.sh` 与相关 fixture / transcript 验证，锁定“安全时主动并行分发”合同
- [x] 3.3 运行相关 prompt-contract / fixture 测试并修正失败，确认 OpenSpec change 达到 apply-ready 的实现基线
