## ADDED Requirements

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
