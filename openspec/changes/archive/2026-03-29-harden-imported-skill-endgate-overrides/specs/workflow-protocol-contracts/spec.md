## ADDED Requirements

### Requirement: Imported or lower-priority skill ending guidance MUST NOT relax strict packet mode
当当前仓库已经通过 repo-managed instruction、`using-superpowers` 或其他更高优先级 guidance 进入 strict packet mode 时，任何 imported、lower-priority、explore-mode、stance-only skill 中关于“无固定结尾”“just provide clarity”“continue later”或等价自由收尾的表述，都 MUST 被视为非终局语气参考，而不能削弱 `endgate-state-packet` 与后续 machine action 的硬约束。

#### Scenario: Imported explore guidance cannot authorize prose-only completion
- **WHEN** assistant 在 strict packet mode 下读取了 imported 或 lower-priority explore skill
- **AND** 该 skill 文案包含 `There’s no required ending`、`Just provide clarity`、`Continue later` 或等价自由结尾表述
- **THEN** assistant MUST 继续遵守当前仓库的 `endgate-state-packet` 契约
- **AND** MUST NOT 因该 imported guidance 直接以 prose-only report 或 recommendation 结束当前 turn

#### Scenario: Repo-managed bootstrap explicitly overrides foreign ending stances
- **WHEN** 本仓库提供 repo-managed instruction bootstrap 与核心 workflow entry skill
- **THEN** 这些 guidance MUST 明确声明 imported / lower-priority skill ending guidance 不能削弱 strict packet mode
- **AND** MUST 把 `no required ending`、`just provide clarity`、`continue later` 或等价 imported stance 视为被覆盖

