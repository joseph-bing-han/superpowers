## Why

今天的 KCPortal session 审计确认了一条明确 incident：assistant 在需要进入
OpenSpec lane 的工作上，先写了普通设计文档和计划文档，直到用户补一句
`openspec呢?` 才转入 OpenSpec。当前仓库虽然已经有
`spec-governed-development` 和入口 guidance，但治理判断仍然过度依赖最前面的
单点触发，导致一旦入口漏判，`brainstorming` 与 `writing-plans` 仍会继续产出
普通 docs。

## What Changes

- 把“重要变更必须先完成 OpenSpec lane decision，再创建普通设计/计划文档”
  升级为仓库级 workflow 硬规则。
- 强化多层兜底：除了 `using-superpowers`，还要求 `brainstorming` 与
  `writing-plans` 在 lane 未决且工作疑似应进入 OpenSpec 时，阻止普通 docs 落地。
- 为这类问题增加 transcript 级顺序审计，显式捕获“先写普通 docs，后问是否要
  OpenSpec”的 session-shaped 漏分流场景。
- 补充 prompt-contract 覆盖，确保入口与下游 skill 都带有 unresolved lane
  guard，而不是只在治理入口写规则。

## Capabilities

### New Capabilities

- 无。

### Modified Capabilities

- `workflow-protocol-contracts`: 增加“OpenSpec lane decision 必须先于普通
  design/plan docs”以及“下游 skill 必须在 unresolved lane 时阻断普通 docs”
  的协议要求。
- `transcript-based-validation`: 增加对 OpenSpec lane entry 顺序错误的
  transcript 审计，以及对 `brainstorming` / `writing-plans` unresolved lane
  guard 的验证要求。

## Impact

- Affected specs:
  - `openspec/specs/workflow-protocol-contracts/spec.md`
  - `openspec/specs/transcript-based-validation/spec.md`
- Affected workflow guidance:
  - `skills/using-superpowers/SKILL.md`
  - `skills/brainstorming/SKILL.md`
  - `skills/writing-plans/SKILL.md`
- Affected validation:
  - `tests/prompt-contracts/test-openspec-entry-and-doc-paths.sh`
  - `tests/codex/test-runtime-endgate-transcript-audit.sh`
  - `tests/codex/fixtures/*`
