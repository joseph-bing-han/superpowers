# 子代理流水线调度与能力路由设计

**日期：** 2026-03-24 22:11  
**线路：** Superpowers-only  
**状态：** 设计已确认，待实现

---

## 1. 背景

当前 `superpowers` 中与实现阶段最相关的两条能力线分别是：

1. `subagent-driven-development`
2. `dispatching-parallel-agents`

前者目前的默认执行模型是严格的串行质量流水线：

```text
implementer -> spec reviewer -> code quality reviewer -> next task
```

该技能文档同时把“并行派发多个 implementation subagent”列为 red flag。  
这意味着现在的默认体验不是“并行调度器”，而是“质量优先的串行编排器”。

这套设计并非没有价值。它提供了：

- 上下文隔离
- 角色分工
- 规格审查与代码质量审查双门禁
- 主线程上下文保护

但也暴露出明显体验问题：

1. 主线程在大量时间里只是等待单个子代理完成工作。
2. 用户容易把“用了子代理”理解为“应该并发提速”，从而产生预期落差。
3. 仓库虽然已经有 `dispatching-parallel-agents`，但默认执行主线并不会自然升级到可并行的调度模型。

因此，本次设计需要同时解决两个问题：

1. 在不牺牲质量门禁的前提下，减少主线程空等与串行等待感。
2. 明确子代理的产品定位与能力路由，让“什么时候是隔离/审查工具，什么时候是并行工具”变得清晰。

---

## 2. 设计目标

### 2.1 本次目标

1. 将实现阶段的默认执行模型从“串行等待”升级为“受控流水线”。
2. 保留现有 `implementer -> spec reviewer -> code quality reviewer` 的质量门禁顺序。
3. 允许主线程在子代理工作期间继续进行后续任务的只读准备工作，而不是空等。
4. 为后续受控并行提供足够的任务元数据基础。
5. 明确 `subagent-driven-development` 与 `dispatching-parallel-agents` 的能力边界。
6. 通过文档与测试，把新的执行语义固定下来，避免未来回退为“默认串行等待但对外隐含并行期待”。

### 2.2 非目标

1. 不直接修改 Codex 底层运行时调度器。
2. 不默认允许多个 implementation subagent 同时在同一冲突域内写代码。
3. 不移除 spec review 或 code quality review。
4. 不要求 planner 在第一版就产出复杂的编译器级依赖图。

---

## 3. 当前问题诊断

### 3.1 当前默认模型的真实语义

从现有技能文档来看，`subagent-driven-development` 的真实语义更接近：

**质量优先的串行执行器**

而不是：

**吞吐优先的并行调度器**

这意味着：

- 子代理的主要收益来自上下文隔离和分工，而非并行吞吐。
- 主线程的工作重心是编排与等待结果，而不是持续调度。
- “用了子代理但还是像在等一个人”的体感是当前设计的自然结果。

### 3.2 当前能力路由不够清晰

仓库已经存在 `dispatching-parallel-agents`，但其语义更偏向“多个独立问题域的并发调查/修复”，并没有被解释为执行阶段的默认升级路径。

因此，用户从 README 和工作流中感知到的是：

- 系统提到了子代理
- 系统提到了并行代理
- 但实际默认行为仍是单通道串行推进

这会导致产品叙事与运行现实不一致。

---

## 4. 核心设计决策

### 4.1 引入三种执行模式

执行阶段统一抽象为三种模式：

### 模式一：Serial SDD

适用于：

- 共享写集
- 高耦合
- 高风险改动
- review 结果很可能直接改变后续任务边界

语义：

- 一次只推进一个任务
- review 未闭环前，不启动后续写任务

### 模式二：Pipeline SDD

这是本次新增的默认推荐模式。

适用于：

- 大多数普通实现任务
- 任务之间存在依赖链，但仍可提前做只读准备
- 需要保留强质量门禁，但希望减少空等

语义：

- 保持质量门禁顺序不变
- 允许 `preflight`、`review` 与主线程调度重叠
- 默认不允许同冲突域的多写手并发

### 模式三：Parallel Dispatch

适用于：

- 写集分离
- 依赖少
- 风险低
- 任务边界清晰

语义：

- 多个 lane 并行推进
- 各自完成 implement / review
- 在集成屏障处汇合

---

### 4.2 新的能力路由矩阵

```text
┌──────────────────────────────┬──────────────────────┐
│ 任务特征                     │ 路由                 │
├──────────────────────────────┼──────────────────────┤
│ 同一文件或同一模块强耦合     │ Serial SDD           │
│ 有依赖链但可提前只读准备     │ Pipeline SDD         │
│ 写集分离、风险低、边界清晰   │ Parallel Dispatch    │
└──────────────────────────────┴──────────────────────┘
```

关键判断维度不是“任务数量”，而是：

1. 依赖关系是否明确
2. 写集是否冲突
3. 风险是否可控
4. reviewer 的回流是否会重写后续任务边界

#### 路由优先级

为避免 `Risk Level`、`Conflict Group`、`Parallelizable` 彼此打架，
本次设计固定以下判定优先级：

```text
1. 先判风险
2. 再判依赖是否阻塞 preflight
3. 再判写集 / 冲突域是否允许真并行
4. 最后才看 Parallelizable 的声明
```

对应伪代码如下：

```text
if Risk Level == high:
  route = Serial SDD
elif unresolved dependency changes this task's file scope or acceptance:
  route = Serial SDD
  task_state = blocked
elif Parallelizable == yes
  and Conflict Group is disjoint
  and Write Set is disjoint:
  route = Parallel Dispatch
elif Parallelizable in {yes, preflight-only, no}:
  route = Pipeline SDD
else:
  route = Serial SDD
```

这里的含义是：

- `Risk Level` 拥有最高裁决权
- `Depends on` 与依赖是否改变任务边界，决定任务是否可以提前进入 `preflight`
- `Parallelizable: yes` 不是单独生效的放行按钮，仍需服从风险、依赖与冲突域判断
- 如果无法证明可安全真并行，则默认回到 `Pipeline SDD`，而不是直接放开 `Parallel Dispatch`

---

### 4.3 Pipeline SDD 的状态机

### 任务状态

每个任务新增以下状态：

```text
queued
  -> preflight
  -> ready
  -> implementing
  -> spec_review
  -> quality_review
  -> done

blocked
```

#### `Depends on` 的门槛语义

`Depends on` 不再用于决定任务能否进入 `preflight`。  
它只决定任务何时可以进入：

1. `ready`
2. `implementing`

规则改为：

1. 只要当前任务的文件范围、规格边界与验收口径已经稳定，任务就可以提前进入 `preflight`
2. 只有当所有 `Depends on` 任务进入 `done`，当前任务才可以进入 `ready`
3. 如果某个前序任务尚未完成，而且它会改变当前任务的文件范围、需求解释或验收标准，则当前任务直接保持 `blocked`，不得提前 `preflight`

这样可以同时满足两件事：

- 允许 Task N 执行期间对 Task N+1 做安全的只读准备
- 避免在依赖仍可能重写任务边界时，做出无效甚至误导性的 `preflight`

### 各状态定义

- `queued`
  - 任务已存在，但尚未开始准备
- `preflight`
  - 只读准备阶段，不写代码
- `ready`
  - 所有必要上下文、依赖、写集判断已完成，可安全启动 implementer
- `implementing`
  - 正在由 implementer 修改代码或文档
- `spec_review`
  - 规格一致性审查中
- `quality_review`
  - 代码质量审查中
- `done`
  - 任务完全闭环
- `blocked`
  - 依赖未满足或冲突域未释放

### 流水线示意

```text
Task N:
  implementing -> spec_review -> quality_review -> done

Task N+1:
  preflight -> ready

Task N+2:
  queued / blocked
```

这个设计的目的不是让所有任务同时写代码，而是让主线程在 Task N 执行期间，提前把 Task N+1 的准备工作做完。

#### Pipeline SDD 的强制重叠契约

为了确保流水线化不是“只在 reviewer 阶段做一点准备”的弱优化，
本次设计把下面两种重叠都列为 Pipeline SDD 的必备能力：

1. `implementer + preflight`
2. `reviewer + preflight`

也就是说，在 Pipeline 模式下：

- 当 Task N 处于 `implementing` 时，系统应尽量推进 Task N+1 的 `preflight`
- 当 Task N 处于 `spec_review` 或 `quality_review` 时，系统也应继续推进后续任务的 `preflight`

只有这样，才能真正减少“实现阶段主线程空等唯一子代理”的体验问题。

---

### 4.4 `preflight` 的职责边界

`preflight` 是第一阶段最关键的新概念。

它只允许做只读工作，包括：

1. 读取必要文件
2. 抽取当前任务的最小上下文
3. 分析依赖与前置条件
4. 标记写集与冲突域
5. 估算合适的模型档位
6. 预生成 reviewer 输入骨架
7. 识别是否需要额外的风险说明

`preflight` 明确不做的事：

1. 不写代码
2. 不修改 plan
3. 不直接替代 implementer
4. 不绕过 review

这保证了第一阶段的流水线优化主要来自“准备工作重叠”，而不是危险的写并发。

---

### 4.5 `writing-plans` 需要增加的最小元数据

当前计划文档已经足够支持执行，但不足以支撑安全调度。  
因此每个任务增加一个轻量元数据块：

```md
**Execution Metadata:**
- Depends on: Task 1, Task 2
- Write Set:
  - `skills/subagent-driven-development/SKILL.md`
  - `tests/prompt-contracts/test-pipeline-routing.sh`
- Conflict Group: `workflow-contracts`
- Risk Level: medium
- Parallelizable: preflight-only
```

第一版只增加五个字段：

1. `Depends on`
2. `Write Set`
3. `Conflict Group`
4. `Risk Level`
5. `Parallelizable`

#### 字段 schema

- `Depends on`
  - 取值：`none` 或逗号分隔的任务引用，例如 `Task 1, Task 2`
  - 允许多值
  - 只控制进入 `ready` / `implementing` 的门槛

- `Write Set`
  - 取值：一个或多个精确文件路径，或以 `/**` 结尾的目录前缀
  - 不允许自由 glob，例如裸 `*`
  - 允许多值
  - 作用是让 planner 和执行器都能稳定判断潜在冲突

- `Conflict Group`
  - 取值：单个 slug，例如 `workflow-contracts`
  - 不允许多值
  - 用于更粗粒度地拦截“虽然文件暂时不同，但实际上属于同一修改域”的并发

- `Risk Level`
  - 取值：`low | medium | high`
  - `high` 直接拥有降级到 `Serial SDD` 的最高优先级

- `Parallelizable`
  - 取值：`no | preflight-only | yes`
  - `no`：不允许升级到 `Parallel Dispatch`
  - `preflight-only`：允许流水线准备重叠，但不允许真并行写
  - `yes`：具备升级到 `Parallel Dispatch` 的资格，但仍需服从风险、依赖、冲突域判断

其中：

- `Depends on` 用于决定任务是否可以进入 `ready`
- `Write Set` 用于识别潜在文件冲突
- `Conflict Group` 用于粗粒度拦截同域并行写入
- `Risk Level` 用于决定是否应降级回 Serial SDD
- `Parallelizable` 用于表达 planner 的显式判断与上限

#### planner 产出约束

为保证 schema 可稳定实现，planner 必须遵守：

1. 每个任务都必须填写完整的 `Execution Metadata`
2. `Write Set` 优先写精确路径，只有在任务天然覆盖目录时才使用 `/**`
3. `Conflict Group` 需在整份 plan 中复用同一套命名，不允许同义重复
4. 如果 planner 无法稳定判断 `Parallelizable: yes`，必须降级为 `preflight-only` 或 `no`

这个设计避免了一开始就把 plan 变成过于沉重的调度 DSL。

---

### 4.6 第一阶段允许的并发形式

为了降低风险，第一阶段只开放以下重叠：

1. 一个 implementer + 一个 preflight agent
2. 一个 implementer + 一个 reviewer
3. 一个 reviewer + 一个 preflight agent
4. 主线程 + 任意只读准备工作

第一阶段明确不承诺：

1. 多个 implementer 在同一冲突域并发
2. 在没有计划元数据支持的情况下自动多 lane 写并发

因此，现有 red flag 不会被简单删除，而会被更细粒度地改写为：

- 禁止同一冲突域的多个 implementation subagent 并发写入
- 允许 reviewer、preflight 与 implementer 重叠
- 允许只读 agent 并发

---

### 4.7 子代理产品定位与文案修正

本次设计要求统一以下叙事：

### `subagent-driven-development`

默认定位为：

- 质量优先执行器
- 默认进入 Pipeline SDD
- 首要价值是上下文隔离、角色分工、质量门禁与编排弹性

### `dispatching-parallel-agents`

默认定位为：

- 独立问题域并发器
- 仅在任务独立、写集分离、风险可控时使用

这样可以避免用户将“子代理”直接等价理解为“天然并发提速工具”。

---

## 5. 影响范围

### 5.1 必改文件

- `skills/using-superpowers/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `skills/subagent-driven-development/SKILL.md`
- `skills/dispatching-parallel-agents/SKILL.md`
- `docs/README.codex.md`

### 5.2 可能新增或改造的测试

- prompt-contract 测试：验证三种执行模式与路由语义
- transcript 级测试：验证是否存在 `preflight` / `review` / `implementation` 的重叠推进
- 冲突测试：验证同一 `Conflict Group` 下不会出现双 implementer 并发
- schema 测试：验证 `Execution Metadata` 的字段格式、合法值与 planner 输出一致性

---

## 6. 验收标准

本次设计以以下结果验收：

1. README 与 skill 文案明确区分 Serial SDD、Pipeline SDD、Parallel Dispatch 三种模式。
2. `writing-plans` 的任务结构新增最小执行元数据块，并明确字段格式、合法值与 planner 约束。
3. `subagent-driven-development` 的流程文档引入 `queued / preflight / ready / implementing / spec_review / quality_review / done / blocked` 状态语义。
4. Pipeline SDD 明确要求支持 `implementer + preflight` 与 `reviewer + preflight` 两类重叠，而不是只在 reviewer 阶段做准备。
5. 第一阶段规则明确允许 reviewer / preflight overlap，但禁止同冲突域的多 implementer 写并发。
6. 路由优先级固定为：`Risk Level` > 依赖是否改写任务边界 > `Conflict Group` / `Write Set` > `Parallelizable`。
7. 测试可以证明：
   - 主线程在 implementer 与 reviewer 期间都会继续推进只读准备工作
   - 不会出现同冲突域双写
   - `Execution Metadata` 的 schema 可被稳定产出与校验
   - 新的路由语义不会退化成旧的单一路径叙事
8. `dispatching-parallel-agents` 被定义为执行期独立 lane 的合法升级路径，而不再只是调试场景的孤立技巧。

---

## 7. 分阶段落地建议

### Phase 1：流水线化

目标：

- 先把“主线程空等唯一子代理”的体验打掉

范围：

- 给 `writing-plans` 增加最小 `Execution Metadata`
- 增加 `preflight`
- 调整 `subagent-driven-development` 状态机
- 更新 README 与核心技能说明

### Phase 2：能力路由

目标：

- 明确什么时候走 Serial SDD、什么时候走 Pipeline SDD、什么时候走 Parallel Dispatch

范围：

- 更新 `using-superpowers`
- 补充路由测试

### Phase 3：受控真并行

目标：

- 仅在 metadata 足够可靠时，允许多 lane 实现代理并发

范围：

- 基于 `Conflict Group` 与 `Write Set` 开放更激进的并发策略
- 增加冲突与集成屏障测试

---

## 8. 最终判断

如果不并行，子代理依然有价值；  
但那份价值主要来自隔离、分工和审查，而不是吞吐。

因此，本次设计不把“默认全并行”作为目标，而是选择：

**默认流水线化，条件满足时再并行化。**

这比直接把系统改成多写手并发更稳，也更符合当前 `superpowers` 以技能文案、prompt 契约和 transcript 验证为主的架构现实。
