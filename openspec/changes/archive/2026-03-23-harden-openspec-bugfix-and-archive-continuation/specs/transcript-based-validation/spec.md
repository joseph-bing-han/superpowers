## ADDED Requirements

### Requirement: Validation audits governed bugfix context recovery guidance
自动化验证 MUST 能够确认 governed bugfix 不会跳过既有 OpenSpec 设计资产，
而是会在调试阶段明确恢复 proposal/design/spec/tasks 上下文。

#### Scenario: Bugfix guidance omits existing OpenSpec artifact recovery
- **WHEN** prompt-contract 测试审计 governed bugfix 相关 guidance
- **THEN** 如果文案没有明确要求识别既有 change 并读取
  `proposal.md`、`design.md`、`specs/*`、`tasks.md`
- **THEN** 测试 MUST 失败

### Requirement: Validation audits OpenSpec apply and archive auto-continuation
自动化验证 MUST 能够确认已知的 OpenSpec lane 下一步不会被降级成泛化的
继续/结束交互。

#### Scenario: Guidance reintroduces generic continue/stop gating before apply or archive
- **WHEN** prompt-contract 测试审计 OpenSpec continuation guidance
- **THEN** 如果文案把已知的 `openspec-apply-change` 或
  `openspec-archive-change` 下一步重新写成 generic continue/stop
  prompt、recommendation-only 结束、或只建议不续跑
- **THEN** 测试 MUST 失败
