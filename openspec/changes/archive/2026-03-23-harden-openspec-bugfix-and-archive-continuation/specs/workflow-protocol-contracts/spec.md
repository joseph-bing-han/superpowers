## ADDED Requirements

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
