# workflow-protocol-contracts Specification

## Purpose
TBD - created by archiving change decouple-prose-from-workflow-protocols. Update Purpose after archive.
## Requirements
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
- **THEN** 直接下一个动作 MUST 是 `request_user_input`，
  且选项 MUST 为 `1. 结束`、`2. 继续`、`3. 自由输入`

#### Scenario: Prose cannot replace the terminal-choice popup
- **WHEN** 终局边界已经达到
- **THEN** 系统 MUST NOT 用自由文本总结、optional follow-up、
  typed free-form confirmation 或 `task_complete` 直接替代
  `terminal-choice` 弹窗

### Requirement: Local skill guidance explicitly inherits the terminal endgate protocol
仓库内每个本地 skill 文档 MUST 显式声明统一终局协议，以便仓库级审计
能够直接检测是否存在“允许直接结束对话”的漂移。

#### Scenario: Repository audit checks a local skill file
- **WHEN** prompt-contract 套件审计任一本地 skill 文档
- **THEN** 该 skill 文档 SHALL 包含与统一终局协议兼容的显式 guidance，
  其内容至少覆盖：
  不得直接结束对话、终局使用 `request_user_input`、以及固定的
  `1/2/3` 终局选择

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
