## MODIFIED Requirements

### Requirement: Same-session subagent execution exposes three routing modes
系统 SHALL 将 same-session 子代理执行明确划分为 `Serial SDD`、
`Pipeline SDD` 与 `Parallel Dispatch` 三种模式，并在满足安全条件时优先选择
`Parallel Dispatch`，而不是把 `Pipeline SDD` 固定为所有 same-session 场景的默认落点。

#### Scenario: High-risk work selects Serial SDD
- **WHEN** 任务属于高风险、强耦合，或未解决依赖会改变任务边界
- **THEN** 路由 MUST 进入 `Serial SDD`

#### Scenario: Parallel-safe same-session lanes prefer Parallel Dispatch
- **WHEN** same-session 路径中存在两个或以上 ready lane
- **AND** 这些 lane 已被计划证明具备独立的 `Write Set` 与 `Conflict Group` 边界
- **AND** 没有更高优先级的风险或依赖边界规则要求串行或 pipeline
- **THEN** 默认路由 MUST 进入 `Parallel Dispatch`
- **AND** MUST NOT 仅因为它们属于 same-session 执行就停留在 `Pipeline SDD`

#### Scenario: Same-session work falls back to Pipeline SDD when parallel safety is not proven
- **WHEN** 任务位于 same-session 子代理执行路径
- **AND** 没有满足 `Parallel Dispatch` 的安全条件
- **AND** 也没有高风险或强耦合因素要求 `Serial SDD`
- **THEN** 默认模式 MUST 是 `Pipeline SDD`

## ADDED Requirements

### Requirement: Execution guidance actively promotes safe parallel lanes
当执行级计划已经提供足够的冲突边界与并行资格信息时，子代理执行 guidance MUST 主动识别并行机会，并把安全 lane 作为首选执行方式，而不是仅在人工额外判断时才启用并行。

#### Scenario: Ready lanes with explicit parallel metadata are surfaced for parallel dispatch
- **WHEN** 计划中的多个任务标记为 `Parallelizable: yes`
- **AND** 它们之间没有共享 `Conflict Group` 或重叠 `Write Set`
- **THEN** execution guidance MUST 将这些任务表述为可立即并行分发的 lane
- **AND** MUST 把并行分发写成推荐动作而不是附带备注

#### Scenario: Preflight-only overlap does not block later parallel dispatch
- **WHEN** 某些任务当前只能进入 `preflight-only`
- **AND** 后续依赖解除后会满足安全并行条件
- **THEN** guidance MUST 允许先执行 safe preflight overlap
- **AND** 在满足条件后将这些 lane 升级到 `Parallel Dispatch`
