---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests → Present options → Execute choice → Clean up → Handoff follow-up workflow when needed.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Verify Tests

**Before presenting options, verify tests pass:**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

### Step 2: Determine Base Branch

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main - is that correct?"

### Step 3: Present Options

Present exactly these 4 options:

When `request_user_input` is available and the choices are enumerable, use it for the main menu and both destructive confirmation stages instead of a prose-only reply prompt.

```
Implementation complete. Choose the next step:

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Reply with `1`, `2`, or `3`.
Reply with `4` to enter the discard confirmation flow.
```

**Don't add explanation** - keep options concise.
**Keep Options 1, 2, and 3 as the non-destructive choices.**
**Option 4 must enter the dedicated destructive confirmation flow below.**
**Only show copyable exact text when a downstream tool truly requires a unique text token.**

### Step 4: Execute Choice

#### Option 1: Merge Locally

```bash
# Switch to base branch
git checkout <base-branch>

# Pull latest
git pull

# Merge feature branch
git merge <feature-branch>

# Verify tests on merged result
<test command>

# If tests pass
git branch -d <feature-branch>
```

Then: Cleanup worktree (Step 5)

#### Option 2: Push and Create PR

```bash
# Push branch
git push -u origin <feature-branch>

# Create PR
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

Then: Keep the branch available for follow-up review / fixes. If an isolated workspace was used, keep it.

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. If an isolated workspace was used, preserve it at <path>."

**Don't cleanup an isolated workspace if one was used.**

#### Option 4: Discard

Use a two-stage destructive confirmation state machine: both stages use numbered choices.

Show the destructive impact before the user chooses either confirmation stage:
```text
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Isolated workspace at <path> (if one was used)
```

##### Stage 1: Enter or Leave the Destructive Subflow

Present exactly these choices:

```text
1. Continue toward the final discard confirmation step
2. Cancel
3. Input other feedback or requirements
```

Text fallback for Stage 1: Reply with `1`, `2`, or `3`.

##### Stage 2: Final Confirmation

Present exactly these choices:

```text
1. Cancel and return to the previous step
2. Confirm discard now
3. Input other feedback or requirements
```

Text fallback for Stage 2: Reply with `1`, `2`, or `3`.

State transitions:

- Choosing Stage 1 `1` moves to Stage 2.
- Choosing Stage 1 `2` returns to the parent flow; if there is no parent flow, it safely ends the destructive subflow without making changes.
- Choosing Stage 2 `1` returns to Stage 1.
- Choosing Stage 1 `3` or Stage 2 `3` treats the input as additional feedback or a help request, then returns to the same step without executing or canceling anything.
- If the user enters an invalid token or submits empty input in the text fallback, stay on the current step, show the valid tokens again, and do not execute or cancel anything.
- Only valid tokens move the state machine forward.
- Keep the final destructive confirmation in slot `2` of Stage 2 so the user must pass through one more safe choice boundary before execution.

Only if a downstream system truly requires a unique text token, show the exact text as copyable text. Do not add a default typed keyword for this skill.

If Stage 2 `2` is chosen:
```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

Then: Cleanup worktree (Step 5)

### Step 5: Cleanup Worktree

Only run this step if an isolated workspace or worktree was used.

Check if in worktree:
```bash
git worktree list | grep $(git branch --show-current)
```

If yes:
```bash
git worktree remove <worktree-path>
```

If no isolated workspace was used, skip this step.

### Step 6: OpenSpec Archive Handoff

If the current work clearly belongs to an OpenSpec-governed lane, consider whether the branch outcome is actually compatible with archive follow-up.
If an OpenSpec proposal / change was created for this work, archive follow-up is part of completion, not an optional extra.

Trigger this handoff only when the context explicitly indicates one of the following:

- the work is in an OpenSpec lane
- the current plan or context names an OpenSpec change
- the user has explicitly said this work belongs to an OpenSpec change

If none of the above is true, do nothing extra.

**Do not guess. Do not auto-archive blindly.**
**But do not skip archive once a completed OpenSpec change reaches its final integration point.**

The handoff should be brief and should make it clear when archive is the next implied lane. Keep the safety checks inside `openspec-archive-change`.

**Outcome rules:**

- **After Option 1 (Merge locally):** If the merged result represents a completed OpenSpec change, treat `openspec-archive-change` as the next mandatory `auto-continue` lane and continue directly into it.
- **After Option 2 (Push and create PR):** Do NOT recommend immediate archive before merge. Instead, make it explicit that archive is still required after the PR is merged and the change is confirmed complete.
- **After Option 3 (Keep as-is):** Do not mention archive.
- **After Option 4 (Discard):** Do not mention archive.

**If the change name is known and Option 1 completed:**

```text
Branch workflow complete.

Continue directly into `openspec-archive-change <change-name>` as the mandatory next auto-continue lane:
openspec-archive-change <change-name>
```

**If the change name is not known and Option 1 completed:**

```text
Branch workflow complete.

Continue directly into `openspec-archive-change` as the mandatory next auto-continue lane:
openspec-archive-change
```

**If Option 2 completed and the change name is known:**

```text
Branch workflow complete.

If this PR is the final integration point for OpenSpec change <change-name>, archive is still required after the PR is merged and the change is confirmed complete:
openspec-archive-change <change-name>
```

Keep change selection, artifact checks, task checks, spec sync decisions, and archive confirmation inside `openspec-archive-change`.
This step is about mandatory auto-continuation into the archive skill when the lane is already known, not about skipping that skill's checks.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | ✓ | - | - | ✓ |
| 2. Create PR | - | ✓ | ✓ | - |
| 3. Keep as-is | - | - | ✓ | - |
| 4. Discard | - | - | - | ✓ (force) |

## Common Mistakes

**Skipping test verification**
- **Problem:** Merge broken code, create failing PR
- **Fix:** Always verify tests before offering options

**Open-ended questions**
- **Problem:** "What should I do next?" → ambiguous
- **Fix:** Present exactly 4 structured options

**Automatic worktree cleanup**
- **Problem:** Remove worktree when might need it (Option 2, 3)
- **Fix:** Only cleanup for Options 1 and 4

**Collapsing discard into one step**
- **Problem:** The user can delete work without passing through both destructive confirmation layers
- **Fix:** Keep both destructive stages as `1/2/3`

**Putting the final destructive confirmation in slot 1**
- **Problem:** A rushed second-step selection can execute the destructive action too easily
- **Fix:** Keep Stage 2 slot `1` as the safe return path and slot `2` as the final confirmation

**Treating free input as confirmation**
- **Problem:** A note, question, or help request accidentally executes or cancels the destructive flow
- **Fix:** Keep slot `3` as feedback-only and always return to the same step afterward

**Advancing on invalid fallback input**
- **Problem:** Typos or empty submits accidentally execute, cancel, or exit the destructive flow
- **Fix:** Stay on the current step until the user provides a valid token

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying tests on result
- Delete work without confirmation
- Force-push without explicit request

**Always:**
- Verify tests before offering options
- Present exactly 4 options
- Run the two-stage destructive confirmation flow for Option 4
- Clean up an isolated workspace only when one was actually used, and only for Options 1 & 4
- Use OpenSpec archive handoff when the context clearly indicates an OpenSpec change and the branch outcome is compatible with completion; for a completed created change, this handoff is required

## Integration

**Called by:**
- **subagent-driven-development** (Step 7) - After all tasks complete
- **executing-plans** (Step 5) - After all batches complete

**Pairs with:**
- **using-git-worktrees** - Optional pairing only when an isolated workspace or worktree was explicitly used earlier
- **openspec-archive-change** - Required finalization step after branch completion for completed OpenSpec-governed work

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
