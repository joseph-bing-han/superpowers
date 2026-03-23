## Why

当前仓库已经为部分关键 workflow 建立了 `terminal-choice` 与
`request_user_input` 约束，但这些规则仍停留在局部 skill 文案与
prompt-contract 层，没有被提升为正式通用协议语义。结果是：
“条件式授权”仍可能被误判为一个可自由文本收口的分析结论，而且并非
所有本地 skill 都显式继承了“完成时不得直接结束对话”的终局约束。

现在需要把这组规则正式收敛成统一协议，彻底禁止依赖用户自由输入来结束
对话的路径，确保任何 skill 在请求工作完成时都必须通过工具化的
`1. 结束 / 2. 继续 / 3. 自由输入` 终局选择来收口。

## What Changes

- 将 `contingent authorization` 正式定义为通用 workflow 协议语义：
  当用户表达“如果没问题就继续下一阶段”“如果设计合理就开始实现”等
  条件式授权时，正向判断本身即视为已满足条件并获得后续授权。
- 将 `terminal-choice` 正式定义为所有 skill 终局边界的统一收口协议：
  任何 skill 在“工作看似完成”的边界都不得直接结束对话，必须改为
  `request_user_input` 驱动的 `1/2/3` 选择。
- 明确禁止通过自由文本收尾、可选式 prose 邀请、typed free-form
  confirmation、或要求用户手动补一句自然语言来结束对话。
- 为仓库内全部本地 skill 建立显式的终局协议继承点，使 prompt-contract
  可以对每个 skill 做统一审计。
- 增加新的 prompt-contract 回归，覆盖“所有 skill 都显式继承终局协议”
  与“条件式授权后不得再 prose-only 收口”这两个治理目标。

## Capabilities

### New Capabilities

- 无

### Modified Capabilities

- `workflow-protocol-contracts`:
  将条件式授权、统一终局协议、禁止直接结束对话，升级为正式 requirement。
- `transcript-based-validation`:
  将“所有 skill 显式继承终局协议”的仓库级验证与
  “条件式授权后禁止 prose-only 收口”的回归约束纳入验证能力范围。

## Impact

- Affected code:
  - `skills/**/*.md`
  - `spec-governed-development/SKILL.md`
  - `docs/README.codex.md`
  - `tests/prompt-contracts/*.sh`
- Affected specs:
  - `openspec/specs/workflow-protocol-contracts/spec.md`
  - `openspec/specs/transcript-based-validation/spec.md`
- Affected systems:
  - skill-level workflow guidance
  - Codex `request_user_input` terminal-choice contract
  - prompt-contract regression auditing for workflow endgates
