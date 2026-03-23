## 1. OpenSpec 与测试基线

- [x] 1.1 完成 proposal、design 和 spec delta，正式定义 governed bugfix context recovery 与 OpenSpec apply/archive auto-continuation
- [x] 1.2 新增 prompt-contract 测试，锁定 bugfix 必须回看既有 OpenSpec artifacts
- [x] 1.3 新增 prompt-contract 测试，锁定已知的 OpenSpec apply/archive 下一步必须 auto-continue

## 2. Skill 与文档实现

- [x] 2.1 更新 `skills/using-superpowers/SKILL.md`，让 bugfix 路径识别既有 OpenSpec-governed work
- [x] 2.2 更新 `skills/systematic-debugging/SKILL.md`，把既有 OpenSpec artifact recovery 加入根因分析前置步骤
- [x] 2.3 更新 `spec-governed-development/SKILL.md`，明确既有 change 的 bugfix continuation 与 apply/archive auto-continuation
- [x] 2.4 更新 `skills/finishing-a-development-branch/SKILL.md` 与 `docs/README.codex.md`，让 archive follow-up 不再停在 recommendation-only

## 3. 回归验证

- [x] 3.1 运行新增 prompt-contract 测试
- [x] 3.2 运行相关既有 prompt-contract 测试，确认没有破坏现有终局协议
- [x] 3.3 运行 `openspec validate harden-openspec-bugfix-and-archive-continuation`
