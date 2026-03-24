## MODIFIED Requirements

### Requirement: Validation audits OpenSpec apply and archive auto-continuation
自动化验证 MUST 能够确认已知的 OpenSpec lane 下一步不会被降级成泛化的
继续/结束交互。

#### Scenario: Guidance reintroduces generic continue/stop gating before apply or archive
- **WHEN** prompt-contract 测试审计 OpenSpec continuation guidance
- **THEN** 如果文案把已知的 `openspec-apply-change` 或
  `openspec-archive-change` 下一步重新写成 generic continue/stop
  prompt、recommendation-only 结束、或只建议不续跑
- **THEN** 测试 MUST 失败

#### Scenario: Guidance allows a created OpenSpec change to finish without archive
- **WHEN** prompt-contract 测试审计 created OpenSpec proposal / change 的终局规则
- **THEN** 如果文案允许 assistant 在最终完成时跳过
  `openspec-archive-change`
- **OR** 允许以 recommendation-only prose、generic continue/stop、
  或普通 terminal-choice 结束该 change
- **THEN** 测试 MUST 失败
