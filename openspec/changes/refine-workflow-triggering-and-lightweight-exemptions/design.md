## Context

当前仓库的过度拉起主要来自四个叠加因素：

1. bootstrap 层把 `using-superpowers` 作为高优先级运行时契约注入，使 workflow 倾向于优先接管会话；
2. `using-superpowers` 中“哪怕 1% 可能适用也必须用 skill”的规则，把 skill 发现扩大成了默认入口；
3. `brainstorming` 与 `test-driven-development` 的适用描述覆盖面过宽，无法天然区分“行为改动”和“纯文本改动”；
4. strict packet mode 的终局协议在实现上被广义套用，导致普通问答也可能被当成 workflow terminal boundary 处理。

用户已经给出新的产品决策：

- 未显式使用 skill，且未命中 workflow 关键词时，默认不要拉起 Superpowers；
- 即使当前已经进入整套流程，只要当前子任务属于简单问答、翻译或文本修改，也不要继续套 workflow，特别不要使用 TDD；
- 普通问答必须先直接输出结果，不能被“结束/继续”弹窗拦在前面。

这是一项跨 bootstrap、skills、文档与验证链路的治理变更，适合用 OpenSpec 记录为长期规则。

## Goals / Non-Goals

**Goals:**

- 把默认交互模式收敛为 Direct Mode，而不是默认 workflow-first。
- 允许通过显式 skill 名或宽松 workflow 关键词进入 workflow mode。
- 为轻量任务建立稳定的豁免与运行时降级规则。
- 明确 copy-only / text-only 改动的 TDD 禁用边界。
- 把 terminal-choice / `request_user_input` 收口限定在真正的 workflow-mode 边界。
- 用 prompt-contract 与 transcript 验证锁住上述行为，防止未来回归。

**Non-Goals:**

- 不移除 Superpowers 的 workflow 能力，也不改写 OpenSpec / archive 等既有治理闭环。
- 不改变 strict packet mode 在真正 workflow lane 中的 canonical carrier 语义。
- 不重做 Codex 客户端 UI，也不尝试修改 `request_user_input` 的渲染机制。
- 不把所有模糊自然语言都解释为“永远不能触发 workflow”；本次仍保留用户批准的宽松 workflow 关键词入口。

## Decisions

### 1. 采用三层模式：Direct Mode、Workflow Mode、Workflow-Scoped Direct Handling

**决策：**

- `Direct Mode` 作为默认模式。
- 只有在“显式 skill 名”或“允许的 workflow 关键词”出现时，才进入 `Workflow Mode`。
- 如果当前已经处于 `Workflow Mode`，但当前子任务被识别为轻量任务，则进入一次 `Workflow-Scoped Direct Handling`：临时按 direct 方式处理该子任务，不补跑 brainstorming/TDD，不触发 workflow terminal-choice。

**为什么这样做：**

- 纯“默认不拉起”只能解决入口问题，无法解决“流程中临时冒出一个轻量子任务仍被重流程接管”的问题。
- 纯“先询问再进”会显著增加额外交互步骤，而且用户已经将决策改为默认不自动拉起。

**替代方案：**

- 方案 A：仍保留语义自动触发，只在触发前询问一次  
  不采纳。虽然安全，但会把很多轻量任务都多出一步确认。
- 方案 B：只有显式 skill 名才允许 workflow  
  不采纳。太严格，会损失“设计一下/写计划/调试这个 bug”这类自然 workflow 意图的可用性。

### 2. 入口只接受显式信号，不再接受模糊语义猜测

**决策：**

- 显式信号包括：
  - 明确 skill 名；
  - 宽松但高意图的 workflow 关键词，例如设计、规划、调试、代码审查、执行计划等。
- 以下不再视为 workflow 入口：
  - 普通问答；
  - 翻译、总结、改写；
  - 文本/文案替换；
  - 仅凭“看起来像开发任务”的模糊语义猜测。

**为什么这样做：**

- 当前主要误触发并不是来自用户真的表达了 workflow 意图，而是来自 skill 系统把“也许相关”放大成了默认入口。
- 保留宽松关键词，能兼顾可用性与可控性。

### 3. 用“是否改变行为”作为轻量任务与 TDD 豁免的硬边界

**决策：**

- 如果当前任务不改变状态流、条件判断、数据契约、交互流程、渲染逻辑或布局结构，只修改显示文字、label、placeholder、help text、日志文案、注释、文档内容，则视为轻量任务。
- 这类任务 MUST 跳过 TDD。
- 如果任务同时包含文案修改与行为变更，则按“有行为变更”处理，允许继续走 workflow/TDD。

**为什么这样做：**

- “只是改一点 UI 文案”之所以被错误拉进 TDD，本质是系统缺少一条稳定的行为边界。
- 以“是否改行为”做判断，最容易映射到 prompt、技能文案与测试断言。

**替代方案：**

- 方案 A：给 TDD 列一堆正反面例子，但不建立统一边界  
  不采纳。例子会持续膨胀且容易漏网。
- 方案 B：完全依赖用户显式说“不要 TDD”  
  不采纳。会把明显应自动处理的轻量任务再次推回给用户兜底。

### 4. terminal-choice 只服务 workflow 边界，Direct Mode 直接结束

**决策：**

- strict packet mode、`terminal-choice` 与 `request_user_input` 的终局收口，只在当前边界仍属于 workflow mode 时适用。
- Direct Mode 回复必须先把结果直接给出，并允许正常结束。
- 对于 workflow 中被临时降级处理的轻量子任务，同样不得在结果前插入终局 popup。

**为什么这样做：**

- 用户反馈的核心问题不是“弹窗形式不好”，而是“结果被弹窗拦在前面”，这本质上是边界分类错了。
- 只要 direct replies 不再被错误归类为 workflow terminal boundary，这个问题会自然消失。

### 5. 用负向测试锁住“不该触发”的路径

**决策：**

- 新增/补强以下验证：
  - 普通问答不应触发 workflow；
  - 翻译任务不应触发 workflow；
  - UI copy-only / text-only 修改不应触发 TDD；
  - 普通问答不应先出现 terminal-choice popup；
  - 宽松 workflow 关键词仍应能合法触发 workflow。

**为什么这样做：**

- 当前测试集更偏向“该触发时能否触发”，但对“不该触发时必须压住”覆盖不足。
- 这次问题本质上就是负样本缺失导致的治理空洞。

## Risks / Trade-offs

- **[宽松关键词仍可能偶发误触发]** → 通过“轻量任务优先级高于 workflow 触发”的规则兜底；即使入口误判，也能在子任务级别降回 direct handling。
- **[不同文档/skill 容易写漂]** → 用 prompt-contract 同时审计 `.codex/instruction.md`、`README` 与关键 skills，防止只改一处。
- **[行为变化与文本变化的边界可能被混合任务模糊化]** → 明确“只要有行为变化，就不再享受 text-only 豁免”，避免为了省流程而漏掉真正需要验证的改动。
- **[部分历史文案仍强调 automatically trigger]** → 需要同步清理 README 与 Codex 文档中的旧表述，避免实现与文档互相打架。

## Migration Plan

1. 先更新 OpenSpec specs，固化“显式拉起 + 轻量任务豁免 + workflow-only endgate”的规范边界。
2. 再修改 bootstrap 与关键 skill 文案，使入口规则、轻量任务降级与 TDD 例外保持一致。
3. 同步更新 README / Codex 使用文档，移除“默认自动拉起一切相关 skill”的表述。
4. 最后补齐 skill-triggering、prompt-contract 与 Codex transcript 负向验证，确保回归可被自动发现。

## Open Questions

- 宽松 workflow 关键词的具体词表是否需要集中维护为单一文档来源，还是先以内联 guidance + 测试样例为准。
- 是否需要把“轻量任务 taxonomy”抽成独立共享段落，供多个 skills 直接引用，以减少未来文案漂移。
