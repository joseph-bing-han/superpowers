---
name: brainstorming
description: "Use when the user explicitly asks to design or brainstorm a non-lightweight change, or when an active workflow has already entered the design phase for a non-lightweight change. Do not use for plain Q&A, translation, or text-only/copy-only edits."
---
+<WORKFLOW-COMPLETION>
Use the shared completion rules in `using-superpowers`. Legacy endgate packets
apply only in explicitly enabled compatible integrations. Completed designs and
reports may be delivered directly; ask only for a real decision or blocker.
</WORKFLOW-COMPLETION>
# Brainstorming Ideas Into Designs

Help turn ideas into fully formed design artifacts through natural collaborative dialogue.

Start with directly relevant context and any existing design, then ask only material unresolved questions. Once the intended behavior and acceptance criteria are clear, present the necessary design. If the user already asked for end-to-end execution and no unresolved questions, risky tradeoffs, or explicit review requests remain, continue without a redundant confirmation.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and either:
1. the user has approved it, or
2. the user already asked for end-to-end execution, the design is straightforward, and no unresolved clarifications, risky tradeoffs, or explicit review requests remain.
This applies to non-lightweight design work that has already entered the brainstorming lane.
</HARD-GATE>

Follow the shared completion rules in `using-superpowers`. A completed design
or assessment can be delivered directly; legacy packet mode is opt-in.

## Lightweight Task Bypass

Do NOT use brainstorming for:

- ordinary questions and explanations
- translation
- summarization or rewriting
- text-only changes
- UI copy-only edits
- comments-only or docs-only edits

If a broader workflow session is already active and the current subtask matches one of the categories above, downgrade that subtask to direct handling instead of forcing it through brainstorming.

## Proportionate Design Work

1. Inspect directly relevant project files and reuse settled requirements or an approved design.
2. Ask only questions whose answers materially affect scope, risk, or acceptance. Batch related questions when helpful; do not force one question per turn.
3. Compare alternatives when real tradeoffs exist. A single well-supported approach is sufficient for a straightforward change.
4. Present the necessary design and acceptance criteria. Respect a user-requested design review before implementation; already-authorized end-to-end work can proceed when no material decision remains.
5. Create durable artifacts only when requested or required by project governance. In an OpenSpec lane, update its canonical artifacts without duplicating the design elsewhere.
6. Use independent review for complex or high-risk designs when available and authorized; otherwise self-review and report material limitations.
7. Continue in the current workspace. Use writing-plans when implementation complexity or a handoff needs a plan, not as an unconditional extra phase.

These are decision criteria, not a mandatory task checklist. The visual companion is optional and only useful when a concrete visual decision benefits from it. Writing a design artifact does not authorize committing it.

## The Process

**Understanding the idea:**

- Inspect relevant current files and docs; read recent commits only when history explains a decision affecting this task
- Before asking detailed questions, assess scope: if the request describes multiple independent subsystems (e.g., "build a platform with chat, file storage, billing, and analytics"), flag this immediately. Don't spend questions refining details of a project that needs to be decomposed first.
- If the project is too large for a single spec, help the user decompose into sub-projects: what are the independent pieces, how do they relate, what order should they be built? Then brainstorm the first sub-project through the normal design flow. Each sub-project gets its own spec → plan → implementation cycle.
- For appropriately-scoped projects, ask only questions that resolve material uncertainty
- Prefer numbered options when asking clarifying questions with known choices
- Group related questions when this makes the decision easier; avoid an unnecessary sequence of confirmation turns
- Focus on understanding: purpose, constraints, success criteria

**Exploring approaches:**

- Compare alternatives when meaningful tradeoffs exist; do not invent alternatives to satisfy a count
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

## Presenting the design:

- Once you believe you understand what you're building, present the design
- Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
- Cover the architecture, components, data flow, error handling and testing that
  matter to the task; omit irrelevant sections.
- Ask for a design decision only when a material tradeoff remains or the user
  explicitly requested review before implementation.
- If end-to-end execution is already authorized and no such decision remains,
  continue without waiting. Conditional authorization applies once satisfied.
- If the request was only for design or assessment, deliver the completed result
  directly. Do not manufacture an end/continue decision or expand the scope.
- Use request_user_input when available and permitted for a real choice; otherwise
  ask a concise plain-text question. Do not require a particular approval phrase.

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

Use project governance, an explicitly named change, and material cross-boundary risk to choose the lane with `spec-governed-development`. Several files or steps alone do not require OpenSpec. Stay with an existing governed change and reuse its relevant artifacts. Ask only when an unresolved lane choice materially changes scope, authority, or durable records; detect available tools and do not install missing tooling implicitly.

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

**Documentation (only when requested or required by governance):**

- In a **Superpowers-only lane**, write the validated design artifact to the structured spec directory selected above (for example `docs/specs/YYYY-MM-DD-<topic>-design.md` or `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`)
  - Only an explicit path from the user or scoped instructions overrides this structured-directory rule
- In an **OpenSpec-governed lane**, update the relevant OpenSpec change artifacts instead of creating a duplicate Superpowers spec document
  - In that lane, OpenSpec artifacts are the canonical record for scope, design, and requirements
  - Do NOT maintain a parallel `docs/superpowers/specs/...` file covering the same change
- Use elements-of-style:writing-clearly-and-concisely skill if available
- Commit design artifacts only when committing is authorized

**Design Artifact Review:**

Review the design against the request, relevant contracts, and acceptance criteria. For complex, high-risk, or cross-boundary designs, use an independent reviewer when available and authorized (see spec-document-reviewer-prompt.md), providing relevant artifact paths and task-specific context rather than session history. For narrow designs, self-review is sufficient.

Resolve material findings and recheck affected sections. Repeated review churn calls for reassessing evidence and assumptions, not an automatic stop after a fixed count. Ask the user when a real unresolved decision is needed. Missing reviewer capability is a limitation to report, not permission to change global configuration.

## User Review Gate:
After the design artifact review loop passes, ask the user to review the written design artifacts before proceeding only when a real review gate is still needed:

> "Design artifacts written to `<path-or-paths>`. Choose the next step:
> 1. Agree and continue
> 2. Request changes
> 3. Input other feedback or requirements"

When `request_user_input` is available and the next steps are enumerable, use it for this review gate instead of a prose-only numbered reply prompt.

When the original request already authorizes end-to-end execution and the artifacts match the settled design with no open issues, do not stop just to ask whether to continue. Mention artifact paths when present and continue with the next warranted implementation step.
If you do open this review gate, wait for the user's response. If they request changes, make them and re-run the design artifact review loop. Only proceed once the user approves.
Do not switch back to prose-only follow-up text like `if you agree` after a tool-backed approval or review choice in the same non-terminal flow.

**Implementation:**

- When implementation follows, continue in the current workspace by default
- Only enter an isolated workspace or worktree when the user explicitly requests that setup
- Use writing-plans when a complex implementation or handoff needs a plan; a settled small change can proceed directly with appropriate implementation and validation skills

## Key Principles

- **Questions on demand** - Resolve material uncertainty without repeating settled decisions
- **Numbered choices preferred** - Easier to answer than open-ended when concrete choices are known
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore real alternatives** - Compare approaches only when the tradeoff matters
- **Incremental validation** - Resolve material design questions and respect explicit review requests without repeating settled approvals
- **Be flexible** - Go back and clarify when something doesn't make sense

## Visual Companion

A browser-based companion for showing mockups, diagrams, and visual options during brainstorming. Available as a tool — not a mode. Accepting the companion means it's available for questions that benefit from visual treatment; it does NOT mean every question goes through the browser.

**Offering the companion:** When you anticipate that upcoming questions will involve visual content (mockups, layouts, diagrams), offer it once for consent:
> "Some of what we're working on might be easier to explain if I can show it to you in a web browser. I can put together mockups, diagrams, comparisons, and other visuals as we go. This feature is still new and can be token-intensive. Want to try it? (Requires opening a local URL)"

Offer only when the optional companion materially helps a current visual decision and has not already been authorized. Use the host's permitted interaction mechanism. Await consent before starting that companion, but continue independent text-based design work. If declined or unavailable, proceed without it.

**Per-question decision:** Even after the user accepts, decide FOR EACH QUESTION whether to use the browser or the terminal. The test: **would the user understand this better by seeing it than reading it?**

- **Use the browser** for content that IS visual — mockups, wireframes, layout comparisons, architecture diagrams, side-by-side visual designs
- **Use the terminal** for content that is text — requirements questions, conceptual choices, tradeoff lists, A/B/C/D text options, scope decisions

A question about a UI topic is not automatically a visual question. "What does personality mean in this context?" is a conceptual question — use the terminal. "Which wizard layout works better?" is a visual question — use the browser.

If they agree to the companion, read the detailed guide before proceeding:
`skills/brainstorming/visual-companion.md`
