## Context

当前仓库已经通过 archived changes 建立了三层基础治理：

- `2026-03-22-decouple-prose-from-workflow-protocols`
  把协议层与表达层分离，减少对自由文本措辞的依赖
- `2026-03-23-formalize-workflow-endgate-semantics`
  统一 `auto-continue`、`needs-user-decision`、`terminal-choice`
  三态 endgate 语义
- `2026-03-23-harden-openspec-bugfix-and-archive-continuation`
  补强 governed bugfix context recovery 与 OpenSpec lane 已知下一步的续跑

但 `2026-03-24` 的真实 Codex transcript 说明仍存在一个未被覆盖的 runtime
缺口：assistant 在分析完成后给出具体推荐方案和明确下一步，却仍可能以
`如果你同意，我下一步可以……`
这类 prose-only 邀请收尾，并直接 `task_complete`。这条路径既不属于
合法 `terminal-choice`，也不属于合法 `auto-continue`，但当前仓库还没有
一个可以直接审计此类 transcript 事件序列的通用机制。

同一天的真实 popup 交互还暴露出第二个设计错误：当前仓库把
`3. 自由输入` 写成了 tool-backed `terminal-choice` 的固定 assistant-authored
选项，但 Codex `request_user_input` 客户端本身已经会自动提供 free-form
`Other/notes` 入口。结果就是：

- popup 中出现重复的自由输入路径
- assistant 自己写出的“自由输入”选项反而比客户端原生入口更慢
- 当前 specs / prompt-contract / fixtures 对 Codex UI 边界的建模已经过时

本次变更需要同时覆盖：

- workflow 协议定义
- transcript 验证能力
- Codex fixture 回归资产
- skills / README / testing 文档

因此这是一次典型的跨模块治理修复，而不是单点 wording 调整。

## Goals / Non-Goals

**Goals:**

- 将“analysis / recommendation boundary”定义为正式 workflow 协议边界
- 明确禁止
  `prose-only next-step invitation + task_complete`
  这种 runtime endgate 泄漏
- 为 Codex `.jsonl` transcript 增加规则化 endgate 审计能力
- 将 `2026-03-24` incident 沉淀为负向 fixture，并补充修复后的正向 fixture
- 让静态 prompt-contract、runtime transcript 审计和测试文档形成闭环
- 让 tool-backed terminal-choice 与 Codex 客户端自动提供的 free-form
  fallback 对齐，不再重复声明 `3. 自由输入`

**Non-Goals:**

- 不尝试修改 Codex UI 或 `request_user_input` 的渲染机制
- 不构建依赖模型推断的“智能语义分类器”
- 不要求所有推荐型 prose 都消失；本次只治理其作为 workflow 结束协议时的
  非法用法
- 不在本次变更中实现所有下游具体代码修复；本次重点是治理协议与验证能力
- 不改变非 tool-backed 文本回退场景下如何表达自由输入；本次只修正
  Codex `request_user_input` 场景

## Decisions

### 1. 把“分析完成后的具体下一步邀请”定义为一个独立协议边界

当前 endgate 规则已经覆盖 terminal completion、contingent authorization 和
OpenSpec known lane continuation，但没有把“分析完成后给出推荐方案并邀请执行”
单独提升为正式边界。结果就是模型虽然读到了全局禁令，仍可能把这类场景当作
“可以自然收尾的建议段落”。

本次决定新增一条专门 requirement：

- 当 assistant 已给出具体推荐方案、已知下一步且准备结束当前 turn 时，
  后续只能走两条合法路径：
  - `auto-continue`
  - `request_user_input`
- 不允许再以 prose-only 邀请结束当前 turn

之所以单独建模，而不是继续往已有 requirement 里堆示例，是因为这次问题的
核心不是 wording，而是**一个漏掉的协议边界**。

备选方案：

- 继续只补更多禁止短语
  - 成本低，但仍依赖 prompt 遵守，无法稳定覆盖 runtime 泄漏
- 把所有分析型回合强制归类为 `terminal-choice`
  - 过于粗暴，会误伤那些已经获得继续授权、应直接 auto-continue 的场景

### 2. 新增一个确定性的 transcript endgate linter，而不是依赖人工审 transcript

`2026-03-24` 这类问题可以从 transcript 事件序列机械识别：

- 同一 turn 中存在 `task_complete`
- 最后一条 assistant 文本属于“具体下一步邀请型 prose”
- 该 turn 内没有 `request_user_input`
- 也没有可证明的 auto-continue 动作

因此本次选择新增一个**确定性、规则化**的 transcript linter，而不是继续依赖：

- 人工阅读 jsonl
- 只看文档中有没有禁令
- 只保留正向 fixture

该 linter 应聚焦事件序列合法性，而不是自然语言全面理解。它只需要回答：

- 这一回合是合法结束，还是把 prose 当协议收尾了？

备选方案：

- 做一个更泛化的 transcript 审计框架
  - 长远可行，但当前需求聚焦，先用 endgate-specific linter 更稳
- 只做负向 regex 搜索
  - 太脆，无法结合 `task_complete`、`request_user_input` 与 turn 边界判定

### 3. 用 incident-based fixtures 固化真实漏点，而不只保留正向成功样本

现有 `tests/codex/fixtures/` 主要是正向成功样例，能证明
`request_user_input` 曾经出现过，但不能证明“某种非法结束会被拦下”。

本次决定新增两类 fixture：

- **负向 fixture**
  - 截取 `2026-03-24` incident 中的最小必要 turn 序列
  - 预期：linter 必须失败
- **正向 fixture**
  - 对应修复后的合法序列
  - 预期：linter 必须通过

这样回归面不再只是“证明系统会成功一次”，而是能持续证明
“这次真实洞不会再复发”。

备选方案：

- 只在 docs/testing.md 记录事故说明
  - 可追溯但不可执行
- 只增加 live smoke test
  - 成本高，且不适合作为快速回归主入口

### 4. 保留静态 prompt-contract，但把 runtime transcript 审计升级为发布前必经验证

prompt-contract 仍然必要，因为它负责验证：

- guidance 是否仍然存在
- wording 是否没有漂移回旧模式

但这次 incident 已证明，**“规则存在”不等于“运行时就不会违约”**。因此本次
决定把验证链升级为：

1. prompt-contract：规则存在性
2. transcript fixture test：runtime 序列合法性
3. docs/testing.md：live smoke 与证据采集规范

备选方案：

- 用 runtime transcript 审计完全替代 prompt-contract
  - 会丢掉对文档契约的快速静态检测，不划算

### 5. Tool-backed terminal-choice 只显式保留 `结束 / 继续`，自由输入交给客户端自动 fallback

当前仓库的固定 `1/2/3` 终局协议把 `3. 自由输入` 当成 assistant 必须显式
写入的 authored option。但在 Codex `request_user_input` 中，客户端已经会自动
追加 free-form `Other/notes` 路径，因此显式写 `自由输入` 会造成重复入口。

本次决定将 Codex tool-backed terminal-choice 收敛为：

- assistant-authored options：`结束 (Recommended)`、`继续`
- free-form fallback：依赖客户端自动追加的 `Other/notes`

这样做的原因：

- 与真实客户端行为一致
- 减少重复选项和认知噪音
- 让 fixtures 和 prompt-contract 检查 assistant 真正负责的 authored payload，
  而不是把客户端 UI 自动行为误当成 skill 契约

备选方案：

- 继续保留显式 `3. 自由输入`
  - 与真实 Codex UI 重复，且已被真实使用体验证明多余
- 彻底移除自由输入能力
  - 不可接受，会损失必要的 free-form fallback

## Risks / Trade-offs

- [规则过于依赖固定短语，未来仍会漏报] → linter 以 turn 结构和事件组合为主，
  短语模式只作为“邀请型 prose”的可扩展触发器，而不是唯一判据
- [把合法建议段落误报为违规结束] → 要求同时满足
  `next-step prose + task_complete + no request_user_input + no auto-continue`
  才判失败，避免只因出现推荐语气就误报
- [incident fixture 过于依赖单一案例] → 保留真实 incident 作为最小负向样本，
  同时补一个修复后的正向样本，后续可继续扩充案例库
- [验证链过长，维护成本上升] → 让 linter 聚焦 endgate 这一件事，不扩展成
  全能 transcript 分析器
- [不同运行环境的 free-form fallback 机制不完全一致] → 本次 requirement
  明确限定在 Codex tool-backed `request_user_input` 场景；文本回退场景另行处理

## Migration Plan

1. 为 `workflow-protocol-contracts` 增加 analysis / recommendation boundary
   requirement，并修正 terminal-choice authored options 约定
2. 为 `transcript-based-validation` 增加 runtime endgate 审计 requirement，
   并更新 terminal-choice fixture 断言基线
3. 新增 Codex transcript endgate linter 与 incident fixtures
4. 更新相关 skill guidance、README 与 testing 文档
5. 运行 prompt-contract、Codex fixture tests 与 OpenSpec validation

回滚策略：

- 若 linter 误报过高，可先保留新增 spec 与 fixtures，临时收窄 pattern 集合
- 若某条 guidance wording 导致静态测试不稳定，可只回滚 wording，不回滚
  runtime 审计 requirement

## Open Questions

- linter 的邀请型 prose pattern 是否先以中英文最小集合起步，还是同时纳入
  更泛化的推荐/判断表达式
- 是否需要在后续变更中把这套 transcript 审计接入安装副本同步或发布脚本
- 是否要为未来新增的 incident fixtures 设计统一的命名与匿名化规范
- 对于非 Codex 客户端，是否需要单独定义“free-form fallback 是否由客户端提供”
  的平台能力矩阵
