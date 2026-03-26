## 1. 协议与文档建模

- [x] 1.1 更新 endgate 相关 specs 与文档，把 strict packet mode 的表述从“可见四行 tail block”升级为“canonical machine-readable carrier”
- [x] 1.2 明确 structured transcript、visible tail block fallback、hidden sidecar mirror 三者的优先级与边界

## 2. 验证器与测试夹具

- [x] 2.1 扩展 shared helper 与 runtime endgate audit，使其优先解析结构化 carrier，并兼容 tail block fallback
- [x] 2.2 新增/更新正负向 fixtures，覆盖 structured carrier 正向样本、wrapper 隐藏正向样本、sidecar-only 负向样本

## 3. 运行时隐藏路径

- [x] 3.1 设计并接入终端渲染隐藏方案，优先支持原生结构化 carrier，其次支持 wrapper / PTY filter 过渡路径
- [x] 3.2 约定并落地 sidecar debug mirror 路径（如 `.codex/.runtime/endgate-state.jsonl` 与 `.codex/.runtime/latest-endgate.json`），同时保证其不是唯一 canonical contract

## 4. 回归验证与迁移说明

- [x] 4.1 执行 prompt-contract、runtime transcript audit 与相关 smoke tests，确认隐藏终端输出后仍满足 endgate 协议
- [x] 4.2 更新 `docs/README.codex.md`、`docs/testing.md` 与相关 workflow guidance，写清迁移策略、兼容回退与风险边界
