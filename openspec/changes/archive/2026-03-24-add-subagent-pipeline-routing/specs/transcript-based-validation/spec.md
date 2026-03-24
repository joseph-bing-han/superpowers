## ADDED Requirements

### Requirement: Validation audits routing and execution-metadata contracts
自动化验证 MUST 能够审计子代理路由相关的 prompt/docs contract，
而不是只在实现完成后依赖人工解释。

#### Scenario: Prompt-contract suite checks routing schema and execution modes
- **WHEN** 仓库运行子代理路由相关的 prompt-contract 测试
- **THEN** 测试 MUST 断言 `Execution Metadata` schema、
  `Pipeline SDD`、`Parallel Dispatch` 与 routing priority 等 contract 存在

### Requirement: Validation audits pipeline overlap and conflict guard evidence
自动化验证 MUST 能够通过 fixture 或 transcript-level evidence 审计
`Pipeline SDD` 的 overlap 与 `Conflict Group` guard，而不仅仅检查文案存在。

#### Scenario: Positive fixture proves both pipeline overlap contracts
- **WHEN** 验证器读取子代理路由的正向 fixture
- **THEN** MUST 分别证明 `implementer + preflight`
  与 `reviewer + preflight` 两类 overlap

#### Scenario: Negative fixture is rejected for same Conflict Group double-write
- **WHEN** 验证器读取同一 `Conflict Group` 中双 implementer 重叠写入的负向 fixture
- **THEN** 验证 MUST 将其判定为被正确拒绝的非法情况
- **AND** 整个审计脚本 MAY 以“负样本被正确拒绝”作为通过结果的一部分
