## Why

当前仓库把 `endgate-state-packet` 作为严格运行时契约写入 assistant 文本尾块，
虽然解决了 transcript 审计与 workflow 漏口问题，但也导致最终用户在终端中持续看见
`ENDGATE_PROTOCOL_VERSION / ENDGATE_STATE / ENDGATE_CHOICE_KIND / ENDGATE_NEXT_ACTION`
这四行协议内容。该信息对自动化验证有价值，却不属于面向用户的业务输出，已经开始干扰终端阅读与注意力。

现在需要把“机器可读协议信号”与“用户可见终端渲染”解耦：协议仍需稳定、可审计、可回放，但默认不应直接暴露在终端主视图中。

## What Changes

- 为 endgate 协议引入“carrier 与 render 分离”设计：
  机器消费优先使用结构化 transcript 字段，
  sidecar 仅作为过渡期 debug mirror，
  用户消费使用精简后的终端输出。
- 将当前“最后 4 行必须是可见 tail block”的硬约束升级为
  “必须存在 canonical machine-readable carrier；若当前环境缺少原生结构化能力，才回退到可见 tail block”。
- 定义两级落地路径：
  - 长期路径：Codex 客户端或渲染层提供原生结构化 endgate 字段，终端不再显示 packet。
  - 过渡路径：wrapper / PTY filter 从终端渲染中隐藏 `ENDGATE_*` 行，并可选写入项目内隐藏 sidecar 文件用于调试与审计辅助。
- 明确 hidden file 只能作为调试镜像或兼容 sidecar，不直接替代 transcript-local canonical contract，避免验证器退化为依赖文件系统状态。
- 更新 runtime audit、prompt-contract 与文档，使其优先消费结构化 carrier，
  在旧环境下继续接受 tail block fallback。

## Capabilities

### New Capabilities
- `endgate-render-separation`: 定义机器可读 endgate carrier 与用户可见终端渲染分离的能力，包括结构化 transcript carrier、wrapper 过滤与 sidecar 镜像边界。

### Modified Capabilities
- `endgate-state-packet`: 调整 packet 的承载方式约束，不再把“用户可见 tail block”视为唯一 canonical 载体，而是允许等价结构化 carrier 优先。
- `transcript-based-validation`: 调整验证优先级与解析逻辑，优先读取结构化 carrier，tail block 仅作为 fallback 与迁移兼容路径。
- `workflow-protocol-contracts`: 调整 strict packet mode 的表述，使其从“必须显示四行文本”收敛为“必须暴露 machine-readable endgate state，并确保后续动作兑现声明”。

## Impact

- 受影响文档与规则：
  `docs/README.codex.md`、相关 workflow skills、OpenSpec specs、测试说明。
- 受影响验证逻辑：
  `tests/codex/test-runtime-endgate-transcript-audit.sh`、
  `tests/shared/workflow-contract-helpers.sh` 及相关 fixtures。
- 可能新增的运行时集成：
  Codex 客户端结构化 transcript 字段，或项目本地 wrapper / PTY filter；
  如采用 sidecar，建议落在 `.codex/.runtime/` 下。
- 兼容性影响：
  需要明确新旧 carrier 并存期间的优先级，保证现有 strict packet 审计不被破坏。
