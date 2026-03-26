## 1. 收紧 OpenSpec 分流硬门

- [x] 1.1 更新 `skills/using-superpowers/SKILL.md`，把“重要变更在 lane decision 前不得让 `brainstorming` / `writing-plans` 先写普通 docs”写成更强的 runtime gate
- [x] 1.2 更新 `skills/brainstorming/SKILL.md`，加入 unresolved OpenSpec lane 时阻止普通设计文档落地的 hard gate
- [x] 1.3 更新 `skills/writing-plans/SKILL.md`，加入 unresolved OpenSpec lane 时阻止普通计划文档落地的 hard gate

## 2. 补齐顺序与回归验证

- [x] 2.1 更新 `tests/prompt-contracts/test-openspec-entry-and-doc-paths.sh`，校验 `brainstorming` 与 `writing-plans` 的 unresolved lane guard
- [x] 2.2 新增 session-shaped Codex transcript fixtures，分别覆盖“先写普通 docs 后问 OpenSpec”的负样本与“先 lane confirmation 再落地”的正样本
- [x] 2.3 扩展现有 Codex transcript audit 或新增专门审计脚本，使其能基于 fixture 顺序证据判定 OpenSpec lane-entry 是否合法

## 3. 运行验证并确认 change 就绪

- [x] 3.1 运行相关 prompt-contract 测试，确认入口与下游 skill 的 OpenSpec 分流约束已生效
- [x] 3.2 运行相关 Codex transcript 审计测试，确认负样本被拒绝、正样本通过
- [x] 3.3 运行 `openspec validate enforce-openspec-lane-decision-before-regular-docs`
