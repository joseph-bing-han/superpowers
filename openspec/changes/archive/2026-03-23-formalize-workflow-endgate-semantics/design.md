## Context

仓库当前已经有一套三态 workflow endgate 约束：
`auto-continue`、`needs-user-decision`、`terminal-choice`。这套约束已经在
`using-superpowers`、`brainstorming`、`writing-plans`、
`executing-plans`、`subagent-driven-development` 和
`spec-governed-development` 等核心 skill 中逐步落地，也有对应的
prompt-contract 测试。

但最近的真实失败 transcript 说明仍存在两类治理缺口：

- **条件式授权没有被提升为正式协议语义**
  用户说“如果没问题就继续下一阶段”时，assistant 仍可能把“没问题”当成
  一个可以用自由文本结论块收口的分析结果，而不是一个已经满足条件、
  必须继续执行的授权判定。
- **仓库内并非所有本地 skill 都显式继承终局协议**
  这会让“不得直接结束对话”的规则只停留在少数核心 skill 上，而缺乏
  仓库级的统一可审计性。

这次改动需要同时覆盖 `openspec/`、`skills/`、`docs/` 与 `tests/`，
属于典型的跨模块治理变更。

## Goals / Non-Goals

**Goals:**

- 将 `contingent authorization` 正式定义为通用协议语义
- 将 “所有 skill 终局必须走 `request_user_input` 的 `1/2/3` 选择”
  正式定义为统一终局协议
- 从仓库层面禁止任何 skill 使用 prose-only 或 typed free-form 的对话结束方式
- 让每个本地 skill 都有显式、可测试的终局协议继承点
- 增加覆盖所有 skill 的 prompt-contract 审计，防止后续再漂移

**Non-Goals:**

- 不修改 Codex UI 本身如何渲染 `request_user_input`
- 不改变中途 blocker / destructive confirmation / execution choice
  等已有非终局枚举交互的语义
- 不要求所有正文措辞统一成单一模板
- 不处理仓库外部安装副本的同步问题；本次先以当前仓库为准

## Decisions

### 1. 将条件式授权定义为 prior authorization

当用户使用 “如果没问题就继续下一阶段”、
“如果设计合理就开始实现” 或同类表达时，
正向判断本身即视为条件满足和后续授权成立。

这样可以把真实失败 transcript 中的错误模式直接归类为协议违约，而不是
“某种不够理想的措辞”。相比只继续补更多禁止短语，这种做法更稳定，
也更容易形成统一测试规则。

备选方案：
- 只在 skill 文案里列举更多反例短语：能缓解，但不是正式语义
- 继续把这类问题视作非终局 prose drift：表达准确，但不够可执行

### 2. 用统一的 `Terminal Endgate Protocol` 覆盖所有本地 skill

为了满足“所有 skill 都不允许直接结束对话”的用户要求，
本次不只修改少数核心 skill，而是给仓库内每个本地 skill 增加一个统一的
终局协议区块，明确声明：

- 不得直接结束对话
- 若工作真正完成，则进入 `terminal-choice`
- `terminal-choice` 的直接下一个动作必须是 `request_user_input`
- 固定选项为 `1. 结束 / 2. 继续 / 3. 自由输入`

对于已有更细节 endgate 规则的 skill，保留原有专属章节，再用统一区块做
显式继承与补充；对于原先没有终局说明的 skill，统一区块提供最小契约面。

备选方案：
- 只在 `using-superpowers` 中保留全局规则，让其他 skill 隐式继承
  这种方式更省改动，但不满足“所有 skill 都显式禁止直接结束”的治理目标。

### 3. 使用仓库级 prompt-contract 审计，而不是人工 spot check

新增一个新的 prompt-contract 测试，遍历所有本地 skill 与
`spec-governed-development/SKILL.md`，要求它们都包含统一终局协议区块和
固定的 `1/2/3` 终局选择。

这比人工检查更适合长期维护，也能把这次治理目标沉淀成可持续的回归面。

### 4. 继续以工具事件和 transcript 作为终局机器契约

虽然这次会在所有 skill 中新增统一文案，但机器契约本身不回退到 prose。
真正可判定的终局协议仍然是：

- `request_user_input` 调用
- transcript 中对应的结构化事件

skill 文案只是把这条规则显式投射到每个 lane，便于约束模型和供测试审计。

## Risks / Trade-offs

- [所有 skill 都增加统一区块会显得重复] → 使用统一、短小、机械可审计的措辞，
  保留各 skill 的专属细节，避免在每个文件里复制整段长规则
- [部分 skill 实际上很少触发终局] → 用“if this skill reaches a terminal boundary”
  这种条件化表达，既保持统一约束，又不强行改变中途流程
- [终局协议与其他枚举式交互混淆] → 明确区分：
  `terminal-choice` 只用于“工作完成时的收口”，
  其他 blocker / review / destructive confirmation 继续保留各自语义
- [回归测试过于依赖固定区块名称] → 选择一个明确且稳定的统一标题，
  把它当作仓库级 audit anchor

## Migration Plan

1. 创建 OpenSpec change artifacts，明确 requirement、设计和任务边界
2. 先新增仓库级 failing prompt-contract 测试，锁定“所有 skill 显式继承终局协议”
3. 更新所有本地 skill 与 `spec-governed-development/SKILL.md`
4. 同步更新 `docs/README.codex.md` 与相关 prompt-contract 测试
5. 运行回归测试，确认：
   - 条件式授权规则成立
   - 所有 skill 都显式禁止直接结束对话
   - 终局一律改为 `request_user_input` 的 `1/2/3` 弹窗

回滚策略：

- 若统一区块命名或措辞导致误判，可保留 OpenSpec requirement 不变，
  只回滚 skill 区块的表述与测试锚点
- 若某些 skill 的流程确有特殊终局约束，允许在统一区块之外追加专属说明，
  但不得削弱统一终局协议

## Open Questions

- 是否需要在后续 change 中把这条统一终局协议同步到安装副本
  `~/.codex/superpowers` 的发布流程校验里
- 是否要为仓库外部 skill 或未来新增 skill 提供一个自动模板插入脚本
