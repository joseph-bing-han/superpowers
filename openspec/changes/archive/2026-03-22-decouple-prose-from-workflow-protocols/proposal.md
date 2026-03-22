## Why

当前仓库中有一部分 workflow 与测试仍依赖 LLM 的自由文本输出进行判定，例如匹配固定短语、固定 verdict 文案或特定措辞。这类做法会随着模型升级、供应商切换、语言偏好变化或输出风格漂移而变脆，导致“功能仍然正确，但测试先失效”或“流程依赖特定话术才能继续”的问题。

现在需要把关键流程从“以 prose 为协议”收敛到“以事件、状态和结构化契约为协议”，从而提升跨模型、跨语言、跨平台的一致性与可维护性。

## What Changes

- 为关键 workflow 定义机器可判定的稳定协议面，优先使用工具调用、transcript 事件和固定枚举状态，而不是自由文本措辞。
- 为 reviewer、workflow checkpoint、execution handoff 等关键节点建立统一的状态字段与 verdict 约定。
- 为仍需文本输出的流程增加稳定的结构化尾块或等价的机器可读信号，避免测试直接依赖正文措辞。
- 将脆弱的集成测试从“匹配助手说了什么”迁移为“验证助手做了什么”，优先解析 stream-json、jsonl transcript 或固定状态块。
- 增加针对语言漂移和模型漂移的回归验证，确认中文、英文或不同表达风格下的协议行为保持一致。

## Capabilities

### New Capabilities
- `workflow-protocol-contracts`: 为关键 workflow 定义与输出稳定的机器可判定协议，包括状态枚举、verdict 语义、next action 约定以及 prose 与协议分层规则。
- `transcript-based-validation`: 为测试与验证流程定义基于工具事件、session transcript 和结构化状态信号的断言方式，替代对自由文本措辞的直接匹配。

### Modified Capabilities

无

## Impact

- Affected code:
  - `skills/**/*.md`
  - `skills/subagent-driven-development/*.md`
  - `tests/claude-code/*.sh`
  - `tests/opencode/*.sh`
  - `tests/skill-triggering/*.sh`
  - `tests/prompt-contracts/*.sh`
- Affected docs:
  - `docs/testing.md`
  - `docs/README.codex.md`
  - 可能涉及 README 中对交互契约和验证方式的说明
- Affected systems:
  - Codex transcript / tool-backed workflow validation
  - Claude / OpenCode 集成测试
  - 后续任何依赖 skill prose 作为判定信号的自动化检查
