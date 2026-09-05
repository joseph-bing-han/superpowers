---
name: writing-plans
description: Use when an approved design, complex dependencies, or an explicit planning request warrants an implementation plan; not for every small edit
---

# Writing Plans

## Overview

Write implementation plans with enough context for the actual executor: affected files, ordered steps, dependencies, acceptance checks, and material risks. Scale detail to uncertainty and handoff needs; a small local change can use a short in-session plan without a new document.

Reuse an existing approved plan or design when it still matches the request. Do not add implementation scope just to fill a template.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** Run planning in the current workspace by default.
If the user explicitly requested an isolated workspace or worktree, honor that request.
Otherwise, do not create or switch to a separate worktree just to start planning.

**When a persistent plan is requested or required by project governance, save it to:** the structured plan directory selected below (for example `docs/plans/YYYY-MM-DD-<feature-name>.md` or `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`)
- Only an explicit path from the user or scoped instructions overrides this structured-directory rule

**When operating in an OpenSpec-governed lane:**
- Read the selected tasks and relevant scope, design, and spec sections. Expand to other OpenSpec artifacts only when dependencies or ambiguity require it; reuse unchanged context.
- Treat OpenSpec as the canonical source for scope, design, and requirements
- Write only the execution-level plan here; do NOT create a duplicate scope/design spec

## Document Path Selection

Choose the plan path in this order:

1. A concrete path explicitly named by the user or scoped instructions
2. An existing structured plan directory such as `docs/plans` or `docs/superpowers/plans`
3. If no structured plan directory exists yet, create `docs/plans` instead of dropping the plan into bare `docs/`

Rules:

- Do not infer bare `docs/` as the default destination just because the repository already has legacy documents there.
- A generic instruction like "store docs under `docs/`" still allows structured subdirectories; it does not override `docs/plans` or `docs/superpowers/plans`.
- If the repo already has `docs/specs`, pair it with `docs/plans`; if it already has `docs/superpowers/specs`, pair it with `docs/superpowers/plans`.
- In an OpenSpec-governed lane, this plan still belongs in the structured plan directory, while scope/design/spec/tasks remain in OpenSpec artifacts.

## OpenSpec Lane Safety Gate

Use `spec-governed-development` when project governance, an explicit change, or material cross-boundary risk requires it. An existing governed change remains canonical. Do not ask the user to choose a lane merely because work has several steps; ask only when the choice materially changes scope, authority, or the required durable record. Detect available tooling before relying on it and never install missing tools implicitly.

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

**Group steps into coherent, independently verifiable units; no fixed duration is required.** For a behavior change, a useful sequence is:
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - only when separately authorized, usually at a coherent change boundary

## Plan Document Header

**Suggested persistent plan header (adapt to project conventions):**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

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

**Depends on:** none

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

- [ ] **Step 5: Commit, only if authorized**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

`Depends on` is `none` or a comma-separated list of task references. Order tasks
so that a task's dependencies always appear before it.

## No Placeholders

Every step must be actionable and identify its acceptance condition. Avoid unresolved placeholders that block execution:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" without naming the behavior, cases, and test location
- References to earlier tasks without enough context to resolve their dependency
- Vague implementation instructions without a concrete target or acceptance condition
- References to types, functions, or methods not defined in any task

## Remember
- Exact file paths always
- Include code when it resolves a subtle contract or makes a handoff executable; concise descriptions and references suffice for straightforward changes
- Exact commands with expected output
- Name relevant skills without force-loading their references
- If OpenSpec governs the change, use OpenSpec artifacts as inputs and keep this document execution-only
- DRY, YAGNI, TDD for behavior changes; commits require authorization

## Plan Review Loop

After writing the complete plan:

1. For complex, high-risk, or cross-boundary plans, use an independent plan-document reviewer when available and authorized (see plan-document-reviewer-prompt.md), with precisely crafted review context rather than session history. For narrow plans, self-review is sufficient; disclose missing independent review when it affects confidence.
   - In a **Superpowers-only lane**, provide: path to the plan document, path to spec document
   - In an **OpenSpec-governed lane**, provide: path to the plan document, plus the relevant OpenSpec artifact paths (`proposal.md`, `design.md`, relevant `specs/*`, `tasks.md`)
2. If Issues Found: resolve material issues and recheck affected sections and dependencies
3. If ✅ Approved: proceed to execution handoff

**Review loop guidance:**
- Same agent that wrote the plan fixes it (preserves context)
- Repeated review churn is a signal to reassess the disputed assumption; ask the user only when a material unresolved choice needs their judgment
- Reviewers are advisory — explain disagreements if you believe feedback is incorrect

## Execution Handoff

If the user requested a plan only or review before implementation, deliver the
plan and wait. If execution is already authorized and the path is clear, continue
with `executing-plans`; saving the plan is not a reason by itself to stop.
Conditional authorization takes effect when its condition is satisfied.

Ask only when a material decision, missing information or new authority changes
the next step. Use the host's supported interaction path, with a concise
plain-text question when a choice tool is unavailable or prohibited.

Follow the shared completion rules in `using-superpowers`. Completed planning
requests are delivered directly. Legacy packet mode is opt-in.
