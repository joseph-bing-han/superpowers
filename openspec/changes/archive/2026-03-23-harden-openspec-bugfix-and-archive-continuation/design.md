## Context

仓库当前已经有两类与 OpenSpec 相关的规则：

1. `spec-governed-development` 负责在新功能 / 跨模块 / 多阶段工作上选择
   `Superpowers-only lane` 或 `OpenSpec lane`
2. `finishing-a-development-branch` 在 OpenSpec lane 的 Option 1 / Option 2
   结果下，给出 archive follow-up 提示

但这两条规则仍停留在“新需求入口”和“收尾提示”两个边界位置，中间缺少：

- **bugfix continuation 的治理恢复**
- **已知下一条 OpenSpec lane 的自动续跑**

因此 assistant 很容易出现两种不良表现：

- 修 bug 时只对 symptom 做局部推理，没有把既有 change 里的设计目标、
  约束和任务进度一起纳入证据
- 明明已经知道下一条正确路径，却仍退化成泛化的 `继续/结束`
  或 prose-only recommendation

## Goals / Non-Goals

**Goals**

- 让 governed bugfix 在进入修复实现前自动恢复既有 OpenSpec 上下文
- 让 OpenSpec lane 的已知下一步被视为 `auto-continue`
- 让 archive follow-up 不再只是一句建议，而是在合适边界上自然续跑
- 用 prompt-contract 测试把上述协议固定下来

**Non-Goals**

- 不修改 OpenSpec CLI 的行为
- 不改变 `openspec-archive-change` 自身的确认、sync 和 warning 机制
- 不把所有普通 bug fix 都强行送进 OpenSpec
- 不处理仓库外安装副本的同步；本次以当前仓库为准

## Decisions

### 1. 把 governed bugfix context recovery 放进 debugging 路径，而不是只放在治理入口

根因之一是当前 `using-superpowers` 对 bugfix 的优先级是
“debugging first, then domain-specific skills”。如果只在
`spec-governed-development` 写规则，而 `systematic-debugging` 本身不恢复
OpenSpec 上下文，assistant 仍可能在形成假设前错过 proposal/design/spec/tasks。

因此这次采用双层约束：

- `using-superpowers`：说明 bugfix 若可能属于既有 OpenSpec-governed work，
  必须恢复治理上下文，而不是只走局部调试
- `systematic-debugging`：把“检查 active change 并读取其 artifacts”
  写成 Phase 1 的证据收集步骤

这样可以确保 governed bugfix 的 OpenSpec 上下文出现在根因分析之前，
而不是变成修复后的补充说明。

### 2. 用“已知 lane 下一步 = auto-continue”统一 apply 与 archive

第二个缺口本质上不是只缺 archive 文案，而是 workflow 没有把
OpenSpec 的 lane-specific next step 当成“已知且安全”的隐含下一步。

这次统一成两条协议：

- 如果当前 change 仍有待完成任务，且当前工作明确属于该 change，
  那么下一步是 `openspec-apply-change`
- 如果当前 change 已完成，且 branch outcome/archive compatibility 已满足，
  那么下一步是 `openspec-archive-change`

只要 change 名称或当前 change 上下文已经明确，这两条都视为
`auto-continue`，不应被降级成泛化 `继续/结束` 选择。

### 3. 继续把 archive 的安全判断留在 `openspec-archive-change`

自动续跑并不代表自动跳过检查。

`openspec-archive-change` 仍然负责：

- 检查 artifacts 是否完成
- 检查 tasks 是否完成
- 检查 delta spec sync
- 必要时给出 warning 和确认

这次变化只负责把“进入 archive skill”定义为自然下一个 lane，
而不是让 `finishing-a-development-branch` 自己做归档决策。

### 4. 用专门的 prompt-contract 覆盖 bugfix context recovery 与 archive continuation

现有测试更聚焦终局协议、非终局 prose drift 和 worktree 生命周期，
没有一条明确锁定：

- bugfix 需要读取既有 OpenSpec artifacts
- OpenSpec lane 的 apply/archive 下一步应当自动续跑

本次新增独立测试文件，避免把这两类协议散落到无关测试里。

## Risks / Trade-offs

- [风险] 把更多 bugfix 送进 OpenSpec lane 可能让流程偏重
  - 缓解：只要求“属于既有 OpenSpec-governed work 的 bugfix”恢复上下文，
    普通局部 bug 仍可走 Superpowers-only
- [风险] archive auto-continue 可能被误触发
  - 缓解：仅在 current change / archive compatibility 明确时触发，
    且后续检查仍由 `openspec-archive-change` 负责
- [风险] 文案可能再次只写成“建议 archive”
  - 缓解：测试断言要求出现 `auto-continue` / direct continue / direct invoke
    语义，而不是 recommendation-only 语义

## Migration Plan

1. 新建 OpenSpec change artifacts，正式定义 bugfix context recovery 与
   apply/archive auto-continuation
2. 先写 failing prompt-contract 测试
3. 更新 skill / README 文案
4. 运行 prompt-contract 与 `openspec validate`

## Open Questions

- 后续是否需要把 `openspec-apply-change` 的上游 skill 文案也一并补成
  “all_done 时 auto-continue into archive”，以减少对仓库本地桥接层的依赖
