---
name: brainstorming
description: "Use when the user explicitly asks to design or brainstorm a non-lightweight change, or when an active workflow has already entered the design phase for a non-lightweight change. Do not use for plain Q&A, translation, or text-only/copy-only edits."
---

# Brainstorming Ideas Into Designs

Help turn ideas into fully formed design artifacts through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design. If the user already asked for end-to-end execution and there are no unresolved questions, risky tradeoffs, or explicit review requests, continue on the recommended path instead of inserting a redundant "continue?" gate.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and either:
1. the user has approved it, or
2. the user already asked for end-to-end execution, the design is straightforward, and no unresolved clarifications, risky tradeoffs, or explicit review requests remain.
This applies to non-lightweight design work that has already entered the brainstorming lane.
</HARD-GATE>

<ENDGATE-HARD-RULE>
Before any brainstorming checkpoint ends:
- Never stop after a prose-only recommendation, summary, or next-step proposal.
- This includes value-framed endings such as `如果你愿意，我下一步最有价值的不是继续泛讨论，而是直接……`.
- A completed evaluation, recommendation memo, comparison writeup, or other report-style deliverable is still a terminal boundary; a bare `结论`, `最终判断`, or `这轮我没有改代码，只做了……` closeout is not enough.
- Every brainstorming checkpoint in this repository uses `endgate-state-packet`; this repository is in strict packet mode.
- In strict packet mode, a canonical machine-readable carrier must exist before the next machine action.
- If the runtime supports a structured carrier, prefer a structured carrier over a user-visible tail block; the tail block is not required and remains only a fallback.
- If the checkpoint is non-terminal, continue automatically or call `request_user_input`; never end with `task_complete`.
</ENDGATE-HARD-RULE>

## Lightweight Task Bypass

Do NOT use brainstorming for:

- ordinary questions and explanations
- translation
- summarization or rewriting
- text-only changes
- UI copy-only edits
- comments-only or docs-only edits

If a broader workflow session is already active and the current subtask matches one of the categories above, downgrade that subtask to direct handling instead of forcing it through brainstorming.

## Checklist

You MUST create a task for each of these items and complete them in order:

1. **Explore project context** — check files, docs, recent commits
2. **Offer visual companion** (if topic will involve visual questions) — this is its own message, not combined with a clarifying question. See the Visual Companion section below.
3. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria; prefer numbered options when the choices are already known
4. **Propose 2-3 approaches** — with trade-offs and your recommendation
5. **Present design** — in sections scaled to their complexity; when a real review gate remains, get user approval after each section using `request_user_input` when available for enumerable choices instead of typed approval words or a prose-only numbered reply prompt
6. **Write design artifacts** — in a Superpowers-only lane, save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit; in an OpenSpec-governed lane, update the relevant OpenSpec change artifacts and commit without creating a duplicate Superpowers spec file
7. **Design artifact review loop** — dispatch the spec reviewer for your platform with precisely crafted review context (never your session history); review the written design artifacts, fix issues, and re-dispatch until approved (max 3 iterations, then surface to human)
8. **User reviews written design artifacts** — only when a real review gate remains; otherwise note the artifact paths and continue automatically
9. **Transition into implementation context** — stay in the current workspace by default and invoke `writing-plans` when implementation follows
10. **Transition to implementation** — invoke writing-plans skill to create implementation plan

## Process Flow

```dot
digraph brainstorming {
    "Explore project context" [shape=box];
    "Visual questions ahead?" [shape=diamond];
    "Offer Visual Companion\n(own message, no other content)" [shape=box];
    "Ask clarifying questions" [shape=box];
    "Propose 2-3 approaches" [shape=box];
    "Present design sections" [shape=box];
    "User approves design?" [shape=diamond];
    "Write design artifacts" [shape=box];
    "Design artifact review loop" [shape=box];
    "Design artifact review passed?" [shape=diamond];
    "User reviews artifacts?" [shape=diamond];
    "Invoke writing-plans skill" [shape=doublecircle];

    "Explore project context" -> "Visual questions ahead?";
    "Visual questions ahead?" -> "Offer Visual Companion\n(own message, no other content)" [label="yes"];
    "Visual questions ahead?" -> "Ask clarifying questions" [label="no"];
    "Offer Visual Companion\n(own message, no other content)" -> "Ask clarifying questions";
    "Ask clarifying questions" -> "Propose 2-3 approaches";
    "Propose 2-3 approaches" -> "Present design sections";
    "Present design sections" -> "User approves design?";
    "User approves design?" -> "Present design sections" [label="no, revise"];
    "User approves design?" -> "Write design artifacts" [label="yes"];
    "Write design artifacts" -> "Design artifact review loop";
    "Design artifact review loop" -> "Design artifact review passed?";
    "Design artifact review passed?" -> "Design artifact review loop" [label="issues found,\nfix and re-dispatch"];
    "Design artifact review passed?" -> "User reviews artifacts?" [label="approved"];
    "User reviews artifacts?" -> "Write design artifacts" [label="changes requested"];
    "User reviews artifacts?" -> "Invoke writing-plans skill" [label="approved"];
}
```

**The terminal implementation handoff is continuing in the current workspace, then invoking `writing-plans`.** Do NOT invoke frontend-design, mcp-builder, or any other implementation skill here.

## The Process

**Understanding the idea:**

- Check out the current project state first (files, docs, recent commits)
- Before asking detailed questions, assess scope: if the request describes multiple independent subsystems (e.g., "build a platform with chat, file storage, billing, and analytics"), flag this immediately. Don't spend questions refining details of a project that needs to be decomposed first.
- If the project is too large for a single spec, help the user decompose into sub-projects: what are the independent pieces, how do they relate, what order should they be built? Then brainstorm the first sub-project through the normal design flow. Each sub-project gets its own spec → plan → implementation cycle.
- For appropriately-scoped projects, ask questions one at a time to refine the idea
- Prefer numbered options when asking clarifying questions with known choices
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, constraints, success criteria

**Exploring approaches:**

- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

## Presenting the design:

- Once you believe you understand what you're building, present the design
- Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
- Before ending a design checkpoint, classify the checkpoint as `auto-continue`, `needs-user-decision`, or `terminal-choice`
- `auto-continue`: the next safe design or artifact step is already implied; take it now
- `needs-user-decision`: a real review or tradeoff decision remains; use `request_user_input`
- `terminal-choice`: the requested brainstorming work is genuinely complete, but do not end directly; use `request_user_input`
- In Codex tool-backed terminal-choice popups, author only:
  1. 结束 (Recommended)
  2. 继续
- Treat free-form requirements as the client-provided `Other` / notes path instead of authoring a duplicate free-form option
- For checkpoint, handoff, and terminal-choice nodes driven by `request_user_input`, the `request_user_input` call and its transcript event are the machine contract; surrounding prose is explanatory only.
- Every brainstorming checkpoint in this repository is carrier-backed; treat the last canonical carrier plus its post-carrier event window as the governing runtime contract for that boundary.
- Earlier same-turn tool calls do not satisfy a later canonical carrier; prose invitation matching remains only a fallback safety net when no carrier exists.
- In strict packet mode, a canonical machine-readable carrier must exist before the next machine action.
- Prefer a structured carrier when the runtime supports it; a user-visible tail block remains only a fallback.
- At every design checkpoint in this repository, ensure the canonical machine-readable carrier contains this exact packet before the next machine action:
```text
ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: AUTO_CONTINUE | NEEDS_USER_DECISION | TERMINAL_CHOICE
ENDGATE_CHOICE_KIND: NONE | SPECIFIC_NEXT_STEP | CONTINUE_OR_STOP
ENDGATE_NEXT_ACTION: CONTINUE_WITH_TOOL | REQUEST_USER_INPUT
```
- Canonical packet pairings:
  - `AUTO_CONTINUE` -> `NONE` + `CONTINUE_WITH_TOOL`
  - `NEEDS_USER_DECISION` -> `SPECIFIC_NEXT_STEP` + `REQUEST_USER_INPUT`
  - `TERMINAL_CHOICE` -> `CONTINUE_OR_STOP` + `REQUEST_USER_INPUT`
- `AUTO_CONTINUE`: ensure the canonical carrier records this packet, then immediately continue with the concrete design or artifact step.
- `NEEDS_USER_DECISION`: ensure the canonical carrier records this packet, then immediately call `request_user_input` with the concrete design-review or next-step options.
- `TERMINAL_CHOICE`: ensure the canonical carrier records this packet, then immediately call `request_user_input` with only `结束 (Recommended)` and `继续`.
- When brainstorming reaches `terminal-choice`, the next action is the popup itself. The very next action must be `request_user_input`.
- Do not produce a plain final-answer-style closeout before the terminal-choice popup, including endings framed like `当前我建议的定稿`, `就按这条落地`, or `最终建议一句话版`.
- A completed evaluation, recommendation memo, comparison writeup, or other report-style deliverable is still a terminal boundary. After presenting the report, emit the `TERMINAL_CHOICE` packet and immediately call `request_user_input`; a bare `结论` / `最终判断` / `这轮我没有改代码，只做了……` closeout is still invalid if it ends the turn directly.
- A settled recommendation, final draft, current recommendation, or final summary is still not permission to end directly.
- Do not call `task_complete` from brainstorming while the terminal-choice popup is still pending.
- Ask after each section whether it looks right so far, using numbered approvals instead of requiring typed approval words
- When `request_user_input` is available and the approval choices are enumerable, use it instead of asking for a prose-only `reply 1/2/3` response.
- Keep a final free-text path only for new feedback that does not fit the listed approval choices.
- If the user already asked for end-to-end execution and the design is straightforward, present a concise design checkpoint and continue without waiting for a separate continue prompt.
- Contingent authorization means auto-continue. If the user frames the checkpoint as `如果没问题就继续下一阶段`, `如果设计合理就开始实现`, or similar, then a positive judgment counts as auto-continue rather than a fresh approval gate.
- Do not end that checkpoint with headings like `最终判断`, `现在可以把结论更新为`, or `可以进入下一阶段` and then stop. Once the condition is satisfied, continue into the already-authorized next phase instead of ending with a free-text conclusion block.
- Stop and ask for approval only when there are material tradeoffs, unresolved risk, or the user explicitly wants to review the design before implementation.
- If the only remaining real choice is continue vs stop, ask that through `request_user_input`; otherwise ask the more specific review or next-artifact choice instead of collapsing it into a generic continue/stop prompt.
- Do not end a design checkpoint with prose-only follow-up text like `if you agree`, `if this direction looks good`, or `I can implement this next if you want`.
- Do not stop with a declarative prose-only next-step proposal like `the next best step is X`, `next I would do X`, or `I can directly prepare X next`.
- This also includes judgment-framed, comparative, recommendation-framed, or value-framed next-step proposals, including Chinese variants such as `如果按我的判断，下一步应该先……`, `下一步最值得做的不是 A，而是 B`, `接下来更值得做的是……`, `我建议先……`, or `如果你愿意，我下一步最有价值的不是继续泛讨论，而是直接……`
- A concrete leak example is `如果你同意，我下一步可以直接按这个推荐方案 A 开始修。`
- Another concrete leak example is `如果你愿意，我下一步最有价值的不是继续泛讨论，而是直接把这次评估收敛成一份可执行清单。`
- That pattern must resolve to either `request_user_input` or `auto-continue`, never `task_complete`
- A non-terminal checkpoint must never end with `task_complete` after only a summary, recommendation, judgment, comparison, or suggestion about the next artifact step
- Either continue automatically into the next workflow step or use `request_user_input` for a real review gate.
- Do not end with prose-only next-step invitations like `if you want, I can turn this into a field-by-field table next`.
- If you can already name the next safe artifact step concretely, take it instead of narrating it and stopping.
- If the next artifact choices are enumerable, use `request_user_input` instead of a prose-only optional next-step invitation.
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

For approval gates, prefer patterns like:

```text
1. Agree and continue
2. Request changes
3. Input other feedback or requirements
```

Avoid requiring the user to type approval words like "agree", "approved", or "go ahead".
Do not accept a prose-only `reply 1/2/3` prompt for these enumerable approval gates when `request_user_input` is available.

**Design for isolation and clarity:**

- Break the system into smaller units that each have one clear purpose, communicate through well-defined interfaces, and can be understood and tested independently
- For each unit, you should be able to answer: what does it do, how do you use it, and what does it depend on?
- Can someone understand what a unit does without reading its internals? Can you change the internals without breaking consumers? If not, the boundaries need work.
- Smaller, well-bounded units are also easier for you to work with - you reason better about code you can hold in context at once, and your edits are more reliable when files are focused. When a file grows large, that's often a signal that it's doing too much.

**Working in existing codebases:**

- Explore the current structure before proposing changes. Follow existing patterns.
- Where existing code has problems that affect the work (e.g., a file that's grown too large, unclear boundaries, tangled responsibilities), include targeted improvements as part of the design - the way a good developer improves code they're working in.
- Don't propose unrelated refactoring. Stay focused on what serves the current goal.

## After the Design

## OpenSpec Lane Safety Gate

If the current work still looks like an important change that probably belongs in OpenSpec, and the lane has not yet been resolved, `brainstorming` must not silently continue as if this were already a Superpowers-only lane.

- If there is no explicit existing change and the user has not explicitly chosen the ordinary-docs fallback, you MUST NOT write ordinary design docs yet（不得先写普通设计文档）.
- In that unresolved state, you MUST use `request_user_input` to run lane confirmation first.
- Slot `1` remains `创建 OpenSpec 提案 (Recommended)`.
- Slot `2` remains the explicit ordinary-docs fallback.
- Only after the user explicitly chooses the ordinary-docs fallback may `brainstorming` write a normal design artifact outside OpenSpec.
- If the user chooses OpenSpec, update the relevant OpenSpec artifacts instead of creating an ordinary design document.

## Document Path Selection

Before writing any non-OpenSpec design artifact, choose the destination path in this order:

1. A concrete path explicitly named by the user or scoped instructions
2. An existing structured spec directory such as `docs/specs` or `docs/superpowers/specs`
3. If no structured spec directory exists yet, create `docs/specs` instead of dropping a new design document into bare `docs/`

Rules:

- Do not infer bare `docs/` as the default destination just because the repository has legacy documents there.
- A generic instruction like "store docs under `docs/`" still allows structured subdirectories; it does not override `docs/specs` or `docs/superpowers/specs`.
- If the repo already has `docs/plans`, prefer the matching structured spec directory `docs/specs`; if it already has `docs/superpowers/plans`, prefer `docs/superpowers/specs`.
- In an OpenSpec lane, do not create a parallel design doc outside OpenSpec artifacts by default. If the user explicitly wants a brainstorming record, store it in the structured spec directory and clearly mark OpenSpec as the canonical source of truth.

**Documentation:**

- In a **Superpowers-only lane**, write the validated design artifact to the structured spec directory selected above (for example `docs/specs/YYYY-MM-DD-<topic>-design.md` or `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`)
  - Only an explicit path from the user or scoped instructions overrides this structured-directory rule
- In an **OpenSpec-governed lane**, update the relevant OpenSpec change artifacts instead of creating a duplicate Superpowers spec document
  - In that lane, OpenSpec artifacts are the canonical record for scope, design, and requirements
  - Do NOT maintain a parallel `docs/superpowers/specs/...` file covering the same change
- Use elements-of-style:writing-clearly-and-concisely skill if available
- Commit the resulting design artifact(s) to git

**Design Artifact Review Loop:**
After writing the design artifact(s):

1. Dispatch spec-document-reviewer subagent (see spec-document-reviewer-prompt.md)
   - In a **Superpowers-only lane**, provide the path to the written design artifact
   - In an **OpenSpec-governed lane**, provide the relevant OpenSpec artifact paths
   - Dispatch the spec reviewer for your platform with precisely crafted review context — never your session history
   - If the state is `granted`, dispatch the reviewer subagent
   - If the state is `denied`, review inline and do not ask again in the same session
2. If Issues Found: fix, re-dispatch, repeat until Approved
3. If loop exceeds 3 iterations, surface to human for guidance

## User Review Gate:
After the design artifact review loop passes, ask the user to review the written design artifacts before proceeding only when a real review gate is still needed:

> "Design artifacts written and committed to `<path-or-paths>`. Choose the next step:
> 1. Agree and continue
> 2. Request changes
> 3. Input other feedback or requirements"

When `request_user_input` is available and the next steps are enumerable, use it for this review gate instead of a prose-only numbered reply prompt.

When the original request already authorizes end-to-end execution and the artifacts match the settled design with no open issues, do not stop just to ask whether to continue. Mention the artifact paths in a progress update and proceed directly to writing-plans.
If you do open this review gate, wait for the user's response. If they request changes, make them and re-run the design artifact review loop. Only proceed once the user approves.
Do not switch back to prose-only follow-up text like `if you agree` after a tool-backed approval or review choice in the same non-terminal flow.

**Implementation:**

- When implementation follows, continue in the current workspace by default
- Only enter an isolated workspace or worktree when the user explicitly requests that setup
- After confirming the execution context, invoke the writing-plans skill to create a detailed implementation plan
- Do NOT invoke any other implementation skill here. The next sequence is current workspace continuation → `writing-plans`

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Numbered choices preferred** - Easier to answer than open-ended when concrete choices are known
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design, get approval before moving on
- **Be flexible** - Go back and clarify when something doesn't make sense

## Visual Companion

A browser-based companion for showing mockups, diagrams, and visual options during brainstorming. Available as a tool — not a mode. Accepting the companion means it's available for questions that benefit from visual treatment; it does NOT mean every question goes through the browser.

**Offering the companion:** When you anticipate that upcoming questions will involve visual content (mockups, layouts, diagrams), offer it once for consent:
> "Some of what we're working on might be easier to explain if I can show it to you in a web browser. I can put together mockups, diagrams, comparisons, and other visuals as we go. This feature is still new and can be token-intensive. Want to try it? (Requires opening a local URL)"

**This offer MUST be its own interaction.** Do not combine it with clarifying questions, context summaries, or any other content.
When `request_user_input` is available, use it for the visual companion consent question instead of a prose-only yes/no prompt.
If you must fall back to plain text, the message should contain ONLY the offer above and nothing else. Wait for the user's response before continuing. If they decline, proceed with text-only brainstorming.

**Per-question decision:** Even after the user accepts, decide FOR EACH QUESTION whether to use the browser or the terminal. The test: **would the user understand this better by seeing it than reading it?**

- **Use the browser** for content that IS visual — mockups, wireframes, layout comparisons, architecture diagrams, side-by-side visual designs
- **Use the terminal** for content that is text — requirements questions, conceptual choices, tradeoff lists, A/B/C/D text options, scope decisions

A question about a UI topic is not automatically a visual question. "What does personality mean in this context?" is a conceptual question — use the terminal. "Which wizard layout works better?" is a visual question — use the browser.

If they agree to the companion, read the detailed guide before proceeding:
`skills/brainstorming/visual-companion.md`
