---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Overview

Load plan, review critically, execute all tasks, report when complete.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (such as Claude Code or Codex). If subagents are available, use superpowers:subagent-driven-development instead of this skill.

## The Process

Before executing tasks, ensure you are already inside a dedicated worktree.
If not already in a dedicated worktree, invoke `using-git-worktrees` first.
Do not create a nested worktree if one is already active; reuse the current dedicated worktree.

Routine summaries, checkpoints, and batch boundaries are internal progress markers, not human approval gates. Do not stop at routine summaries, checkpoints, or batch boundaries just to ask whether to continue.
Before ending a routine batch boundary, classify the batch boundary as `auto-continue`, `needs-user-decision`, or `terminal-choice`.
- `auto-continue`: the next task is already clear and safe; execute it immediately
- `needs-user-decision`: the workflow cannot safely continue until the user chooses among concrete options; use `request_user_input`
- `terminal-choice`: the requested execution work is complete, but do not end directly; use `request_user_input` with:
  1. 结束
  2. 继续
  3. 自由输入
Do not stop with prose-only follow-up text like `if you want me to continue` after a routine summary or checkpoint.
Do not stop with a declarative prose-only next-step proposal like `the next best step is to continue with task 2` or `next I would continue with task 2` after a routine summary or checkpoint.
This also includes judgment-framed, comparative, or recommendation-framed checkpoint endings, including Chinese variants such as `如果按我的判断，下一步应该先……`, `下一步最值得做的不是 A，而是 B`, `接下来更值得做的是……`, or `我建议先……`
If the next task is already clear and safe, execute it rather than narrating the step and stopping.
If the path is clear, keep executing automatically.

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting, using numbered options instead of an open-ended prompt whenever the next actions are already known
4. If concerns need human input and the next actions are already known, use `request_user_input` when available instead of a prose-only numbered reply prompt.
5. If no concerns: Create TodoWrite and proceed

### Step 2: Execute Tasks

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed
5. Continue to the next task automatically unless a real blocker requires human input

### Step 3: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice
- Treat that finishing step as the standard worktree convergence path: merge/discard outcomes clean up the worktree, while PR/keep-as-is outcomes preserve it for follow-up work

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

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

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:finishing-a-development-branch** - Complete development after all tasks
