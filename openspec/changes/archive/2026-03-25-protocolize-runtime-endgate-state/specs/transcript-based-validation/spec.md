## MODIFIED Requirements

### Requirement: Text-only fallbacks use fixed machine-readable signals
对于暂时无法直接从工具事件或 transcript 中提取协议信号的流程，系统 MUST 提供固定机器可读尾块或等价结构化信号，供验证使用。

#### Scenario: Endgate packet remains parseable across transcript transports
- **WHEN** 某个 workflow 边界尚未拥有原生结构化 endgate transcript 字段
- **THEN** 该边界 SHALL 通过固定字段的 `endgate-state-packet` 暴露协议状态
- **AND** validator MUST 能从 tail block 或等价结构化字段解析出
  `ENDGATE_PROTOCOL_VERSION`、`ENDGATE_STATE`、
  `ENDGATE_CHOICE_KIND` 与 `ENDGATE_NEXT_ACTION`

### Requirement: Validation audits runtime prose-endgate leaks from Codex transcripts
自动化验证 MUST 能够直接从 Codex `.jsonl` transcript 中审计 runtime endgate
是否合法，而不能只验证文档里是否写有禁止 prose-only 结束的 guidance。

#### Scenario: Packet-driven validation rejects an undeclared or unfulfilled ending
- **WHEN** 验证器读取一个 transcript fixture
- **AND** 同一 turn 中存在 `endgate-state-packet`
- **AND** 该 packet 后续没有得到与其状态匹配的兑现动作
- **THEN** 验证 MUST 失败
- **AND** MUST 报告 packet declaration 与 observed event sequence 不一致

#### Scenario: Legacy invitation leak still fails when packet is absent
- **WHEN** 验证器读取一个 transcript fixture
- **AND** 当前 turn 尚未发出 `endgate-state-packet`
- **AND** 同一 turn 中最后一条 assistant 文本属于具体下一步邀请型 prose
- **AND** 该 turn 随后直接发生 `task_complete`
- **AND** 该 turn 内不存在 `request_user_input` 或可证明的 `auto-continue` 动作
- **THEN** 验证 MUST 失败
- **AND** 该路径 SHALL 作为 legacy prose safety net 被继续拦截

## ADDED Requirements

### Requirement: Validation anchors endgate audits on the last declared packet
当 transcript 中存在 `endgate-state-packet` 时，validator MUST 以当前 turn
最后一份 packet 作为 endgate 审计锚点，并只审计该 packet 之后的事件窗口。

#### Scenario: Prior tool call does not satisfy a later packet
- **WHEN** transcript 在最后一份 `endgate-state-packet` 之前已经存在普通工具调用
- **AND** packet 之后没有新的合法 continuation action
- **THEN** validator MUST 将该 turn 判定为未兑现的 endgate
- **AND** MUST NOT 用 packet 之前的工具调用为其放行

### Requirement: Validation distinguishes needs-user-decision from terminal-choice by protocol data
对于都以 `request_user_input` 作为直接动作的 endgate 状态，validator MUST 依赖
packet 字段与 popup 结构，而不是 prose 文案，来区分
`NEEDS_USER_DECISION` 与 `TERMINAL_CHOICE`。

#### Scenario: Needs-user-decision expects a non-terminal request_user_input payload
- **WHEN** packet 声明 `ENDGATE_STATE=NEEDS_USER_DECISION`
- **THEN** validator MUST 观察到 `request_user_input`
- **AND** 该 payload MUST 对应具体下一步选择
- **AND** MUST NOT 被当作 terminal-choice popup 通过

#### Scenario: Terminal-choice expects the canonical terminal_choice popup
- **WHEN** packet 声明 `ENDGATE_STATE=TERMINAL_CHOICE`
- **THEN** validator MUST 观察到 `request_user_input`
- **AND** 其问题标识 MUST 对应 `terminal_choice`
- **AND** assistant-authored options MUST 继续只包含
  `结束 (Recommended)` 与 `继续`

### Requirement: Validation keeps prose matching as a secondary safety net only
当 `endgate-state-packet` 已经存在时，validator MUST 以 packet 和后续事件序列
作为主断言依据；invitation prose 模式匹配只能作为补充诊断，不能覆盖 packet
已经声明出的正式状态。

#### Scenario: Packet presence suppresses prose-first classification
- **WHEN** transcript 中已经存在可解析的 `endgate-state-packet`
- **THEN** validator MUST 优先根据该 packet 与其后的事件窗口做判定
- **AND** prose 模式匹配 MAY 作为错误说明的一部分
- **AND** prose 模式匹配 MUST NOT 取代 packet 成为主合规依据
