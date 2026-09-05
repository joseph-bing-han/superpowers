---
name: spec-governed-development
description: Use for explicit OpenSpec requests, existing governed changes, project-required governance, or high-risk work needing durable scope and design decisions; not merely because a task has several steps or touches two modules.
---

# Spec Governed Development

## Overview

按当前请求的风险和项目制度选择治理方式。OpenSpec 保存正式范围、设计、
需求和进度；Superpowers 只提供必要的设计、执行与验证方法，不维护第二份
等价设计记录。

## When To Use

以下条件触发治理判断：

- 用户明确要求 OpenSpec 或指定已有 change。
- 本次工作属于 existing change / active OpenSpec lane。
- 项目明确要求受管理的变更流程。
- 高风险、长期协作或实质设计取舍需要持久范围与决策记录。

新功能、跨两个模块、多个步骤本身都不是强制治理条件。
明确、局部、低风险的修改直接实现并做聚焦验证；不强制生成设计或计划文档。

## Lane Decision

已有 change 或已获授权的路线直接复用，不反复确认。
只有治理方式尚未明确且会实质影响范围、交付或协作时才询问用户；
不能因为“看起来重要”就强制创建 proposal。

尚未选定正式记录位置时，不先创建可能重复的设计文档。可以继续相关只读调查。
用户明确要求先给方案时，交付方案后等待；端到端实现已授权时自动继续必要步骤。

简要说明所选路线和原因即可，不要求固定输出模板或必经 skill 清单。

## OpenSpec Workflow

1. 识别相关 change；需要时使用可用的 `openspec list --json`。
2. 按任务读取正式上下文：
   - 范围不清时读 `proposal.md`；
   - 设计约束相关时读 `design.md`；
   - 行为契约相关时读对应 `specs/*`；
   - 继续执行或判断完成度时读相关 `tasks.md`。
   已完整读取且未变化的上下文可复用，不要求每次通读全部工件。
3. 缺少必要范围或设计时才探索、提出或补充记录。已有批准设计直接使用。
4. 实现阶段在本次授权范围内执行 `openspec-apply-change` 或支持的项目等价流程。
   只有存在真实执行复杂度时才补充执行级计划。
5. 行为或范围变化同步到正式 artifacts；验证本次受影响的契约。
6. 请求完成、change 完成和归档是不同边界，按下节分别处理。

## Capabilities and Fallback

使用 OpenSpec CLI 或外部 `openspec-*` skills 前检查当前可用能力；
本仓库不保证这些工具已安装。缺少工具时，可按明确的现有格式安全地读取、
编辑本次相关工件，并执行可用的静态/契约检查，注明未执行的工具验证。
不要默认安装依赖、修改全局设置，或虚构外部 skill 调用。

如果缺少能力会影响规范同步、正确性或归档安全，完成其余独立工作，
报告具体阻塞及所需能力。不能为绕过治理而另建一份平行设计真相源。

## Source of Truth

OpenSpec lane 中：

- `proposal.md`：动机与范围。
- `design.md`：设计取舍和约束。
- `specs/*`：正式行为契约。
- `tasks.md`：change 级任务及状态。

`docs/superpowers/plans/...` 仅在需要时记录执行细节，不能复制或替代上述内容。
非治理的小任务不要求创建持久工件；需要文档时使用项目约定。

## Completion and Archive

- **本次请求完成**：所请求的部分已处理，相关验证和限制已报告。
  即使 change 还有其他任务或未合并，也可直接交付；保留其开放状态。
- **整个 change 完成**：范围内全部要求与相称验证满足，任务状态准确，
  以及项目要求的审查、集成步骤已完成。不要把局部通过称为整体完成。
- **归档**：只在 change 真正完成、规范同步与 archive compatibility 明确、
  项目要求的合并阶段完成且归档在授权范围内时进行。
  创建 proposal 不自动授权归档，更不授权 merge。

若本次请求就是完整收尾且条件已满足，自动继续到
`openspec-archive-change`，不再问是否继续。
否则报告归档尚待满足的条件，不提前归档，不自动执行无关剩余任务。

## Handoff Guidance

在请求范围内继续安全、已授权的下一步；有真正缺失信息或新授权时才询问。
局部阻塞不阻止独立工作。完成后直接交付，不强制“结束/继续”弹窗。
共享路由与完成规则见 `using-superpowers`；只有显式启用的兼容运行环境
才使用 version 1 endgate-state-packet。
