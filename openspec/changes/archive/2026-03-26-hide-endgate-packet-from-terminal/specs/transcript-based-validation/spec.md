## MODIFIED Requirements

### Requirement: Text-only fallbacks use fixed machine-readable signals
对于暂时无法直接从工具事件或 transcript 中提取协议信号的流程，系统 MUST 提供固定机器可读尾块或等价结构化信号，供验证使用。

#### Scenario: Endgate packet prefers structured transcript carriers
- **WHEN** 某个 workflow 边界已经拥有原生结构化 endgate transcript 字段
- **THEN** validator MUST 优先读取该结构化 carrier
- **AND** MUST NOT 因为用户可见终端中缺少 `ENDGATE_*` 行而判定失败

#### Scenario: Endgate packet remains parseable across transcript transports
- **WHEN** 某个 workflow 边界尚未拥有原生结构化 endgate transcript 字段
- **THEN** 该边界 SHALL 通过固定字段的 `endgate-state-packet` 暴露协议状态
- **AND** validator MUST 能从 tail block 或等价结构化字段解析出
  `ENDGATE_PROTOCOL_VERSION`、`ENDGATE_STATE`、
  `ENDGATE_CHOICE_KIND` 与 `ENDGATE_NEXT_ACTION`

### Requirement: Validation audits runtime prose-endgate leaks from Codex transcripts
自动化验证 MUST 能够直接从 Codex `.jsonl` transcript 或等价结构化事件中审计 runtime endgate
是否合法，而不能只验证文档里是否写有禁止 prose-only 结束的 guidance。

#### Scenario: Packet-driven validation rejects an undeclared or unfulfilled ending
- **WHEN** 验证器读取一个 transcript fixture
- **AND** 同一 turn 中存在 canonical endgate carrier
- **AND** 该 carrier 后续没有得到与其状态匹配的兑现动作
- **THEN** 验证 MUST 失败
- **AND** MUST 报告 carrier declaration 与 observed event sequence 不一致

#### Scenario: Structured carrier passes without visible packet text
- **WHEN** 验证器读取一个 transcript fixture
- **AND** 当前 turn 包含结构化 endgate carrier
- **AND** 用户可见 assistant 文本中不存在可解析的 `ENDGATE_*` tail block
- **AND** 该 carrier 后续存在与其状态匹配的兑现动作
- **THEN** 验证 MUST 通过
- **AND** MUST NOT 因“终端未显示 packet 文本”而失败

#### Scenario: Legacy invitation leak still fails when the carrier is absent
- **WHEN** 验证器读取一个 transcript fixture
- **AND** 当前 turn 尚未发出 canonical endgate carrier
- **AND** 同一 turn 中最后一条 assistant 文本属于具体下一步邀请型 prose
- **AND** 该 turn 随后直接发生 `task_complete`
- **AND** 该 turn 内不存在 `request_user_input` 或可证明的 `auto-continue` 动作
- **THEN** 验证 MUST 失败
- **AND** 该路径 SHALL 作为 legacy prose safety net 被继续拦截

#### Scenario: Strict packet lanes fail when the transcript never emits a canonical carrier
- **WHEN** 验证器读取的 transcript 属于本仓库当前 packetized local workflow lane
- **AND** 当前 turn 既没有结构化 endgate carrier，也没有可解析 tail block
- **THEN** 验证 MUST 失败
- **AND** MUST 优先报告 missing canonical carrier，而不是把缺失 carrier 当成可接受的 prose-only 分支
