## MODIFIED Requirements

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
