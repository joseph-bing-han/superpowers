# Team Codex Install Source Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Point the Codex installation flow at the team fork `joseph-bing-han/superpowers` on the `openspec` branch instead of the upstream repository.

**Architecture:** Keep the change inside the documentation lane. Update the Codex quick-install entry in `README.md`, then align the detailed Codex guide and `.codex/INSTALL.md` so every documented clone, update, and help link points at the team fork and branch. Finish with focused search-based verification to ensure no Codex-install upstream references remain in scope.

**Tech Stack:** Markdown documentation, Bash verification with `rg`

---

### Task 1: Update the Public Codex Entry Points

**Files:**
- Modify: `README.md`
- Modify: `docs/README.codex.md`

- [ ] **Step 1: Update the quick-install raw URL in `README.md`**

Replace the Codex quick-install prompt so it points to:

```text
https://raw.githubusercontent.com/joseph-bing-han/superpowers/refs/heads/openspec/.codex/INSTALL.md
```

- [ ] **Step 2: Update the same raw URL in `docs/README.codex.md`**

Use the same `raw.githubusercontent.com/joseph-bing-han/superpowers/refs/heads/openspec/.codex/INSTALL.md` value.

- [ ] **Step 3: Update the clone command in `docs/README.codex.md`**

Replace the upstream clone command with:

```bash
git clone --branch openspec --single-branch https://github.com/joseph-bing-han/superpowers.git ~/.codex/superpowers
```

- [ ] **Step 4: Update the help links in `docs/README.codex.md`**

Point `Report issues` and `Main documentation` to `https://github.com/joseph-bing-han/superpowers`.

### Task 2: Align the Native Codex Installer Instructions

**Files:**
- Modify: `.codex/INSTALL.md`

- [ ] **Step 1: Update the clone command**

Replace the upstream clone command with:

```bash
git clone --branch openspec --single-branch https://github.com/joseph-bing-han/superpowers.git ~/.codex/superpowers
```

- [ ] **Step 2: Update the migration/update commands**

Ensure the update command reads:

```bash
cd ~/.codex/superpowers && git pull origin openspec
```

- [ ] **Step 3: Add a short team-source note**

State that the Codex install path is the team-maintained fork and that the `openspec` branch is the default team installation source.

### Task 3: Verify the Codex Install Chain

**Files:**
- Verify: `README.md`
- Verify: `docs/README.codex.md`
- Verify: `.codex/INSTALL.md`

- [ ] **Step 1: Search for stale upstream Codex-install references**

Run:

```bash
rg -n "raw.githubusercontent.com/obra/superpowers/refs/heads/main/.codex/INSTALL.md|git clone https://github.com/obra/superpowers.git ~/.codex/superpowers|github.com/obra/superpowers/issues|Main documentation: https://github.com/obra/superpowers" README.md docs/README.codex.md .codex/INSTALL.md
```

Expected: no matches in the Codex installation chain.

- [ ] **Step 2: Sanity-check the new team-fork references**

Run:

```bash
rg -n "joseph-bing-han/superpowers|refs/heads/openspec|git pull origin openspec|--branch openspec --single-branch" README.md docs/README.codex.md .codex/INSTALL.md
```

Expected: matches appear in the intended Codex documentation locations.

- [ ] **Step 3: Commit**

```bash
git add README.md docs/README.codex.md .codex/INSTALL.md docs/superpowers/specs/2026-03-22-13-41-team-codex-install-source-design.md docs/superpowers/plans/2026-03-22-13-41-team-codex-install-source.md
git commit -m "docs: point codex install flow to team fork"
```
