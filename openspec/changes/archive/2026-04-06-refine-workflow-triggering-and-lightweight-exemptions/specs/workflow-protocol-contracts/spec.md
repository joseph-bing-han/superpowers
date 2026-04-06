## ADDED Requirements

### Requirement: Terminal-choice applies only to workflow-mode boundaries
系统 MUST 仅在当前边界仍属于 workflow mode 时使用 `terminal-choice`、`request_user_input` 终局 popup 与 strict packet mode 的 workflow 收口规则；Direct Mode 回复或被临时降级处理的轻量子任务 MUST 直接输出结果，不得先被终局 popup 拦截。

#### Scenario: Direct-mode answer completes without terminal-choice
- **WHEN** 当前请求属于普通问答、翻译、总结、润色或其他轻量任务
- **AND** 当前边界不属于 workflow mode
- **THEN** 系统 MUST 直接输出结果
- **AND** MUST NOT 在结果前插入 `terminal-choice` 或 `request_user_input` popup

#### Scenario: Workflow completion still uses terminal-choice
- **WHEN** 当前工作已经处于 workflow mode
- **AND** 当前边界是真正的 workflow terminal boundary
- **THEN** 系统 MUST 继续使用既有的 `terminal-choice` / `request_user_input` 协议
- **AND** MUST NOT 因本次变更而削弱 workflow lane 的 strict packet mode

#### Scenario: Downgraded lightweight subtask does not inherit workflow popup
- **WHEN** 当前会话整体仍在 workflow mode
- **AND** 当前子任务已被分类为 direct-handled 轻量任务
- **THEN** 该子任务的回复 MUST 先直接给出结果
- **AND** MUST NOT 复用 workflow terminal-choice 作为该子任务的结束方式
