## ADDED Requirements

### Requirement: Workflow entry requires explicit user intent
系统 MUST 仅在用户显式点名 skill，或命中允许的 workflow 关键词时进入
Superpowers workflow；不得仅凭模糊语义猜测自动拉起 workflow。

#### Scenario: Plain question stays in direct mode
- **WHEN** 用户只是提出普通问题、请求解释、请求翻译、请求总结或请求文本润色
- **AND** 消息中没有显式 skill 名，也没有 workflow 关键词
- **THEN** 系统 MUST 保持在 Direct Mode
- **AND** MUST NOT 拉起 Superpowers workflow

#### Scenario: Workflow keyword can explicitly enter workflow mode
- **WHEN** 用户使用设计、规划、调试、代码审查、执行计划等 workflow 关键词
- **THEN** 系统 MAY 进入对应的 workflow mode
- **AND** 后续 skill 选择 MUST 仍受轻量任务豁免规则约束

### Requirement: Lightweight tasks bypass workflow skills
系统 MUST 将简单问答、翻译、总结/改写、文本修改、UI copy-only、注释修改、
文档修改视为轻量任务，并直接处理，而不是默认套用 workflow skills。

#### Scenario: Translation request bypasses workflow
- **WHEN** 用户请求翻译一段文字
- **THEN** 系统 MUST 直接给出翻译结果
- **AND** MUST NOT 进入 brainstorming、writing-plans 或其他 workflow skill

#### Scenario: Text-only UI copy change bypasses heavyweight workflow
- **WHEN** 当前修改仅替换 UI 文案、label、placeholder、help text 或 message
- **AND** 不改变状态流、条件判断、交互流程、数据契约、渲染逻辑或布局结构
- **THEN** 系统 MUST 将其视为轻量任务
- **AND** MUST NOT 因“看起来像开发任务”而自动拉起整套 workflow

### Requirement: Workflow mode can downgrade lightweight subtasks
当当前会话已经进入 workflow mode，但当前子任务被识别为轻量任务时，系统 MUST
临时降级为 direct handling，并跳过不必要的 workflow skills。

#### Scenario: Workflow session handles a translation subtask directly
- **WHEN** 当前会话已经处于 workflow mode
- **AND** 用户临时请求翻译、润色或解释一段文本
- **THEN** 系统 MUST 直接处理该子任务
- **AND** MUST NOT 为该子任务补跑 brainstorming 或 planning

#### Scenario: Workflow session handles copy-only edit directly
- **WHEN** 当前会话已经处于 workflow mode
- **AND** 当前子任务被判定为 text-only / copy-only 修改
- **THEN** 系统 MUST 临时按 Direct Mode 处理该子任务
- **AND** 当前子任务完成后 MAY 回到原 workflow 上下文继续后续重任务

### Requirement: TDD is suppressed for non-behavioral text changes
系统 MUST NOT 对不改变行为、状态流、条件判断、数据契约、交互流程、渲染逻辑或布局结构、仅修改文本内容的任务调用 TDD。

#### Scenario: Copy-only change skips TDD
- **WHEN** 当前任务仅修改 UI 文案、翻译文本、日志文本、注释或文档
- **THEN** 系统 MUST NOT 调用 `test-driven-development`
- **AND** MUST 直接执行该文本修改

#### Scenario: Mixed text and behavior change remains eligible for TDD
- **WHEN** 当前任务既修改文本，又修改行为、逻辑、交互流程或数据契约
- **THEN** 系统 MUST 将其视为行为变更
- **AND** MUST NOT 因包含文本修改而自动豁免 TDD
