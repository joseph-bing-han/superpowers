## MODIFIED Requirements

### Requirement: Repository-managed workflow boundaries run in strict packet mode
对于本仓库维护的本地 workflow skills，任何 workflow boundary MUST 把
`endgate-state-packet` 视为默认且强制的协议载体，而不是可选 guidance。

#### Scenario: Local workflow boundary cannot skip canonical carrier emission
- **WHEN** 任一本仓库维护的本地 workflow skill 到达 checkpoint、handoff、
  analysis recommendation boundary、reviewed-task boundary 或 terminal boundary
- **THEN** assistant MUST 在下一个机器动作之前暴露 canonical
  `endgate-state-packet`
- **AND** MUST NOT 退回到“如果使用 packet 就……”这类条件式 guidance

#### Scenario: Structured carrier satisfies strict packet mode without visible packet text
- **WHEN** 当前运行时能够在 transcript 中记录结构化 endgate carrier
- **THEN** strict packet mode MUST 视该结构化 carrier 为合法满足
- **AND** workflow guidance MUST NOT 再把“最后 4 行必须是用户可见文本”写成唯一合法路径

#### Scenario: Visible tail block remains the fallback for legacy runtimes
- **WHEN** 当前运行时尚未提供结构化 endgate carrier
- **THEN** workflow guidance SHALL 继续使用 canonical `ENDGATE_*` tail block 作为 fallback
- **AND** prose fallback MUST 仍只作为 legacy fixture 或历史 incident 的残余安全网
