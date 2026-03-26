## ADDED Requirements

### Requirement: OpenSpec lane decision MUST precede ordinary design and plan docs for important changes
系统 MUST 在工作看起来应进入 OpenSpec lane，且当前既没有明确的 existing change、
也没有用户明确选择 ordinary-docs fallback 时，先完成 lane decision，再允许创建普通设计文档或计划文档。

#### Scenario: Important change asks about OpenSpec before ordinary design docs
- **WHEN** assistant 处理一个新功能、跨模块、多阶段或其他疑似应进入 OpenSpec lane 的工作
- **AND** 当前还没有明确 existing change
- **AND** 用户还没有明确选择继续仅生成常规设计/计划文档
- **THEN** assistant MUST 先通过 `request_user_input` 发起 lane confirmation
- **AND** MUST NOT 先创建普通设计文档

#### Scenario: Important change asks about OpenSpec before ordinary plan docs
- **WHEN** assistant 即将为一个疑似应进入 OpenSpec lane 的工作创建普通计划文档
- **AND** 当前还没有明确 existing change
- **AND** 用户还没有明确选择继续仅生成常规设计/计划文档
- **THEN** assistant MUST 先完成 lane confirmation
- **AND** MUST NOT 先创建普通计划文档

#### Scenario: Explicit ordinary-docs fallback unlocks regular docs
- **WHEN** assistant 已通过 tool-backed lane confirmation 提供
  `创建 OpenSpec 提案` 与 `继续仅生成常规设计/计划文档` 选项
- **AND** 用户明确选择继续仅生成常规设计/计划文档
- **THEN** assistant MAY 进入 Superpowers-only lane
- **AND** 之后才允许创建普通设计文档或计划文档

### Requirement: Downstream design and planning skills MUST block unresolved OpenSpec lane drift
系统 MUST 在入口治理判断漏触发、且 `brainstorming` 或 `writing-plans` 发现当前工作仍处于 unresolved OpenSpec lane 时，阻断普通 docs 产出并回到 lane confirmation，而不是默认沿 ordinary-docs 路径继续。

#### Scenario: Brainstorming blocks ordinary design docs when lane is unresolved
- **WHEN** `brainstorming` 发现当前工作疑似应进入 OpenSpec lane
- **AND** 当前还没有明确 existing change
- **AND** 用户还没有明确选择 ordinary-docs fallback
- **THEN** `brainstorming` MUST 阻止普通设计文档落地
- **AND** MUST 先触发 lane confirmation

#### Scenario: Writing plans blocks ordinary plan docs when lane is unresolved
- **WHEN** `writing-plans` 发现当前工作疑似应进入 OpenSpec lane
- **AND** 当前还没有明确 existing change
- **AND** 用户还没有明确选择 ordinary-docs fallback
- **THEN** `writing-plans` MUST 阻止普通计划文档落地
- **AND** MUST 先触发 lane confirmation

#### Scenario: Existing change bypasses ordinary-docs fallback and stays governed
- **WHEN** 当前工作已经存在明确的 active 或 existing OpenSpec change
- **THEN** assistant MUST 继续沿 OpenSpec lane 工作
- **AND** MUST NOT 把缺少用户再次确认当作创建普通设计文档或计划文档的理由
