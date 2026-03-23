## ADDED Requirements

### Requirement: Validation audits universal terminal-choice inheritance across local skills
自动化验证 MUST 能够从仓库层面确认所有本地 skill 都显式继承了统一终局协议，
而不是只依赖少数核心 skill 的局部文案。

#### Scenario: A local skill omits explicit terminal endgate guidance
- **WHEN** prompt-contract 测试审计本地 skill 文件集合
- **THEN** 如果任一 skill 缺少显式的终局协议区块、缺少
  `request_user_input` 终局要求，或缺少 `1. 结束 / 2. 继续 / 3. 自由输入`
  选项约束，测试 MUST 失败

### Requirement: Validation catches contingent-authorization prose-only endings
自动化验证 MUST 覆盖条件式授权场景，防止系统在正向判断后再次退回
prose-only 的自由文本收口。

#### Scenario: Guidance reintroduces a contingent-authorization free-text ending
- **WHEN** skill 文案或文档重新出现“条件成立后用自由文本结论块结束当前 turn”
  的规则或示例
- **THEN** prompt-contract 验证 MUST 失败，并指出该路径不符合统一终局协议
