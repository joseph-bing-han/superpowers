# Spec Governed Development Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 安装 `spec-governed-development` skill，并以最小改动方式接入现有 Superpowers 流程。

**Architecture:** 新增一个桥接 skill 作为流程治理入口；仅调整 `using-superpowers`、`brainstorming`、`writing-plans` 三个现有 skills 的规则文字，不改动其它 skill 的职责边界。OpenSpec 保持长期变更资产真相源，Superpowers 保持执行级计划与实施流程。

**Tech Stack:** Markdown skills, Codex native skill discovery, OpenSpec workflow, Superpowers workflow

---

### Task 1: 准备安装内容与最小改动方案

**Files:**
- Create: `spec-governed-development/SKILL.md`
- Modify: `.staging/superpowers/using-superpowers/SKILL.md`
- Modify: `.staging/superpowers/brainstorming/SKILL.md`
- Modify: `.staging/superpowers/writing-plans/SKILL.md`

- [x] **Step 1: 确认桥接 skill 设计稿**

已完成并落盘，作为本次安装与接入的基础。

- [x] **Step 2: 确定最小接入点**

仅调整以下 3 个现有 skills：
- `using-superpowers`
- `brainstorming`
- `writing-plans`

- [x] **Step 3: 将改动应用到 staging 副本**

在当前工作区先完成所有文档改动，避免直接写入系统技能目录。

### Task 2: 安装新 skill

**Files:**
- Create: `~/.codex/skills/spec-governed-development/SKILL.md`

- [x] **Step 1: 复制桥接 skill 到 `~/.codex/skills/`**

通过受控安装将 staging 中的 `SKILL.md` 写入真实技能目录。

- [x] **Step 2: 检查目录结构**

确认技能目录存在且只包含必要文件。

### Task 3: 接入 Superpowers

**Files:**
- Modify: `~/.codex/superpowers/skills/using-superpowers/SKILL.md`
- Modify: `~/.codex/superpowers/skills/brainstorming/SKILL.md`
- Modify: `~/.codex/superpowers/skills/writing-plans/SKILL.md`

- [x] **Step 1: 更新 `using-superpowers`**

加入“新功能 / 跨模块 / 多阶段 / 需要长期历史时，先进入 `spec-governed-development`”的入口规则。

- [x] **Step 2: 更新 `brainstorming`**

加入 OpenSpec lane 下的文档落点规则，避免重复维护 `docs/superpowers/specs/...`。

- [x] **Step 3: 更新 `writing-plans`**

加入 OpenSpec artifacts 作为输入上下文与唯一设计真相源的说明。

### Task 4: 验证与交付

**Files:**
- Verify: `~/.codex/skills/spec-governed-development/SKILL.md`
- Verify: `~/.codex/superpowers/skills/using-superpowers/SKILL.md`
- Verify: `~/.codex/superpowers/skills/brainstorming/SKILL.md`
- Verify: `~/.codex/superpowers/skills/writing-plans/SKILL.md`

- [x] **Step 1: 检查 frontmatter 与关键规则是否存在**

验证新 skill 可被发现，现有 skill 已包含新的治理入口和 OpenSpec lane 规则。

- [x] **Step 2: 说明启用方式**

说明是否需要重启 Codex，以及后续如何触发这条新流程。
