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
- `terminal-choice`: the requested execution work is complete, but do not end directly; use `request_user_input`
- In Codex tool-backed terminal-choice popups, author only:
  1. 结束 (Recommended)
  2. 继续
- Treat free-form requirements as the client-provided `Other` / notes path instead of authoring a duplicate free-form option
- For checkpoint, handoff, and terminal-choice nodes driven by `request_user_input`, the `request_user_input` call and its transcript event are the machine contract; surrounding prose is explanatory only.
- Every routine boundary in this repository uses `endgate-state-packet`; treat the last packet plus its post-packet event window as the governing runtime contract for that boundary.
- Earlier same-turn tool calls do not satisfy a later `endgate-state-packet`; prose invitation matching remains only a fallback safety net when no packet exists.
- At every routine boundary in this repository, emit this exact packet immediately before the next machine action:
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
- `AUTO_CONTINUE`: emit the packet, then immediately execute the next concrete task.
- `NEEDS_USER_DECISION`: emit the packet, then immediately call `request_user_input` with the concrete blocker-resolution or next-step options.
- `TERMINAL_CHOICE`: emit the packet, then immediately call `request_user_input` with only `结束 (Recommended)` and `继续`.
- When this routine boundary reaches `terminal-choice`, the next action is the popup itself. The very next action must be `request_user_input`.
- Do not produce a plain final-answer-style closeout before the terminal-choice popup.
- A settled recommendation, final draft, or final summary is still not permission to end directly.
- Do not call `task_complete` while the terminal-choice popup is still pending.
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

## Terminal Endgate Protocol

If this skill reaches a terminal boundary where the current request appears complete:
- This skill must not end the conversation directly with prose, `task_complete`, or a typed free-form prompt.
- Treat this terminal boundary as strict `endgate-state-packet` territory; packet emission is mandatory, not optional guidance.
- Emit this exact packet immediately before the next machine action:
```text
ENDGATE_PROTOCOL_VERSION: 1
ENDGATE_STATE: TERMINAL_CHOICE
ENDGATE_CHOICE_KIND: CONTINUE_OR_STOP
ENDGATE_NEXT_ACTION: REQUEST_USER_INPUT
```
- The last 4 non-empty lines before the next machine action must be that canonical `ENDGATE_*` packet.
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
