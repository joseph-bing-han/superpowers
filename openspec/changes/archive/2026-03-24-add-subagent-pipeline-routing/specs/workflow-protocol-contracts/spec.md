## ADDED Requirements

### Requirement: Subagent workflow guidance exposes explicit routing semantics
涉及子代理执行的 workflow guidance MUST 显式说明执行模式、路由优先级、
状态语义与冲突边界，而不是只保留“逐任务派发子代理”的模糊叙述。

#### Scenario: Same-session workflow documents execution modes
- **WHEN** 仓库中的 workflow guidance 描述 same-session 子代理执行
- **THEN** 文档 MUST 区分 `Serial SDD`、`Pipeline SDD` 与 `Parallel Dispatch`
- **AND** MUST 说明默认 same-session 模式是哪一个

#### Scenario: Routing guidance is conflict-aware
- **WHEN** 文档声明何时允许并发、何时需要串行
- **THEN** guidance MUST 显式引用 `Conflict Group` 与 `Write Set`
  等冲突边界
- **AND** MUST NOT 用“有子代理 = 自动最大并发”的模糊表述替代正式路由规则

### Requirement: Pipeline workflow guidance defines stable state and overlap contracts
当 workflow guidance 引入 `Pipeline SDD` 时，系统 MUST 用稳定术语描述状态机与
overlap 契约，使实现者与验证器能基于同一协议理解流程。

#### Scenario: Pipeline guidance exposes state machine terms
- **WHEN** 文档描述 `Pipeline SDD`
- **THEN** MUST 包含 `queued`、`preflight`、`ready`、`blocked`
  等状态语义

#### Scenario: Pipeline guidance defines both overlap contracts
- **WHEN** 文档声称 `Pipeline SDD` 能减少主线程空等
- **THEN** MUST 同时定义 `implementer + preflight`
  与 `reviewer + preflight`
- **AND** MUST 明确这些 overlap 不等于放开同冲突域并发写入
