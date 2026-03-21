# Finishing Branch OpenSpec 归档衔接设计

**目标**

在不破坏 `finishing-a-development-branch` 现有职责的前提下，为 OpenSpec lane 增加一层**引导式归档**能力，使实现完成后的工作流能自然收束到 `openspec-archive-change`。

---

## 背景

当前流程中：

- `finishing-a-development-branch` 只负责测试验证、分支处理、PR/合并/保留/丢弃
- `openspec-archive-change` 负责 change 归档，但不会被前者自然接上

这会导致 OpenSpec lane 的最后一段闭环依赖人工记忆，容易遗漏。

---

## 设计原则

1. **不改变原有四个收尾选项**
2. **不自动归档**
3. **只在检测到 OpenSpec lane 时追加归档引导**
4. **保持 `finishing-a-development-branch` 为通用 skill，不变成 OpenSpec 专属 skill**

---

## 推荐方案

采用“引导式归档”：

- 当 `finishing-a-development-branch` 完成原有收尾逻辑后
- 如果当前工作属于 OpenSpec lane，或者上下文明确存在待归档的 OpenSpec change
- 且当前分支收尾结果与 archive follow-up 兼容
- 则追加一个简短的后置提示

提示内容应表达：

- 代码与分支收尾已完成
- 如果这是 OpenSpec change，下一步应进入 `openspec-archive-change`
- 若 change 名称已知，应建议显式带上 change 名称
- 但该提示必须与具体收尾选项绑定，不能对所有选项一概提示

---

## 触发条件

归档引导需要同时满足两层条件：

### 第一层：上下文明确表明当前工作属于 OpenSpec 变更

1. 当前会话已明确处于 OpenSpec lane
2. 当前计划或上下文中已声明 `OpenSpec Change`
3. 用户明确表示这是一个 OpenSpec change

若以上条件均不满足，则保持现有 `finishing-a-development-branch` 行为，不追加 OpenSpec 归档引导。

### 第二层：分支收尾结果必须与 archive follow-up 兼容

- **Option 1: Merge locally**
  - 如果 merge 后的结果代表一个已完成的 OpenSpec change，可立即给出 archive 推荐
- **Option 2: Push and create PR**
  - 不应立即提示 archive
  - 只能提示“待 PR merge 且 change 确认完成后再 archive”
- **Option 3: Keep as-is**
  - 不追加 archive 引导
- **Option 4: Discard**
  - 不追加 archive 引导

---

## 文案策略

引导文案应短、明确、非强制。

建议形式：

```text
Branch workflow complete.

If this work belongs to an OpenSpec change, the next recommended step is:
`openspec-archive-change <change-name>`
```

如果 change 名称未知，则不要猜测，只提示进入 `openspec-archive-change`。

对于 **Option 2**，文案也必须体现“延后归档”，而不是让用户误解为当前即可 archive。

对于 **Option 3 / Option 4**，不应输出任何 archive 引导文案。

---

## 风险与处理

### 风险 1：误把普通分支工作当成 OpenSpec lane

处理：

- 必须依赖明确上下文或显式标记
- 不做模糊猜测

### 风险 2：用户误以为已经归档

处理：

- 明确写出“next recommended step”
- 不使用任何会让人误解为已自动归档的文案

### 风险 3：与 `openspec-archive-change` 的选择逻辑冲突

处理：

- `finishing-a-development-branch` 只负责 handoff
- change 选择、状态检查、同步确认仍由 `openspec-archive-change` 自己负责

---

## 预期结果

第二阶段完成后：

- 普通 Superpowers 流程保持不变
- OpenSpec lane 会在合适的收尾结果下自然获得归档提醒
- PR 场景只会获得延后归档提示
- 保留分支或丢弃分支场景不会出现 archive 提示
- OpenSpec 与 Superpowers 的闭环将更完整
