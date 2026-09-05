---
name: using-superpowers
description: Use when the user requests Superpowers, names a skill, or asks for design, planning, debugging, review, or plan execution; select only the workflow relevant to the current task.
---

# Using Superpowers

## Instruction Priority

Follow the host instruction hierarchy. Skills are task guidance, not authority to
override system or developer instructions. Within that hierarchy, explicit user
requests and applicable project rules override skill defaults. A stricter rule
does not automatically have higher priority.

## Direct Mode and Lightweight Exemptions

Direct Mode is the default. Ordinary questions, translation, summaries, rewriting,
and non-behavioral text, UI copy, comments or documentation edits do not require
brainstorming, planning or TDD. A lightweight subtask stays direct even within an
active workflow. Text that controls agent behavior or a public contract is not
automatically non-behavioral just because it lives in Markdown.

Use a named skill when explicitly requested. Otherwise select a relevant skill
when the task matches its trigger; a workflow keyword quoted in text to translate
or explain is not itself workflow intent. Do not turn one applicable skill into
the whole development pipeline.

## Context Loading

Read the selected skill entrypoint completely when it is first needed. Read
supporting references only when their stated conditions apply and only for the
current task. Reuse unchanged instructions and context already read in this
session; refresh when their content or applicability changes.

Inspect directly relevant project rules, files and tests before deciding what
else to load. Do not require a repository-wide document tour before every edit.
For existing governed work, recover the relevant requirements and task state,
not every historical proposal or every unrelated specification.

## How to Access Skills

Use the host's native skill loader when available (Skill in Claude Code, skill in
Copilot CLI, activate_skill in Gemini CLI, native discovery in Cursor and Codex).
If no loader exists, read the selected SKILL.md with available file tools.

Non-Claude tool mappings are in references/copilot-tools.md,
references/codex-tools.md and references/cursor-tools.md. Load only the mapping
for your platform when a tool adaptation is needed. Gemini's GEMINI.md includes
its mapping. Do not install tools or change global configuration just to satisfy
a skill default.

## Skill Routing

- Unresolved design decisions: brainstorming.
- A requested plan or implementation with meaningful dependencies: writing-plans.
- An approved plan to execute: executing-plans.
- A reproducible failure or investigation: systematic-debugging.
- Behavior implementation: test-driven-development, scaled to the affected risk.
- Completion claims: verification-before-completion.
- Review requests: requesting-code-review or receiving-code-review as applicable.
- Branch integration, PR preparation or cleanup explicitly in scope:
  finishing-a-development-branch.
- Skill behavior changes: writing-skills.

A local, clear, low-risk change can be implemented and checked directly. New
functionality, two touched modules or multiple steps alone do not require a
governance lane, design artifact, plan document or independent review.

## Governance Routing

Use spec-governed-development for explicit OpenSpec requests, existing governed
changes, project-mandated governance, or material risk that needs durable
scope/design decisions. Reuse the identified change as the canonical record.
Ask about a new governance lane only when an unresolved choice materially
affects the work; do not ask again for a lane the user has already authorized.

OpenSpec tooling and external skills are optional capabilities. Check
availability when needed; use supported local artifact operations where safe,
or explain the specific blocked step. Do not silently install dependencies.

## Autonomous Continuation

If the user asked for end-to-end completion and no clarification is needed,
execute the next safe, authorized step. Summaries are progress updates, not
approval gates. Conditional authorization (for example, "if the design is sound,
implement it") authorizes that next step once the condition is satisfied.

Classify the current request by outcome, not by the existence of more possible work:

- AUTO_CONTINUE: necessary work remains within scope and authority; do it.
- NEEDS_USER_DECISION: missing information, a material tradeoff or new authority
  prevents that work; ask the specific question and continue independent work.
- DONE: the requested deliverable and proportionate verification are complete;
  deliver the result, evidence and remaining limitations.

Completed requests are delivered directly, including assessments, audits,
reviews and research reports. Do not require an end/continue popup. A suggestion
for a future task does not authorize it or make the present request incomplete.
When the user asks for a plan before changes, deliver the plan and wait.

Before declaring a blocker, investigate safely, repair problems introduced by
this task and try in-scope alternatives. Do not abandon all work because one
check fails. Stop for input only when remaining progress genuinely depends on it;
state what is done, what is blocked and what decision is needed.

## User Choice Formatting

Ask only when the answer changes the work. If request_user_input is available
and permitted for the decision, use its choices for a small enumerable option
set; recommend an option and use the client's free-text fallback when provided.
If unavailable or prohibited, ask a concise plain-text question. Tool availability
must not turn a question into a permanent blocker or a fabricated tool call.

Follow the host/project confirmation rules for destructive or external actions.
For high-risk irreversible actions requiring two stages, put the safe exit first
and final execution second in the final confirmation. Editing is not permission
to commit, push, create a PR, merge or change global configuration.

## Legacy Endgate Compatibility

Version 1 endgate-state-packet is only for an explicitly enabled legacy runtime
or transcript replay with a compatible consumer and request_user_input support.
Loading this bootstrap, mentioning a workflow or reading an old spec does not
enable it. Normal workflow completion uses DONE above, not a version 1 packet.

When that integration is explicitly enabled, read the endgate-state-packet and
endgate-render-separation specifications under openspec/specs for its exact
carrier and event rules. Preserve structured carriers, visible-tail fallback,
last-declaration event windows and version 1 pairings for those consumers.
Do not emit a new DONE enum into an unchanged version 1 consumer.

If the integration cannot be honored, disclose the limitation and use the normal
completion/decision path where permitted. Never bypass higher-priority
instructions to satisfy a legacy popup contract.

## Reviewer Subagents

Independent read-only review is valuable for shared behavior, security-sensitive
changes and substantial design or implementation work. Scope the review to the
request and provide relevant artifacts and the complete task diff, including
uncommitted and untracked changes; do not forward unrelated session history.

Use supported runtime routing and report capability limits. Prompt text cannot
change the model already running. If independent review is unavailable, perform
a focused self-review and disclose its limits; only a specifically required
external approval blocks integration. Ordinary edits do not require a reviewer.
Other subagent work is optional when authorized and useful; there is no mandatory
execution-mode routing.
