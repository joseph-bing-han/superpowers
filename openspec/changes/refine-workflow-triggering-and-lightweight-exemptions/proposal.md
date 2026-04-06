## Why

当前 Superpowers 在实际使用中存在明显的“过度拉起”问题：普通问答也可能被整套 workflow 接管，简单翻译或 UI 文案替换也会被拉进 TDD，导致响应变慢、交互变重、结果还可能被 `request_user_input` 终局弹窗拦在前面。这已经偏离了“重流程服务重任务、轻任务直接完成”的目标，需要把 workflow 入口、轻量任务豁免、以及终局协议范围重新收紧。

## What Changes

- 将默认交互模式收敛为 Direct Mode：未显式点名 skill，且未命中允许的 workflow 关键词时，不自动拉起 Superpowers workflow。
- 保留“宽松 workflow 关键词”作为显式意图入口，例如设计、规划、调试、代码审查、执行计划等高层动作；但不再允许仅凭模糊语义猜测触发 workflow。
- 引入轻量任务豁免规则：简单问答、翻译、总结/改写、文本修改、UI copy-only、注释/文档修改直接跳过 workflow，尤其跳过 TDD。
- 允许 workflow 内部对当前子任务做“轻量化降级”：即使当前会话已经进入 workflow，只要当前子任务被判定为轻量任务，也临时按 Direct Mode 处理。
- 收紧 terminal-choice / `request_user_input` 的适用范围：只对真正处于 workflow mode 的边界生效；普通问答必须先直接输出结果，不能被结束弹窗拦在前面。
- 为上述行为补齐 prompt-contract、triggering、runtime transcript 等负向与正向验证。

## Capabilities

### New Capabilities
- `workflow-trigger-governance`: 定义 workflow 的显式拉起规则、轻量任务豁免、运行时降级与 TDD 抑制边界。

### Modified Capabilities
- `workflow-protocol-contracts`: 调整 terminal-choice / `request_user_input` 的适用范围，仅对 workflow-mode 边界生效，并明确 direct-mode / 轻量化降级子任务不能被终局弹窗拦截结果。
- `transcript-based-validation`: 增加对显式触发边界、轻量任务豁免、TDD 抑制、以及“普通问答不应先弹终局 popup”的验证。

## Impact

- 受影响文件与说明：
  - `.codex/instruction.md`
  - `skills/using-superpowers/SKILL.md`
  - `skills/brainstorming/SKILL.md`
  - `skills/test-driven-development/SKILL.md`
  - `docs/README.codex.md`
  - `README.md`
  - `tests/skill-triggering/*`
  - `tests/prompt-contracts/*`
  - `tests/codex/*`
- 受影响系统：
  - Codex 的 repo-managed bootstrap
  - 本地 workflow skill 触发与 endgate 收口规则
  - 相关 transcript / prompt-contract 自动化验证
