# Testing Superpowers Skills

This document describes how to test Superpowers skills, particularly the integration tests for complex skills like `subagent-driven-development`.

## Overview

Testing skills that involve subagents, workflows, and complex interactions requires running actual Claude Code sessions in headless mode and verifying their behavior through session transcripts.

## Test Structure

```
tests/
├── codex/
│   ├── fixtures/
│   │   ├── request-user-input-execution-handoff.jsonl
│   │   ├── request-user-input-terminal-choice.jsonl
│   │   ├── runtime-prose-endgate-leak-negative.jsonl
│   │   ├── runtime-prose-endgate-repaired-autocontinue.jsonl
│   │   └── runtime-prose-endgate-repaired-request-user-input.jsonl
│   ├── test-request-user-input-transcript-fixtures.sh
│   └── test-runtime-endgate-transcript-audit.sh
├── claude-code/
│   ├── test-helpers.sh                    # Shared test utilities
│   ├── test-subagent-driven-development-integration.sh
│   ├── analyze-token-usage.py             # Token analysis tool
│   └── run-skill-tests.sh                 # Test runner (if exists)
└── prompt-contracts/
    ├── test-machine-readable-workflow-contracts.sh
    └── test-numeric-choice-interactions.sh
```

## Running Tests

### Integration Tests

Integration tests execute real Claude Code sessions with actual skills:

```bash
# Run the subagent-driven-development integration test
cd tests/claude-code
./test-subagent-driven-development-integration.sh
```

**Note:** Integration tests can take 10-30 minutes as they execute real implementation plans with multiple subagents.

### Integration Test Requirements

- Must run from the **superpowers plugin directory** (not from temp directories)
- Claude Code must be installed and available as `claude` command
- Local dev marketplace must be enabled: `"superpowers@superpowers-dev": true` in `~/.claude/settings.json`

### Prompt Contract Tests

Prompt contract tests validate expected wording and interaction boundaries in skill and Codex-facing documentation:

```bash
bash tests/prompt-contracts/test-subagent-pipeline-routing.sh
bash tests/prompt-contracts/test-machine-readable-workflow-contracts.sh
bash tests/codex/test-request-user-input-transcript-fixtures.sh
bash tests/codex/test-runtime-endgate-transcript-audit.sh
bash tests/prompt-contracts/test-numeric-choice-interactions.sh
```

Use `bash tests/prompt-contracts/test-subagent-pipeline-routing.sh` as the routing and `Execution Metadata` regression, and `bash tests/codex/test-subagent-pipeline-routing-fixtures.sh` as the transcript/fixture evidence check for Pipeline overlap and conflict guard semantics on this branch.

### Prompt Contract Test Requirements

- Run from the repository root so the script can resolve documented paths correctly
- Bash must be available
- `rg` (ripgrep) must be installed and available on `PATH`
- `jq` must be installed and available on `PATH` for transcript-fixture parsing

## Machine-Readable Workflow Contracts

本节冻结当前仓库的 workflow contract 审计边界、覆盖地图与验证优先级，
避免后续只靠 prose 解释导致契约漂移。

这是一份当前 change 的 branch-local contract snapshot，也是 rollout snapshot，
只描述 `close-runtime-prose-endgate-leaks` 在本分支上的契约冻结状态，
不把后续任务的计划证据误写成“仓库里已经存在的实现”。

### Source-of-truth priority

当前 source-of-truth priority 固定为
`tool events / transcript events / fixed machine-readable tail blocks / prose`。

同一顺序也可以写成
`tool events > transcript events > fixed machine-readable tail blocks > prose`。

- `tool events`：最强约束，直接来自工具调用本身。
- `transcript events`：第二优先级，记录真实 session 行为。
- `fixed machine-readable tail blocks`：用于 reviewer / implementer
  报告等稳定尾块，便于 prompt-contract 断言。
- `prose`：只用于补充解释；当它和前三层冲突时，以前三层为准。

### Repository audit and fragility tiers

- `P0`：最脆弱、最容易漂移的 workflow protocol，必须优先依赖
  tool-backed 或 transcript-backed contract。
- `P1`：中等脆弱层，通常已有文档与测试，但仍需要固定 coverage map
  以避免 wording drift。
- `P2`：较稳定层，可以继续依赖现有测试与文档，只需要在仓库审计中
  明确归档位置。

Change-scoped snapshot: `close-runtime-prose-endgate-leaks`.

Covered node families:

- `reviewer / implementer reports`
- `checkpoint / handoff / terminal-choice flows`
- `Codex runtime endgate incident fixtures`
- `Claude transcript-backed behavior tests`
- `OpenCode raw marker / tool-payload tests`

### Workflow Node / Contract Carrier / Verification Matrix

| Workflow Node | Contract Carrier | Verification | Status |
| --- | --- | --- | --- |
| reviewer / implementer reports | fixed machine-readable tail blocks + transcript events | prompt-contract + Claude tests | in scope |
| checkpoint / handoff / terminal-choice flows | request_user_input call + transcript event | prompt-contract + Codex fixture tests (`tests/codex/test-request-user-input-transcript-fixtures.sh`, `tests/codex/test-runtime-endgate-transcript-audit.sh`) | in scope; transcript fixture evidence landed on this branch |
| OpenCode tool loading | raw marker / tool payload | `tests/opencode/test-tools.sh` | in scope |
| skill-triggering discovery | existing Skill tool event transcript | `tests/skill-triggering/*.sh` | audited, out-of-scope for this change because they already assert Skill tool events |

### First drift matrix

First drift matrix: `Chinese / English / concise / verbose`.

| Axis A | Axis B | 审计目的 |
| --- | --- | --- |
| Chinese | concise | 防止简体中文短回复把 machine-readable carrier 缩成纯 prose |
| Chinese | verbose | 防止中文详细说明覆盖既有 transcript / tail-block contract |
| English | concise | 防止英文短回复丢失固定 marker、raw payload 或 tail block |
| English | verbose | 防止英文长说明重写 source-of-truth priority 或 verification map |

### Drift Matrix Protocol

当前 drift matrix 明确覆盖以下变体：

- `Chinese`
- `English`
- `concise`
- `verbose`
- `second runner or second model when available`

允许变化的是 surrounding prose 的语言、长短和措辞。
不允许变化的是 reviewer 输出末尾的 machine-readable fields。

在 drift 验证里，以下字段必须保持稳定：

- `REVIEW_VERDICT`
- `BLOCKING_ISSUE_COUNT`
- `NEXT_ACTION`

也就是说，prose may vary while the machine-readable fields must remain stable。

### Latest Machine-Readable Contract Evidence

- `tests/codex/fixtures/request-user-input-terminal-choice.jsonl`
  当前证据：real terminal-choice transcript fixture，由
  `tests/codex/test-request-user-input-transcript-fixtures.sh` 解析。
  Latest local result: parsed successfully in this Codex-only validation pass.
- `tests/codex/fixtures/request-user-input-execution-handoff.jsonl`
  当前证据：real non-terminal execution-handoff transcript fixture，由
  `tests/codex/test-request-user-input-transcript-fixtures.sh` 解析。
  Latest local result: parsed successfully in this Codex-only validation pass.
- `tests/codex/fixtures/runtime-prose-endgate-leak-negative.jsonl`
  当前证据：negative runtime prose-endgate incident fixture，由
  `tests/codex/test-runtime-endgate-transcript-audit.sh` 拒绝。
  Latest local result: rejected as a runtime prose-endgate leak in this
  Codex-only validation pass.
- `tests/codex/fixtures/runtime-prose-endgate-repaired-request-user-input.jsonl`
  当前证据：request_user_input repair fixture，由
  `tests/codex/test-runtime-endgate-transcript-audit.sh` 放行。
  Latest local result: passed the runtime endgate audit in this Codex-only
  validation pass.
- `tests/codex/fixtures/runtime-prose-endgate-repaired-autocontinue.jsonl`
  当前证据：authorized auto-continue repair fixture，由
  `tests/codex/test-runtime-endgate-transcript-audit.sh` 放行。
  Latest local result: passed the runtime endgate audit in this Codex-only
  validation pass.
- `tests/claude-code/test-subagent-driven-development.sh`
  当前 contract：锁定 transcript 中的 `Skill` / `Task` / `TodoWrite`
  事件，要求保留 `TASK_STATUS` / `TEST_STATUS` / `NEXT_ACTION`
  精确行，并包含“不得重新进入 subagent consent gate”的负向断言。
  Latest local result: live Claude-runner verification was not executed in
  this Codex-only validation pass.
- `tests/claude-code/test-reviewer-contract-drift.sh`
  当前 contract：锁定 `Chinese` / `English` / `concise` / `verbose`
  四种 reviewer prompt 变体，并在本地可用时补跑 `second runner or second model`
  分支。
  Latest local result: script landed and static validation passed in this
  Codex-only validation pass; live runner execution was not performed here.

## Runtime Endgate Transcript Audits

这组审计把真实 incident 固化成可回归的 Codex transcript fixtures，用来验证
“analysis / recommendation boundary”是否仍然会在运行期漏成 prose-only
结束。

Runtime Audit A: A negative incident fixture with a prose-only next-step
invitation followed by `task_complete` must be rejected.

Runtime Audit B: A repaired fixture that routes the next-step split through
`request_user_input` must pass.

Runtime Audit C: A repaired fixture that directly executes an authorized
auto-continue step must pass.

### Required Audit Evidence

- 保留最小负向 incident fixture，能够稳定复现
  `prose-only next-step invitation + task_complete`。
- 至少保留一个 `request_user_input` 修复样本和一个 `auto-continue`
  修复样本。
- 记录每个样本由哪一个脚本验证，以及最近一次本地验证结果。

### Latest Runtime Endgate Audit Evidence

| Audit | What to capture | Location |
| --- | --- | --- |
| A | Negative incident fixture with invitation prose, direct `task_complete`, and no `request_user_input` | `tests/codex/fixtures/runtime-prose-endgate-leak-negative.jsonl` + `tests/codex/test-runtime-endgate-transcript-audit.sh` |
| B | Repaired fixture that resolves the next-step split through `request_user_input` | `tests/codex/fixtures/runtime-prose-endgate-repaired-request-user-input.jsonl` + `tests/codex/test-runtime-endgate-transcript-audit.sh` |
| C | Repaired fixture that shows authorized auto-continue via a real tool action | `tests/codex/fixtures/runtime-prose-endgate-repaired-autocontinue.jsonl` + `tests/codex/test-runtime-endgate-transcript-audit.sh` |

## Numeric Choice Smoke Tests

These smoke tests must be run in a real session because the choice UI only appears when the assistant actually calls `request_user_input`.

The main coordinating session should collect this evidence from a live run. Prompt-contract coverage only proves the documented protocol exists; it does not prove the UI was rendered.

Smoke Test A: A non-dangerous final-step or next-step prompt must trigger `request_user_input` for real instead of falling back to a prose-only numbered reply.

Smoke Test B: A multi-question interaction must keep the choice UI across consecutive questions and must not degrade into plain text prompts.

Smoke Test C: A dangerous two-stage confirmation must use numbered choices in both stages, with the final confirmation in slot `2` of Stage 2. Stage 1 records the initial numeric choice, and Stage 2 records the final numeric confirmation.

### Required Evidence

Transcript / tool call record is required evidence for every numeric-choice smoke test run.

The required evidence should show the prompt, the `request_user_input` payload, and the selected token for each stage that was exercised.

对于 terminal-choice 相关 evidence，必须把 authored payload 与客户端 UI fallback 分开记录：assistant-authored payload 只包含 `结束 (Recommended)`、`继续`；客户端 UI 会自动追加 `Other` / notes path 作为自由输入兜底，不应把它记录成 assistant-authored `3`。

### Optional Evidence

Screenshot / operator notes are optional evidence when they help explain UI state or operator observations.

### Acceptance Mapping

| File | Contract slice | Smoke tests |
| --- | --- | --- |
| `skills/using-superpowers/SKILL.md` | Global default for tool-backed choice UI and destructive two-stage confirmation | A, B, C |
| `skills/brainstorming/SKILL.md` | Design approval and review-gate choice UI | A, B |
| `skills/writing-plans/SKILL.md` | Execution handoff choice UI | A |
| `skills/executing-plans/SKILL.md` | Blocker and next-step escalation choice UI | A, B |
| `skills/finishing-a-development-branch/SKILL.md` | Dangerous two-stage confirmation state machine | C |

### Latest Numeric Choice Smoke Evidence

| Smoke Test | What to capture | Location |
| --- | --- | --- |
| A | Transcript / tool call record showing the final-step or next-step `request_user_input` call | 2026-03-22 Codex interactive session (this conversation). `request_user_input` used for a single non-dangerous next-step question. Selected option: `继续验证 (Recommended)`. |
| B | Transcript / tool call record showing consecutive choice UI questions without plain-text degradation | 2026-03-22 Codex interactive session (this conversation). One `request_user_input` call carried three consecutive questions. Selected options: `完整三题 (Recommended)`, `记录工具调用 (Recommended)`, `保持选择 UI (Recommended)`. |
| C | Transcript / tool call record showing numeric Stage 1 and numeric Stage 2 confirmation | 2026-03-22 Codex interactive session (this conversation). Stage 1 used `request_user_input` and selected `1. 继续进入第二段 (Recommended)`. Stage 2 used `request_user_input` and selected `2. 最终确认 (Recommended)`. |

Operator note from the latest smoke run:

- The updated destructive flow rendered as a real `request_user_input` choice UI in both stages.
- Stage 2 now keeps the safe return path in slot `1` and the final destructive confirmation in slot `2`, matching the new anti-misclick design.
- The earlier lettered Stage 2 experiment exposed an `a` / `b` / `c` hotkey boundary in this Codex session, so the current design no longer depends on alphabetic hotkeys.
- Tool-backed rendering still depends on the assistant actually calling `request_user_input`, and any raw hotkey behavior still depends on the Codex input layer rather than the skill documents.

## Integration Test: subagent-driven-development

### What It Tests

The integration test verifies the `subagent-driven-development` skill correctly:

1. **Plan Loading**: Reads the plan once at the beginning
2. **Full Task Text**: Provides complete task descriptions to subagents (doesn't make them read files)
3. **Self-Review**: Ensures subagents perform self-review before reporting
4. **Review Order**: Runs spec compliance review before code quality review
5. **Review Loops**: Uses review loops when issues are found
6. **Independent Verification**: Spec reviewer reads code independently, doesn't trust implementer reports

### How It Works

1. **Setup**: Creates a temporary Node.js project with a minimal implementation plan
2. **Execution**: Runs Claude Code in headless mode with the skill
3. **Verification**: Parses the session transcript (`.jsonl` file) to verify:
   - Skill tool was invoked
   - Subagents were dispatched (Task tool)
   - TodoWrite was used for tracking
   - Implementation files were created
   - Tests pass
   - Git commits show proper workflow
4. **Token Analysis**: Shows token usage breakdown by subagent

### Test Output

```
========================================
 Integration Test: subagent-driven-development
========================================

Test project: /tmp/tmp.xyz123

=== Verification Tests ===

Test 1: Skill tool invoked...
  [PASS] subagent-driven-development skill was invoked

Test 2: Subagents dispatched...
  [PASS] 7 subagents dispatched

Test 3: Task tracking...
  [PASS] TodoWrite used 5 time(s)

Test 6: Implementation verification...
  [PASS] src/math.js created
  [PASS] add function exists
  [PASS] multiply function exists
  [PASS] test/math.test.js created
  [PASS] Tests pass

Test 7: Git commit history...
  [PASS] Multiple commits created (3 total)

Test 8: No extra features added...
  [PASS] No extra features added

=========================================
 Token Usage Analysis
=========================================

Usage Breakdown:
----------------------------------------------------------------------------------------------------
Agent           Description                          Msgs      Input     Output      Cache     Cost
----------------------------------------------------------------------------------------------------
main            Main session (coordinator)             34         27      3,996  1,213,703 $   4.09
3380c209        implementing Task 1: Create Add Function     1          2        787     24,989 $   0.09
34b00fde        implementing Task 2: Create Multiply Function     1          4        644     25,114 $   0.09
3801a732        reviewing whether an implementation matches...   1          5        703     25,742 $   0.09
4c142934        doing a final code review...                    1          6        854     25,319 $   0.09
5f017a42        a code reviewer. Review Task 2...               1          6        504     22,949 $   0.08
a6b7fbe4        a code reviewer. Review Task 1...               1          6        515     22,534 $   0.08
f15837c0        reviewing whether an implementation matches...   1          6        416     22,485 $   0.07
----------------------------------------------------------------------------------------------------

TOTALS:
  Total messages:         41
  Input tokens:           62
  Output tokens:          8,419
  Cache creation tokens:  132,742
  Cache read tokens:      1,382,835

  Total input (incl cache): 1,515,639
  Total tokens:             1,524,058

  Estimated cost: $4.67
  (at $3/$15 per M tokens for input/output)

========================================
 Test Summary
========================================

STATUS: PASSED
```

## Token Analysis Tool

### Usage

Analyze token usage from any Claude Code session:

```bash
python3 tests/claude-code/analyze-token-usage.py ~/.claude/projects/<project-dir>/<session-id>.jsonl
```

### Finding Session Files

Session transcripts are stored in `~/.claude/projects/` with the working directory path encoded:

```bash
# Example for /Users/yourname/Documents/GitHub/superpowers/superpowers
SESSION_DIR="$HOME/.claude/projects/-Users-yourname-Documents-GitHub-superpowers-superpowers"

# Find recent sessions
ls -lt "$SESSION_DIR"/*.jsonl | head -5
```

### What It Shows

- **Main session usage**: Token usage by the coordinator (you or main Claude instance)
- **Per-subagent breakdown**: Each Task invocation with:
  - Agent ID
  - Description (extracted from prompt)
  - Message count
  - Input/output tokens
  - Cache usage
  - Estimated cost
- **Totals**: Overall token usage and cost estimate

### Understanding the Output

- **High cache reads**: Good - means prompt caching is working
- **High input tokens on main**: Expected - coordinator has full context
- **Similar costs per subagent**: Expected - each gets similar task complexity
- **Cost per task**: Typical range is $0.05-$0.15 per subagent depending on task

## Troubleshooting

### Skills Not Loading

**Problem**: Skill not found when running headless tests

**Solutions**:
1. Ensure you're running FROM the superpowers directory: `cd /path/to/superpowers && tests/...`
2. Check `~/.claude/settings.json` has `"superpowers@superpowers-dev": true` in `enabledPlugins`
3. Verify skill exists in `skills/` directory

### Permission Errors

**Problem**: Claude blocked from writing files or accessing directories

**Solutions**:
1. Use `--permission-mode bypassPermissions` flag
2. Use `--add-dir /path/to/temp/dir` to grant access to test directories
3. Check file permissions on test directories

### Test Timeouts

**Problem**: Test takes too long and times out

**Solutions**:
1. Increase timeout: `timeout 1800 claude ...` (30 minutes)
2. Check for infinite loops in skill logic
3. Review subagent task complexity

### Session File Not Found

**Problem**: Can't find session transcript after test run

**Solutions**:
1. Check the correct project directory in `~/.claude/projects/`
2. Use `find ~/.claude/projects -name "*.jsonl" -mmin -60` to find recent sessions
3. Verify test actually ran (check for errors in test output)

## Writing New Integration Tests

### Template

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

# Create test project
TEST_PROJECT=$(create_test_project)
trap "cleanup_test_project $TEST_PROJECT" EXIT

# Set up test files...
cd "$TEST_PROJECT"

# Run Claude with skill
PROMPT="Your test prompt here"
cd "$SCRIPT_DIR/../.." && timeout 1800 claude -p "$PROMPT" \
  --allowed-tools=all \
  --add-dir "$TEST_PROJECT" \
  --permission-mode bypassPermissions \
  2>&1 | tee output.txt

# Find and analyze session
WORKING_DIR_ESCAPED=$(echo "$SCRIPT_DIR/../.." | sed 's/\\//-/g' | sed 's/^-//')
SESSION_DIR="$HOME/.claude/projects/$WORKING_DIR_ESCAPED"
SESSION_FILE=$(find "$SESSION_DIR" -name "*.jsonl" -type f -mmin -60 | sort -r | head -1)

# Verify behavior by parsing session transcript
if grep -q '"name":"Skill".*"skill":"your-skill-name"' "$SESSION_FILE"; then
    echo "[PASS] Skill was invoked"
fi

# Show token analysis
python3 "$SCRIPT_DIR/analyze-token-usage.py" "$SESSION_FILE"
```

### Best Practices

1. **Always cleanup**: Use trap to cleanup temp directories
2. **Parse transcripts**: Don't grep user-facing output - parse the `.jsonl` session file
3. **Grant permissions**: Use `--permission-mode bypassPermissions` and `--add-dir`
4. **Run from plugin dir**: Skills only load when running from the superpowers directory
5. **Show token usage**: Always include token analysis for cost visibility
6. **Test real behavior**: Verify actual files created, tests passing, commits made

## Session Transcript Format

Session transcripts are JSONL (JSON Lines) files where each line is a JSON object representing a message or tool result.

### Key Fields

```json
{
  "type": "assistant",
  "message": {
    "content": [...],
    "usage": {
      "input_tokens": 27,
      "output_tokens": 3996,
      "cache_read_input_tokens": 1213703
    }
  }
}
```

### Tool Results

```json
{
  "type": "user",
  "toolUseResult": {
    "agentId": "3380c209",
    "usage": {
      "input_tokens": 2,
      "output_tokens": 787,
      "cache_read_input_tokens": 24989
    },
    "prompt": "You are implementing Task 1...",
    "content": [{"type": "text", "text": "..."}]
  }
}
```

The `agentId` field links to subagent sessions, and the `usage` field contains token usage for that specific subagent invocation.
