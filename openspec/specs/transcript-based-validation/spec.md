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

#### Scenario: Endgate packet remains parseable across transcript transports
- **WHEN** 某个 workflow 边界尚未拥有原生结构化 endgate transcript 字段
- **THEN** 该边界 SHALL 通过固定字段的 `endgate-state-packet` 暴露协议状态
- **AND** validator MUST 能从 tail block 或等价结构化字段解析出
  `ENDGATE_PROTOCOL_VERSION`、`ENDGATE_STATE`、
  `ENDGATE_CHOICE_KIND` 与 `ENDGATE_NEXT_ACTION`

### Requirement: Validation audits universal terminal-choice inheritance across local skills
自动化验证 MUST 能够从仓库层面确认所有本地 skill 都显式继承了统一终局协议，
而不是只依赖少数核心 skill 的局部文案。

#### Scenario: A local skill omits explicit terminal endgate guidance
- **WHEN** prompt-contract 测试审计本地 skill 文件集合
- **THEN** 如果任一 skill 缺少显式的终局协议区块、缺少
  `request_user_input` 终局要求，或仍把 tool-backed terminal-choice 写成固定的
  `1. 结束 / 2. 继续 / 3. 自由输入`
- **THEN** 测试 MUST 失败

#### Scenario: Terminal-choice fixture authored payload keeps only explicit end and continue options
- **WHEN** transcript fixture 验证 Codex tool-backed terminal-choice payload
- **THEN** assistant-authored options MUST 只包含 `结束 (Recommended)` 与 `继续`
- **AND** 测试 MUST NOT 把客户端自动追加的 free-form `Other/notes` 路径误判为
  assistant-authored payload 缺失

### Requirement: Validation catches contingent-authorization prose-only endings
自动化验证 MUST 覆盖条件式授权场景，防止系统在正向判断后再次退回
prose-only 的自由文本收口。

#### Scenario: Guidance reintroduces a contingent-authorization free-text ending
- **WHEN** skill 文案或文档重新出现“条件成立后用自由文本结论块结束当前 turn”
  的规则或示例
- **THEN** prompt-contract 验证 MUST 失败，并指出该路径不符合统一终局协议

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

#### Scenario: Guidance allows a created OpenSpec change to finish without archive
- **WHEN** prompt-contract 测试审计 created OpenSpec proposal / change 的终局规则
- **AND** 当前 guidance 涉及“创建 proposal 后的最终完成边界”
- **THEN** 如果文案允许 assistant 在最终完成时跳过
  `openspec-archive-change`
- **OR** 允许以 recommendation-only prose、generic continue/stop、
  或普通 terminal-choice 结束该 change
- **OR** 没有把“创建过 proposal 后未归档”判定为测试失败
- **THEN** 测试 MUST 失败

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

#### Scenario: Strict packet lanes fail when the transcript never emits a packet
- **WHEN** 验证器读取的 transcript 属于本仓库当前 packetized local workflow lane
- **AND** 当前 turn 没有发出 `endgate-state-packet`
- **THEN** 验证 MUST 失败
- **AND** MUST 优先报告 missing packet，而不是把缺失 packet 当成可接受的
  prose-only 分支

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
