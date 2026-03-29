## 1. Guidance and contract updates

- [x] 1.1 更新 `.codex/instruction.md`，显式声明 imported / lower-priority / explore-mode ending guidance 不能削弱 strict packet mode。
- [x] 1.2 更新 `skills/using-superpowers/SKILL.md`，补强对 `no required ending` / `just provide clarity` / `continue later` 类 imported stance 的覆盖规则。
- [x] 1.3 更新 `docs/README.codex.md`，把这条 imported-skill override 规则同步到 Codex 使用说明。

## 2. Validation hardening

- [x] 2.1 新增一条贴近真实事故的 session-shaped runtime transcript negative fixture，覆盖 imported explore guidance + prose-only recommendation + `task_complete`。
- [x] 2.2 扩展 `tests/codex/test-runtime-endgate-transcript-audit.sh`，把新 fixture 纳入 runtime endgate audit。
- [x] 2.3 扩展 prompt-contract 测试，校验 repo-managed bootstrap / core guidance 已显式写出 imported-skill override。

## 3. Verification and sync

- [x] 3.1 运行相关测试脚本，确认 guidance 与 runtime audit 全部通过。
- [x] 3.2 运行 `openspec validate harden-imported-skill-endgate-overrides` 并修正残余问题。
- [x] 3.3 回写任务完成状态，确保 change artifacts 与实际实现同步。
