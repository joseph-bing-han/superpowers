# OpenSpec Bridge Review Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复 OpenSpec 与 Superpowers 桥接方案在 repo 版本中的 review 问题，使 lane-aware 规则真正闭环。

**Architecture:** 先修复 `brainstorming` 的重复 spec 风险，再修复 `writing-plans` 的 OpenSpec review context 和 header 泄漏，随后收紧 `finishing-a-development-branch` 的 archive handoff 时机，最后补齐 `spec-governed-development` 对已有 change 续做场景的 guidance。

**Tech Stack:** Markdown skills, OpenSpec workflow, Superpowers workflow

---

### Task 0: 接回治理入口

**Files:**
- Modify: `skills/using-superpowers/SKILL.md`

- [x] **Step 1: 加入 governance routing 规则**
- [x] **Step 2: 明确新功能 / 跨模块 / 多阶段工作优先进入 `spec-governed-development`**

### Task 1: 修复 brainstorming 的 lane-aware 规则

**Files:**
- Modify: `skills/brainstorming/SKILL.md`

- [x] **Step 1: 将 checklist 第 6-8 步改为 lane-aware**
- [x] **Step 2: 将流程图和 After the Design 文案改为 design artifacts 语义**
- [x] **Step 3: 确保 OpenSpec lane 下不会被要求生成平行 `docs/superpowers/specs/...`**

### Task 2: 修复 writing-plans 的 OpenSpec 边界

**Files:**
- Modify: `skills/writing-plans/SKILL.md`

- [x] **Step 1: 将 `OpenSpec Change` 改为仅在 OpenSpec lane 下出现的可选元数据**
- [x] **Step 2: 将 review loop 改为 OpenSpec lane 下的 artifact-aware reviewer context**
- [x] **Step 3: 保持 Superpowers-only lane 的原有 plan 结构不受影响**

### Task 3: 收紧 finishing 的 archive handoff

**Files:**
- Modify: `skills/finishing-a-development-branch/SKILL.md`

- [x] **Step 1: 将 archive handoff 与具体分支收尾选项绑定**
- [x] **Step 2: 排除 Option 3 和 Option 4 的 archive 引导**
- [x] **Step 3: 将 Option 2 改为“PR 合并并确认 change 完成后再 archive”的延后提示**

### Task 4: 补齐 bridge skill 的已有 change guidance 与默认输出语义

**Files:**
- Modify: `spec-governed-development/SKILL.md`

- [x] **Step 1: 在所有用户可见入口与示例输出中补充已有 change 的续做路径，确保不限于单个章节标题**
- [x] **Step 2: 移除默认 re-propose 信号，避免任何入口给人造成每次都要重新 propose 的印象**

### Task 5: 验证与回写

**Files:**
- Verify: `skills/using-superpowers/SKILL.md`
- Verify: `skills/brainstorming/SKILL.md`
- Verify: `skills/writing-plans/SKILL.md`
- Verify: `skills/finishing-a-development-branch/SKILL.md`
- Verify: `spec-governed-development/SKILL.md`

- [x] **Step 1: 用 diff/grep 验证每条 review 反馈都被覆盖**
- [x] **Step 2: 将确认后的文件写回 repo**
