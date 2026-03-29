## ADDED Requirements

### Requirement: Validation MUST keep an incident-shaped transcript fixture for imported-skill endgate drift
自动化验证 MUST 保留至少一条贴近真实事故的 session-shaped transcript fixture，用来锁定“assistant 读取 imported explore guidance 后，仍以 prose-only recommendation + `task_complete` 结束”的漂移路径，而不能只依赖抽象化 prose leak 样本。

#### Scenario: Session-shaped imported-skill incident fixture fails runtime endgate audit
- **WHEN** validator 读取一个 session-shaped transcript fixture
- **AND** 该 fixture 中先出现 strict packet mode 证据与 imported explore guidance
- **AND** 后续 assistant 以 report-style recommendation 收尾
- **AND** 该 turn 直接发生 `task_complete`
- **AND** 该 turn 中不存在 canonical carrier、`request_user_input` 或合法 auto-continue action
- **THEN** runtime endgate audit MUST 失败
- **AND** MUST 将其归类为 imported-skill / prose-only endgate drift 的负样本

### Requirement: Validation MUST audit repo-managed override guidance for imported ending stances
prompt-contract 验证 MUST 确认本仓库自己管理的 bootstrap、核心 workflow entry skill 与主要使用文档，已经显式声明 imported / lower-priority skill ending guidance 不能削弱 strict packet mode。

#### Scenario: Repo-managed bootstrap omits the imported-skill override
- **WHEN** prompt-contract 测试审计 `.codex/instruction.md`、`skills/using-superpowers/SKILL.md` 或相关 Codex 使用文档
- **AND** 这些文件没有明确写出 imported / lower-priority ending guidance override
- **OR** 没有覆盖 `no required ending`、`just provide clarity`、`continue later` 这类 imported stance 示例
- **THEN** 测试 MUST 失败

