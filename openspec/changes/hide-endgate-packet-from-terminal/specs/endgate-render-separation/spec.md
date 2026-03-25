## ADDED Requirements

### Requirement: Canonical endgate carrier and terminal render are separable
系统 MUST 将 endgate 的机器可读 carrier 与用户可见终端 render 视为两个独立层次，
以便在不削弱协议可验证性的前提下隐藏协议正文。

#### Scenario: Structured carrier suppresses visible packet text
- **WHEN** 当前运行时能够为 workflow boundary 暴露结构化 endgate transcript 字段
- **THEN** 该结构化字段 MUST 成为 canonical endgate carrier
- **AND** 用户可见终端 render MUST NOT 默认显示原始 `ENDGATE_*` 行

### Requirement: Wrapper fallback may redact terminal output while preserving canonical evidence
当原生结构化 carrier 尚不可用时，系统 MUST 支持一个 wrapper / PTY filter
过渡路径；在该路径中，终端中的 `ENDGATE_*` 行 MAY 被隐藏，但该方案 MUST
不破坏 canonical 协议证据。

#### Scenario: Wrapper hides one or more endgate lines and writes a debug mirror
- **WHEN** wrapper 检测到一行或多行 `ENDGATE_*` 内容
- **THEN** wrapper MAY 将这些行从用户可见终端输出中移除
- **AND** wrapper MAY 将等价数据追加写入 `.codex/.runtime/endgate-state.jsonl`
- **AND** wrapper MAY 同步维护 `.codex/.runtime/latest-endgate.json`
- **AND** transcript 或等价结构化事件 MUST 仍保留 canonical endgate carrier

### Requirement: Hidden sidecar files are debug mirrors rather than sole source of truth
隐藏 sidecar 文件 MUST 只承担调试、排障或兼容镜像作用，不能单独替代 transcript-local
endgate contract。

#### Scenario: Sidecar-only evidence is insufficient
- **WHEN** 某个 strict packet workflow boundary 只写入 hidden sidecar file
- **AND** 同一 turn 中不存在结构化 carrier 或可解析 tail block
- **THEN** 该 boundary MUST 被视为缺少 canonical endgate carrier
- **AND** validator MUST NOT 仅凭 sidecar file 将其判定为合法
