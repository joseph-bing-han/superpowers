# Codex 安装指令引导接入实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让首次安装 Superpowers 的 Codex 用户自动接入仓库内维护的 `instruction.md` 引导层。

**Architecture:** 将 canonical instruction source 固定在仓库内的 `.codex/instruction.md`，再增加一个幂等的 Codex 安装脚本，同时配置技能发现链路与 `model_instructions_file`。最后统一更新 Codex 安装文档，并用临时 HOME 安装 smoke test 与 prompt-contract 检查覆盖该行为。

**Tech Stack:** Bash、Markdown、现有 shell prompt-contract tests

---

### Task 1: 增加先失败的安装 Smoke Test

**Files:**
- Create: `tests/codex/test-codex-install-bootstrap.sh`

**Execution Metadata:**
- Depends on: none
- Write Set:
  - `tests/codex/test-codex-install-bootstrap.sh`
- Conflict Group: `codex-install-bootstrap`
- Risk Level: low
- Parallelizable: no

- [x] **Step 1: 写出先失败的 smoke test**
- [x] **Step 2: 运行 smoke test，确认它在实现前失败**

### Task 2: 增加 Canonical Bootstrap 文件

**Files:**
- Create: `.codex/instruction.md`
- Create: `.codex/install-codex.sh`

**Execution Metadata:**
- Depends on: Task 1
- Write Set:
  - `.codex/instruction.md`
  - `.codex/install-codex.sh`
- Conflict Group: `codex-install-bootstrap`
- Risk Level: medium
- Parallelizable: no

- [x] **Step 1: 增加仓库内维护的 canonical instruction 文件**
- [x] **Step 2: 实现幂等安装脚本**
- [x] **Step 3: 重新运行安装 smoke test 并使其通过**

### Task 3: 对齐安装文档与契约检查

**Files:**
- Modify: `.codex/INSTALL.md`
- Modify: `docs/README.codex.md`
- Modify: `README.md`
- Modify: `tests/prompt-contracts/test-openspec-entry-and-doc-paths.sh`

**Execution Metadata:**
- Depends on: Task 2
- Write Set:
  - `.codex/INSTALL.md`
  - `docs/README.codex.md`
  - `README.md`
  - `tests/prompt-contracts/test-openspec-entry-and-doc-paths.sh`
- Conflict Group: `codex-install-bootstrap`
- Risk Level: low
- Parallelizable: no

- [x] **Step 1: 更新 Codex 安装文档，改用安装脚本**
- [x] **Step 2: 补充仓库内 `model_instructions_file` bootstrap 说明**
- [x] **Step 3: 扩展 prompt-contract 检查，覆盖新的安装路径**

### Task 4: 端到端验证

**Files:**
- Verify: `tests/codex/test-codex-install-bootstrap.sh`
- Verify: `tests/prompt-contracts/test-openspec-entry-and-doc-paths.sh`

**Execution Metadata:**
- Depends on: Task 3
- Write Set:
  - `tests/codex/test-codex-install-bootstrap.sh`
  - `tests/prompt-contracts/test-openspec-entry-and-doc-paths.sh`
- Conflict Group: `codex-install-bootstrap`
- Risk Level: low
- Parallelizable: no

- [x] **Step 1: 运行安装 smoke test**
- [x] **Step 2: 运行 prompt-contract 验证**
- [x] **Step 3: 更新本计划，反映本轮实施已完成**
