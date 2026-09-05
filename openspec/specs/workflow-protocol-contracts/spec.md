# workflow-protocol-contracts Specification

## Purpose

定义按任务触发、按授权推进、按风险验证的工作流契约。
历史归档中的旧严格终局规则不再是默认行为。

## Requirements

### Requirement: Host priority and task scope govern skill defaults
系统 MUST 服从宿主指令优先级；Skill MUST NOT 声称覆盖系统或开发者规则。
用户当前请求和适用项目规则在该层级内覆盖 Skill 默认流程。

#### Scenario: A stricter skill conflicts with user scope
- **WHEN** 用户只要求审查，而 Skill 建议实现或提交
- **THEN** 系统 MUST 只交付审查，MUST NOT 实现、commit、push 或创建 PR
- **AND** 不得以“更严格”为由提高低优先级规则的权限

### Requirement: Completion is scoped to the current request
完成 MUST 表示本次请求及相称验证已处理，不表示所有可能后续工作都已结束。

#### Scenario: A report is the requested deliverable
- **WHEN** 审查、分析、研究或方案已经完成
- **THEN** 系统 MUST 直接交付结果、证据与限制
- **AND** MUST NOT 默认追加结束/继续弹窗

#### Scenario: Plan-first request is ready for user review
- **WHEN** 用户要求先给方案并等待确认
- **THEN** 系统 MUST 交付方案并等待
- **AND** MUST NOT 把可执行的下一步误当成已授权实现

### Requirement: Safe authorized continuation does not require repeated confirmation
系统 MUST 自动继续本次请求内必要、安全、已获授权的工作。
进度摘要、保存计划和阶段边界 MUST NOT 自动成为审批门禁。

#### Scenario: Contingent authorization is satisfied
- **WHEN** 用户要求“如果设计合理就开始实现”且条件成立
- **THEN** 系统 MUST 继续已授权实现，不再询问是否继续

#### Scenario: One task is blocked but another is independent
- **WHEN** 一个步骤缺凭据或依赖，另一个已授权步骤不依赖它
- **THEN** 系统 MUST 安全诊断并继续独立步骤
- **AND** 只对真正无法推进的剩余部分报告阻塞

### Requirement: Real decisions use available permitted interaction
仅当缺失信息、实质取舍或新授权会改变工作时才询问。

#### Scenario: Choice tool is unavailable
- **WHEN** request_user_input 不可用或不适用于当前授权问题
- **THEN** 系统 MUST 用简洁普通文字询问
- **AND** MUST NOT 虚构工具调用或永久等待不存在的弹窗

### Requirement: Machine contracts are capability-scoped
机器消费者存在时 MUST 保留稳定协议；不得要求每个 Skill 重复整份协议。

#### Scenario: Normal workflow completes
- **WHEN** 没有显式启用兼容的 version 1 legacy integration
- **THEN** DONE 表示直接交付完成结果，不输出 version 1 packet
- **AND** 仅加载 Skill、读取规范或运行隐藏文本的 wrapper MUST NOT 启用 strict mode

#### Scenario: Legacy runtime is explicitly enabled
- **WHEN** 明确启用 version 1 集成且 carrier consumer 和选择工具可用、被允许
- **THEN** 系统 MUST 遵守 endgate-state-packet 与 endgate-render-separation 规范
- **AND** 保留 canonical carrier、固定字段配对和最后声明后的事件窗口
- **AND** MUST NOT 向未升级的 version 1 consumer 发送 DONE

#### Scenario: Reviewer returns a consumed verdict
- **WHEN** review consumer 需要 REVIEW_VERDICT、BLOCKING_ISSUE_COUNT 和 NEXT_ACTION
- **THEN** reviewer MUST 保留这些稳定字段
- **AND** 正文措辞不是唯一机器契约

### Requirement: Context is loaded on demand
系统 MUST 完整读取当前触发的 Skill 入口，再按任务需要展开引用。
已读且未变化的上下文 MAY 复用。

#### Scenario: Governed bugfix needs design context
- **WHEN** 本次回归属于 existing OpenSpec change
- **THEN** 系统 MUST 识别该 change 并读取相关需求、设计约束与任务状态
- **AND** MUST NOT 每次强制通读所有 proposal、specs 和历史材料

### Requirement: Governance follows risk and existing ownership
治理 MUST 由明确请求、既有 change、项目制度或需要持久决策的实质风险触发。
新功能、模块数量或步骤数量单独 MUST NOT 强制 OpenSpec。

#### Scenario: A local change is clear and low risk
- **WHEN** 不存在治理要求或需要记录的实质设计取舍
- **THEN** 系统 MAY 直接实现并聚焦验证，无须路线弹窗或额外文档

#### Scenario: Canonical record ownership is genuinely unresolved
- **WHEN** 正式记录位置会实质影响工作且尚未决定
- **THEN** 系统 MUST 在创建可能重复的设计文档前解决该决策
- **AND** 已明确的 change 或用户路线 MUST 直接复用，不重复询问

### Requirement: Request completion and change archive are separate
OpenSpec lane MUST 保留正式记录，但不得扩大本次授权范围。

#### Scenario: One regression is fixed within a larger change
- **WHEN** 本次回归已修复并验证，但 change 尚有其他任务
- **THEN** 系统 MUST 交付本次完成结果并保持 change 开放
- **AND** MUST NOT 自动实现无关任务或提前归档

#### Scenario: Full closure is requested and archive prerequisites hold
- **WHEN** 本次授权包含完整收尾，change 已完成，所需审查、合并和规范同步已满足
- **THEN** 系统 MUST 自动继续已授权归档，无须重复确认
- **AND** 若能力缺失或条件未满足，MUST 准确报告待办，不能称已归档

### Requirement: Review and verification match risk
共享行为、安全边界和复杂跨模块契约 SHOULD 有独立只读审查与对应行为证据。
普通文本修订只需相关静态检查；局部行为变更需聚焦回归。

#### Scenario: Independent review is unavailable
- **WHEN** 当前运行环境没有合适 reviewer
- **THEN** 系统 MUST 自审并说明限制，不默认修改全局设置
- **AND** 只有明确要求的独立审批才阻止相应集成，不阻止交付现状

#### Scenario: Existing evidence is still applicable
- **WHEN** 已有可靠验证且相关输入、环境和契约未变化
- **THEN** 系统 MAY 复用证据，只复核受影响部分
- **AND** MUST 准确区分已通过、未覆盖、无法运行和失败

#### Scenario: Review includes local changes
- **WHEN** 本次修改尚未全部提交
- **THEN** review MUST 覆盖完整任务 diff，包括 staged、unstaged 和相关 untracked 文件
- **AND** MUST NOT 用 BASE_SHA..HEAD_SHA 代替未提交内容

#### Scenario: Review covers an authorized subset of a plan
- **WHEN** 用户仅授权计划中的部分任务
- **THEN** 派发 MUST 提供完整计划作为上下文，以及独立的 REVIEW_SCOPE，列出获准任务、验收条件与延期或排除任务
- **AND** reviewer MUST 检查全部获准任务，不得把延期任务当作本次缺失功能
- **AND** 影响本次交付物的真实缺陷或依赖问题仍 MUST 报告
- **AND** 执行器 MUST NOT 为消除范围外审查意见而自动扩展任务

### Requirement: Cleanup and external operations have bounded authorization
本地编辑、commit、push、PR、merge 和归档 MUST 区分授权范围。
整理 MUST 仅处理本次创建且已确认可清理的资源。

#### Scenario: Worktree contains unrelated user changes
- **WHEN** 当前任务完成或准备整理
- **THEN** 系统 MUST 保留用户已有文件与无关改动
- **AND** MUST NOT 为获得干净工作区而丢弃它们
