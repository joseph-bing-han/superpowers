## Context

当前现行 Superpowers workflow 在多个入口把 `using-git-worktrees` 设成默认前置：

- `brainstorming` 把设计后的实现交接固定成 `using-git-worktrees` → `writing-plans`
- `writing-plans`、`executing-plans`、`subagent-driven-development` 把“已在 dedicated worktree 中”视为执行前提
- `finishing-a-development-branch` 与 `docs/README.codex.md` 也把 worktree 生命周期当作默认收尾路径

这使“在当前工作区直接完成任务”变成非标准路径，和实际使用习惯相反。

与此同时，`subagent-execution-routing` 已经定义了 `Serial SDD`、`Pipeline SDD` 与 `Parallel Dispatch`，但当前 wording 更强调默认 `Pipeline SDD`，让并行分发仍像保守升级路径，而不是在安全时优先使用的执行模式。结果是：即使计划已经给出了独立 `Write Set`、`Conflict Group` 和 `Parallelizable: yes`，workflow 也缺少足够强的“主动并行”引导。

## Goals / Non-Goals

**Goals:**

- 把“当前工作区执行”确立为现行 workflow 的默认 contract
- 从现行 skill、文档、测试中移除对 worktree 的默认依赖
- 保留隔离 workspace 的扩展点，但仅作为显式请求下的可选手段
- 将子代理 same-session 路由收敛为“安全即主动并行，不安全才退回 Pipeline/Serial”
- 用 prompt-contract 与 fixture 验证锁定以上两类行为

**Non-Goals:**

- 不修改历史 archive 文档或已归档 change
- 不承诺新增底层 runtime scheduler 能力
- 不把所有子代理任务都强行并行化
- 不要求移除仓库里所有与 worktree 相关的历史实现痕迹，只移除现行默认流程依赖

## Decisions

### 1. 用新增 capability 表达“当前工作区是默认执行上下文”

选择新增 `workspace-execution-context`，而不是把这部分揉进已有 workflow spec。

原因：

- worktree 默认与否是一个独立的行为合同，不只是 wording 微调
- 该合同会同时影响设计交接、计划生成、实现执行、收尾文档与 README
- 独立 capability 更容易在后续继续扩展“显式隔离 workspace”或其他执行上下文策略

备选方案：只改 skill 文案，不新增 spec。

不采用原因：这样无法把“当前工作区默认执行”沉淀成可验证的长期合同，后续容易被 prompt drift 再次带回 worktree-first。

### 2. Worktree 从默认前置改为显式 opt-in 能力

现行流程不再自动调用 `using-git-worktrees`，也不再要求已经身处 dedicated worktree 才能进入规划或执行。

原因：

- 该仓库当前需求是“去除 worktrees”，核心是取消默认依赖，而不是只弱化措辞
- 大多数实现任务可以直接在当前工作区安全完成，默认隔离会增加无必要的切换与维护成本
- 把隔离手段降为显式 opt-in，既满足当前需求，也保留未来在特殊场景下手动使用的空间

备选方案：保留 worktree 作为推荐，但不是强制。

不采用原因：只要仍保留“推荐进入 worktree”的现行主路径，模型就会继续优先沿旧路径执行，无法真正完成本次行为收敛。

### 3. Same-session 子代理路由改为“并行优先，Pipeline 兜底”

保留三模式：`Serial SDD`、`Pipeline SDD`、`Parallel Dispatch`，但调整默认决策顺序：

1. 高风险或边界未定 -> `Serial SDD`
2. 已证明 lane 独立 -> `Parallel Dispatch`
3. 其余 same-session 情况 -> `Pipeline SDD`

原因：

- 用户要求“子代理功能，要积极地实现并行处理”
- 现有元数据已经足够判断安全并行条件，不需要等待新的 runtime 能力
- 真正阻止并行的应是风险、依赖边界和冲突域，而不是“same-session”这个事实本身

备选方案：继续以 `Pipeline SDD` 为默认，只有人工判断时才升级并行。

不采用原因：这会继续把并行变成“可用但不常用”的能力，无法改变实际执行倾向。

### 4. planner 不新增复杂 schema，只强化对并行 lane 的使用义务

`Execution Metadata` 仍保持现有五字段：

- `Depends on`
- `Write Set`
- `Conflict Group`
- `Risk Level`
- `Parallelizable`

原因：

- 当前 schema 已能支撑安全并行的判断
- 本次问题不在于元数据缺失，而在于 executor 没有被要求“积极消费”这些元数据
- 保持 schema 稳定，能把变更集中在 routing guidance 和验证层，降低迁移面

备选方案：新增更细的 lane、phase、resource 锁字段。

不采用原因：会显著扩大规划成本，不符合这次“改执行倾向而不是重做协议”的目标。

### 5. 用测试替换而不是测试叠加来完成合同迁移

现有 `test-worktree-execution-lifecycle.sh` 锁定的是旧合同，因此应改造成当前工作区执行合同，而不是保留旧测试再额外加一个新测试。

原因：

- 旧测试如果继续存在，会和新合同直接冲突
- 这次是合同迁移，不是兼容双轨运行
- 子代理并行相关测试则需要在现有路由测试基础上补入“主动并行”断言，而不是平行维护两套相反预期

## Risks / Trade-offs

- [风险：失去默认隔离后，用户更容易在脏工作区直接执行] → 将当前工作区执行写清为默认合同，同时保留显式 opt-in 的隔离入口，避免 workflow 再自动分叉
- [风险：把“积极并行”误解成“所有任务都并行”] → 继续保留 `Risk Level`、依赖边界、`Conflict Group` / `Write Set` 的优先级，并在 spec 中明确只有安全 lane 才并行
- [风险：现有 README、tests 与 skill wording 漂移不同步] → 以 OpenSpec specs 为基准统一更新 skill、README 与 prompt-contract / fixture 套件
- [风险：`using-git-worktrees` skill 仍被误当成默认能力] → 从现行交接语句、执行前提与 README 生命周期说明中彻底脱钩，只保留为显式请求时才可能使用的附加能力

## Migration Plan

1. 新增 `workspace-execution-context` spec，定义当前工作区默认执行与隔离 opt-in 规则
2. 修改 `subagent-execution-routing` spec，把安全并行 lane 的默认路由改为 `Parallel Dispatch`
3. 修改 `transcript-based-validation` spec，补入当前工作区与主动并行合同的验证要求
4. 依 spec 更新 active skills、README 与 prompt-contract / fixture 测试
5. 运行相关测试，确认 worktree-first 合同已被 current-workspace 与 proactive-parallel 合同替代

本次不涉及运行时部署迁移；若需回退，以 git revert 或 follow-up change 为准。

## Open Questions

- `skills/using-git-worktrees/SKILL.md` 是否保留为可手动调用的辅助 skill，还是后续另开 change 完全移除
- `dispatching-parallel-agents` 是否还需要进一步加入“计划拆分建议”的 wording，以便在规划阶段就更主动暴露并行 lane
