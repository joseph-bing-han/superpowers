# Claude Code Skills Tests

Automated tests for superpowers skills using Claude Code CLI.

## Overview

This test suite verifies that skills are loaded correctly and Claude follows them as expected. Tests invoke Claude Code in headless mode (`claude -p`) and verify the behavior.

## Requirements

- Claude Code CLI installed and in PATH (`claude --version` should work)
- Local superpowers plugin installed (see main README for installation)
- The suite runner requires `timeout` on `PATH`; it reports unavailable prerequisites instead of installing tools or changing global settings.

## Running Tests

### Run the local runner regression (no Claude session):
```bash
bash tests/claude-code/test-run-skill-tests.sh
```

Run this command from the repository root. The remaining commands are relative to `tests/claude-code/`.
There is no default fast skill suite: invoking `run-skill-tests.sh` without a test selection reports `NOT RUN` and returns non-zero.

### Run integration tests (slow, 10-30 minutes):
```bash
./run-skill-tests.sh --integration --timeout 1800
```

### Run specific test:
```bash
./run-skill-tests.sh --test test-requesting-code-review.sh
```

### Run with verbose output:
```bash
./run-skill-tests.sh --verbose --test test-requesting-code-review.sh
```

### Set custom timeout:
```bash
./run-skill-tests.sh --integration --timeout 1800
```

## Test Structure

### test-helpers.sh
Common functions for skills testing:
- `run_claude "prompt" [timeout]` - Run Claude with prompt
- `assert_contains output pattern name` - Verify pattern exists
- `assert_not_contains output pattern name` - Verify pattern absent
- `assert_count output pattern count name` - Verify exact count
- `assert_order output pattern_a pattern_b name` - Verify order
- `create_test_project` - Create temp test directory
- `create_test_plan project_dir` - Create sample plan file

### Test Files

Each test file:
1. Sources `test-helpers.sh`
2. Runs Claude Code with specific prompts
3. Verifies expected behavior using assertions
4. Returns 0 on success, non-zero on failure

## Example Test

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: My Skill ==="

# Ask Claude about the skill
output=$(run_claude "What does the my-skill skill do?" 30)

# Verify response
assert_contains "$output" "expected behavior" "Skill describes behavior"

echo "=== All tests passed ==="
```

## Current Tests

### Integration Tests (use --integration flag)

The integration selection runs `test-requesting-code-review.sh`, `test-document-review-system.sh`, and `test-reviewer-contract-drift.sh`. These invoke actual Claude sessions; the drift test can exercise a second runner/model when available. Missing files, skipped selections, and failed checks cannot produce a passing suite result.

#### test-requesting-code-review.sh
Behavioral test for the code reviewer subagent (~5 minutes):
- Builds a tiny project with a baseline commit
- Adds a second commit that plants two real bugs (SQL injection, plaintext password handling)
- Dispatches the code reviewer via the requesting-code-review skill
- Verifies the reviewer flags the planted bugs at Critical/Important severity and refuses to approve

**What it tests:**
- The skill actually dispatches a working code reviewer subagent
- The reviewer template produces reviewers that catch obvious security bugs
- The reviewer is not sycophantic — it does not approve a diff with planted Critical issues

## Adding New Tests

1. Create new test file: `test-<skill-name>.sh`
2. Source test-helpers.sh
3. Write tests using `run_claude` and assertions
4. Add to test list in `run-skill-tests.sh`
5. Make executable: `chmod +x test-<skill-name>.sh`

## Timeout Considerations

- Default timeout: 5 minutes per test
- Claude Code may take time to respond
- Adjust with `--timeout` if needed
- Tests should be focused to avoid long runs

## Debugging Failed Tests

With `--verbose`, you'll see full Claude output:
```bash
./run-skill-tests.sh --verbose --test test-requesting-code-review.sh
```

Without verbose, only failures show output.

## CI/CD Integration

To run in CI:
```bash
# Run with explicit timeout for CI environments
./run-skill-tests.sh --integration --timeout 1800

# Exit code 0 = success, non-zero = failure
```

## Notes

- The runner regression uses isolated CLI stubs and does not prove live skill behavior
- Integration tests exercise actual reviewer behavior and have model-dependent outcomes
- Select focused tests for the affected contract; run the full integration selection when its coverage is relevant
- Record prompts, versions, results, and unavailable coverage rather than assuming determinism
- Avoid testing implementation details
