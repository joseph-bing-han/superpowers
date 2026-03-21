# Numeric Choice Interaction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Superpowers present numbered options for user-choice prompts across the main workflow skills, while preserving typed confirmation for dangerous actions and documenting that true single-key submit is a separate Codex input-layer concern.

**Architecture:** Add a repository-wide interaction rule in `skills/using-superpowers/SKILL.md`, then update the high-frequency workflow skills to obey that rule with context-specific numbered choices and a last-option free-text fallback. Protect the prompt contract with a small Bash regression test that inspects the skill docs and Codex docs so future edits do not drift back to open-ended prompts.

**Tech Stack:** Markdown skill docs, Bash, ripgrep (`rg`), Git worktrees

---

## File Structure

- `skills/using-superpowers/SKILL.md`
  Purpose: Define the repo-wide rule that user-choice prompts should prefer numbered options, put the recommended choice in slot `1`, and keep free-text fallback only when needed.
- `skills/brainstorming/SKILL.md`
  Purpose: Convert clarifying questions, design approvals, and artifact review gates away from “type approval words” toward numbered options.
- `skills/writing-plans/SKILL.md`
  Purpose: Keep the execution handoff fully numbered and remove the remaining open-ended wording.
- `skills/executing-plans/SKILL.md`
  Purpose: Tell the executor to raise blockers and concerns with numbered choices instead of open-ended questions.
- `skills/finishing-a-development-branch/SKILL.md`
  Purpose: Align the branch-finish workflow with the new interaction rule without weakening the typed `discard` confirmation.
- `docs/README.codex.md`
  Purpose: Explain the Phase 1 vs Phase 2 boundary for Codex users: numbered options are in-scope here, raw single-key submit is not.
- `docs/testing.md`
  Purpose: Document the new prompt-contract regression test entry point.
- `tests/prompt-contracts/test-numeric-choice-interactions.sh`
  Purpose: Guard the prompt contract so numbered-choice guidance and typed-dangerous-action confirmation stay in place.

### Task 1: Add the Prompt-Contract Regression Test

**Files:**
- Create: `tests/prompt-contracts/test-numeric-choice-interactions.sh`
- Modify: `docs/testing.md`

- [ ] **Step 1: Write the failing test script**

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

assert_contains() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if rg -q "$pattern" "$REPO_ROOT/$file"; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Pattern: $pattern"
    exit 1
  fi
}

assert_contains "skills/using-superpowers/SKILL.md" "numbered options" "global rule mentions numbered options"
assert_contains "skills/using-superpowers/SKILL.md" "recommended.*1|option 1" "global rule reserves slot 1 for the recommendation"
assert_contains "skills/brainstorming/SKILL.md" "1\\. Agree and continue|1\\. Approve and continue" "brainstorming approval uses numbered choice"
assert_contains "skills/brainstorming/SKILL.md" "Input other feedback|Input other requirements" "brainstorming keeps a free-text fallback"
assert_contains "skills/writing-plans/SKILL.md" "1\\. Subagent-Driven" "plan execution handoff stays numbered"
assert_contains "skills/executing-plans/SKILL.md" "numbered options|structured options" "executor guidance mentions numbered options"
assert_contains "skills/finishing-a-development-branch/SKILL.md" "Type 'discard' to confirm\\." "dangerous actions still require typed confirmation"
assert_contains "docs/README.codex.md" "single-key|raw key|numbered options" "Codex docs describe the scope boundary"

echo "All numeric-choice prompt contract checks passed."
```

- [ ] **Step 2: Make the test executable**

Run: `chmod +x tests/prompt-contracts/test-numeric-choice-interactions.sh`  
Expected: no output

- [ ] **Step 3: Run the test to verify it fails**

Run: `bash tests/prompt-contracts/test-numeric-choice-interactions.sh`  
Expected: FAIL because the target files do not yet contain the new numbered-choice guidance

- [ ] **Step 4: Document the new test entry point**

````md
## Prompt Contract Tests

These tests verify skill-document interaction rules without invoking a live model.

```bash
bash tests/prompt-contracts/test-numeric-choice-interactions.sh
```
````

- [ ] **Step 5: Re-run the failing test**

Run: `bash tests/prompt-contracts/test-numeric-choice-interactions.sh`  
Expected: still FAIL, because only the test and docs entry point exist so far

### Task 2: Implement Numbered-Choice Guidance Across Workflow Skills

**Files:**
- Modify: `skills/using-superpowers/SKILL.md:95-129`
- Modify: `skills/brainstorming/SKILL.md:20-32`
- Modify: `skills/brainstorming/SKILL.md:89-150`
- Modify: `skills/writing-plans/SKILL.md:140-158`
- Modify: `skills/executing-plans/SKILL.md:18-23`
- Modify: `skills/executing-plans/SKILL.md:39-55`
- Modify: `skills/finishing-a-development-branch/SKILL.md:49-64`
- Modify: `skills/finishing-a-development-branch/SKILL.md:114-126`
- Test: `tests/prompt-contracts/test-numeric-choice-interactions.sh`

- [ ] **Step 1: Add the global rule to `skills/using-superpowers/SKILL.md`**

```md
## User Choice Formatting

When asking the user to choose between actions, prefer numbered options instead of requiring natural-language replies.

- Put the recommended option in slot `1`
- Prefer 2-4 options
- Use a final free-text fallback only when the choice cannot be fully enumerated
- Do not use open-ended prompts like "Which approach?" when concrete choices are already known
- Keep typed confirmations for dangerous or destructive actions
```

- [ ] **Step 2: Update `skills/brainstorming/SKILL.md` to require numbered approvals and choices**

````md
- Prefer numbered options when asking clarifying questions with known choices
- For approval gates, prefer patterns like:

```text
1. Agree and continue
2. Request changes
3. Input other feedback or requirements
```

- Avoid requiring the user to type approval words like "agree", "approved", or "go ahead"
````

- [ ] **Step 3: Update `skills/writing-plans/SKILL.md` so the execution handoff is fully numbered and non-open-ended**

```md
Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Choose the execution path:

1. Subagent-Driven (recommended)
2. Inline Execution
3. Input other requirements
```

- [ ] **Step 4: Update `skills/executing-plans/SKILL.md` so blockers and plan concerns are raised with numbered choices**

```md
If concerns or blockers need human input, present numbered options instead of open-ended questions.

Example:
1. Clarify the missing instruction
2. Revise the plan before execution
3. Stop here and investigate the blocker
4. Input other guidance
```

- [ ] **Step 5: Align `skills/finishing-a-development-branch/SKILL.md` with the new rule without weakening safety**

```md
- Keep the four numbered completion options exactly as they are
- Explicitly call out that Option 4 still requires the user to type `discard`
- Do not add a one-key shortcut for destructive actions
```

- [ ] **Step 6: Run the prompt-contract test to verify it now passes**

Run: `bash tests/prompt-contracts/test-numeric-choice-interactions.sh`  
Expected: PASS with all checks green

- [ ] **Step 7: Commit the workflow guidance and regression test**

```bash
git add \
  docs/testing.md \
  skills/using-superpowers/SKILL.md \
  skills/brainstorming/SKILL.md \
  skills/writing-plans/SKILL.md \
  skills/executing-plans/SKILL.md \
  skills/finishing-a-development-branch/SKILL.md \
  tests/prompt-contracts/test-numeric-choice-interactions.sh
git commit -m "feat: add numeric choice guidance for workflow prompts"
```

### Task 3: Document the Codex Scope Boundary

**Files:**
- Modify: `docs/README.codex.md:50-98`
- Test: `tests/prompt-contracts/test-numeric-choice-interactions.sh`

- [ ] **Step 1: Extend the Codex docs with the Phase 1 vs Phase 2 boundary**

```md
## Choice-Based Interaction

Superpowers skill prompts now prefer numbered options for user-choice moments so Codex users can respond with short numeric replies instead of typing approval phrases.

This does not mean Superpowers can force raw single-key submit inside Codex CLI. True "press one key and continue immediately" behavior depends on the Codex input layer, not the skill documents.
```

- [ ] **Step 2: Run the prompt-contract test to verify the new doc text is covered**

Run: `bash tests/prompt-contracts/test-numeric-choice-interactions.sh`  
Expected: PASS, including the Codex scope-boundary assertion

- [ ] **Step 3: Review the final diff before committing**

Run: `git diff -- docs/README.codex.md docs/testing.md skills/using-superpowers/SKILL.md skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md skills/finishing-a-development-branch/SKILL.md tests/prompt-contracts/test-numeric-choice-interactions.sh`  
Expected: diff shows only numbered-choice guidance, Codex boundary clarification, and the new prompt-contract test

- [ ] **Step 4: Commit the Codex documentation clarification if it was not included in the previous commit**

```bash
git add docs/README.codex.md
git commit -m "docs: clarify Codex numeric choice interaction scope"
```

### Task 4: Final Verification for the Plan’s Implementation Scope

**Files:**
- Verify: `docs/README.codex.md`
- Verify: `docs/testing.md`
- Verify: `skills/using-superpowers/SKILL.md`
- Verify: `skills/brainstorming/SKILL.md`
- Verify: `skills/writing-plans/SKILL.md`
- Verify: `skills/executing-plans/SKILL.md`
- Verify: `skills/finishing-a-development-branch/SKILL.md`
- Verify: `tests/prompt-contracts/test-numeric-choice-interactions.sh`

- [ ] **Step 1: Run the prompt-contract regression test one more time from the worktree root**

Run: `bash tests/prompt-contracts/test-numeric-choice-interactions.sh`  
Expected: PASS with no missing-pattern failures

- [ ] **Step 2: Record the worktree status before handoff**

Run: `git status --short`  
Expected: clean working tree, or only intentionally uncommitted changes if the user requested them

- [ ] **Step 3: Hand off to branch-finishing or execution**

Run: `printf '%s\n' "Ready for superpowers:subagent-driven-development or superpowers:executing-plans"`  
Expected: prints the handoff message for the next workflow stage
