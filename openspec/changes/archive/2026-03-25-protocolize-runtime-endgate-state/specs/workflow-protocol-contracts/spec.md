## MODIFIED Requirements

### Requirement: Key workflow checkpoints expose machine-readable state
关键 workflow 节点 MUST 暴露稳定的机器可判定状态信号，使自动化流程能够在不依赖自然语言措辞的前提下判断当前状态。

#### Scenario: Checkpoint state is available for automation
- **WHEN** 任一关键 workflow 到达 checkpoint、handoff、review verdict、
  analysis recommendation boundary 或 terminal-choice 边界
- **THEN** 系统 SHALL 产生可解析的状态信号
- **AND** 对 endgate 类边界，canonical 状态信号 MUST 为固定字段的
  `endgate-state-packet`

### Requirement: Analysis and recommendation boundaries use protocolized next-step handling
当 assistant 在当前 turn 中已经完成分析、给出具体推荐方案，并且能够指出明确的下一步时，系统 MUST 将该边界视为正式 workflow 协议边界，并且只能在 `auto-continue` 与 `request_user_input` 两种路径之间选择，不得以 prose-only 的下一步邀请结束当前 turn。

#### Scenario: Concrete next step with remaining user choice uses a declared needs-user-decision packet
- **WHEN** assistant 已经完成分析并给出具体推荐方案
- **AND** 下一步需要用户在若干具体选项中做选择
- **THEN** assistant MUST 先声明 `ENDGATE_STATE=NEEDS_USER_DECISION`
  的 `endgate-state-packet`
- **AND** 随后 MUST 使用 `request_user_input`
- **AND** MUST NOT 以 `如果你同意，我下一步可以……`、
  `如果你下一步是要……我可以继续接着做`、`I can do X next if you agree`
  或等价 prose 邀请后直接结束当前 turn

#### Scenario: Preauthorized next step auto-continues after a declared packet
- **WHEN** assistant 已经完成分析并给出具体推荐方案
- **AND** 用户先前已经对该下一步给出足够授权
- **THEN** assistant MUST 先声明 `ENDGATE_STATE=AUTO_CONTINUE`
  的 `endgate-state-packet`
- **AND** workflow MUST 进入 `auto-continue`
- **AND** assistant MUST 直接执行已授权的下一步，而不是先输出 prose-only
  的可选邀请

#### Scenario: True completion declares terminal-choice instead of prose closeout
- **WHEN** assistant 判断当前请求已经到达真正完成边界
- **THEN** assistant MUST 先声明 `ENDGATE_STATE=TERMINAL_CHOICE`
  的 `endgate-state-packet`
- **AND** 直接下一个边界动作 MUST 是 `request_user_input`
- **AND** MUST NOT 用 prose-only closeout 替代 terminal-choice popup

## ADDED Requirements

### Requirement: Endgate declarations are boundary-scoped rather than turn-scoped
workflow endgate 的合法性 MUST 由最后一次边界声明及其后的兑现动作决定，
而不是由同一 turn 任意更早位置发生过什么工具调用来决定。

#### Scenario: Earlier tool work cannot legalize a later prose-only ending
- **WHEN** 同一 turn 较早位置已经发生过 `exec_command`、`apply_patch`
  或其他普通 continuation action
- **AND** assistant 在更后面进入新的 analysis / recommendation boundary
- **THEN** 只有该边界最后声明的 `endgate-state-packet` 之后的事件才可以作为
  合法性证据
- **AND** 较早位置的普通工具调用 MUST NOT 被复用为后续边界的
  `auto-continue` 证明
