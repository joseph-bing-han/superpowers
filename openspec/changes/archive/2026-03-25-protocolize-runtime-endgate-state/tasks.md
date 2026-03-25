## 1. 协议定义与契约收敛

- [x] 1.1 新增 `endgate-state-packet` capability spec，固定 packet 字段、枚举和值配对关系
- [x] 1.2 更新 `workflow-protocol-contracts`，要求 analysis / checkpoint /
  handoff / terminal 边界先声明 packet，再进入下一步动作
- [x] 1.3 更新 `transcript-based-validation`，把 runtime endgate 审计明确改为
  packet-first，并保留 prose 作为残余安全网

## 2. Runtime validator 升级

- [x] 2.1 为 shared helper 增加 endgate packet 解析能力，能够从固定 tail block
  或等价 transcript 字段提取最后一份 packet
- [x] 2.2 将 `tests/codex/test-runtime-endgate-transcript-audit.sh`
  升级为“最后 packet 之后的事件窗口”审计，而不是 turn-wide 推断
- [x] 2.3 为 validator 增加 packet declaration / observed sequence mismatch
  的明确失败输出，区分：
  缺失 packet、未兑现 packet、legacy prose leak

## 3. Guidance、fixtures 与文档迁移

- [x] 3.1 更新 `skills/using-superpowers/SKILL.md`、关键 workflow skills 与
  `docs/README.codex.md`，把三态 endgate 改写为 packet-first guidance
- [x] 3.2 为 Codex transcript fixtures 新增 packet-positive 与 packet-negative
  样本，同时保留至少一个 legacy prose negative 样本证明安全网仍在
- [x] 3.3 更新 `docs/testing.md`，写明 packet、tool events、transcript events
  与 legacy prose safety net 的证据优先级

## 4. 回归与落地门槛

- [x] 4.1 运行 OpenSpec validate，确认新 change 的 design/spec/tasks 完整且 apply-ready
- [x] 4.2 运行 prompt-contract 与 Codex transcript tests，确认 packet-first
  契约没有破坏现有 terminal-choice / request_user_input 验证
- [x] 4.3 明确迁移阶段策略：哪些 lane 仍允许 prose fallback，
  哪些 lane 已进入“缺失 packet 即失败”的严格模式
