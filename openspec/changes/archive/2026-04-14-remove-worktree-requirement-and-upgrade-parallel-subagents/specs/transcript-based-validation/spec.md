## MODIFIED Requirements

### Requirement: Validation audits routing and execution-metadata contracts
自动化验证 MUST 能够审计子代理路由相关的 prompt/docs contract，
包括 `Execution Metadata` schema、三模式路由，以及“安全时主动并行分发”的合同，
而不是只在实现完成后依赖人工解释。

#### Scenario: Prompt-contract suite checks routing schema and proactive parallel semantics
- **WHEN** 仓库运行子代理路由相关的 prompt-contract 测试
- **THEN** 测试 MUST 断言 `Execution Metadata` schema、
  `Pipeline SDD`、`Parallel Dispatch` 与 routing priority 等 contract 存在
- **AND** MUST 断言安全 lane 会被表述为主动并行分发，而不是仅被描述为可选升级路径

## ADDED Requirements

### Requirement: Validation audits current-workspace execution contracts
自动化验证 MUST 能审计现行 workflow 已将“当前工作区默认执行”收敛为正式合同，并把 worktree 从默认前置降为显式 opt-in 能力。

#### Scenario: Prompt-contract suite rejects dedicated-worktree prerequisites in active workflows
- **WHEN** 验证器审计 `brainstorming`、`writing-plans`、`executing-plans`、`subagent-driven-development`、`finishing-a-development-branch` 与 README 等现行入口文档
- **THEN** 测试 MUST 拒绝“必须先进入 dedicated worktree”或等价默认前置语句
- **AND** MUST 证明这些文档把当前工作区执行写成默认路径

#### Scenario: Validation allows optional isolation only behind explicit request semantics
- **WHEN** 验证器审计仍然保留的 worktree / isolated workspace 文档
- **THEN** 测试 MUST 证明它们只以显式 opt-in 或条件性步骤出现
- **AND** MUST NOT 把它们判定为现行默认 workflow 的必经环节
