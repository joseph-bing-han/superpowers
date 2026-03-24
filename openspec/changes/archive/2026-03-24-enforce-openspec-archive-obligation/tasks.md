## 1. OpenSpec 规则与验证基线

- [x] 1.1 完成 proposal、design 与 spec delta，正式定义 created OpenSpec change 的强制归档义务
- [x] 1.2 新增或更新 prompt-contract 测试，锁定“最终完成不得跳过 `openspec-archive-change`”

## 2. Workflow Guidance 收紧

- [x] 2.1 更新 `skills/using-superpowers/SKILL.md`，明确 created OpenSpec proposal 会产生 archive obligation
- [x] 2.2 更新 `spec-governed-development/SKILL.md`，明确 created change 在 archive 前不得离开 OpenSpec lane
- [x] 2.3 更新 `skills/finishing-a-development-branch/SKILL.md`，把已完成 OpenSpec change 的 archive follow-up 写成 mandatory handoff
- [x] 2.4 更新 `docs/README.codex.md`，同步 created proposal/change 的强制归档规则

## 3. 验证与收口

- [x] 3.1 运行 `bash tests/prompt-contracts/test-openspec-archive-obligation.sh`
- [x] 3.2 运行相关既有回归测试，确认 OpenSpec continuation 规则没有回退
- [x] 3.3 运行 `openspec validate enforce-openspec-archive-obligation`
