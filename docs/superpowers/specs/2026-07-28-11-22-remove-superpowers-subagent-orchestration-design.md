# 移除 Superpowers 子代理编排、增加 Cursor reviewer 模型路由、改为批量 review

日期: 2026-07-28
状态: 已实施

## 背景与动机

Superpowers 当前的子代理编排机制（`subagent-driven-development`、`dispatching-parallel-agents`、`using-git-worktrees`）是为能力较弱的模型设计的：把工作拆成小块、派发给独立子代理、每步强制审查。在当前一代强模型下，模型自身已能判断何时需要子代理并自行创建，这套外部编排反而成为负担：

1. 强制的 per-task review 循环（实现 → 审查 → 修改 → 再审查 → 下一个任务）带来大量往返开销。
2. 固定的 worktree 隔离前置步骤在多数场景下并无必要。
3. 三模式路由（`Serial SDD` / `Pipeline SDD` / `Parallel Dispatch`）把模型本可自主完成的判断固化成了流程分支。

同时存在两个独立诉求：Cursor 环境下 reviewer 始终落在 `general-purpose`，没有用上高思考强度模型；以及 review 时机应从逐任务改为批量。

## 目标

1. 彻底移除 Superpowers 自有的子代理编排机制，reviewer 除外。
2. 为 Cursor 增加 reviewer 模型路由，支持按父模型选择最高思考强度，并保留兜底。
3. 把 plan 执行过程中的 per-task review 改为全部任务完成后的统一批量 review。

## 非目标

- 不改动 `docs/superpowers/plans` 与 `docs/superpowers/specs` 下的历史记录文档。历史记录保留原状，仅活跃行为定义与治理规范同步。
- 不移除 reviewer 机制本身。reviewer 是明确保留并强化的部分。
- 不改动 endgate / carrier 协议相关内容。

## 已确认的范围决策

| 决策项 | 选择 |
|---|---|
| 移除范围 | 活跃 skill 面 + 治理规范重写，历史文档保留 |
| `subagent-driven-development` | 删除 |
| `using-git-worktrees` | 删除 |
| `dispatching-parallel-agents` | 删除 |
| `Execution Metadata` 字段 | 移除 `Write Set` / `Conflict Group` / `Parallelizable`，保留 `Depends on` |
| granted 分支落点 | 统一为 `executing-plans` |
| Session consent 状态机 | 移除 |
| Reviewer 派发方式 | 预置 subagent 文件 + 模型档位表 |
| 每任务自动化验证 | 保留 |
| 批量 review 循环上限 | 3 次，超出上交人类 |

## 第一部分：移除子代理编排

### 删除的文件与目录

- `skills/using-git-worktrees/`（整个目录）
- `skills/subagent-driven-development/`（整个目录，含 `implementer-prompt.md`、`spec-reviewer-prompt.md`、`code-quality-reviewer-prompt.md`）
- `skills/dispatching-parallel-agents/`（整个目录）
- `tests/subagent-driven-dev/`（整个目录）
- `tests/claude-code/test-worktree-native-preference.sh`
- `openspec/specs/subagent-execution-routing/`（整个目录）

`subagent-execution-routing` 整份规范建立在 SDD 状态机与并行路由之上，其每一条 Requirement 都随着编排机制消失而失去主体，因此整份删除而非重写。

### 活跃 skill 引用改写

`skills/writing-plans/SKILL.md` 是改动核心：

- 第 85 行的 REQUIRED SUB-SKILL 提示改为只指向 `executing-plans`。
- Execution Handoff 段（约 263-272 行）移除 granted / denied 双分支，统一落到 `executing-plans`；删除「Choosing `Subagent-Driven` counts as explicit session-scoped consent」整条。
- `Execution Metadata` 段落及 planner constraints 中关于 `Write Set` / `Conflict Group` / `Parallelizable` 的要求一并移除。

`skills/executing-plans/SKILL.md`：

- 第 14 行删除「If subagents are available, use superpowers:subagent-driven-development instead of this skill」。移除后 `executing-plans` 是唯一执行路径，不应再自我贬低。

`skills/using-superpowers/SKILL.md`：

- `## Session-Scoped Subagent Consent` 整节删除。
- `## Subagent Execution Modes` 整节删除（三模式随编排机制消失）。
- 环境说明处（约 47-49 行）在 Gemini 与 other environments 之间补入 Cursor 条目，指向新增的 `references/cursor-tools.md`。

`skills/using-superpowers/references/codex-tools.md`：

- 第 25 行去掉 `dispatching-parallel-agents` 与 `subagent-driven-development` 具名引用。
- 第 46 行去掉 `using-git-worktrees` Step 0 引用。

`skills/finishing-a-development-branch/SKILL.md`：

- 第 304 行删除 SDD 触发条目，第 308 行删除 worktree 可选配对条目。

`skills/spec-governed-development/SKILL.md`：

- 第 184、207 行「使用 `subagent-driven-development` 或 `executing-plans`」收敛为单一 `executing-plans`。

`skills/writing-skills/render-graphs.js`：

- 第 96-97 行示例路径替换为仍然存在的 skill 目录。

`skills/brainstorming/SKILL.md`：

- Design Artifact Review Loop 中依赖 consent 状态的措辞改写为直接派发 reviewer。

`skills/writing-plans/SKILL.md` 的 `## Plan Review Loop`：

- 该段自身也有一套 `unknown` / `granted` / `denied` 判断（约 191-194 行），与 Execution Handoff 的 consent 是两处独立位置。consent 状态机整体移除，两处必须一并改写为直接派发 reviewer。遗漏此处会留下引用已删除状态机的悬空逻辑。

### 治理规范同步

`openspec/specs/workspace-execution-context/spec.md`：清除对 `using-git-worktrees` 与 `subagent-driven-development` 的具名引用。该规范「默认使用当前工作区、隔离仅显式 opt-in」的核心主张在移除后依然成立且更彻底，故保留并改写引用，不整份删除。

其余 `openspec/specs/` 下规范逐个核查具名引用。

### 对外声明同步

- `.codex-plugin/plugin.json` 技能白名单移除已删除的 skill 条目。
- `.claude-plugin/`、`.cursor-plugin/`、`.opencode/` 下的技能声明同步核查。
- `README.md`、`RELEASE-NOTES.md` 技能列表同步。
- `AGENTS.md`、`CLAUDE.md`、`GEMINI.md` 中的具名引用核查。

### 测试契约

- `tests/prompt-contracts/test-subagent-session-consent.sh` 整体失效（consent 状态机已移除），删除该文件。
- `tests/prompt-contracts/test-autonomous-continuation.sh`、`tests/explicit-skill-requests/` 下引用逐个核查修正。
- `tests/prompt-contracts/test-machine-readable-workflow-contracts.sh` 中针对已删除 reviewer 模板的断言移除，保留 plan / spec / code reviewer 三者的尾块断言。

## 第二部分：Cursor reviewer 模型路由

### 平台能力调研结论

Cursor 自定义 subagent 支持 5 个 frontmatter 字段：`name`、`description`、`model`、`readonly`、`is_background`。`model` 接受 `inherit` 或具体模型 ID，并支持括号参数语法 `model: gpt-5.5[effort=xhigh]` 设置思考强度。

关键约束（决定实现路径）：Cursor 官方确认，从 chat 即时派发的 subagent 存在「父模型 reasoning effort 天花板」，父级为 `high` 时无法派发 `xhigh` 子代理；但自定义 subagent 文件不受此限制。官方原话是这个上限「only applies to spawning subagents on the fly from chat」。

因此本需求必须通过预置 subagent 文件实现，不能靠运行时在 prompt 里协商模型。若实现为「让 agent 派发时自行选择最高强度」，会撞上天花板并静默降级。

另有两处已知不确定性，需在文档中标注：

1. 括号参数语法被官方标注为 isn't officially documented yet，且不适用于 CLI `--model` 参数（CLI 需要 `gpt-5.3-codex-xhigh` 这类完整 slug）。
2. `inherit` 能否附带 `[effort=]` 参数没有官方证据。本设计通过「默认 `inherit` 不带参数 + 需要提效时走具名模型档位」绕开该未知。

`reasoning_effort` 作为独立 frontmatter 字段可用但未在官方文档列出；文档化写法是 `model: id[effort=xhigh]`。档位表同时列出两种写法。

### 新增 `skills/using-superpowers/references/cursor-tools.md`

与既有 `codex-tools.md`、`gemini-tools.md` 同构，包含两部分：

工具名映射表：`Task` 工具、`TodoWrite`、`Skill`、文件与 shell 工具的 Cursor 等价物。

Reviewer 模型档位表，实现三级降级链：

| 档位 | 条件 | 配置 |
|---|---|---|
| 1 | 父模型非 `gpt-5.6-sol` | 该族最高思考强度，`model: <family>[effort=<max>]` |
| 2 | 父模型为 `gpt-5.6-sol` | `model: gpt-5.6-sol[effort=xhigh]` |
| 3 | 前两级因 plan 限制、admin 屏蔽或 Max Mode 缺失不可用 | 回落 `general-purpose` |

模型 ID 只出现在这一个文件中，skill 正文通过间接引用消费，隔离模型 ID 的易变性。

### 新增 `agents/` 目录与 reviewer 文件

`.cursor-plugin/plugin.json` 已声明 `"agents": "./agents/"` 但该目录不存在，本次补上。为保留的三个 reviewer 各建一个文件：

- `agents/plan-reviewer.md`
- `agents/spec-reviewer.md`
- `agents/code-reviewer.md`

统一使用 `readonly: true`。评审不应修改文件，而当前 `general-purpose` 派发是带写权限的，这是顺带修掉的真实风险。默认 `model: inherit`，档位提升在档位表中说明。

### Reviewer 模板改写

以下三处 `Task tool (general-purpose):` 改为指向档位表的间接引用：

- `skills/writing-plans/plan-document-reviewer-prompt.md` 第 12 行
- `skills/brainstorming/spec-document-reviewer-prompt.md` 第 12 行
- `skills/requesting-code-review/code-reviewer.md` 第 8 行
- `skills/requesting-code-review/SKILL.md` 第 34 行同步

### 新增测试

`tests/prompt-contracts/` 下新增契约测试，断言 `cursor-tools.md` 档位表结构完整、三级降级链齐备，风格与既有 `test-machine-readable-workflow-contracts.sh` 一致。

## 第三部分：批量 review

### 保留与移除的边界

保留每个 task 的自动化验证。`executing-plans` Step 2 的 `Run verifications as specified` 不动，真实错误仍在当场被测试捕获。

移除每个 task 后的 reviewer 子代理派发。省掉的是每轮 reviewer 的往返开销，而非测试保护。

### `skills/requesting-code-review/SKILL.md` 改动

`## When to Request Review` 的 Mandatory 列表：删除「After each task in subagent-driven development」，改为「After all plan tasks complete」。

`## Integration with Workflows`：`Subagent-Driven Development` 整节删除；`Executing Plans` 的「Review after each task or at natural checkpoints」改写为批量语义——全部 task 完成且各自验证通过后，一次性派发 reviewer，覆盖 plan 起点到当前 HEAD 的完整 diff。

`## How to Request` 的 SHA 取法：当前 `BASE_SHA=$(git rev-parse HEAD~1)` 是单 task 增量，改为取执行 plan 之前的基线 commit，覆盖全部 task 的累积改动。

`## Example` 整体重写。现有例子是「完成 Task 2 → review → 修 → 继续 Task 3」，与批量模式直接矛盾，替换为「全部 task 完成 → 一次 review → 集中修 → 复审」。

`## Red Flags` 保留，但「Proceed with unfixed Important issues」重新表述：批量模式下它约束的是「复审未通过就进入 finishing」，而非「进入下一个 task」。

### `skills/executing-plans/SKILL.md` 改动

在 Step 3（进入 `finishing-a-development-branch`）之前插入统一 review 阶段：

1. 全部 task 完成并各自验证通过。
2. 派发 reviewer，覆盖完整累积 diff，以 plan 全文作为对照基准。
3. 集中修复发现的问题。
4. 复审。循环上限 3 次，与 `writing-plans`、`brainstorming` 现有 review loop 约定一致；超出上限上交人类。
5. 通过后进入 `finishing-a-development-branch`。

### 已知权衡

批量 review 的 diff 面积显著大于单 task，reviewer 的上下文压力与漏检风险都会上升。这是效率换来的代价。缓解手段是让 reviewer 拿到 plan 全文作为对照基准（而非单个 task 描述），该要求写入模板。

## 验证方式

1. 全仓库检索三个已删除 skill 名，确认活跃面（`skills/`、`tests/`、`openspec/specs/`、插件声明、README、`docs/testing.md`、`docs/README.codex.md`）零残留，仅 `docs/superpowers/plans`、`docs/superpowers/specs`、`openspec/changes/archive/` 与 `RELEASE-NOTES.md` 下历史记录保留。
2. 运行 `tests/prompt-contracts/`、`tests/codex/`、`tests/shared/` 下契约测试，确认无新增失败。
3. 确认 `agents/` 下三个 reviewer 文件的 frontmatter 合法。
4. 确认 `cursor-tools.md` 三级降级链完整。

## 实施结果

18 个契约测试套件中 17 个通过，共 639 条断言。

`tests/codex/test-endgate-wrapper-filter.sh` 失败，但已通过 `git stash` 对照验证：改动前 baseline 同样 `exit=1`，属于既有失败，不在本次范围内。

### 实施中发现的、设计阶段遗漏的改动面

设计评审（由 spec reviewer 执行）发现 4 处遗漏，实施中另发现若干处，均已修正：

- `tests/prompt-contracts/test-universal-terminal-endgate-protocol.sh` 的 `SKILL_FILES` 硬编码数组含三个待删 skill 路径
- `tests/prompt-contracts/test-subagent-pipeline-routing.sh`、`tests/codex/test-subagent-pipeline-routing-fixtures.sh`、`tests/prompt-contracts/test-worktree-execution-lifecycle.sh` 整体失效，已删除
- `docs/README.codex.md` 的 consent 与三模式两节，以及多处具名引用
- `writing-plans` 的 `## Plan Review Loop` 自带一套 consent 判断，与 Execution Handoff 的 consent 是两处独立位置
- `tests/claude-code/run-skill-tests.sh` 与 `tests/claude-code/README.md` 的测试数组与文档条目
- `docs/testing.md` 的整节 `Integration Test: subagent-driven-development`
- `tests/explicit-skill-requests/` 下 5 个 prompt 与 4 个脚本把 SDD 硬编码为被测技能，已改为指向 `executing-plans` / `systematic-debugging` 以保留原测试意图
- `tests/skill-triggering/run-all.sh` 的 `SKILLS` 数组

### 实施中修正的一处设计错误

设计文档原本要求保留 `dispatching-parallel-agents` 并保留 `Execution Metadata`。用户随后明确要求彻底移除 Superpowers 自有子代理编排（reviewer 除外），因此该 skill 一并删除，`Execution Metadata` 的 `Write Set` / `Conflict Group` / `Parallelizable` 三个字段失去全部消费者后移除，仅保留 `Depends on` 用于任务排序。`openspec/specs/subagent-execution-routing/` 整份删除。

### 一次真实的反面案例

实施初期，本 agent 用 `explore` subagent 派发设计评审，结果落在 MiMo Pro 这个快速小模型上——恰好是需求 2 要修复的问题。根因是 Cursor 内置 `explore` 故意绑定快速模型，且不继承父模型。这印证了档位表中「必须通过预置 subagent 文件实现，不能靠运行时协商模型」这条约束的必要性，也促使实施顺序调整为先建立 reviewer 能力、再用它审后续工作。该案例已写入 `cursor-tools.md` 作为显式禁令。
