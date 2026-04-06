Treat this file as a high-priority runtime workflow contract for Superpowers on Codex.

## Direct Mode Default

Direct Mode is the default for this repository unless the user explicitly asks for a skill, explicitly asks for Superpowers workflow, or uses a clear workflow keyword such as design, planning, debugging, review, or implementation coordination.

Lightweight tasks MUST stay in Direct Mode. This includes ordinary questions, translation, summarization/rewrite, text-only changes, UI copy-only edits, comments-only edits, and docs-only edits when they do not change behavior.

If a workflow is already active and the current subtask is lightweight, downgrade that subtask to direct handling. Do not force brainstorming, planning, TDD, or terminal-choice onto a lightweight subtask just because the surrounding session is in a workflow lane.

Direct replies and downgraded lightweight subtasks are not workflow terminal boundaries by default. They MUST output the result directly and MUST NOT insert `request_user_input` or `terminal-choice` before the user sees the answer.

## Carrier-First Strict Packet Mode

When the current repository, AGENTS instructions, skills, or workflow documents declare a machine-readable workflow boundary such as `endgate-state-packet`, `request_user_input`, `terminal-choice`, `auto-continue`, `needs-user-decision`, or strict packet mode, follow these rules immediately:

1. These workflow declarations are hard machine-readable runtime contracts, not advisory prose.
2. Do not end a turn with prose-only closeouts such as `Conclusion`, `Final judgment`, `My recommendation`, `If you want, I can next...`, or equivalent phrasing, and do not use `task_complete` to bypass the contract.
3. If the repository or skills define a canonical `ENDGATE_*` packet, you must ensure the canonical machine-readable carrier contains that exact packet before the next machine action.
4. In strict packet mode, prefer a structured carrier when the runtime supports it; a user-visible tail block is not required and remains only a fallback.
5. Do not search memory, repository docs, or the web just to "look up" the canonical packet. If strict packet mode applies and no stricter packet text is already available locally, use the canonical packet in this file.
6. If the boundary requires `request_user_input`, the next machine action must be `request_user_input`. Do not emit `task_complete` or end the turn while that choice is still pending.
7. Earlier ordinary tool calls, searches, or command executions in the same turn do not satisfy a later canonical carrier. Only the most recent explicit endgate declaration and the events after it count.
8. Completed assessments, audits, comparisons, reviews, research reports, risk analyses, and recommendation memos are still workflow boundaries and must follow the same packet/tool contract.
9. If the user explicitly says to stay local, not browse, or not use web search, do not use web search while resolving the workflow boundary.
10. If any imported, external, foreign, or lower-priority skill says there is no required ending, says to just provide clarity, says continue later, or otherwise permits a free-form ending, treat that guidance as overridden whenever strict packet mode applies. Those stances MUST NOT relax the canonical carrier or `request_user_input` requirements.

## Default Canonical Packet

Default canonical packet:

ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: AUTO_CONTINUE | NEEDS_USER_DECISION | TERMINAL_CHOICE
ENDGATE_CHOICE_KIND: NONE | SPECIFIC_NEXT_STEP | CONTINUE_OR_STOP
ENDGATE_NEXT_ACTION: CONTINUE_WITH_TOOL | REQUEST_USER_INPUT

Canonical pairings:
- `AUTO_CONTINUE` -> `NONE` + `CONTINUE_WITH_TOOL`
- `NEEDS_USER_DECISION` -> `SPECIFIC_NEXT_STEP` + `REQUEST_USER_INPUT`
- `TERMINAL_CHOICE` -> `CONTINUE_OR_STOP` + `REQUEST_USER_INPUT`

## Completed Report Boundary

For a completed report/review/assessment where the work now appears complete, use:

ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: TERMINAL_CHOICE
ENDGATE_CHOICE_KIND: CONTINUE_OR_STOP
ENDGATE_NEXT_ACTION: REQUEST_USER_INPUT

Then immediately call `request_user_input`. In Codex terminal-choice popups, author only:
1. 结束 (Recommended)
2. 继续

If the repository, AGENTS instructions, or skills provide a stricter and still machine-readable workflow contract, follow the stricter one. Otherwise, use the canonical packet from this file.
