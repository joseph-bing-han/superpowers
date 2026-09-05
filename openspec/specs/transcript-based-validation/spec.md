# transcript-based-validation Specification

## Purpose
定义按请求范围完成、按授权继续，以及显式 legacy 协议兼容的验证要求。

## Applicability

普通 workflow 使用当前任务范围与宿主授权规则，不要求 endgate packet 或结束弹窗。
下文 version 1 carrier、terminal-choice 与历史 prose-leak fixture 的要求仅适用于
显式启用的兼容集成或历史 transcript 回放。加载 Skill、读取规范或运行仅隐藏文本的
wrapper 不能启用 legacy mode。旧 fixture 通过仅证明兼容消费者，不证明当前模型行为。

## Requirements
### Requirement: Automated validation prefers behavioral evidence over prose
自动化验证 MUST 优先使用工具调用、session transcript、stream-json 或其他结构化行为证据，而不是助手自由文本中的关键词或句式。

#### Scenario: Tool-backed interaction is validated from transcript
- **WHEN** workflow 通过工具调用完成关键动作，例如触发选择 UI 或加载 skill
- **THEN** 测试 SHALL 以 transcript 或等价结构化事件为主要断言依据

### Requirement: Validation tolerates language and style drift
当协议层信号保持一致时，自动化验证 MUST 容忍中文、英文及不同表达风格带来的正文变化。

#### Scenario: Output language changes but protocol stays stable
- **WHEN** 同一 workflow 在中文与英文条件下输出不同自然语言正文
- **THEN** 测试 MUST 依据相同的协议层信号判定通过，而不是因为措辞不同失败

### Requirement: Text-only fallbacks use fixed machine-readable signals
对于存在机器消费者、但暂时无法直接从工具事件或 transcript 中提取协议信号的流程，系统 MUST 提供固定机器可读尾块或等价结构化信号，供验证使用。普通完成不得因此被强制转换为 version 1 packet。

#### Scenario: Endgate packet prefers structured transcript carriers
- **WHEN** 显式 legacy integration 的边界已经拥有原生结构化 endgate transcript 字段
- **THEN** validator MUST 优先读取该结构化 carrier
- **AND** MUST NOT 因为用户可见终端中缺少 `ENDGATE_*` 行而判定失败

#### Scenario: Endgate packet remains parseable across transcript transports
- **WHEN** 显式 legacy integration 的边界尚未拥有原生结构化 endgate transcript 字段
- **THEN** 该边界 SHALL 通过固定字段的 `endgate-state-packet` 暴露协议状态
- **AND** validator MUST 能从 tail block 或等价结构化字段解析出
  `ENDGATE_PROTOCOL_VERSION`、`ENDGATE_STATE`、
  `ENDGATE_CHOICE_KIND` 与 `ENDGATE_NEXT_ACTION`

### Requirement: Validation distinguishes normal completion from legacy terminal choices
验证 MUST 覆盖所有本地 workflow 对共享完成规则的继承，并区分普通完成与
显式启用的 version 1 集成；不得要求每个 Skill 复制旧终局协议。

#### Scenario: Normal completion does not require a terminal popup
- **WHEN** 本次报告、审查或实现及相称验证已完成，且未启用 legacy integration
- **THEN** 验证 MUST 接受直接交付结果，不要求 packet 或 request_user_input
- **AND** MUST 将无必要的结束/继续门禁视为回归

#### Scenario: Loading instructions does not enable legacy mode
- **WHEN** transcript 只有加载 Skill、读取规范或启用显示 wrapper 的事件
- **THEN** 验证 MUST NOT 将这些事件当成 version 1 集成已获授权的证据
- **AND** MUST NOT 把普通完成误报为 missing canonical carrier

#### Scenario: Terminal-choice fixture authored payload keeps only explicit end and continue options
- **WHEN** 显式 legacy integration 或历史 fixture 回放验证 Codex terminal-choice payload
- **THEN** assistant-authored options MUST 只包含 `结束 (Recommended)` 与 `继续`
- **AND** 测试 MUST NOT 把客户端自动追加的 free-form `Other/notes` 路径误判为
  assistant-authored payload 缺失

### Requirement: Validation audits explicit workflow-trigger boundaries
自动化验证 MUST 同时覆盖“该触发时能触发”与“该压住时必须压住”的 workflow
入口边界，而不能只验证正向触发样本。

#### Scenario: Plain question fixture does not trigger workflow
- **WHEN** 验证器读取一个普通问答 transcript 或 triggering fixture
- **AND** 其中不存在显式 skill 名或 workflow 关键词
- **THEN** 测试 MUST 证明 workflow 没有被拉起
- **AND** MUST 将“未触发任何 workflow skill”视为通过条件的一部分

#### Scenario: Workflow keyword fixture still triggers workflow
- **WHEN** 验证器读取一个包含允许的 workflow 关键词的 transcript 或 triggering fixture
- **THEN** 测试 MUST 证明对应 workflow 仍可被触发
- **AND** MUST 防止本次治理把显式 workflow 意图一并误杀

### Requirement: Validation audits lightweight-task bypass and TDD suppression
自动化验证 MUST 覆盖轻量任务 bypass、text-only 改动的 TDD 抑制、以及
“普通问答不得先弹终局 popup”这三类负向路径。

#### Scenario: Copy-only change fixture does not trigger TDD
- **WHEN** 验证器读取一个仅修改 UI 文案或其他 text-only 内容的 fixture
- **THEN** 测试 MUST 证明 `test-driven-development` 没有被调用
- **AND** MUST 将其视为合法 bypass，而不是漏掉 workflow

#### Scenario: Direct answer fixture returns result without terminal popup
- **WHEN** 验证器读取一个普通问答 transcript fixture
- **THEN** 测试 MUST 证明结果先被直接输出
- **AND** MUST NOT 接受“先出现 `request_user_input` popup，再由用户选择结束后才看到结果”的路径

#### Scenario: Downgraded lightweight subtask fixture bypasses workflow popup
- **WHEN** 验证器读取一个 workflow 中临时处理轻量子任务的 transcript fixture
- **THEN** 测试 MUST 证明该子任务未触发 TDD
- **AND** MUST 证明该子任务未被 workflow terminal-choice popup 拦截

### Requirement: Conditional authorization preserves scoped completion
自动化验证 MUST 区分条件式授权下仍需执行的工作、已完成的请求和未生效的授权，
不得把条件判断本身转换为终局弹窗要求。

#### Scenario: A satisfied condition leaves authorized work
- **WHEN** 授权条件成立且仍有安全、获准的后续工作
- **THEN** 验证 MUST 要求继续执行，不接受只报告正向判断或重复询问是否继续

#### Scenario: A conditional request is complete
- **WHEN** 本次授权任务及相称验证均已完成
- **THEN** 验证 MUST 接受直接交付结果，不要求额外的结束/继续门禁

#### Scenario: An unmet condition does not authorize continuation
- **WHEN** 条件不成立
- **THEN** 验证 MUST 确认系统未执行依赖该条件的步骤，并接受判断依据及限制的报告

### Requirement: Validation audits governed bugfix context recovery guidance
自动化验证 MUST 能够确认 governed bugfix 不会跳过既有 OpenSpec 设计资产，
而是会在调试阶段明确恢复 proposal/design/spec/tasks 上下文。

#### Scenario: Bugfix guidance omits existing OpenSpec artifact recovery
- **WHEN** prompt-contract 测试审计 governed bugfix 相关 guidance
- **THEN** 测试 MUST 确认指导要求识别既有 change，并恢复相关需求、设计约束与任务状态
- **AND** MUST NOT 要求每次通读所有工件或重复读取未变化的上下文

### Requirement: Validation audits OpenSpec apply and archive auto-continuation
自动化验证 MUST 能够确认已知的 OpenSpec lane 下一步不会被降级成泛化的
继续/结束交互，前提是该步骤属于本次授权范围且所需条件已满足。

#### Scenario: Guidance reintroduces generic continue/stop gating before apply or archive
- **WHEN** prompt-contract 测试审计 OpenSpec continuation guidance
- **AND** 下一步已授权、条件满足且无实质用户决策
- **THEN** 如果文案把已知的 `openspec-apply-change` 或
  `openspec-archive-change` 下一步重新写成 generic continue/stop
  prompt、recommendation-only 结束、或只建议不续跑
- **THEN** 测试 MUST 失败

#### Scenario: Partial completion leaves the change open
- **WHEN** 用户仅要求修复一个回归或执行计划子集，且该范围已完成
- **THEN** 验证 MUST 接受本次交付并确认较大的 change 仍保持开放
- **AND** 自动执行无关任务、提前归档或把局部通过称为整体完成 MUST 失败

#### Scenario: Authorized closure continues to archive
- **WHEN** 用户授权完整收尾，change 已完成且所需审查、最终集成、规范同步和归档能力均满足
- **THEN** 验证 MUST 确认自动继续已授权归档，不新增继续/结束门禁
- **AND** 只有 proposal 已创建、PR 尚未合并或缺少归档授权时，不得据此要求归档

### Requirement: Validation audits runtime prose-endgate leaks from Codex transcripts
version 1 兼容验证 MUST 能够从显式 legacy integration 或历史回放的 Codex `.jsonl`
transcript 审计 runtime endgate，不能只验证禁止 prose-only 结束的文案。

#### Scenario: Packet-driven validation rejects an undeclared or unfulfilled ending
- **WHEN** 验证器读取一个 transcript fixture
- **AND** 同一 turn 中存在 canonical endgate carrier
- **AND** 该 carrier 后续没有得到与其状态匹配的兑现动作
- **THEN** 验证 MUST 失败
- **AND** MUST 报告 carrier declaration 与 observed event sequence 不一致

#### Scenario: Structured carrier passes without visible packet text
- **WHEN** 验证器读取一个 transcript fixture
- **AND** 当前 turn 包含结构化 endgate carrier
- **AND** 用户可见 assistant 文本中不存在可解析的 `ENDGATE_*` tail block
- **AND** 该 carrier 后续存在与其状态匹配的兑现动作
- **THEN** 验证 MUST 通过
- **AND** MUST NOT 因“终端未显示 packet 文本”而失败

#### Scenario: Legacy invitation leak still fails when the carrier is absent
- **WHEN** 验证器读取一个 transcript fixture
- **AND** fixture 明确属于 legacy 集成或历史事故回放
- **AND** 当前 turn 尚未发出 canonical endgate carrier
- **AND** 同一 turn 中最后一条 assistant 文本属于具体下一步邀请型 prose
- **AND** 该 turn 随后直接发生 `task_complete`
- **AND** 该 turn 内不存在 `request_user_input` 或可证明的 `auto-continue` 动作
- **THEN** 验证 MUST 失败
- **AND** 该路径 SHALL 作为 legacy prose safety net 被继续拦截

#### Scenario: Strict packet lanes fail when the transcript never emits a canonical carrier
- **WHEN** 验证器读取的 transcript 明确属于已启用的兼容 strict packet lane
- **AND** 当前 turn 既没有结构化 endgate carrier，也没有可解析 tail block
- **THEN** 验证 MUST 失败
- **AND** MUST 优先报告 missing canonical carrier，而不是把缺失 carrier 当成可接受的 prose-only 分支

### Requirement: Validation MUST keep an incident-shaped transcript fixture for imported-skill endgate drift
自动化验证 MUST 保留至少一条贴近真实事故的 session-shaped transcript fixture，用来锁定“assistant 读取 imported explore guidance 后，仍以 prose-only recommendation + `task_complete` 结束”的漂移路径，而不能只依赖抽象化 prose leak 样本。

#### Scenario: Session-shaped imported-skill incident fixture fails runtime endgate audit
- **WHEN** validator 读取一个 session-shaped transcript fixture
- **AND** 该 fixture 中先出现 strict packet mode 证据与 imported explore guidance
- **AND** 后续 assistant 以 report-style recommendation 收尾
- **AND** 该 turn 直接发生 `task_complete`
- **AND** 该 turn 中不存在 canonical carrier、`request_user_input` 或合法 auto-continue action
- **THEN** runtime endgate audit MUST 失败
- **AND** MUST 将其归类为 imported-skill / prose-only endgate drift 的负样本

### Requirement: Validation respects host priority when importing skill guidance
prompt-contract 验证 MUST 确认 bootstrap、workflow 入口与使用文档服从宿主优先级、
用户范围和工具可用性。显式 legacy 协议也不得覆盖更高优先级指令。

#### Scenario: A stricter imported instruction conflicts with the host
- **WHEN** prompt-contract 测试审计 `.codex/instruction.md`、`skills/using-superpowers/SKILL.md` 或相关 Codex 使用文档
- **THEN** 测试 MUST 拒绝“Skill 覆盖系统规则”或“更严格即优先”的规定
- **AND** MUST 确认缺少或禁止 choice tool 时允许宿主支持的普通交互

### Requirement: Validation audits reviewer dispatch contracts
自动化验证 MUST 能够审计 reviewer 派发相关的 prompt/docs contract，
包括 reviewer 只读要求与平台特定的 reviewer 模型选择，
而不是只在实现完成后依赖人工解释。

#### Scenario: Prompt-contract suite checks reviewer dispatch semantics
- **WHEN** 仓库运行 reviewer 相关的 prompt-contract 测试
- **THEN** 测试 MUST 断言 reviewer 派发以只读方式运行
- **AND** MUST 断言平台特定的 reviewer 模型选择合同存在

#### Scenario: Reviewer receives a partial plan assignment
- **WHEN** 只有部分计划任务属于本次请求
- **THEN** 验证 MUST 确认 REVIEW_SCOPE 随计划、diff 与验收条件一起传给 reviewer
- **AND** MUST 覆盖延期任务不算缺失功能、获准任务的真实缺陷仍被报告两个方向

### Requirement: Validation audits current-workspace execution contracts
自动化验证 MUST 能审计现行 workflow 已将“当前工作区默认执行”收敛为正式合同，并把 worktree 从默认前置降为显式 opt-in 能力。

#### Scenario: Prompt-contract suite rejects dedicated-worktree prerequisites in active workflows
- **WHEN** 验证器审计 `brainstorming`、`writing-plans`、`executing-plans`、`finishing-a-development-branch` 与 README 等现行入口文档
- **THEN** 测试 MUST 拒绝“必须先进入 dedicated worktree”或等价默认前置语句
- **AND** MUST 证明这些文档把当前工作区执行写成默认路径

#### Scenario: Validation allows optional isolation only behind explicit request semantics
- **WHEN** 验证器审计仍然保留的 worktree / isolated workspace 文档
- **THEN** 测试 MUST 证明它们只以显式 opt-in 或条件性步骤出现
- **AND** MUST NOT 把它们判定为现行默认 workflow 的必经环节

### Requirement: Validation anchors endgate audits on the last declared packet
当 transcript 中存在 `endgate-state-packet` 时，validator MUST 以当前 turn
最后一份 packet 作为 endgate 审计锚点，并只审计该 packet 之后的事件窗口。

#### Scenario: Prior tool call does not satisfy a later packet
- **WHEN** transcript 在最后一份 `endgate-state-packet` 之前已经存在普通工具调用
- **AND** packet 之后没有新的合法 continuation action
- **THEN** validator MUST 将该 turn 判定为未兑现的 endgate
- **AND** MUST NOT 用 packet 之前的工具调用为其放行

### Requirement: Validation distinguishes needs-user-decision from terminal-choice by protocol data
对于都以 `request_user_input` 作为直接动作的 endgate 状态，validator MUST 依赖
packet 字段与 popup 结构，而不是 prose 文案，来区分
`NEEDS_USER_DECISION` 与 `TERMINAL_CHOICE`。

#### Scenario: Needs-user-decision expects a non-terminal request_user_input payload
- **WHEN** packet 声明 `ENDGATE_STATE=NEEDS_USER_DECISION`
- **THEN** validator MUST 观察到 `request_user_input`
- **AND** 该 payload MUST 对应具体下一步选择
- **AND** MUST NOT 被当作 terminal-choice popup 通过

#### Scenario: Terminal-choice expects the canonical terminal_choice popup
- **WHEN** packet 声明 `ENDGATE_STATE=TERMINAL_CHOICE`
- **THEN** validator MUST 观察到 `request_user_input`
- **AND** 其问题标识 MUST 对应 `terminal_choice`
- **AND** assistant-authored options MUST 继续只包含
  `结束 (Recommended)` 与 `继续`

### Requirement: Validation keeps prose matching as a secondary safety net only
当 `endgate-state-packet` 已经存在时，validator MUST 以 packet 和后续事件序列
作为主断言依据；invitation prose 模式匹配只能作为补充诊断，不能覆盖 packet
已经声明出的正式状态。

#### Scenario: Packet presence suppresses prose-first classification
- **WHEN** transcript 中已经存在可解析的 `endgate-state-packet`
- **THEN** validator MUST 优先根据该 packet 与其后的事件窗口做判定
- **AND** prose 模式匹配 MAY 作为错误说明的一部分
- **AND** prose 模式匹配 MUST NOT 取代 packet 成为主合规依据

### Requirement: Validation MUST audit OpenSpec lane-entry ordering from transcripts
自动化验证 MUST 能从 transcript fixture 中识别 OpenSpec lane decision、
ordinary design/plan docs 创建，以及 OpenSpec change 创建等关键顺序证据，
并在正式记录归属尚未解决且会实质影响工作时，拒绝先创建冲突文档。

#### Scenario: Negative fixture fails when ordinary docs precede lane confirmation
- **WHEN** 验证器读取一个 session-shaped transcript fixture
- **AND** fixture 的场景明确要求先解决正式记录归属
- **AND** 该 fixture 中普通设计文档或普通计划文档的创建事件早于
  OpenSpec lane confirmation
- **THEN** 验证 MUST 失败
- **AND** MUST 报告 ordinary docs 在 lane decision 之前落地

#### Scenario: Positive fixture passes when lane confirmation happens first
- **WHEN** 验证器读取一个 session-shaped transcript fixture
- **AND** 存在影响正式记录归属的未决问题
- **AND** 该 fixture 中 assistant 先完成 OpenSpec lane confirmation
- **AND** 之后才创建普通 docs fallback 或 OpenSpec change
- **THEN** 验证 MUST 通过
- **AND** MUST 将 lane decision 顺序视为合法

#### Scenario: An existing authorized lane needs no confirmation
- **WHEN** 用户已经指定 change 或已批准正式记录位置
- **THEN** 验证 MUST 允许直接继续对应工作，不要求新的 lane confirmation
- **AND** 无治理要求的明确低风险任务也不得被强制创建 proposal

### Requirement: Validation MUST audit unresolved lane guards across downstream skills
自动化验证 MUST 覆盖 `brainstorming` 与 `writing-plans` 的 unresolved lane guard，
防止实质记录归属未决时提前创建重复设计真相源；已选定的路线不得再次审批。

#### Scenario: Prompt-contract fails if brainstorming omits unresolved lane guard
- **WHEN** prompt-contract 测试审计 `skills/brainstorming/SKILL.md`
- **AND** 文案允许在正式记录归属实质未决时创建冲突设计文档
- **THEN** 测试 MUST 失败

#### Scenario: Prompt-contract fails if writing plans omits unresolved lane guard
- **WHEN** prompt-contract 测试审计 `skills/writing-plans/SKILL.md`
- **AND** 文案允许在正式记录归属实质未决时创建冲突计划文档
- **THEN** 测试 MUST 失败

#### Scenario: Prompt-contract keeps the entry guard and downstream guards aligned
- **WHEN** prompt-contract 测试同时审计 `using-superpowers`、`brainstorming`
  与 `writing-plans`
- **THEN** 测试 MUST 确认三者都表达出相同的核心约束：
  只对会实质影响正式记录归属的未决问题设置门禁，已授权路线直接复用
