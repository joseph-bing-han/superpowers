# Finishing Branch OpenSpec Archive Handoff Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 `finishing-a-development-branch` 增加 OpenSpec lane 下的引导式归档提示。

**Architecture:** 保持原有四个收尾选项和清理逻辑不变，仅在技能文档中增加一个后置 handoff 规则：当上下文明确表明当前工作属于 OpenSpec lane 时，收尾完成后引导进入 `openspec-archive-change`。该改动不自动归档，不改变 change 选择和归档校验职责。

**Tech Stack:** Markdown skills, Superpowers workflow, OpenSpec workflow

---

### Task 1: 设计与约束落档

**Files:**
- Create: `docs/superpowers/specs/2026-03-21-15-06-finishing-branch-openspec-archive-handoff-design.md`
- Create: `docs/superpowers/plans/2026-03-21-15-06-finishing-branch-openspec-archive-handoff-plan.md`

- [x] **Step 1: 记录第二阶段设计**

- [x] **Step 2: 记录实施计划**

### Task 2: 更新 finishing skill 的规则

**Files:**
- Modify: `.staging/superpowers/finishing-a-development-branch/SKILL.md`
- Modify: `~/.codex/superpowers/skills/finishing-a-development-branch/SKILL.md`

- [x] **Step 1: 在 staging 中加入 OpenSpec lane 的 handoff 规则**

- [x] **Step 2: 保持原有 4 个选项与危险操作确认逻辑不变**

- [x] **Step 3: 将确认后的改动写回真实 skill 目录**

### Task 3: 验证与启用说明

**Files:**
- Verify: `~/.codex/superpowers/skills/finishing-a-development-branch/SKILL.md`

- [x] **Step 1: 检查关键规则是否存在**

- [x] **Step 2: 说明重启与触发方式**
