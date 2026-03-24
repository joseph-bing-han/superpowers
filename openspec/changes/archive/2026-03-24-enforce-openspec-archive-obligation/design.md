## Context

仓库当前已经解决了两类 OpenSpec workflow 问题：

1. 当 bugfix 属于既有 OpenSpec change 时，要先恢复 `proposal.md`、
   `design.md`、`specs/*`、`tasks.md` 上下文。
2. 当 workflow 已经明确知道下一条 OpenSpec lane 时，应 auto-continue
   到 `openspec-apply-change` 或 `openspec-archive-change`。

但目前仍缺少一个更上层的闭环约束：

- assistant 一旦已经创建了 OpenSpec proposal / change，后续流程就应被视为
  “尚未完成的受治理工作”。
- 只要这个 change 还未 archive，OpenSpec lane 就不应被视为真正结束。

因此问题不是 archive skill 不存在，而是“创建 change 后仍可绕过 archive”
没有被写成协议级错误。

## Goals / Non-Goals

**Goals:**

- 明确规定：创建过 OpenSpec proposal / change 就会产生 archive obligation。
- 明确规定：当该 change 最终完成时，workflow 必须进入
  `openspec-archive-change`，不能跳过。
- 让 prompt-contract 能直接审计这一规则是否被文案或实现重新削弱。

**Non-Goals:**

- 不修改 `openspec-archive-change` 自身的交互细节。
- 不要求尚未真正完成的 PR 在未 merge 前强行 archive。
- 不把所有普通工作都强行送进 OpenSpec lane。

## Decisions

### 1. 用“archive obligation”描述 created proposal 的后续义务

决策：

- 只要 assistant 创建了 OpenSpec proposal / change，就认为该工作已经拥有
  必须完成 archive 的治理义务。

原因：

- proposal 的创建本身就是“这项工作需要长期追溯”的明确承诺。
- 如果允许 proposal 创建后仍在终局阶段不 archive，就会持续积累悬空 change。

备选方案：

- 只在 assistant 主观判断“ready to archive”时推荐 archive。
  - 放弃原因：这正是当前遗漏归档的根因，强度不足。

### 2. 把“不能跳过 archive skill”写成 workflow 协议，而不是只写在 finishing 提示里

决策：

- 在 `workflow-protocol-contracts` 主 spec 中增加 requirement，规定：
  对已创建 OpenSpec change 的工作，最终完成时 MUST 进入
  `openspec-archive-change`。

原因：

- 这样约束的是整个 workflow，而不只是某个具体 skill。
- `using-superpowers`、`spec-governed-development`、`finishing-a-development-branch`
  和 `docs/README.codex.md` 都能围绕同一 canonical rule 对齐。

备选方案：

- 只更新 `finishing-a-development-branch`。
  - 放弃原因：其它路径仍可能在 finishing 之前或之外结束 turn。

### 3. 保留 archive skill 的安全检查，不做“盲归档”

决策：

- 新规则要求“必须进入 `openspec-archive-change`”，但不要求绕过其中的
  incomplete tasks / spec sync / final confirmation 检查。

原因：

- 目标是防止跳过 archive lane，不是移除 archive lane 的防护。

## Risks / Trade-offs

- [风险：把“必须归档”理解成“代码写完立刻归档”] → 在文案中明确只有
  “最终完成”才触发该义务；未 merge 的 PR 仍不应提前 archive。
- [风险：普通 OpenSpec explore/propose 中途草稿也被误判必须立即归档] →
  文案中明确 obligation 的触发是“created proposal/change”，但真正进入
  `openspec-archive-change` 的时机仍以“最终完成”为准。
- [风险：多个 skill 对同一规则描述不一致] → 通过新增 prompt-contract
  测试统一锁定 wording 强度。
