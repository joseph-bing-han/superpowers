## MODIFIED Requirements

### Requirement: Validation audits universal terminal-choice inheritance across local skills
自动化验证 MUST 能够从仓库层面确认所有本地 skill 都显式继承了统一终局协议，
而不是只依赖少数核心 skill 的局部文案。

#### Scenario: A local skill omits explicit terminal endgate guidance
- **WHEN** prompt-contract 测试审计本地 skill 文件集合
- **THEN** 如果任一 skill 缺少显式的终局协议区块、缺少
  `request_user_input` 终局要求，或仍把 tool-backed terminal-choice 写成固定的
  `1. 结束 / 2. 继续 / 3. 自由输入`
- **THEN** 测试 MUST 失败

#### Scenario: Terminal-choice fixture authored payload keeps only explicit end and continue options
- **WHEN** transcript fixture 验证 Codex tool-backed terminal-choice payload
- **THEN** assistant-authored options MUST 只包含 `结束 (Recommended)` 与 `继续`
- **AND** 测试 MUST NOT 把客户端自动追加的 free-form `Other/notes` 路径误判为
  assistant-authored payload 缺失

## ADDED Requirements

### Requirement: Validation audits runtime prose-endgate leaks from Codex transcripts
自动化验证 MUST 能够直接从 Codex `.jsonl` transcript 中审计 runtime endgate
是否合法，而不能只验证文档里是否写有禁止 prose-only 结束的 guidance。

#### Scenario: Incident fixture with prose-only invitation before task_complete fails validation
- **WHEN** 验证器读取一个 transcript fixture
- **AND** 同一 turn 中最后一条 assistant 文本属于具体下一步邀请型 prose
- **AND** 该 turn 随后直接发生 `task_complete`
- **AND** 该 turn 内不存在 `request_user_input` 或可证明的 `auto-continue` 动作
- **THEN** 验证 MUST 失败
- **AND** MUST 报告该 turn 存在 runtime prose-endgate leak

#### Scenario: Corrected fixture with request_user_input passes validation
- **WHEN** 验证器读取一个修复后的 transcript fixture
- **AND** assistant 在分析完成后通过 `request_user_input` 进入下一步分流
- **THEN** 验证 MUST 通过
- **AND** MUST 认定该 turn 的 endgate 协议合法

#### Scenario: Corrected fixture with authorized auto-continue passes validation
- **WHEN** 验证器读取一个修复后的 transcript fixture
- **AND** assistant 在分析完成后直接执行已授权的下一步
- **AND** 该 turn 没有出现 prose-only 的可选邀请收尾
- **THEN** 验证 MUST 通过
- **AND** MUST 认定该 turn 属于合法 `auto-continue`
