## Context

当前仓库已经把 `endgate-state-packet`、strict packet mode、`request_user_input` terminal-choice 与 transcript-based runtime audit 作为正式治理机制，但事故 transcript 证明仍存在一条跨技能漂移路径：assistant 先加载本仓库 guidance，再读取外部 / 低优先级 skill（例如 `openspec-explore`），随后被其中“无固定结尾”“just provide clarity”“continue later”之类语义带偏，在真正完成的评审边界上直接输出 prose-only recommendation 并 `task_complete`。

这个问题不是 packet 语义缺失，而是“谁有权定义结尾边界”的优先级仍不够显式。当前本仓库 tests 也主要覆盖本地 skills 与抽象化 fixtures，缺少一条贴近真实事故的 session-shaped transcript，用来锁定 imported skill drift。

## Goals / Non-Goals

**Goals:**
- 明确 repo-managed instruction 与核心 workflow skill 对 imported / lower-priority skill ending guidance 的覆盖关系。
- 把“探索型 stance 可以自由结束”与“strict packet mode 必须继续履约”之间的优先级冲突写成可审计、可验证的正式 guidance。
- 新增一条贴近真实事故的 session-shaped negative transcript fixture，并把它纳入 runtime endgate audit。
- 为 repo-managed bootstrap / core guidance 增加 prompt-contract 断言，避免未来再次被 imported skill 文案削弱。

**Non-Goals:**
- 不直接修改上游 OpenSpec system skill 的实现或发布流程。
- 不改变 `endgate-state-packet` 的字段枚举、carrier 结构或 `request_user_input` popup 语义。
- 不把 runtime transcript audit 扩展成通用任意对话质量审查器；本次只聚焦 imported-skill endgate drift。

## Decisions

### 1. 用 repo-managed bootstrap 显式声明“外部技能不得削弱 strict packet mode”

在 `.codex/instruction.md` 与 `skills/using-superpowers/SKILL.md` 中增加明确规则：凡是 imported、lower-priority、explore-mode、stance-only guidance 里的“无固定结尾 / just provide clarity / continue later / no required ending”之类表述，一旦遇到 strict packet mode 或 workflow boundary，全部视为被覆盖，不得作为直接结束 turn 的依据。

**为什么这样做：**
- 事故发生在技能优先级冲突，而不是 packet 定义缺失。
- `.codex/instruction.md` 是 repo-managed 最高优先级 bootstrap，最适合承担跨技能覆盖条款。
- `using-superpowers` 是 runtime workflow 总入口，需要同步声明该覆盖关系，避免模型只记住 packet，而忽略“其他 skill 不得削弱 packet”。

**备选方案：**
- 直接修改外部 `openspec-explore` skill：能缓解当前案例，但不解决“任何 imported skill 都可能带来相同漂移”的治理问题，而且该 skill 不由本仓库管理。
- 只加 runtime fixture、不改 guidance：只能提高事后发现率，不能强化运行时优先级提示。

### 2. 用“真实事故形态”fixture 补 runtime audit，而不是只靠抽象 negative case

新增一条 session-shaped `.jsonl` fixture，保留事故的关键结构特征：
- turn 中先出现 strict packet mode / using-superpowers / imported explore skill guidance
- assistant 最终输出 recommendation-style report
- 之后直接 `task_complete`
- 中间没有 canonical carrier，也没有 `request_user_input`

**为什么这样做：**
- 当前抽象 negative fixtures 已能拦常见 prose leak，但没有锁定“imported explore skill + report-style completion”的组合路径。
- 真实事故形态更能防止未来出现“测试都绿，但实际 transcript 又绕开”的盲区。

**备选方案：**
- 仅记录截图或文档说明，不加 transcript fixture：不可执行、不可回归。
- 直接引入完整真实 session：噪音太大，且包含大量与断言无关的上下文；应保留关键信号并做最小化 fixture。

### 3. prompt-contract 只审 repo-managed override，不直接依赖外部 skill 文件

新增/扩展 prompt-contract 时，只校验本仓库自己拥有的文件是否明确写出 imported-skill override，不把测试直接绑定到 `~/.codex/skills/openspec-explore/SKILL.md` 之类外部路径。

**为什么这样做：**
- 本仓库无法保证所有环境都存在同一份外部 skill 文件。
- 真正需要稳定的是“仓库自己的 bootstrap 是否足够强，能在运行时压住外部漂移”。

**备选方案：**
- 让测试直接 grep 外部 skill：脆弱、不可移植，也会把仓库 CI 绑到环境状态。

## Risks / Trade-offs

- **[覆盖规则更强，文案更长]** → 只在 repo-managed bootstrap 与核心入口 skill 中增加少量高信号规则，不向所有文件重复铺开事故背景。
- **[session-shaped fixture 维护成本更高]** → 只保留最小事故结构，避免复制完整 transcript 噪音。
- **[仍不能物理阻止外部 skill 被加载]** → 通过更高优先级 guidance + runtime audit 双层防线降低再发概率；外部 skill 本体修复仍可作为后续独立事项。
- **[用户可能误以为仓库已修复外部 skill 本身]** → 在文档与 design 中明确 Non-Goal：不直接修改上游 system skill。

## Migration Plan

1. 更新 OpenSpec delta specs，明确 imported-skill override 与 incident-fixture audit 要求。
2. 先写失败测试：
   - runtime transcript audit 新增 incident-shaped negative fixture
   - prompt-contract 新增 repo-managed override 断言
3. 最小修改 `.codex/instruction.md`、`skills/using-superpowers/SKILL.md`、`docs/README.codex.md` 使测试转绿。
4. 运行相关验证脚本：
   - `bash tests/codex/test-runtime-endgate-transcript-audit.sh`
   - `bash tests/prompt-contracts/test-machine-readable-workflow-contracts.sh`
   - 必要时补跑 `bash tests/prompt-contracts/test-universal-terminal-endgate-protocol.sh`
5. `openspec validate harden-imported-skill-endgate-overrides`
6. 若需要对已安装环境生效，用户拉取最新仓库后重跑 `.codex/install-codex.sh`；若 `model_instructions_file` 已指向 repo-managed 文件，则通常只需更新仓库内容即可。

## Open Questions

- 是否还需要把同类 override 文案同步下沉到更多本地 skill，而不仅是 `using-superpowers`？当前先以“最高优先级 bootstrap + 核心入口 skill + 文档 + tests”作为最小闭环。
