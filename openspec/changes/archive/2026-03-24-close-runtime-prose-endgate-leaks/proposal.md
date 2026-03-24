## Why

当前仓库已经通过三轮治理修复，分别补强了 `prose` 与协议解耦、统一
`terminal-choice` 终局协议，以及 OpenSpec lane 的 governed bugfix /
apply / archive auto-continuation。但 `2026-03-24` 的真实 Codex transcript
再次暴露出一个尚未被正式治理的缺口：assistant 在完成分析并给出具体
推荐方案后，仍可能用
`如果你同意，我下一步可以直接按这个推荐方案 A 开始修。`
这类 prose-only 下一步邀请收尾，并紧接着 `task_complete`，中间既没有
`request_user_input`，也没有已授权的 auto-continue 动作。

这说明现有修复主要覆盖了规则层、文档层和静态 prompt-contract 层，但还
没有把“真实 transcript 最后一跳的 endgate 行为”纳入正式协议与自动审计。
同时，当前终局 `request_user_input` 设计还存在一个 Codex UI 对齐错误：
skill guidance 和 fixture 仍把 `3. 自由输入` 当作 assistant 需要显式提供的
固定选项，但 Codex 客户端本身已经会自动追加 free-form `Other/notes` 路径。
结果是 popup 里出现重复的自由输入入口，既增加理解负担，也让“选择自由输入”
的交互变得更慢。

现在需要把这类 runtime prose leak 定义为明确违约，并同步把 terminal-choice
协议调整为与 Codex 客户端的自动 free-form fallback 对齐，避免同类漏洞和
重复交互继续穿透到真实项目对话中。

## What Changes

- 正式定义“analysis / recommendation boundary”协议：当 assistant 已经给出
  具体推荐方案、已知下一步，并准备结束当前 turn 时，必须在
  `auto-continue` 与 `request_user_input` 之间做出协议化分流，不得再以
  prose-only 邀请结束。
- 明确将
  `prose-only next-step invitation + task_complete`
  视为 runtime workflow 违约，而不是单纯文案不理想。
- 为 Codex transcript 新增 endgate 审计能力，能够从 `.jsonl` 会话记录中
  识别这类违规结束路径。
- 把 `2026-03-24` 这次真实 incident 沉淀为负向回归 fixture，并补一个
  对应的正向 fixture，锁定修复后的合法事件序列。
- 调整 tool-backed `terminal-choice` 协议：assistant 仅显式提供
  `结束 / 继续` 两个选项，自由输入路径改为使用 Codex 客户端自动追加的
  `Other/notes` 入口，而不是重复声明 `3. 自由输入`。
- 同步更新相关 skill guidance、README 与测试文档，使“规则存在性”与
  “runtime 行为合法性”形成闭环。

## Capabilities

### New Capabilities

- 无

### Modified Capabilities

- `workflow-protocol-contracts`: 增加 analysis / recommendation boundary 的
  正式 requirement，并修正 terminal-choice 的 Codex tool-backed 选项约定；
  明确“具体下一步邀请”必须进入 `auto-continue` 或 `request_user_input`，
  不得 prose-only 结束。
- `transcript-based-validation`: 增加对 Codex transcript runtime endgate
  审计、incident fixture 回归、tool-backed terminal-choice authored options
  约束，以及 `prose-only next-step invitation + task_complete`
  负向检测的 requirement。

## Impact

- Affected code:
  - `skills/using-superpowers/SKILL.md`
  - `skills/systematic-debugging/SKILL.md`
  - `skills/brainstorming/SKILL.md`
  - `docs/README.codex.md`
  - `docs/testing.md`
  - `tests/prompt-contracts/*.sh`
  - `tests/codex/*.sh`
  - `tests/codex/fixtures/*.jsonl`
- Affected specs:
  - `openspec/specs/workflow-protocol-contracts/spec.md`
  - `openspec/specs/transcript-based-validation/spec.md`
- Affected systems:
  - Codex workflow endgate governance
  - Codex session transcript auditing
  - prompt-contract + transcript-fixture regression validation
