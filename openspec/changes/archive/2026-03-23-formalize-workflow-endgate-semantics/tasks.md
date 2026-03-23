## 1. OpenSpec 与测试基线

- [x] 1.1 完成 proposal、design 和 spec delta，正式定义条件式授权与统一终局协议
- [x] 1.2 新增仓库级 prompt-contract 测试，审计所有本地 skill 都显式继承统一终局协议
- [x] 1.3 补强条件式授权回归测试，确保正向判断后不再允许 prose-only 收口

## 2. Skill 与文档实现

- [x] 2.1 为所有本地 skill 与 `spec-governed-development/SKILL.md` 添加统一终局协议区块
- [x] 2.2 保留并对齐已有核心 skill 的专属 endgate 章节，使其与统一协议一致
- [x] 2.3 更新 `docs/README.codex.md`，明确禁止自由文本结束对话与 typed free-form 终局路径

## 3. 回归验证

- [x] 3.1 运行新的全 skill 终局协议审计测试
- [x] 3.2 运行既有 autonomous-continuation、nonterminal-workflow-gates、contingent-next-phase 与 transcript fixture 回归测试
- [x] 3.3 检查 OpenSpec artifacts、skill 文案与测试断言之间是否仍有语义漂移
