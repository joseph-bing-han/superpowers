# transcript-based-validation Specification

## Purpose
TBD - created by archiving change decouple-prose-from-workflow-protocols. Update Purpose after archive.
## Requirements
### Requirement: Automated validation prefers behavioral evidence over prose
自动化验证 MUST 优先使用工具调用、session transcript、stream-json 或其他结构化行为证据，而不是助手自由文本中的关键词或句式。

#### Scenario: Tool-backed interaction is validated from transcript
- **WHEN** workflow 通过工具调用完成关键动作，例如触发选择 UI 或加载 skill
- **THEN** 测试 SHALL 以 transcript 或等价结构化事件为主要断言依据

### Requirement: Validation tolerates language and style drift
当协议层信号保持一致时，自动化验证 MUST 容忍中文、英文及不同表达风格带来的正文变化。

#### Scenario: Output language changes but protocol stays stable
- **WHEN** 同一 workflow 在中文与英文条件下输出不同自然语言正文
- **THEN** 测试 MUST 依据相同的协议层信号判定通过，而不是因为措辞不同失败

### Requirement: Text-only fallbacks use fixed machine-readable signals
对于暂时无法直接从工具事件或 transcript 中提取协议信号的流程，系统 MUST 提供固定机器可读尾块或等价结构化信号，供验证使用。

#### Scenario: Fallback flow still exposes a parseable contract
- **WHEN** 某个 review 或 handoff 流程主要通过文本向用户展示结果
- **THEN** 该流程 SHALL 同时输出固定格式的机器可读信号，供自动化验证解析

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

