## Why

真实 Codex transcript 已暴露一个新的 runtime 漏口：即使 `using-superpowers`、仓库级 instruction 与 strict packet mode 已经生效，assistant 仍可能在读取外部 / 低优先级 skill（例如 `openspec-explore`）后，被其中“无需固定结尾”“just provide clarity”“continue later”一类自由收尾语义带偏，最终以 prose-only recommendation + `task_complete` 结束 turn，跳过本应触发的 `request_user_input`。

这个问题说明当前治理虽然已经覆盖本仓库维护的本地 skills 与通用 runtime endgate 审计，但对“外部 skill / imported stance 不能削弱 strict packet mode”的覆盖仍不够显式，也缺少一条直接锁定该 incident 形态的 session-shaped transcript 回归样本。

## What Changes

- 收紧仓库级 workflow contract，明确外部、低优先级、探索型或 stance-only 技能中的自由结尾语义不得削弱 strict packet mode。
- 把“`There’s no required ending` / `Just provide clarity` / `Continue later` 等 imported guidance 仍必须服从 `endgate-state-packet` + `request_user_input`”写入 repo-managed instruction、核心 skill guidance 与 Codex 使用文档。
- 为 runtime transcript audit 增加一条贴近真实事故的 session-shaped negative fixture，锁定“读过 imported explore skill 后仍以 prose-only recommendation + `task_complete` 收口”的失败路径。
- 扩展 prompt-contract / transcript-based validation，确保未来既审计 guidance override，也审计真实 transcript 事件序列。

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `workflow-protocol-contracts`: 增加 imported / lower-priority skill ending guidance 不得削弱 strict packet mode 的协议约束。
- `transcript-based-validation`: 增加针对 imported-skill drift 的 session-shaped transcript 审计要求与回归样本。

## Impact

- Affected code and docs:
  - `.codex/instruction.md`
  - `skills/using-superpowers/SKILL.md`
  - `docs/README.codex.md`
  - 可能需要同步相关测试说明文档
- Affected validation:
  - `tests/codex/test-runtime-endgate-transcript-audit.sh`
  - `tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`
  - 新增或修改 `tests/codex/fixtures/*.jsonl`
- Affected systems:
  - Codex runtime workflow bootstrap
  - Superpowers 本地技能治理
  - transcript-based regression audit
