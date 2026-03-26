## MODIFIED Requirements

### Requirement: Workflow endgate boundaries emit a fixed machine-readable packet
系统 MUST 在任何 workflow 到达 checkpoint、analysis recommendation
boundary、handoff 或 terminal boundary 时，暴露一份固定字段的
`endgate-state-packet`，供 transcript validator 与后续自动化逻辑消费。

#### Scenario: Boundary packet exposes the canonical fields through the preferred carrier
- **WHEN** assistant 到达任一 endgate 边界
- **THEN** 系统 SHALL 暴露以下 canonical 字段：
  `ENDGATE_PROTOCOL_VERSION`、`ENDGATE_STATE`、
  `ENDGATE_CHOICE_KIND`、`ENDGATE_NEXT_ACTION`
- **AND** 若当前运行时支持结构化 transcript 字段，carrier SHALL 使用该结构化字段
- **AND** 仅当该能力不存在时，carrier MAY 回退为固定 tail block

#### Scenario: Tail block remains the compatibility fallback
- **WHEN** 当前运行时尚未提供原生结构化 endgate transcript 字段
- **THEN** 系统 SHALL 继续通过固定 tail block 暴露 canonical 字段
- **AND** validator MUST 仍能按现有字段名解析该 packet
