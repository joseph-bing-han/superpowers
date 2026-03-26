## Context

仓库当前已经有两层与 OpenSpec 分流相关的 guidance：

1. `using-superpowers` 要求对新功能、跨模块、多阶段工作优先触发
   `spec-governed-development`
2. `spec-governed-development` 要求当工作疑似应进入 OpenSpec lane 时，在创建普通
   `plans/specs` 文档前先用 `request_user_input` 做 lane confirmation

但今天的 KCPortal incident 说明，这两层规则仍不足以防止真实 runtime 漂移：

- assistant 先进入 `brainstorming`
- 先落普通设计文档
- 再落普通计划文档
- 用户补一句 `openspec呢?`
- assistant 这时才去读取 `spec-governed-development`

这意味着当前治理链路仍然过度依赖入口单点命中。一旦入口漏判，
`brainstorming` 与 `writing-plans` 仍会继续沿普通 docs 路径产出工件。
同时，现有验证主要聚焦文案存在与 endgate 协议，不足以覆盖“先写普通 docs，
后做 lane decision”的真实 session 顺序错误。

## Goals / Non-Goals

**Goals:**

- 让 OpenSpec lane decision 成为重要变更进入普通 design/plan docs 之前的强制前置条件
- 为 `using-superpowers`、`brainstorming`、`writing-plans` 建立一致的 unresolved lane guard
- 用 transcript fixture 和 prompt-contract 测试覆盖这类顺序错误
- 防止未来再次出现“先写普通 docs，后问要不要 OpenSpec”的 session-shaped incident

**Non-Goals:**

- 不强制所有工作都进入 OpenSpec lane
- 不改变 `openspec-propose`、`openspec-apply-change`、`openspec-archive-change` 的职责分工
- 不把普通 docs 路径移除；用户仍可显式选择继续仅生成常规设计/计划文档
- 不调整 endgate packet 协议本身

## Decisions

### 1. 采用“三层硬门”而不是继续依赖入口单点路由

决策：

- 在 `using-superpowers` 保留并强化前置治理规则
- 在 `brainstorming` 增加 unresolved lane hard gate
- 在 `writing-plans` 增加 unresolved lane hard gate

原因：

- 当前问题的本质是入口单点漏判后，下游没有拦截
- 三层硬门能把治理从“前置建议”升级为“多层兜底”

备选方案：

- 只修改 `using-superpowers`
  - 不采用原因：一旦真实 session 中未及时读取或未命中该段 guidance，下游仍会继续漂移

### 2. 把“普通 docs 创建前必须先完成 lane decision”写成协议级要求

决策：

- 在 `workflow-protocol-contracts` 中新增 requirement
- 明确普通 design/plan docs 的合法前提是：
  - 已确认进入 Superpowers-only lane
  - 或用户已显式选择常规 docs fallback
  - 或已存在明确 active/existing OpenSpec change 并进入 OpenSpec lane

原因：

- 这样约束的是 workflow 顺序，不只是 skill 文案习惯
- 后续可以让 skill guidance、tests、fixtures 围绕同一 canonical rule 收敛

备选方案：

- 只在 `spec-governed-development` 中补一句更强的话
  - 不采用原因：这仍然是单一 skill 规则，难以形成仓库级一致约束

### 3. 让 transcript 审计显式检查“lane confirmation 与普通 docs”的先后顺序

决策：

- 为这次 incident 增加 session-shaped 负样本 fixture
- 为正确顺序增加正样本 fixture
- 扩展 `tests/codex/test-runtime-endgate-transcript-audit.sh`
  或相邻审计脚本，使其可识别：
  - 普通 design/plan docs 已创建
  - lane confirmation 发生时间
  - OpenSpec change 创建时间

原因：

- 现有测试能看到“有没有规则”，但看不到“真实 session 是不是先写错 docs 再补问 OpenSpec”
- 这类 bug 必须通过 transcript 顺序证据才能稳定回归

备选方案：

- 只加 prompt-contract 测试
  - 不采用原因：只能锁 wording，不能锁 runtime 顺序

### 4. 保持 ordinary-docs fallback 合法，但要求其必须先被明确选择

决策：

- 不取消 “继续仅生成常规设计/计划文档” 这个 fallback
- 但要求它必须在 tool-backed lane confirmation 中被明确选中后，普通 docs 才允许落地

原因：

- 用户有时确实只想走轻量流程
- 真正的问题不是 fallback 存在，而是 fallback 没被明确选择却被默认执行

备选方案：

- 直接禁止普通 docs fallback
  - 不采用原因：会过度扩大 OpenSpec 的适用范围，不符合当前工作流定位

## Risks / Trade-offs

- [风险] 多层 hard gate 可能让简单工作也更频繁触发治理判断。 → 通过 requirement 明确只对“疑似应进入 OpenSpec lane”的工作触发，不扩大到所有任务。
- [风险] transcript 审计如果依赖具体路径字符串，可能对实现细节过敏。 → fixture 只锁定关键顺序证据，不把无关文案或完整大段 transcript 作为断言。
- [风险] 三个 skill 的判定标准若不一致，会形成新的漂移。 → 通过 prompt-contract 测试同时锁定三个 skill 的 unresolved lane guard。
- [风险] 旧 session 格式或 legacy 运行时可能缺少足够事件。 → 保持正负 fixture 最小化，只覆盖当前 Codex transcript 已有的稳定事件形态。

## Migration Plan

1. 先更新 `workflow-protocol-contracts` 与 `transcript-based-validation` delta specs，确定 canonical rule。
2. 修改 `skills/using-superpowers/SKILL.md`，把 OpenSpec lane decision 前置硬门写强。
3. 修改 `skills/brainstorming/SKILL.md`，加入 unresolved lane 时禁止写普通设计文档的 hard gate。
4. 修改 `skills/writing-plans/SKILL.md`，加入 unresolved lane 时禁止写普通计划文档的 hard gate。
5. 更新 prompt-contract 测试，锁定三层 guard。
6. 新增或扩展 Codex transcript fixture / audit，覆盖错误顺序与正确顺序。
7. 运行相关测试与 `openspec validate` 做回归验证。

回滚策略：

- 如实现后发现约束过严，可优先放宽 skill wording 或 fixture 断言范围
- 无需数据迁移，回滚成本仅限文档与测试文件

## Open Questions

- transcript 审计应直接扩展现有 `test-runtime-endgate-transcript-audit.sh`，还是拆成一个专门的 OpenSpec lane entry audit 脚本，需在实施时根据测试复杂度决定。
