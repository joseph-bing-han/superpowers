---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Overview

Load the relevant plan, review critically, execute the tasks authorized by the current request, and report their completion. Remaining plan tasks do not automatically expand the assignment.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## The Process

Before executing tasks, continue in the current workspace by default.
Only switch to an isolated workspace or worktree when the user explicitly requested that execution context.
Do not create or require a separate worktree as the default starting condition.

+Routine summaries, checkpoints, and batch boundaries are progress markers, not
automatic approval gates. Continue clear authorized work. Ask only when a real
decision, missing information or new authority blocks the next safe step.
If the user requested a plan-only handoff, deliver the plan and wait.

### Step 1: Load and Review Plan
1. Read the plan and identify the tasks and acceptance criteria authorized by the current request, including any deferred or excluded tasks
2. Review critically - identify any questions or concerns about the plan
3. Resolve concerns with safe local inspection first. Ask your human partner only about material ambiguity, changed scope, or missing authority; proceed with independent clear tasks
4. If concerns need human input and the next actions are already known, use `request_user_input` when available instead of a prose-only numbered reply prompt.
5. If no concerns: Create TodoWrite and proceed

### Step 2: Execute Tasks

For each task:
1. Mark as in_progress
2. Follow the plan's intent and constraints; adjust incidental details to repository reality, explaining material deviations
3. Run the specified affected verifications, reusing reliable evidence when relevant inputs, environment, and contracts are unchanged
4. Mark as completed
5. Continue to the next task automatically unless a real blocker requires human input

### Step 3: Batch Review

Review at meaningful risk boundaries and before integration. A narrow change can be self-reviewed; complex or shared behavior warrants independent review when available and authorized.

Per-task verification in Step 2 already catches real errors at the point they
occur. A reviewer dispatched after every task adds a round trip without adding
much protection, so the review gate sits here instead.

1. Confirm every in-scope task is complete and record verification results and unavailable coverage
2. Capture the range to review:

```bash
BASE_SHA=$(git rev-parse <commit before the first task>)
HEAD_SHA=$(git rev-parse HEAD)
```

3. Announce: "I'm using the requesting-code-review skill to review the completed work."
4. **REQUIRED SUB-SKILL:** Use superpowers:requesting-code-review
5. Give the reviewer the whole plan for context and an explicit `REVIEW_SCOPE`:
   authorized task IDs, their acceptance criteria, and deferred or excluded tasks.
   For full-plan execution, state that all tasks are in scope. Include the full
   `BASE_SHA..HEAD_SHA` range and in-scope staged, unstaged, and untracked changes.
   Completion is judged against this scope; the rest of the plan is context.
   Do not commit merely to make changes reviewable.
6. Fix all valid Critical and Important issues affecting the authorized deliverable; deferred work is not a missing feature in this review
7. Re-review the same way

**Review loop guidance:**
- After repeated review churn, reassess the evidence and disputed assumptions; ask only when progress requires a user decision
- Reviewers are advisory — explain disagreements if you believe feedback is incorrect
- Do not claim integration readiness with unresolved Critical or Important issues; report or preserve the work with its actual status

A batch review covers a much larger diff than a per-task review, so a reviewer is
likelier to skim. Passing the plan with its explicit authorized scope keeps the
review anchored to what every in-scope task was supposed to accomplish.

### Step 4: Complete Development

After batch review passes:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- Use superpowers:finishing-a-development-branch when branch integration or cleanup is in scope; ordinary workspace edits finish with an evidence-backed handoff
- Follow the already-authorized outcome; do not infer commit, push, PR, merge, or cleanup permission
- Treat that finishing step as the standard convergence path for branch outcomes; if an isolated workspace was explicitly used, let the finishing flow handle cleanup conditionally

## When to Stop and Ask for Help

**Investigate before escalating:**
- Diagnose failing tests and missing dependencies using safe in-scope checks; fix regressions introduced by this task
- Inspect relevant code and plan context to resolve unclear instructions
- Continue independent tasks when another task is blocked
- Reassess repeated failures instead of repeating speculative changes

Ask when a critical gap, unavailable prerequisite, material choice, or missing authority genuinely prevents further safe progress. Do not install global tools, alter unrelated dependencies, or broaden scope to bypass a blocker.

If concerns or blockers need human input, present numbered options instead of open-ended questions.
If concerns, blockers, or known next actions need human input and the choices are enumerable, use `request_user_input` when available.
If a real blocker requires input and the choices are enumerable, use `request_user_input`; otherwise continue automatically once the path is clear.
If the only remaining real decision is continue vs stop, ask that through `request_user_input`; otherwise ask the more specific blocker-resolution choice instead of collapsing it into a generic continue/stop prompt.
Keep a final free-text path only for guidance that does not fit the listed options.
Do not ask for a prose-only `reply 1/2/3` response in these flows when `request_user_input` is available.

Example:
1. Clarify the missing instruction
2. Revise the plan before execution
3. Stop here and investigate the blocker
4. Input other guidance

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through real blockers** - report evidence, completed work, and the specific input needed after exhausting safe in-scope alternatives.

## Remember
- Review plan critically first
- Follow the plan's required behavior and acceptance criteria
- Don't skip verifications
- Reference skills when plan says to
- Stop when blocked, don't guess
- Respect the repository's branch policy and current workspace; branch names alone do not create a new approval gate

## Integration

**Required workflow skills:**
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:finishing-a-development-branch** - Complete development after all in-scope tasks

## Completion

Follow the shared completion rules in `using-superpowers`: continue safe,
authorized work; ask only about a genuine blocker or decision; deliver completed
requests directly with evidence and limitations. Legacy packet mode is opt-in.
