# endgate-state-packet Specification

## Purpose
保留 version 1 legacy endgate consumer 与 transcript replay 的兼容契约。

## Applicability

以下要求仅用于显式启用的 legacy integration 或历史 fixture 回放，且运行环境
必须支持 carrier consumer 与可用、被允许的 request_user_input。
普通 workflow 默认不启用 strict packet mode；完成后直接交付。
加载 Skill、读取规范或启用仅隐藏文本的 wrapper 不构成集成授权。
DONE 是普通工作流完成状态，不是 version 1 枚举，不得发给旧消费者。
缺少能力时说明限制并按宿主允许的普通交互降级，不得覆盖更高优先级指令。

## Requirements
### Requirement: Workflow endgate boundaries emit a fixed machine-readable packet
系统 MUST 在任何 workflow 到达 checkpoint、analysis recommendation
boundary、handoff 或 terminal boundary 时，暴露一份固定字段的
`endgate-state-packet`，供 transcript validator 与后续自动化逻辑消费。

#### Scenario: Boundary packet exposes the canonical fields through the preferred carrier
- **WHEN** assistant 到达任一 endgate 边界
- **THEN** 系统 SHALL 暴露以下 canonical 字段：
  `ENDGATE_PROTOCOL_VERSION`、`ENDGATE_STATE`、
  `ENDGATE_CHOICE_KIND`、`ENDGATE_NEXT_ACTION`
- **AND** 若当前运行时支持结构化 transcript 字段，carrier SHALL 使用该结构化字段
- **AND** 仅当该能力不存在时，carrier MAY 回退为固定 tail block

#### Scenario: Tail block remains the compatibility fallback
- **WHEN** 当前运行时尚未提供原生结构化 endgate transcript 字段
- **THEN** 系统 SHALL 继续通过固定 tail block 暴露 canonical 字段
- **AND** validator MUST 仍能按现有字段名解析该 packet

### Requirement: Packet fields use stable enums and valid pairings
`endgate-state-packet` 的字段值 MUST 使用固定枚举，并遵守稳定的字段配对，
避免验证器再次回退到自然语言推断。

#### Scenario: AUTO_CONTINUE uses the fixed pairing
- **WHEN** `ENDGATE_STATE` 为 `AUTO_CONTINUE`
- **THEN** `ENDGATE_CHOICE_KIND` MUST 为 `NONE`
- **AND** `ENDGATE_NEXT_ACTION` MUST 为 `CONTINUE_WITH_TOOL`

#### Scenario: NEEDS_USER_DECISION uses the fixed pairing
- **WHEN** `ENDGATE_STATE` 为 `NEEDS_USER_DECISION`
- **THEN** `ENDGATE_CHOICE_KIND` MUST 为 `SPECIFIC_NEXT_STEP`
- **AND** `ENDGATE_NEXT_ACTION` MUST 为 `REQUEST_USER_INPUT`

#### Scenario: TERMINAL_CHOICE uses the fixed pairing
- **WHEN** `ENDGATE_STATE` 为 `TERMINAL_CHOICE`
- **THEN** `ENDGATE_CHOICE_KIND` MUST 为 `CONTINUE_OR_STOP`
- **AND** `ENDGATE_NEXT_ACTION` MUST 为 `REQUEST_USER_INPUT`

### Requirement: Packet scope is boundary-local and last declaration wins
系统 MUST 将 `endgate-state-packet` 视为 boundary-local declaration；
同一 turn 中如果出现多个 endgate 声明，只有最后一份 packet 对应当前边界，
验证器 MUST 从该 packet 开始计算合法事件窗口。

#### Scenario: Earlier same-turn actions do not satisfy a later packet
- **WHEN** 同一 turn 中较早位置已经发生普通工具调用
- **AND** assistant 在更后面重新声明了新的 `endgate-state-packet`
- **THEN** validator MUST 只使用最后 packet 之后的事件判断该边界是否合法
- **AND** 较早位置的工具调用 MUST NOT 被计作最后 packet 的兑现动作

### Requirement: Declared packet semantics must be fulfillable from transcript events
`endgate-state-packet` 的字段组合 MUST 对应可观察、可验证的 transcript
事件序列，而不是只作为文档性注释存在。

#### Scenario: AUTO_CONTINUE packet requires a real continuation action
- **WHEN** packet 声明 `AUTO_CONTINUE`
- **THEN** 在同一合法事件窗口内 MUST 观察到至少一个非
  `request_user_input` 的 continuation action
- **AND** 在该 continuation action 之前 MUST NOT 直接出现
  仅靠 `task_complete` 的结束

#### Scenario: NEEDS_USER_DECISION packet requires a specific next-step popup
- **WHEN** packet 声明 `NEEDS_USER_DECISION`
- **THEN** 在该 packet 之后的直接边界动作 MUST 是 `request_user_input`
- **AND** 该 popup MUST 表示具体下一步选择，而不是 generic
  continue/stop terminal-choice

#### Scenario: TERMINAL_CHOICE packet requires the terminal-choice popup
- **WHEN** packet 声明 `TERMINAL_CHOICE`
- **THEN** 在该 packet 之后的直接边界动作 MUST 是 `request_user_input`
- **AND** 该 popup 的问题标识 MUST 对应 `terminal_choice`
- **AND** 在该 popup 之前 MUST NOT 以 prose-only closeout 或
  `task_complete` 直接收口
