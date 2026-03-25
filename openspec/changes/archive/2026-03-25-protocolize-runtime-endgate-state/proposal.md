## Why

当前仓库对 endgate 漏口的治理，虽然已经从纯 prompt wording 进化到 transcript 审计，但主约束仍然过度依赖 assistant 的 prose 语义与少量示例句式。真实回归已经证明，这种做法很容易被新的措辞变体绕过，或者被 turn 内更早的普通工具调用误判为合法 `auto-continue` 证据。

现在需要把 endgate 约束从“最后一句话像不像邀请”升级为“workflow 边界显式声明了什么协议状态，以及后续事件序列是否兑现了该状态”。只有这样，仓库才能用通用协议与机器校验稳定收住这类问题，而不是持续追加新的句式正则。

## What Changes

- 为 workflow 边界引入显式、固定枚举的 endgate 状态协议，用于声明当前 turn 的收口路径。
- 定义基于协议状态的事件序列校验规则，使 `task_complete` 只能出现在合法闭环之后。
- 将 runtime transcript 审计从“prose 邀请句式识别”为主，升级为“协议状态 + 尾部事件顺序验证”为主。
- 保留 prose 模式识别作为残余安全网，但不再作为主要合规依据。
- 明确 skill、README、testing docs、fixtures 与 runtime audit 之间的单一真相源，避免协议层和文案层再次漂移。

## Capabilities

### New Capabilities
- `endgate-state-packet`: 定义 workflow 边界的显式 endgate 状态包，以及状态值与后续事件之间的兑现规则。

### Modified Capabilities
- `workflow-protocol-contracts`: 将 workflow 终局与非终局边界的合法收口条件，从 prose guidance 升级为协议状态驱动的规则。
- `transcript-based-validation`: 将 transcript 审计从依赖邀请型文案，升级为优先校验协议状态包与尾部事件顺序，并把 prose 模式识别降为辅助安全网。

## Impact

- 受影响代码与资产：
  - `skills/using-superpowers/SKILL.md`
  - 其他继承 endgate 协议的本地 skills
  - `docs/README.codex.md`
  - `docs/testing.md`
  - `tests/codex/test-runtime-endgate-transcript-audit.sh`
  - `tests/codex/fixtures/*.jsonl`
  - `tests/prompt-contracts/*.sh`
- 受影响系统：
  - 本地 skill guidance
  - transcript-based runtime auditing
  - machine-readable workflow contract tests
- 外部依赖：
  - 无新增外部服务依赖
  - 继续依赖 `jq` 和 `openspec` CLI 完成验证与资产生成
