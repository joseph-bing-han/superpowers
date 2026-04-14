# workspace-execution-context Specification

## Purpose
TBD - created by archiving change remove-worktree-requirement-and-upgrade-parallel-subagents. Update Purpose after archive.
## Requirements
### Requirement: Active workflows default to the current workspace
现行 Superpowers workflow 在进入设计后规划、实现执行与收尾 guidance 时，MUST 默认以当前工作区作为执行上下文，而不是要求先创建或切换到 dedicated worktree。

#### Scenario: Planning handoff stays in the current workspace
- **WHEN** workflow 从设计阶段进入 `writing-plans`
- **AND** 用户没有明确要求额外隔离 workspace
- **THEN** assistant MUST 直接在当前工作区继续规划
- **AND** MUST NOT 把 `using-git-worktrees` 作为默认前置步骤

#### Scenario: Implementation guidance does not require a dedicated worktree
- **WHEN** workflow 进入 `executing-plans`、`subagent-driven-development` 或等价实现路径
- **AND** 当前工作在现有工作区即可继续
- **THEN** guidance MUST 允许直接在当前工作区执行
- **AND** MUST NOT 声明“必须已经位于 dedicated worktree 中”

### Requirement: Isolated workspaces are explicit opt-in only
额外隔离 workspace 或 worktree MUST 只在用户明确要求隔离执行环境时才允许进入，不得作为现行默认路线自动触发。

#### Scenario: Explicit isolation request allows optional worktree setup
- **WHEN** 用户明确要求使用 worktree、isolated workspace，或其他单独隔离工作区
- **THEN** workflow MAY 调用相应的隔离能力
- **AND** MUST 把该动作视为显式 opt-in，而不是现行默认合同

#### Scenario: No explicit isolation request keeps the main workflow in place
- **WHEN** 用户只要求完成变更或继续下一阶段
- **AND** 没有提出隔离 workspace 的显式要求
- **THEN** workflow MUST 继续沿当前工作区路径执行
- **AND** MUST NOT 因为实现即将开始就自动切到 worktree 生命周期

### Requirement: Finish guidance treats worktree cleanup as optional context
收尾 workflow MUST 能在没有 dedicated worktree 的情况下完整结束，不得把 worktree cleanup 当作默认必经步骤。

#### Scenario: Finish flow completes without worktree cleanup
- **WHEN** assistant 进入 `finishing-a-development-branch`
- **AND** 当前实现是在主工作区完成的
- **THEN** flow MUST 继续提供正常的收尾选项
- **AND** MUST NOT 因缺少 worktree cleanup 步骤而阻塞收尾

#### Scenario: Optional cleanup appears only when an isolated workspace was used
- **WHEN** 当前实现确实使用了额外 worktree 或 isolated workspace
- **THEN** finish guidance MAY 提供对应清理说明
- **AND** 这些说明 MUST 明确是条件性步骤，而不是默认流程前提
