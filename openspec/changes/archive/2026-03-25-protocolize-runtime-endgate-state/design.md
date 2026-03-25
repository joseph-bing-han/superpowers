## Context

当前仓库已经完成了两轮与 endgate 相关的治理：

- `2026-03-23-formalize-workflow-endgate-semantics`
  正式定义了 `auto-continue`、`needs-user-decision`、
  `terminal-choice` 三态语义
- `2026-03-24-close-runtime-prose-endgate-leaks`
  用 transcript 审计和 incident fixtures 把
  `prose-only next-step invitation + task_complete`
  这类运行时漏口纳入了回归

2026-03-25 的这次真实回归进一步证明，上述治理虽然已经能止血，但主约束仍然
没有真正协议化：

- invitation prose 仍然主要靠若干句式模式触发
- validator 仍然需要从 transcript 中反推 assistant “大概想表达什么状态”
- 同一 turn 中更早的普通工具调用，可能被误当成后续 endgate 的合法
  `auto-continue` 证据

本质问题不是“又漏了一个句式”，而是**endgate 边界只有行为，没有显式声明**。
只要没有一份固定的、机器可读的边界状态包，验证器就必须持续做自然语言推断。

## Goals / Non-Goals

**Goals:**

- 为 workflow 边界引入固定字段、固定枚举的 `endgate-state-packet`
- 让 validator 从“声明了什么状态”出发，再去检查“后续事件是否兑现”
- 把验证窗口收缩到“最后一份 endgate 声明之后”，彻底切断同 turn 早期工具事件
  对后续边界的误伤
- 保留现有三态 endgate 语义，但把它们升级为可观察、可验证的数据协议
- 将 prose 模式识别降级为迁移期残余安全网，而不是主约束

**Non-Goals:**

- 不修改 Codex 客户端如何渲染 `request_user_input`
- 不引入依赖大模型语义理解的“智能 endgate 分类器”
- 不取消现有 `request_user_input` transcript contract；本次是在其上增加显式状态声明
- 不要求一次性替换所有历史 fixture；迁移期允许 packet-first + prose-fallback 并存

## Decisions

### 1. 为 workflow 边界新增固定的 `endgate-state-packet`

后续实现不再只靠 prose 暗示当前边界属于哪种状态，而是要求边界显式输出一段
固定字段的机器可读状态包。当前 change 采用与仓库现有 reviewer tail block 一致的
思路：先落为固定 tail block，未来如果 Codex 提供原生结构化字段，再允许等价替换。

首版 canonical 字段最小集合为：

```text
ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: AUTO_CONTINUE | NEEDS_USER_DECISION | TERMINAL_CHOICE
ENDGATE_CHOICE_KIND: NONE | SPECIFIC_NEXT_STEP | CONTINUE_OR_STOP
ENDGATE_NEXT_ACTION: CONTINUE_WITH_TOOL | REQUEST_USER_INPUT
```

这样设计的原因：

- 字段足够少，适合在每个边界稳定复用
- `ENDGATE_STATE` 表示分类语义
- `ENDGATE_CHOICE_KIND` 表示用户是否仍需做选择，以及选择的类型
- `ENDGATE_NEXT_ACTION` 表示边界后的直接机器动作

这组字段已经足以稳定表达当前仓库的三态 endgate：

- `AUTO_CONTINUE` → `NONE` + `CONTINUE_WITH_TOOL`
- `NEEDS_USER_DECISION` → `SPECIFIC_NEXT_STEP` + `REQUEST_USER_INPUT`
- `TERMINAL_CHOICE` → `CONTINUE_OR_STOP` + `REQUEST_USER_INPUT`

### 2. validator 改为“先看声明，再看兑现”

当前 runtime 审计的主要弱点，是它要从 prose 和 turn 结构里反推出
assistant 的真实 endgate 意图。协议化之后，validator 的流程应改为：

1. 找到当前 turn 中最后一份 `endgate-state-packet`
2. 把它视为该边界的唯一声明
3. 只检查这份 packet 之后直到：
   - 下一份 packet
   - `task_complete`
   - transcript 结束
4. 判断后续事件是否兑现声明

这样做可以直接消除“同一 turn 更早的工具调用掩盖后续漏口”的问题，因为**早于
packet 的事件不再有资格为该 packet 背书**。

### 3. `task_complete` 不再被视为 endgate 的主动声明，只是终局事件

`task_complete` 只能表示“这个 turn 结束了”，不能再承担“系统处于哪个 endgate
状态”的语义。真正的状态必须由 packet 或等价结构化字段显式声明。

因此：

- 若 packet 声明 `NEEDS_USER_DECISION` 或 `TERMINAL_CHOICE`，在合法的
  `request_user_input` 之前不得出现 `task_complete`
- 若 packet 声明 `AUTO_CONTINUE`，则必须先观察到真实 continuation action，
  再允许 turn 继续收束

这可以把“是否结束 turn”与“为什么这样结束 / 是否允许这样结束”彻底拆开。

### 4. prose 检测保留，但降级为 legacy safety net

这次 change 并不主张立刻删除现有 invitation prose 检测。原因是迁移期内，
仓库会同时存在：

- 已经发 packet 的新路径
- 还没补 packet 的旧 guidance / 旧 fixture

因此 validator 需要采用以下优先级：

1. `endgate-state-packet`
2. tool / transcript 结构化事件
3. legacy prose safety net

也就是说：

- 有 packet 时，以 packet 为主
- 没 packet 时，允许暂时退回现有 prose leak 检测
- 一旦对应 lane 完成 packet 化，测试就应逐步把“缺失 packet”升级为失败

### 5. packet 采用“最后声明生效”原则

同一 turn 可能存在多个分析片段、多个 checkpoint、甚至前后两次重新判断。
为了避免 validator 必须猜“哪一段 prose 对应哪一次动作”，协议上明确：

- 一个边界只看**最后一份** packet
- 该 packet 之后的事件窗口，才是 validator 需要检查的兑现区间
- 早于最后 packet 的普通工具调用、旧判断或旧消息，一律不能为最后 packet
  提供合法性证明

这条规则也是对这次真实 bug 的直接修复：旧脚本错误地把 turn 内更早的
`exec_command` 算成了后续邀请型结尾的 `auto-continue` 证据。

## Risks / Trade-offs

- [packet 增加了 transcript 噪音] → 通过固定四字段最小集控制长度，并让 prose
  保持服务于人类阅读
- [迁移期双轨制会让 validator 复杂化] → 明确证据优先级，避免 packet 与 prose
  同权竞争
- [packet 声明和真实动作可能漂移] → 将“声明-兑现不一致”视为一类明确失败，
  而不是容忍隐式解释
- [不同平台的结构化事件能力不同] → 先以 tail block 作为平台无关的最小公约数，
  后续允许更强平台提供等价结构化字段

## Migration Plan

1. 为 `endgate-state-packet` 新增 capability spec，固定字段、枚举和值配对规则
2. 更新 `workflow-protocol-contracts`，要求 analysis / checkpoint /
   handoff / terminal 边界显式声明 packet
3. 更新 `transcript-based-validation`，将 runtime 审计改为
   packet-first，并限定验证窗口为“最后 packet 之后”
4. 为 shared helper、runtime audit、fixtures、prompt-contract 与 docs
   增加 packet 解析与断言
5. 在迁移期保留 prose safety net；待主要 lanes 完成 packet 化后，再把
   “缺失 packet”逐步升级为硬失败

回滚策略：

- 若 packet 字段设计不合适，可保留“packet-first”原则，只调整字段名和枚举
- 若某一验证脚本迁移成本过高，可暂时保持 prose safety net，但不得回退到
  turn-wide 工具调用放行模型

## Open Questions

- `ENDGATE_NEXT_ACTION` 首版是否只保留
  `CONTINUE_WITH_TOOL | REQUEST_USER_INPUT`
  两个最小枚举，还是要提前细分 `OPENSPEC_APPLY_CHANGE` /
  `OPENSPEC_ARCHIVE_CHANGE`
- Codex 若未来提供更原生的结构化 transcript 字段，是否保留 tail block 作为
  兼容层，还是让 tail block 退化为仅测试 fixture 使用
- 对已经 packet 化的 lane，何时把“缺失 packet 但 prose 看起来没问题”从
  warning 提升为 failure
