# Remove Worktree Requirement And Upgrade Parallel Subagents Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 Superpowers 的现行 workflow 默认在当前工作区执行，并在安全条件满足时主动把子代理任务升级为并行分发。

**Architecture:** 本次改动只收敛 active skills、README 与 prompt-contract / fixture 测试，不改底层 runtime。实现上分成两个可并行 lane：一条替换 worktree-first 合同，一条强化 proactive parallel routing；随后再统一收口共享文档与验证。

**Tech Stack:** Markdown skills/docs, Bash prompt-contract tests, OpenSpec artifacts

---

**OpenSpec Change:** `remove-worktree-requirement-and-upgrade-parallel-subagents`

### Task 1: Current-Workspace Contract Lane

**Files:**
- Modify: `skills/brainstorming/SKILL.md`
- Modify: `skills/writing-plans/SKILL.md`
- Modify: `skills/executing-plans/SKILL.md`
- Modify: `skills/finishing-a-development-branch/SKILL.md`
- Test: `tests/prompt-contracts/test-worktree-execution-lifecycle.sh`

**Execution Metadata:**
- Depends on: none
- Write Set:
  - `skills/brainstorming/SKILL.md`
  - `skills/writing-plans/SKILL.md`
  - `skills/executing-plans/SKILL.md`
  - `skills/finishing-a-development-branch/SKILL.md`
  - `tests/prompt-contracts/test-worktree-execution-lifecycle.sh`
- Conflict Group: `workspace-contract`
- Risk Level: medium
- Parallelizable: yes

- [ ] **Step 1: 先把 worktree 合同测试改成当前工作区合同**

```bash
编辑 tests/prompt-contracts/test-worktree-execution-lifecycle.sh，把断言方向改成：
- brainstorming 不再要求 using-git-worktrees → writing-plans
- writing-plans / executing-plans 不再要求 dedicated worktree 前置
- finishing-a-development-branch 只在条件性上下文里提到 worktree cleanup
- README 使用 current workspace / explicit opt-in isolation 语义
```

- [ ] **Step 2: 运行测试，确认它先失败在旧 skill 文案上**

Run: `bash tests/prompt-contracts/test-worktree-execution-lifecycle.sh`
Expected: FAIL，失败点指向仍保留 worktree-first wording 的 skill / README。

- [ ] **Step 3: 最小化更新 skill 文案，去掉默认 worktree 前置**

```md
把类似下面的旧语义替换掉：

- invoke `using-git-worktrees` before planning
- ensure you are already inside a dedicated worktree
- worktree cleanup as the default completion path

替换成：

- continue in the current workspace by default
- isolated workspace is explicit opt-in only
- only mention worktree cleanup when an isolated workspace was actually used
```

- [ ] **Step 4: 再跑一次 worktree 合同测试**

Run: `bash tests/prompt-contracts/test-worktree-execution-lifecycle.sh`
Expected: PASS，输出 `All worktree execution lifecycle prompt contract checks passed.`

### Task 2: Proactive Parallel Routing Lane

**Files:**
- Modify: `skills/using-superpowers/SKILL.md`
- Modify: `skills/subagent-driven-development/SKILL.md`
- Modify: `skills/dispatching-parallel-agents/SKILL.md`
- Test: `tests/prompt-contracts/test-subagent-pipeline-routing.sh`

**Execution Metadata:**
- Depends on: none
- Write Set:
  - `skills/using-superpowers/SKILL.md`
  - `skills/subagent-driven-development/SKILL.md`
  - `skills/dispatching-parallel-agents/SKILL.md`
  - `tests/prompt-contracts/test-subagent-pipeline-routing.sh`
- Conflict Group: `parallel-routing`
- Risk Level: medium
- Parallelizable: yes

- [ ] **Step 1: 先把子代理路由测试改成“安全时主动并行”预期**

```bash
编辑 tests/prompt-contracts/test-subagent-pipeline-routing.sh，新增断言：
- using-superpowers 明确优先顺序：Serial -> Parallel Dispatch -> Pipeline
- subagent-driven-development 明确“ready lanes with disjoint Write Set / Conflict Group”应进入 Parallel Dispatch
- dispatching-parallel-agents 被写成安全 lane 的首选升级路径，而不是被动补充技巧
```

- [ ] **Step 2: 运行测试，确认它先失败在旧 routing wording 上**

Run: `bash tests/prompt-contracts/test-subagent-pipeline-routing.sh`
Expected: FAIL，失败点指向仍把 Pipeline SDD 写成默认落点的 skill 文案。

- [ ] **Step 3: 最小化更新 routing 相关 skill 文案**

```md
保留三模式：
- Serial SDD
- Pipeline SDD
- Parallel Dispatch

但把决策顺序改成：
1. 高风险或边界未定 -> Serial SDD
2. 安全独立 lane -> Parallel Dispatch
3. 其余 same-session -> Pipeline SDD

并补一条明确语义：
safe parallel lanes are the preferred execution path, not just an optional upgrade.
```

- [ ] **Step 4: 再跑一次子代理路由测试**

Run: `bash tests/prompt-contracts/test-subagent-pipeline-routing.sh`
Expected: PASS，输出 `All subagent pipeline routing prompt contract checks passed.`

### Task 3: Shared README Convergence

**Files:**
- Modify: `docs/README.codex.md`

**Execution Metadata:**
- Depends on: Task 1, Task 2
- Write Set:
  - `docs/README.codex.md`
- Conflict Group: `shared-docs`
- Risk Level: low
- Parallelizable: no

- [ ] **Step 1: 把 README 的 workspace 生命周期改成当前工作区默认**

```md
把 `## Worktree Lifecycle` 重写为更贴切的章节，例如：

## Execution Workspace

- current workspace is the default path
- isolated workspace / worktree is explicit opt-in only
- finishing flow only cleans up a worktree when one was actually used
```

- [ ] **Step 2: 在同一文档里同步 proactive parallel routing 语义**

```md
把子代理执行模式说明改成：

- Serial SDD for high-risk work
- Parallel Dispatch for safe disjoint lanes
- Pipeline SDD as the fallback when parallel safety is not proven
```

- [ ] **Step 3: 用 grep 做一次快速自检**

Run: `rg -n "worktree|current workspace|Parallel Dispatch|Pipeline SDD" docs/README.codex.md`
Expected: 输出同时包含 `current workspace` 与更新后的 `Parallel Dispatch` / `Pipeline SDD` 描述，且不再把 worktree 写成默认前置。

### Task 4: Final Verification And OpenSpec Sync

**Files:**
- Modify: `openspec/changes/remove-worktree-requirement-and-upgrade-parallel-subagents/tasks.md`

**Execution Metadata:**
- Depends on: Task 1, Task 2, Task 3
- Write Set:
  - `openspec/changes/remove-worktree-requirement-and-upgrade-parallel-subagents/tasks.md`
- Conflict Group: `verification`
- Risk Level: low
- Parallelizable: no

- [ ] **Step 1: 运行本次 change 的相关验证命令**

Run:

```bash
bash tests/prompt-contracts/test-worktree-execution-lifecycle.sh
bash tests/prompt-contracts/test-subagent-pipeline-routing.sh
```

Expected: 两个脚本都 PASS。

- [ ] **Step 2: 确认 OpenSpec change 仍然完整**

Run: `openspec status --change "remove-worktree-requirement-and-upgrade-parallel-subagents"`
Expected: 显示 `All artifacts complete!`

- [ ] **Step 3: 回填 OpenSpec tasks 完成状态，并检查 diff**

```md
把 openspec/changes/remove-worktree-requirement-and-upgrade-parallel-subagents/tasks.md
中的复选框按实际完成情况更新为 [x]。
```

- [ ] **Step 4: 记录最终验证结果**

Run: `git diff -- openspec/changes/remove-worktree-requirement-and-upgrade-parallel-subagents skills docs tests`
Expected: diff 只包含本次 change 约定的 OpenSpec、skills、README 和测试文件改动。
