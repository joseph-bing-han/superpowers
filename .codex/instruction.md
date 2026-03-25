Treat this file as a high-priority runtime workflow contract for Superpowers on Codex.

When the current repository, AGENTS instructions, skills, or workflow documents declare a machine-readable workflow boundary such as `endgate-state-packet`, `request_user_input`, `terminal-choice`, `auto-continue`, `needs-user-decision`, or strict packet mode, follow these rules immediately:

1. These workflow declarations are hard machine-readable runtime contracts, not advisory prose.
2. Do not end a turn with prose-only closeouts such as `Conclusion`, `Final judgment`, `My recommendation`, `If you want, I can next...`, or equivalent phrasing, and do not use `task_complete` to bypass the contract.
3. If the repository or skills define a canonical `ENDGATE_*` packet, you must emit that exact packet. In strict packet mode, the last 4 non-empty lines before the next machine action must be that packet.
4. Do not search memory, repository docs, or the web just to "look up" the canonical packet. If strict packet mode applies and no stricter packet text is already available locally, use the canonical packet in this file.
5. If the boundary requires `request_user_input`, the next machine action must be `request_user_input`. Do not emit `task_complete` or end the turn while that choice is still pending.
6. Earlier ordinary tool calls, searches, or command executions in the same turn do not satisfy a later workflow boundary. Only the most recent explicit endgate declaration and the events after it count.
7. Completed assessments, audits, comparisons, reviews, research reports, risk analyses, and recommendation memos are still workflow boundaries and must follow the same packet/tool contract.
8. If the user explicitly says to stay local, not browse, or not use web search, do not use web search while resolving the workflow boundary.

Default canonical packet:

ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: AUTO_CONTINUE | NEEDS_USER_DECISION | TERMINAL_CHOICE
ENDGATE_CHOICE_KIND: NONE | SPECIFIC_NEXT_STEP | CONTINUE_OR_STOP
ENDGATE_NEXT_ACTION: CONTINUE_WITH_TOOL | REQUEST_USER_INPUT

Canonical pairings:
- `AUTO_CONTINUE` -> `NONE` + `CONTINUE_WITH_TOOL`
- `NEEDS_USER_DECISION` -> `SPECIFIC_NEXT_STEP` + `REQUEST_USER_INPUT`
- `TERMINAL_CHOICE` -> `CONTINUE_OR_STOP` + `REQUEST_USER_INPUT`

For a completed report/review/assessment where the work now appears complete, use:

ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: TERMINAL_CHOICE
ENDGATE_CHOICE_KIND: CONTINUE_OR_STOP
ENDGATE_NEXT_ACTION: REQUEST_USER_INPUT

Then immediately call `request_user_input`. In Codex terminal-choice popups, author only:
1. 结束 (Recommended)
2. 继续

If the repository, AGENTS instructions, or skills provide a stricter and still machine-readable workflow contract, follow the stricter one. Otherwise, use the canonical packet from this file.
