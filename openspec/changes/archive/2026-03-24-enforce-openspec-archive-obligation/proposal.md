## Why

当前 superpowers 已经能在不少场景下把已知的 OpenSpec 下一步自动续跑到
`openspec-apply-change` 或 `openspec-archive-change`，但这仍然只是“当系统已经判断出下一步是 archive 时”的续跑规则。
实际使用中，只要 assistant 曾经为某项工作创建过 OpenSpec proposal / change，后续流程就已经进入了受治理的 OpenSpec lane；如果最终完成时还能以 recommendation-only prose、generic continue/stop，或普通 terminal-choice 结束而不真正进入 archive，就会留下长期悬空的 active change，破坏 OpenSpec 作为 canonical record 的闭环。

## What Changes

- 把“创建过 OpenSpec proposal / change 即产生 archive obligation”升级为仓库级 workflow 硬规则。
- 明确要求：一旦某项工作进入 OpenSpec lane 并创建了 proposal / change，直到 `openspec-archive-change` 完成前，都不得把该工作当成可自由终止的普通流程。
- 收紧 terminal completion 语义：对已创建 OpenSpec change 的工作，“最终完成”时不得停在 recommendation-only prose、generic continue/stop 或普通 terminal-choice；必须继续进入 `openspec-archive-change`。
- 保留现有安全边界：是否真的可归档、是否需要同步 specs、是否仍有未完成任务，仍由 `openspec-archive-change` 自身检查与确认；本次只禁止“跳过 archive skill”。

## Capabilities

### New Capabilities

- 无。

### Modified Capabilities

- `workflow-protocol-contracts`: 增加 created proposal/change 的强制归档义务，以及最终完成时不得跳过 `openspec-archive-change` 的协议要求。
- `transcript-based-validation`: 增加对“创建过 OpenSpec proposal 后仍跳过 archive”这一漂移的自动化验证要求。

## Impact

- Affected specs:
  - `openspec/specs/workflow-protocol-contracts/spec.md`
  - `openspec/specs/transcript-based-validation/spec.md`
- Affected workflow guidance:
  - `skills/using-superpowers/SKILL.md`
  - `spec-governed-development/SKILL.md`
  - `skills/finishing-a-development-branch/SKILL.md`
  - `docs/README.codex.md`
- Affected prompt-contract coverage:
  - `tests/prompt-contracts/test-openspec-governed-continuation.sh`
  - `tests/prompt-contracts/test-openspec-archive-obligation.sh`
