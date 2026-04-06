## 1. 收紧入口与轻量任务分类

- [ ] 1.1 更新 `.codex/instruction.md`，把默认模式改为 Direct Mode，并明确只有显式 skill 名或允许的 workflow 关键词才可进入 workflow
- [ ] 1.2 更新 `skills/using-superpowers/SKILL.md`，移除“simple question 也必须 check skill / overkill 也要用”的宽触发表述，加入轻量任务豁免与运行时降级规则
- [ ] 1.3 更新 `skills/brainstorming/SKILL.md`，明确普通问答、翻译、文本修改、UI copy-only 不应进入 brainstorming lane

## 2. 收紧 TDD 与终局边界

- [ ] 2.1 更新 `skills/test-driven-development/SKILL.md`，新增 text-only / copy-only / translation / docs-comments 任务的硬性豁免规则
- [ ] 2.2 更新 workflow endgate 相关 guidance，使 `terminal-choice` / `request_user_input` 只适用于 workflow-mode 边界，不再拦截 Direct Mode 的结果输出
- [ ] 2.3 更新 `docs/README.codex.md` 与 `README.md`，移除“相关 skill 会自动触发”的旧叙述，改成显式拉起 + 轻量任务豁免模型

## 3. 补齐验证与回归防护

- [ ] 3.1 扩展 `tests/skill-triggering/*`，覆盖普通问答不触发 workflow、宽松 workflow 关键词仍可触发 workflow
- [ ] 3.2 扩展 prompt-contract / transcript 验证，覆盖翻译与 copy-only 任务不触发 TDD，以及普通问答不应先出现 terminal popup
- [ ] 3.3 运行相关测试并修正残余回归，确保新的触发边界、轻量任务降级与 workflow-only endgate 行为一致
