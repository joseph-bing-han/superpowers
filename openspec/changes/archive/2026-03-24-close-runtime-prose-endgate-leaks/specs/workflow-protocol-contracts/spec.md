## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Analysis and recommendation boundaries use protocolized next-step handling
当 assistant 在当前 turn 中已经完成分析、给出具体推荐方案，并且能够指出明确的下一步时，系统 MUST 将该边界视为正式 workflow 协议边界，并且只能在 `auto-continue` 与 `request_user_input` 两种路径之间选择，不得以 prose-only 的下一步邀请结束当前 turn。

#### Scenario: Concrete next step with remaining user choice uses request_user_input
- **WHEN** assistant 已经完成分析并给出具体推荐方案
- **AND** 下一步需要用户在若干具体选项中做选择
- **THEN** assistant MUST 使用 `request_user_input`
- **AND** MUST NOT 以 `如果你同意，我下一步可以……`、
  `I can do X next if you agree` 或等价 prose 邀请后直接结束当前 turn

#### Scenario: Preauthorized next step auto-continues after analysis
- **WHEN** assistant 已经完成分析并给出具体推荐方案
- **AND** 用户先前已经对该下一步给出足够授权
- **THEN** workflow MUST 进入 `auto-continue`
- **AND** assistant MUST 直接执行已授权的下一步，而不是先输出 prose-only
  的可选邀请

#### Scenario: Prose-only next-step invitation cannot be followed by task completion
- **WHEN** assistant 在 turn 末尾输出具体下一步邀请型 prose
- **THEN** 该 turn MUST NOT 直接进入 `task_complete`
- **AND** 在出现 `task_complete` 之前，系统 MUST 已经执行
  `request_user_input` 或合法的 `auto-continue` 动作
