## ADDED Requirements

### Requirement: Key workflow checkpoints expose machine-readable state
关键 workflow 节点 MUST 暴露稳定的机器可判定状态信号，使自动化流程能够在不依赖自然语言措辞的前提下判断当前状态。

#### Scenario: Checkpoint state is available for automation
- **WHEN** 任一关键 workflow 到达 checkpoint、handoff、review verdict 或 terminal-choice 边界
- **THEN** 系统 SHALL 产生可解析的状态信号，例如工具事件、transcript 字段或固定枚举尾块

### Requirement: Human-readable prose is not the sole machine contract
给用户阅读的自然语言正文 SHALL 与机器判定协议解耦；正文可以变化，但不得成为唯一的自动化判定依据。

#### Scenario: Prose wording changes without breaking protocol
- **WHEN** 同一 workflow 在不同模型、不同语言或不同表达风格下输出不同正文
- **THEN** 自动化流程 MUST 仍能仅依赖稳定协议信号完成状态判定

### Requirement: Review and execution flows use stable verdict and next-action semantics
review、execution handoff 与类似决策节点 MUST 使用稳定的 verdict 与 next-action 语义，以便后续自动化逻辑一致消费。

#### Scenario: Reviewer returns a stable verdict
- **WHEN** reviewer 判断当前工件需要修改或可以继续
- **THEN** 系统 SHALL 输出稳定的 verdict 与 next-action 信号，而不是只输出自由文本结论
