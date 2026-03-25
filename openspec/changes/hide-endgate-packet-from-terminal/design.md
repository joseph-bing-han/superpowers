## Context

当前仓库已经把 `endgate-state-packet` 升级为 strict packet mode 的核心运行时契约，
并在 docs、skills、fixtures 与 transcript 审计脚本中默认要求 assistant 在下一个机器动作前
输出 canonical 四字段 packet。该设计解决了 prose-only endgate 泄漏，但代价是：

- 最终用户会在终端主视图中直接看到协议字段；
- 当前 runtime audit 主要从 transcript 中的 assistant 文本解析 packet；
- 仓库层 guidance 已经把“最后 4 行是 packet”写成显式规则，因此单纯修改文案无法隐藏显示。

本次变更的真实目标不是取消 endgate 协议，而是把“机器可读 carrier”与“用户可见 render”分层。
系统仍需保持 transcript 可审计、状态可验证、旧环境可兼容，同时默认不把协议正文暴露给终端用户。

## Goals / Non-Goals

**Goals:**

- 保留 endgate 的四字段 canonical 语义与三态配对规则。
- 允许新环境通过结构化 transcript carrier 提供 endgate 状态，而不再强制在终端打印四行文本。
- 为短期无法改 Codex 原生 transcript 的环境提供 wrapper / PTY filter 过渡路径，实现“终端隐藏、协议仍可保留”。
- 明确 hidden sidecar file 的角色边界，避免其破坏 transcript-local 审计模型。
- 让验证器、文档与 workflow guidance 对新旧 carrier 并存有清晰优先级。

**Non-Goals:**

- 不取消 `request_user_input`、`auto-continue`、`terminal-choice` 的现有行为契约。
- 不把 hidden file 变成唯一 canonical 数据源。
- 不要求一次性移除所有 tail block fixture；迁移期允许 fallback 并存。
- 不尝试用 ANSI 控制符、零宽字符或其他脆弱技巧“伪隐藏”协议文本。

## Decisions

### 1. 引入 carrier/render 分离模型

endgate 协议改为区分两个概念：

- **carrier**：机器消费的正式状态载体；
- **render**：用户在终端主视图中看到的呈现结果。

canonical 规则改为：

1. 若当前环境支持结构化 transcript endgate 字段，则该字段是首选 carrier；
2. 若不支持结构化字段，但可由 wrapper 捕获 assistant 输出并写入 sidecar，
   则允许在保持 transcript 可验证前提下隐藏 render；
3. 仅当以上能力都不存在时，才回退为当前可见 tail block。

这样可以让“必须有 machine-readable carrier”继续成立，但“必须打印给用户看”不再是硬约束。

### 2. 结构化 transcript carrier 是长期标准方案

长期方案优先选择原生结构化 carrier，而不是隐藏文件：

- transcript event 直接包含 `ENDGATE_PROTOCOL_VERSION`、
  `ENDGATE_STATE`、`ENDGATE_CHOICE_KIND`、`ENDGATE_NEXT_ACTION`
- validator 先读结构化字段，再决定后续窗口是否合法
- terminal renderer 默认不显示这些字段

选择该方案而不是“只写隐藏文件”的原因：

- 结构化 transcript 仍然是 session-local、时序稳定、可回放的证据；
- 不需要跨文件系统关联 turn 与 packet；
- 能保留现有“最后一份声明生效、只看后续事件窗口”的验证思路。

### 3. wrapper / PTY filter 是短期过渡方案

在 Codex 原生结构化字段尚不可用时，允许增加一个项目级 wrapper：

- 捕获终端渲染流中的连续 `ENDGATE_*` 行；
- 从用户可见终端输出中移除这些行；
- 可选把同样的数据追加写入 `.codex/.runtime/endgate-state.jsonl`，
  并同步维护 `.codex/.runtime/latest-endgate.json` 作为最近快照。

该方案的关键边界：

- **终端隐藏** 是 wrapper 责任；
- **协议合法性** 仍以 transcript / structured event 为主；
- sidecar 仅用于调试、排障与兼容镜像，不能单独代替 transcript 审计。

### 4. hidden sidecar file 不作为唯一 canonical contract

拒绝把隐藏文件升级为唯一正式 carrier，原因如下：

- `request_user_input` 与 `AUTO_CONTINUE` 的合法性需要与 turn 内事件窗口严格对应；
- 文件系统写入存在时序、覆盖、多会话并发与清理问题；
- validator 若必须跨 transcript 与本地文件拼装证据，会显著提高复杂度并削弱可移植性。

因此 hidden file 只能承担：

- wrapper 隐藏后的镜像落盘；
- 本地调试与人工排障；
- 在极端旧环境中的辅助兼容证据。

### 5. strict packet mode 从“可见文本”改为“可验证 carrier”

仓库内 strict packet mode 的定义调整为：

- 每个 workflow boundary MUST 暴露 canonical endgate carrier；
- 该 carrier 可以是结构化 transcript 字段，或 fallback tail block；
- 文档与 skill 不再强制“最后 4 行必须是用户可见文本”，而是要求“在下一个机器动作前存在可验证的 canonical carrier”。

这样既保留协议强度，也为隐藏终端输出提供正式制度空间。

## Risks / Trade-offs

- [新旧 carrier 并存导致理解成本上升] → 用明确优先级固定：structured transcript > transcript-visible tail block > sidecar mirror。
- [wrapper 方案只解决显示层，不解决根本 carrier 形态] → 明确其为过渡路径，并把原生结构化字段设为长期标准。
- [测试在迁移期出现误判] → 先让验证器支持多 carrier 解析，再逐步收紧“缺少结构化 carrier”的失败条件。
- [开发者误把 hidden file 当正式协议] → 在 spec 与 docs 中明确 sidecar 仅为 debug mirror，不可独立替代 transcript。
- [不同平台渲染行为不同] → 禁止采用 ANSI 擦除等脆弱技巧，优先使用结构化 carrier 或 wrapper 过滤。

## Migration Plan

1. 在 OpenSpec specs 中新增 `endgate-render-separation` capability，
   并为 `endgate-state-packet`、`transcript-based-validation`、
   `workflow-protocol-contracts` 编写 delta spec。
2. 更新文档与 skills，把 strict packet mode 的定义从
   “可见四行 tail block”升级为“canonical machine-readable carrier”。
3. 更新 runtime audit 与 shared helper，使其优先解析结构化 carrier，
   并保留 tail block fallback。
4. 若本地先走过渡方案，补充 wrapper / PTY filter 设计与 sidecar 路径约定：
   `.codex/.runtime/endgate-state.jsonl` 与 `.codex/.runtime/latest-endgate.json`。
5. 添加迁移期 fixtures：
   - 结构化 carrier 正向样本；
   - wrapper 隐藏但 transcript 合法的正向样本；
   - 只写 sidecar、缺少 transcript carrier 的负向样本。
6. 当结构化 carrier 成为默认路径后，逐步把“仅有可见 tail block、缺少结构化 carrier”从兼容分支升级为受限分支。

回滚策略：

- 若结构化 carrier 接入受阻，可暂时保留 tail block fallback；
- 若 wrapper 方案不稳定，可关闭终端过滤，但不回退对结构化 carrier 的 spec 设计；
- sidecar 镜像可随时移除，不影响 canonical transcript contract。

## Open Questions

- Codex 运行时能否原生暴露 endgate 结构化 transcript 字段，还是需要先由 wrapper 模拟？
- wrapper 如果以 PTY 方式代理 Codex，是否会影响现有交互式 `request_user_input` 行为？
- 迁移期是否需要为不同执行器（Codex / 其他 CLI）分别定义 carrier capability matrix？
- 当结构化 carrier 已存在时，是否仍保留可见 tail block 作为 debug 开关，而不是默认行为？
