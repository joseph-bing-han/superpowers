---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Use an independent code reviewer for complex, high-risk, or shared behavior when available and authorized. Provide task-specific review context rather than session history. For narrow changes, self-review can suffice; disclose unavailable independent review when material. Do not change global configuration to enable reviewers.

**Core principle:** Review early, review often.

## When to Request Review

**Review required, with depth proportionate to risk:**
- Before claiming the in-scope plan tasks are complete
- After completing a major feature or shared-contract change
- Before authorized integration into the target branch

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

Review the complete authorized task set together. Per-task verification already catches
real errors where they happen; a reviewer after every task adds round trips
without adding much protection.

## How to Request

**1. Identify the complete review scope:**

Identify the authorized tasks and acceptance criteria before selecting the diff.
Pass the whole plan as context, with an explicit `REVIEW_SCOPE` listing the
authorized task IDs, acceptance criteria, and deferred or excluded tasks.
If the request covers the whole plan, say so. Review every in-scope task together;
the presence of other plan tasks does not make them part of this assignment.

```bash
BASE_SHA=$(git rev-parse <commit before the first task>)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

If you captured the baseline before executing the plan, use that value. If not,
find the commit that precedes the first task's commit — not `HEAD~1`, which
covers only the most recent task.

Also inspect `git status --short`, `git diff --cached`, `git diff`, and in-scope untracked files. A commit range alone omits work that has not been committed. Give the reviewer the baseline, exact relevant paths, and all these changes, clearly separating pre-existing user edits. Do not create a commit solely for review.

**2. Dispatch code reviewer subagent:**

Fill the template at `code-reviewer.md`. For reviewer model selection per
platform, see `using-superpowers/references/cursor-tools.md` (Cursor) or the
equivalent reference for your platform.

**Placeholders:**
- `{DESCRIPTION}` - Brief summary of what you built
- `{PLAN_OR_REQUIREMENTS}` - The relevant requirements or whole plan for context
- `{REVIEW_SCOPE}` - Authorized task IDs or requirements, acceptance criteria, and deferred or excluded tasks; explicitly say when all plan tasks are in scope
- `{BASE_SHA}` - Commit before the first task
- `{HEAD_SHA}` - Ending commit, supplemented by in-scope staged, unstaged, and untracked contents
- `{WORKING_TREE_SCOPE}` - Exact in-scope paths and staged/unstaged/untracked contents

**3. Act on feedback:**
- Fix all valid Critical and Important issues affecting the authorized deliverable; do not implement deferred tasks to satisfy a review of the wrong scope
- Note Minor issues for later
- Re-review after the fixes
- Push back if reviewer is wrong (with reasoning)

## Example

```
[All 5 tasks in the deployment plan are complete, each verification passed]

You: All tasks are done. Requesting review of the completed work.

BASE_SHA=a7981ec   # captured before Task 1
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code reviewer subagent]
  DESCRIPTION: Deployment index verification and repair, tasks 1-5
  PLAN_OR_REQUIREMENTS: docs/superpowers/plans/deployment-plan.md
  REVIEW_SCOPE: Tasks 1-5 and their acceptance criteria; no deferred tasks
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Issues:
    Important: Missing progress indicators (task 3)
    Important: Task 4 left repairIndex() unreachable after the task 5 refactor
    Minor: Magic number (100) for reporting interval
  Coverage: verified tasks 1-5 against the complete diff
  Strengths: Clean architecture, real tests
  Assessment: With fixes

You: [Fix both Important issues together]
[Re-review, then finish the branch]
```

That second Important issue is the kind a per-task review cannot find: each task
was internally correct, but task 5 stranded task 4's code.

## Integration with Workflows

**Executing Plans:**
- Review once, after every in-scope task is complete and verified
- Pass the whole plan as context and the authorized subset as the completion standard
- Fix all Critical and Important issues together, then re-review

**Ad-Hoc Development:**
- Review before merge
- Review when stuck

## Red Flags

**Never:**
- Skip proportionate self-review or project-required review
- Ignore Critical issues
- Claim readiness or merge with unfixed Important issues; reporting and preserving incomplete work remain valid
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at: requesting-code-review/code-reviewer.md

## Completion

Follow the shared completion rules in `using-superpowers`: continue safe,
authorized work; ask only about a genuine blocker or decision; deliver completed
requests directly with evidence and limitations. Legacy packet mode is opt-in.
