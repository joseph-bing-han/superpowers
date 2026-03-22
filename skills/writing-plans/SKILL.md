---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** If working in an isolated worktree, it should have been created via the `superpowers:using-git-worktrees` skill at execution time.

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

**When operating in an OpenSpec-governed lane:**
- Read the relevant OpenSpec artifacts first (`proposal.md`, `design.md`, `specs/*`, `tasks.md`)
- Treat OpenSpec as the canonical source for scope, design, and requirements
- Write only the execution-level plan here; do NOT create a duplicate scope/design spec

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

**Only in an OpenSpec-governed lane, add this extra metadata below the required header:**

```markdown
**OpenSpec Change:** <change-name>
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Remember
- Exact file paths always
- Complete code in every step — if a step changes code, show the code
- Exact commands with expected output
- Reference relevant skills with @ syntax
- If OpenSpec governs the change, use OpenSpec artifacts as inputs and keep this document execution-only
- DRY, YAGNI, TDD, frequent commits

## Plan Review Loop

After writing the complete plan:

1. Review the written plan.
   - If a reviewer subagent would materially help and the session consent state is unknown, use `request_user_input` to ask once before dispatching it
   - If the state is `granted`, dispatch the reviewer subagent: a single plan-document-reviewer subagent (see plan-document-reviewer-prompt.md) with precisely crafted review context — never your session history. This keeps the reviewer focused on the plan, not your thought process.
   - If the state is `denied`, review inline and do not ask again in the same session
   - In a **Superpowers-only lane**, provide: path to the plan document, path to spec document
   - In an **OpenSpec-governed lane**, provide: path to the plan document, plus the relevant OpenSpec artifact paths (`proposal.md`, `design.md`, relevant `specs/*`, `tasks.md`)
2. If ❌ Issues Found: fix the issues, then review the whole plan again using the same session-consent rules
3. If ✅ Approved: proceed to execution handoff

**Review loop guidance:**
- Same agent that wrote the plan fixes it (preserves context)
- If loop exceeds 3 iterations, surface to human for guidance
- Reviewers are advisory — explain disagreements if you believe feedback is incorrect

## Execution Handoff

If the execution path is already clear, continue automatically. If the user asked for end-to-end completion and the path is already implied by consent state, tool availability, or the surrounding workflow, do not pause after saving the plan just to ask whether to continue. Saving the plan is not a reason by itself to stop.

When a real execution choice is still needed after saving the plan, offer execution choice:

```text
Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Choose the execution path:

1. Subagent-Driven (recommended)
2. Inline Execution
3. Input other requirements
```

When `request_user_input` is available, use it for this execution handoff because the choices are known and enumerable.
Keep a final free-text path only for requirements that do not fit the listed execution choices.
Do not ask for a prose-only `reply 1/2/3` response in this handoff when `request_user_input` is available.
Do not end this handoff with prose-only follow-up text like `if you want me to execute next`.
Either continue automatically on the already-implied execution path or use `request_user_input` when a real execution choice remains.
Choosing `Subagent-Driven` counts as explicit session-scoped consent to use implementation subagents for the rest of the session.
Treat that choice as setting the shared session consent state to `granted` for implementation subagents.
Do not immediately ask again for the same subagent consent after that choice.

If the execution path is already clear:
- If session consent is `granted`, continue automatically with `subagent-driven-development`
- If session consent is `denied`, or subagents are unavailable, continue automatically with `executing-plans`
- Do not pause after saving the plan just to ask whether to continue

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
- Fresh subagent per task + two-stage review

**If Inline Execution chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:executing-plans
- Batch execution with checkpoints for review
