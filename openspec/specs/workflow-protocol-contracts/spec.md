# workflow-protocol-contracts Specification

## Purpose
TBD - created by archiving change decouple-prose-from-workflow-protocols. Update Purpose after archive.
## Requirements
### Requirement: Key workflow checkpoints expose machine-readable state
关键 workflow 节点 MUST 暴露稳定的机器可判定状态信号，使自动化流程能够在不依赖自然语言措辞的前提下判断当前状态。

#### Scenario: Checkpoint state is available for automation
- **WHEN** 任一关键 workflow 到达 checkpoint、handoff、review verdict、
  analysis recommendation boundary 或 terminal-choice 边界
- **THEN** 系统 SHALL 产生可解析的状态信号
- **AND** 对 endgate 类边界，canonical 状态信号 MUST 为固定字段的
  `endgate-state-packet`

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

### Requirement: Contingent authorization counts as prior authorization
当用户通过条件式表达授权后续动作时，系统 MUST 将正向判断视为条件已满足，
并直接进入已经获得授权的下一步，而不是把该判断当成一个可以 prose-only
收口的分析结论。

#### Scenario: Positive contingent judgment auto-continues
- **WHEN** 用户表达 `如果没问题就继续下一阶段`、
  `如果设计合理就开始实现` 或等价的条件式授权
- **THEN** 一旦系统判断条件成立，后续状态 MUST 进入 `auto-continue`
  或已经授权的下游动作，而不是等待用户再次确认

#### Scenario: Contingent judgment cannot end with prose-only conclusion
- **WHEN** 系统刚完成一个条件式正向判断
- **THEN** 系统 MUST NOT 只输出 `最终判断`、
  `现在可以把结论更新为`、`项目现在可以稳妥进入 ...` 或等价的
  prose-only 结论块后直接结束当前 turn

### Requirement: Terminal completion uses tool-backed terminal-choice across all local skills
任何本地 skill 在“请求工作已完成”的终局边界 MUST 使用统一的
`terminal-choice` 协议收口，而不是直接结束对话或要求用户额外输入自由文本。

#### Scenario: Any skill reaches a terminal boundary
- **WHEN** 任一本地 skill 或 skill-guided workflow 到达
  “当前请求看似已完成”的终局边界
- **THEN** 直接下一个动作 MUST 是 `request_user_input`
- **AND** 在 Codex tool-backed popup 中，assistant-authored 选项 MUST 为
  `结束 (Recommended)` 与 `继续`
- **AND** 当客户端自动提供 free-form `Other/notes` 路径时，workflow MUST
  使用该客户端路径作为自由输入 fallback，而不是重复追加显式 `自由输入`
  选项

#### Scenario: Prose cannot replace the terminal-choice popup
- **WHEN** 终局边界已经达到
- **THEN** 系统 MUST NOT 用自由文本总结、optional follow-up、
  typed free-form confirmation 或 `task_complete` 直接替代
  `terminal-choice` 弹窗

#### Scenario: Client-provided free-form fallback is not duplicated
- **WHEN** `request_user_input` 客户端会自动追加 free-form `Other/notes`
  路径
- **THEN** assistant MUST NOT 在同一个 popup 中再次 authored 一个重复的
  `自由输入` 选项
- **AND** 相关 guidance、fixtures 与 tests MUST 以客户端自动提供的 free-form
  fallback 作为 canonical 路径

### Requirement: Local skill guidance explicitly inherits the terminal endgate protocol
仓库内每个本地 skill 文档 MUST 显式声明统一终局协议，以便仓库级审计
能够直接检测是否存在“允许直接结束对话”的漂移。

#### Scenario: Repository audit checks a local skill file
- **WHEN** prompt-contract 套件审计任一本地 skill 文档
- **THEN** 该 skill 文档 SHALL 包含与统一终局协议兼容的显式 guidance
- **AND** 其内容至少覆盖：
  不得直接结束对话、终局使用 `request_user_input`、以及在 tool-backed
  terminal-choice 中只显式 authored `结束 / 继续`，自由输入改用客户端
  自动提供的 fallback

### Requirement: Governed bugfixes recover existing OpenSpec context before proposing fixes
当一个 bug 或异常行为属于既有 OpenSpec change 的范围时，系统 MUST 在提出
修复方案前恢复该 change 的正式上下文，而不能只基于当前 symptom 做局部修补。

#### Scenario: Bugfix belongs to an existing OpenSpec change
- **WHEN** 当前 bug、失败测试或异常行为明显属于既有 OpenSpec-governed work
- **THEN** 系统 MUST 先识别对应的 active change
- **AND** MUST 读取该 change 的 `proposal.md`、`design.md`、`specs/*`、`tasks.md`
- **AND** 仅在恢复上述上下文后，才继续根因分析与修复设计

#### Scenario: Local symptom fix cannot skip governed design context
- **WHEN** assistant 正在分析一个 governed bug
- **THEN** assistant MUST NOT 直接跳到局部修复建议
- **AND** MUST 把既有 OpenSpec artifacts 视为当前 bugfix 的设计约束与全局目标

### Requirement: Known OpenSpec lane continuations auto-continue into apply or archive
当当前 workflow 已经知道下一条 OpenSpec lane 时，系统 MUST 将其视为
`auto-continue`，而不是退化成泛化的继续/结束选择或 recommendation-only
收口。

#### Scenario: Active change still has remaining work
- **WHEN** 当前工作已明确属于某个 active OpenSpec change
- **AND** 该 change 仍有待完成任务或待继续实现的工作
- **THEN** 系统 MUST 把下一步视为 `openspec-apply-change`
- **AND** MUST auto-continue 到该 skill，而不是先询问泛化的继续/结束

#### Scenario: Active change is complete and archive-compatible
- **WHEN** 当前工作已明确属于某个 active OpenSpec change
- **AND** 当前 branch / workflow 结果已经满足 archive compatibility
- **THEN** 系统 MUST 把下一步视为 `openspec-archive-change`
- **AND** MUST auto-continue 到该 skill，而不是只输出 “ready to archive”
  或 recommendation-only handoff

### Requirement: Created OpenSpec changes carry a mandatory archive obligation
只要 assistant 已经为某项工作创建了 OpenSpec proposal / change，该工作就 MUST
保持在受治理的 OpenSpec lane 中，直到该 change 通过
`openspec-archive-change` 完成归档；最终完成时不得跳过这一归档步骤。

#### Scenario: Proposal creation establishes archive obligation
- **WHEN** assistant 已经为当前工作创建了 OpenSpec proposal / change
- **THEN** 该工作 MUST 被视为带有 archive obligation 的 OpenSpec lane 工作
- **AND** 在 archive 完成前，系统 MUST NOT 把它降级回可自由结束的普通流程

#### Scenario: Final completion of a created change cannot skip archive
- **WHEN** 当前工作对应的 OpenSpec change 已完成实现、验证与最终收尾
- **AND** 该 change 先前已经被创建
- **THEN** workflow MUST 继续进入 `openspec-archive-change`
- **AND** MUST NOT 用 recommendation-only prose、generic continue/stop
  选择、或普通 terminal-choice 直接结束

#### Scenario: Archive skill remains the place for archive safety checks
- **WHEN** created OpenSpec change 已到达最终完成边界
- **THEN** workflow MUST 进入 `openspec-archive-change`
- **AND** incomplete tasks、delta spec sync、以及最终确认等安全检查
  仍由 `openspec-archive-change` 自身负责

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

### Requirement: Repository-managed workflow boundaries run in strict packet mode
对于本仓库维护的本地 workflow skills，任何 workflow boundary MUST 把
`endgate-state-packet` 视为默认且强制的协议载体，而不是可选 guidance。

#### Scenario: Local workflow boundary cannot skip packet emission
- **WHEN** 任一本仓库维护的本地 workflow skill 到达 checkpoint、handoff、
  analysis recommendation boundary、reviewed-task boundary 或 terminal boundary
- **THEN** assistant MUST 在下一个机器动作之前发出 canonical
  `endgate-state-packet`
- **AND** MUST NOT 退回到“如果使用 packet 就……”这类条件式 guidance

#### Scenario: Prose fallback is legacy-only once the local lane is packetized
- **WHEN** 当前路径属于本仓库维护的本地 workflow skills
- **THEN** prose fallback MUST 只作为 legacy fixture 或历史 incident 的
  残余安全网存在
- **AND** MUST NOT 被当成本地 canonical lane 的正常替代分支

### Requirement: Subagent workflow guidance exposes explicit routing semantics
涉及子代理执行的 workflow guidance MUST 显式说明执行模式、路由优先级、
状态语义与冲突边界，而不是只保留“逐任务派发子代理”的模糊叙述。

#### Scenario: Same-session workflow documents execution modes
- **WHEN** 仓库中的 workflow guidance 描述 same-session 子代理执行
- **THEN** 文档 MUST 区分 `Serial SDD`、`Pipeline SDD` 与 `Parallel Dispatch`
- **AND** MUST 说明默认 same-session 模式是哪一个

#### Scenario: Routing guidance is conflict-aware
- **WHEN** 文档声明何时允许并发、何时需要串行
- **THEN** guidance MUST 显式引用 `Conflict Group` 与 `Write Set`
  等冲突边界
- **AND** MUST NOT 用“有子代理 = 自动最大并发”的模糊表述替代正式路由规则

### Requirement: Pipeline workflow guidance defines stable state and overlap contracts
当 workflow guidance 引入 `Pipeline SDD` 时，系统 MUST 用稳定术语描述状态机与
overlap 契约，使实现者与验证器能基于同一协议理解流程。

#### Scenario: Pipeline guidance exposes state machine terms
- **WHEN** 文档描述 `Pipeline SDD`
- **THEN** MUST 包含 `queued`、`preflight`、`ready`、`blocked`
  等状态语义

#### Scenario: Pipeline guidance defines both overlap contracts
- **WHEN** 文档声称 `Pipeline SDD` 能减少主线程空等
- **THEN** MUST 同时定义 `implementer + preflight`
  与 `reviewer + preflight`
- **AND** MUST 明确这些 overlap 不等于放开同冲突域并发写入

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
