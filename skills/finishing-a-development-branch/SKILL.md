---
name: finishing-a-development-branch
description: Use when branch integration, PR submission, or cleanup is requested after development; not for every completed workspace edit
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests → Present options → Execute choice → Clean up → Handoff follow-up workflow when needed.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Verify the Requested Outcome

Choose checks from the actual affected behavior and repository test instructions, not a generic full-suite command. Reuse reliable results when their inputs, environment, and contracts are unchanged. Distinguish failures introduced here, pre-existing failures, skipped tests, and unavailable harnesses.

A failing required check blocks a readiness claim or integration that requires it. It does not block an honest report, preserving the branch, or an explicitly confirmed discard. Diagnose safe in-scope failures before escalating.

### Step 2: Determine the Target Only When Needed

For integration, inspect the configured upstream, remote default branch, project policy, and user's requested target. Do not assume main/master; this fork uses its actual configured target. Ask only when the target remains materially ambiguous. Inspect worktree status and preserve unrelated changes before switching branches.

### Step 3: Follow Authorization

An editing request is not authorization to commit, push, create a PR, merge, delete a branch, or remove a worktree. These are distinct outcomes. Execute an outcome already clearly requested without asking the user to choose it again. If only workspace editing was requested, report the result and leave the work in place.

When an integration outcome is genuinely undecided, present the relevant choices and tradeoffs using the host's supported interaction mechanism. Do not force a fixed four-option menu or treat merge as non-destructive. The following sections describe possible authorized outcomes, not automatic steps.

### Step 4: Execute Choice

#### Option 1: Merge Locally

```bash
# Switch to base branch
git checkout <base-branch>

# Fetch or update only as authorized by the integration workflow

# Merge feature branch
git merge <feature-branch>

# Verify tests on merged result
<test command>

# Only if branch cleanup is also authorized and no work would be lost
git branch -d <feature-branch>
```

Then: Cleanup worktree (Step 5)

#### Option 2: Push and Create PR

```bash
# Push branch
git push -u origin <feature-branch>

# Create PR using the target repository's complete template and submission rules
gh pr create --title "<title>" --body-file <reviewed-pr-body-path>
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

Only run this step if this task created an isolated workspace or worktree and cleanup is authorized. Resolve the exact path, confirm it is not the primary workspace, and check for uncommitted or unrelated work before removal. Preserve dirty or pre-existing resources unless their removal is explicitly approved.

Check if in worktree:
```bash
git worktree list --porcelain
```

If yes:
```bash
git worktree remove <worktree-path>
```

If no isolated workspace was used, skip this step.

### Step 6: OpenSpec Lifecycle

Only apply this section when the task explicitly belongs to an OpenSpec change. Distinguish completion of this request, completion of the whole change, final integration, and archival.

Archive is appropriate only when the whole change is complete, the required integration point is confirmed, and project policy or the user authorizes archive within this task. Continue automatically only when all those conditions are met. A local merge does not by itself establish final integration. A PR awaiting merge is not ready for archive.

When archive is still pending but outside the current task, report the pending lifecycle step without blocking delivery or expanding scope. Detect whether the archive skill/tool is available; do not install it implicitly, invent a successful archive, or archive blindly. Preserve incomplete or discarded changes unless their removal is explicitly authorized.

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
- **Fix:** Verify the checks required for the requested integration; report failures without blocking preservation or status delivery

**Open-ended questions**
- **Problem:** "What should I do next?" → ambiguous
- **Fix:** Ask about only the unresolved outcome; follow an already-authorized choice directly

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
- Claim readiness or perform gated integration with failing required checks
- Merge without verifying tests on result
- Delete work without confirmation
- Force-push without explicit request

**Always:**
- Verify checks proportionate to the requested outcome
- Keep commit, push, PR, merge, and cleanup authorization distinct
- Run the two-stage destructive confirmation flow for Option 4
- Clean up an isolated workspace only when one was actually used, and only for Options 1 & 4
- Report pending OpenSpec lifecycle steps and archive only when completion, final integration, and authority are established

## Integration

**Called by:**
- **executing-plans** (Step 4) - After all tasks complete and batch review passes

**Pairs with:**
- **openspec-archive-change** - Finalization when the whole governed change is integrated and archive is in scope

## Completion

Follow the shared completion rules in `using-superpowers`: continue safe,
authorized work; ask only about a genuine blocker or decision; deliver completed
requests directly with evidence and limitations. Legacy packet mode is opt-in.
