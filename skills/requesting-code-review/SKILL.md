---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- After all plan tasks complete and their own verifications pass
- After completing major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

Review once per plan, not once per task. Per-task verification already catches
real errors where they happen; a reviewer after every task adds round trips
without adding much protection.

## How to Request

**1. Get git SHAs:**

Cover the whole plan, not the last task:

```bash
BASE_SHA=$(git rev-parse <commit before the first task>)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

If you captured the baseline before executing the plan, use that value. If not,
find the commit that precedes the first task's commit — not `HEAD~1`, which
covers only the most recent task.

**2. Dispatch code reviewer subagent:**

Fill the template at `code-reviewer.md`. For reviewer model selection per
platform, see `using-superpowers/references/cursor-tools.md` (Cursor) or the
equivalent reference for your platform.

**Placeholders:**
- `{DESCRIPTION}` - Brief summary of what you built
- `{PLAN_OR_REQUIREMENTS}` - Path to the plan; pass the whole plan, since it is the standard the work is judged against
- `{BASE_SHA}` - Commit before the first task
- `{HEAD_SHA}` - Ending commit

**3. Act on feedback:**
- Fix all Critical and Important issues together
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
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Coverage: verified tasks 1-5 against the diff
  Issues:
    Important: Missing progress indicators (task 3)
    Important: Task 4 left repairIndex() unreachable after the task 5 refactor
    Minor: Magic number (100) for reporting interval
  Assessment: With fixes

You: [Fix both Important issues together]
[Re-review, then finish the branch]
```

That second Important issue is the kind a per-task review cannot find: each task
was internally correct, but task 5 stranded task 4's code.

## Integration with Workflows

**Executing Plans:**
- Review once, after every task is complete and verified
- Pass the whole plan as the reference standard
- Fix all Critical and Important issues together, then re-review

**Ad-Hoc Development:**
- Review before merge
- Review when stuck

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Finish a branch or merge with unfixed Important issues
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at: requesting-code-review/code-reviewer.md

## Terminal Endgate Protocol

If this skill reaches a terminal boundary where the current request appears complete:
- This skill must not end the conversation directly with prose, `task_complete`, or a typed free-form prompt.
- Treat this terminal boundary as strict `endgate-state-packet` territory; a canonical machine-readable carrier is mandatory, not optional guidance.
- Ensure the canonical machine-readable carrier contains this exact packet before the next machine action:
```text
ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: TERMINAL_CHOICE
ENDGATE_CHOICE_KIND: CONTINUE_OR_STOP
ENDGATE_NEXT_ACTION: REQUEST_USER_INPUT
```
- In strict packet mode, a canonical machine-readable carrier must exist before the next machine action.
- Prefer a structured carrier when the runtime supports it; a user-visible tail block remains only a fallback.
- Route true completion through `terminal-choice`.
- The very next action must be `request_user_input`.
- In Codex tool-backed terminal-choice popups, author only:
  1. 结束 (Recommended)
  2. 继续
- Treat free-form requirements as the client-provided `Other` / notes path instead of authoring a duplicate free-form option.
- Do not produce a plain final-answer-style closeout or any other prose-only closeout before the terminal-choice popup.
- A completed assessment, audit, comparison, review, recommendation memo, or research report is still a terminal boundary. After presenting that deliverable, emit the `TERMINAL_CHOICE` packet and immediately call `request_user_input`; a bare closeout such as `结论`, `最终判断`, `我的推荐`, or `这轮我没有改代码，只做了……` is still invalid if it ends the turn directly.
- Concrete invitation prose such as `如果你同意，我下一步可以直接按这个推荐方案 A 开始修。` must resolve through `request_user_input` or `auto-continue`, never `task_complete`.
- If the next safe step is already implied, use the relevant non-terminal continuation path instead of stopping at terminal-choice.
