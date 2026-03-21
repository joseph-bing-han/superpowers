---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests → Detect environment → Present options → Execute choice → Clean up → Handoff follow-up workflow when needed.

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

### Step 2: Detect Environment

**Determine workspace state before presenting options:**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

This determines which menu to show and how cleanup works:

| State | Menu | Cleanup |
|-------|------|---------|
| `GIT_DIR == GIT_COMMON` (normal repo) | Standard 4 options | No worktree to clean up |
| `GIT_DIR != GIT_COMMON`, named branch | Standard 4 options | Provenance-based (see Step 6) |
| `GIT_DIR != GIT_COMMON`, detached HEAD | Reduced 3 options (no merge) | No cleanup (externally managed) |

### Step 3: Determine Base Branch

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main - is that correct?"

### Step 4: Present Options

**Normal repo and named-branch worktree — present exactly these 4 options:**

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

**Detached HEAD — present exactly these 3 options:**

```
Implementation complete. You're on a detached HEAD (externally managed workspace).

1. Push as new branch and create a Pull Request
2. Keep as-is (I'll handle it later)
3. Discard this work

Which option?
```

**Don't add explanation** - keep options concise.
**Keep Options 1, 2, and 3 as the non-destructive choices.**
**Option 4 must enter the dedicated destructive confirmation flow below.**
**Only show copyable exact text when a downstream tool truly requires a unique text token.**

### Step 5: Execute Choice

#### Option 1: Merge Locally

```bash
# Get main repo root for CWD safety
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"

# Merge first — verify success before removing anything
git checkout <base-branch>
git pull
git merge <feature-branch>

# Verify tests on merged result
<test command>

# Only after merge succeeds: cleanup worktree (Step 6), then delete branch
```

Then: Cleanup worktree (Step 6), then delete branch:

```bash
git branch -d <feature-branch>
```

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

**Do NOT clean up worktree** — keep it alive for PR follow-up review/fixes.

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

**Don't cleanup worktree.**

#### Option 4: Discard

Use a two-stage destructive confirmation state machine: both stages use numbered choices.

Show the destructive impact before the user chooses either confirmation stage:
```text
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>
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
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
```

Then: Cleanup worktree (Step 6), then force-delete branch:
```bash
git branch -D <feature-branch>
```

### Step 6: Cleanup Workspace

**Only runs for Options 1 and 4.** Options 2 and 3 always preserve the worktree.

**For Options 1 and 4:**

Check if in worktree:
```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

**If `GIT_DIR == GIT_COMMON`:** Normal repo, no worktree to clean up. Done.

**If worktree path is under `.worktrees/`, `worktrees/`, or `~/.config/superpowers/worktrees/`:** Superpowers created this worktree — we own cleanup.

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
git worktree remove "$WORKTREE_PATH"
git worktree prune  # Self-healing: clean up any stale registrations
```

**Otherwise:** The host environment (harness) owns this workspace. Do NOT remove it. If your platform provides a workspace-exit tool, use it. Otherwise, leave the workspace in place.

### Step 7: OpenSpec Archive Handoff

If the current work clearly belongs to an OpenSpec-governed lane, consider whether the branch outcome is actually compatible with archive follow-up.

Trigger this handoff only when the context explicitly indicates one of the following:

- the work is in an OpenSpec lane
- the current plan or context names an OpenSpec change
- the user has explicitly said this work belongs to an OpenSpec change

If none of the above is true, do nothing extra.

**Do not guess. Do not auto-archive.**

The handoff should be brief and should make it clear that archive is the next recommended step, not something already completed.

**Outcome rules:**

- **After Option 1 (Merge locally):** If the merged result represents a completed OpenSpec change, recommend `openspec-archive-change` now.
- **After Option 2 (Push and create PR):** Do NOT recommend immediate archive. Instead, note that archive should happen only after the PR is merged and the change is confirmed complete.
- **After Option 3 (Keep as-is):** Do not mention archive.
- **After Option 4 (Discard):** Do not mention archive.

**If the change name is known and Option 1 completed:**

```text
Branch workflow complete.

If this work belongs to OpenSpec change <change-name>, the next recommended step is:
openspec-archive-change <change-name>
```

**If the change name is not known and Option 1 completed:**

```text
Branch workflow complete.

If this work belongs to an OpenSpec change, the next recommended step is:
openspec-archive-change
```

**If Option 2 completed and the change name is known:**

```text
Branch workflow complete.

If this PR is the final integration point for OpenSpec change <change-name>, archive only after the PR is merged and the change is confirmed complete:
openspec-archive-change <change-name>
```

Keep change selection, artifact checks, task checks, spec sync decisions, and archive confirmation inside `openspec-archive-change`.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | yes | - | - | yes |
| 2. Create PR | - | yes | yes | - |
| 3. Keep as-is | - | - | yes | - |
| 4. Discard | - | - | - | yes (force) |

## Common Mistakes

**Skipping test verification**
- **Problem:** Merge broken code, create failing PR
- **Fix:** Always verify tests before offering options

**Open-ended questions**
- **Problem:** "What should I do next?" is ambiguous
- **Fix:** Present exactly 4 structured options (or 3 for detached HEAD)

**Cleaning up worktree for Option 2**
- **Problem:** Remove worktree user needs for PR iteration
- **Fix:** Only cleanup for Options 1 and 4

**Deleting branch before removing worktree**
- **Problem:** `git branch -d` fails because worktree still references the branch
- **Fix:** Merge first, remove worktree, then delete branch

**Running git worktree remove from inside the worktree**
- **Problem:** Command fails silently when CWD is inside the worktree being removed
- **Fix:** Always `cd` to main repo root before `git worktree remove`

**Cleaning up harness-owned worktrees**
- **Problem:** Removing a worktree the harness created causes phantom state
- **Fix:** Only clean up worktrees under `.worktrees/`, `worktrees/`, or `~/.config/superpowers/worktrees/`

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
- Remove a worktree before confirming merge success
- Clean up worktrees you didn't create (provenance check)
- Run `git worktree remove` from inside the worktree

**Always:**
- Verify tests before offering options
- Detect environment before presenting menu
- Present exactly 4 options (or 3 for detached HEAD)
- Run the two-stage destructive confirmation flow for Option 4
- Clean up worktree for Options 1 & 4 only
- `cd` to main repo root before worktree removal
- Run `git worktree prune` after removal
- Use OpenSpec archive handoff only when the context clearly indicates an OpenSpec change and the branch outcome is compatible with completion

## Integration

**Called by:**
- **subagent-driven-development** (Step 7) - After all tasks complete
- **executing-plans** (Step 5) - After all batches complete

**Pairs with:**
- **using-git-worktrees** - Cleans up worktree created by that skill
- **openspec-archive-change** - Optional next step after branch completion for OpenSpec-governed work
