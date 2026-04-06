## ADDED Requirements

### Requirement: Validation audits explicit workflow-trigger boundaries
自动化验证 MUST 同时覆盖“该触发时能触发”与“该压住时必须压住”的 workflow
入口边界，而不能只验证正向触发样本。

#### Scenario: Plain question fixture does not trigger workflow
- **WHEN** 验证器读取一个普通问答 transcript 或 triggering fixture
- **AND** 其中不存在显式 skill 名或 workflow 关键词
- **THEN** 测试 MUST 证明 workflow 没有被拉起
- **AND** MUST 将“未触发任何 workflow skill”视为通过条件的一部分

#### Scenario: Workflow keyword fixture still triggers workflow
- **WHEN** 验证器读取一个包含允许的 workflow 关键词的 transcript 或 triggering fixture
- **THEN** 测试 MUST 证明对应 workflow 仍可被触发
- **AND** MUST 防止本次治理把显式 workflow 意图一并误杀

### Requirement: Validation audits lightweight-task bypass and TDD suppression
自动化验证 MUST 覆盖轻量任务 bypass、text-only 改动的 TDD 抑制、以及
“普通问答不得先弹终局 popup”这三类负向路径。

#### Scenario: Copy-only change fixture does not trigger TDD
- **WHEN** 验证器读取一个仅修改 UI 文案或其他 text-only 内容的 fixture
- **THEN** 测试 MUST 证明 `test-driven-development` 没有被调用
- **AND** MUST 将其视为合法 bypass，而不是漏掉 workflow

#### Scenario: Direct answer fixture returns result without terminal popup
- **WHEN** 验证器读取一个普通问答 transcript fixture
- **THEN** 测试 MUST 证明结果先被直接输出
- **AND** MUST NOT 接受“先出现 `request_user_input` popup，再由用户选择结束后才看到结果”的路径

#### Scenario: Downgraded lightweight subtask fixture bypasses workflow popup
- **WHEN** 验证器读取一个 workflow 中临时处理轻量子任务的 transcript fixture
- **THEN** 测试 MUST 证明该子任务未触发 TDD
- **AND** MUST 证明该子任务未被 workflow terminal-choice popup 拦截
