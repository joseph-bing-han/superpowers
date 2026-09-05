---
name: verification-before-completion
description: Use before claiming work is complete, fixed, or passing, and before authorized commit or integration steps that require verification evidence
---

# Verification Before Completion

## Overview

Completion claims must match the available verification evidence and its coverage.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

Evidence is fresh when its relevant inputs, environment, and contracts have not changed. Reuse reliable earlier results after checking those conditions; a new message is not a reason to rerun tests. Rerun affected checks after relevant changes, and name any untested or unavailable coverage.

## The Gate Function

```
BEFORE claiming completion or correctness:

1. IDENTIFY: What evidence and scope support this claim?
2. CHECK: Reuse still-valid evidence or run the affected verification command
3. READ: Check relevant output, exit code, executed test count, failures and skips
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Do not present missing or narrower evidence as complete verification
```

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Named suite actually executed with 0 failures | Zero tests, skips, invalidated earlier run, "should pass" |
| Linter clean | Named lint scope: 0 errors | Extrapolating a focused check to untouched scopes |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Presenting focused verification as proof of broader coverage
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Focused checks support focused claims; broaden with risk and shared contracts |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
✅ Reproduce old behavior in an isolated fixture or reversible patch → Run (FAIL) → Apply fix → Run (PASS)
❌ "I've written a regression test" (without red-green verification)
```

**Build:**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

## Why This Matters

From 24 failure memories:
- your human partner said "I don't believe you" - trust broken
- Undefined functions shipped - would crash
- Missing requirements shipped - incomplete features
- Time wasted on false completion → redirect → rework
- Violates: "Honesty is a core value. If you lie, you'll be replaced."

## When To Apply

**Apply before:**
- ANY variation of success/completion claims
- Committing, PR creation, task completion

Choose verification proportionate to the change: text-only edits need relevant format/link checks; local behavior changes need focused regression tests; shared workflows need contract and representative positive/negative behavior checks; integration and release need the corresponding project checks. A missing optional harness does not block other authorized work, but its untested coverage must be reported. Do not run unrelated full suites solely because a prior task did.

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness

## The Bottom Line

**No shortcuts for verification.**

Confirm the evidence remains valid. Read the result. THEN make the appropriately scoped claim.

This is non-negotiable.

## Completion

Follow the shared completion rules in `using-superpowers`: continue safe,
authorized work; ask only about a genuine blocker or decision; deliver completed
requests directly with evidence and limitations. Legacy packet mode is opt-in.
