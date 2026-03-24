## 1. 协议与 guidance 收敛

- [x] 1.1 更新 `workflow-protocol-contracts` 与 `transcript-based-validation` 对应正文和说明，明确 analysis / recommendation boundary 的正式语义
- [x] 1.2 补强所有受 terminal endgate protocol 约束的 skill guidance（含 `spec-governed-development`），显式禁止 `prose-only next-step invitation + task_complete`
- [x] 1.3 将 Codex tool-backed terminal-choice 从显式 `结束 / 继续 / 自由输入` 调整为只 authored `结束 / 继续`，自由输入改用客户端自动追加的 `Other/notes` 路径
- [x] 1.4 更新 `docs/README.codex.md`，把新的 runtime endgate 规则写入 Codex 使用说明

## 2. Transcript endgate 审计器

- [x] 2.1 新增一个面向 Codex `.jsonl` transcript 的 endgate linter，按 turn 检查 `task_complete` 之前的合法事件序列
- [x] 2.2 为 linter 定义最小可维护的邀请型 prose pattern 集合，并支持中英文扩展
- [x] 2.3 为 linter 增加“存在 `request_user_input` 或已授权 auto-continue 时放行”的合法路径判定

## 3. Fixtures 与自动化回归

- [x] 3.1 提取 `2026-03-24` incident 的最小负向 transcript fixture，并断言 linter 必须失败
- [x] 3.2 更新 terminal-choice 正向 transcript fixture，使其 authored payload 只保留 `结束 / 继续`
- [x] 3.3 视实现复杂度补一个 `auto-continue` 正向 fixture，覆盖已授权继续时的合法路径
- [x] 3.4 更新 `tests/codex/*.sh` 与 `tests/prompt-contracts/*.sh`，把 runtime 审计纳入默认回归入口

## 4. 文档与验证闭环

- [x] 4.1 更新 `docs/testing.md`，新增这类 prose-endgate leak 的 smoke test 与证据要求
- [x] 4.2 运行 OpenSpec validate、prompt-contract 和 Codex fixture tests，确认新 change 达到 apply-ready
- [x] 4.3 记录本次 incident 如何被 fixture 固化，以及后续安装/发布前应如何复核 runtime endgate
