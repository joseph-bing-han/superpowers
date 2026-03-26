## ADDED Requirements

### Requirement: Validation MUST audit OpenSpec lane-entry ordering from transcripts
自动化验证 MUST 能从 transcript fixture 中识别 OpenSpec lane decision、
ordinary design/plan docs 创建，以及 OpenSpec change 创建等关键顺序证据，
并把“先写普通 docs，后做 lane confirmation”判定为失败。

#### Scenario: Negative fixture fails when ordinary docs precede lane confirmation
- **WHEN** 验证器读取一个 session-shaped transcript fixture
- **AND** 该 fixture 中普通设计文档或普通计划文档的创建事件早于
  OpenSpec lane confirmation
- **THEN** 验证 MUST 失败
- **AND** MUST 报告 ordinary docs 在 lane decision 之前落地

#### Scenario: Positive fixture passes when lane confirmation happens first
- **WHEN** 验证器读取一个 session-shaped transcript fixture
- **AND** 该 fixture 中 assistant 先完成 OpenSpec lane confirmation
- **AND** 之后才创建普通 docs fallback 或 OpenSpec change
- **THEN** 验证 MUST 通过
- **AND** MUST 将 lane decision 顺序视为合法

### Requirement: Validation MUST audit unresolved lane guards across downstream skills
自动化验证 MUST 覆盖 `brainstorming` 与 `writing-plans` 的 unresolved lane guard，
防止仓库再次退回到“只有入口 skill 知道要问 OpenSpec，下游 skill 仍会先写 docs”
的状态。

#### Scenario: Prompt-contract fails if brainstorming omits unresolved lane guard
- **WHEN** prompt-contract 测试审计 `skills/brainstorming/SKILL.md`
- **AND** 文案未明确要求在 unresolved OpenSpec lane 时阻断普通设计文档
- **THEN** 测试 MUST 失败

#### Scenario: Prompt-contract fails if writing plans omits unresolved lane guard
- **WHEN** prompt-contract 测试审计 `skills/writing-plans/SKILL.md`
- **AND** 文案未明确要求在 unresolved OpenSpec lane 时阻断普通计划文档
- **THEN** 测试 MUST 失败

#### Scenario: Prompt-contract keeps the entry guard and downstream guards aligned
- **WHEN** prompt-contract 测试同时审计 `using-superpowers`、`brainstorming`
  与 `writing-plans`
- **THEN** 测试 MUST 确认三者都表达出相同的核心约束：
  重要变更在 lane decision 完成前不得先写普通 docs
