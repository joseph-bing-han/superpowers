# Superpowers for Codex

Guide for using Superpowers with OpenAI Codex via native skill discovery.

## Quick Install

Tell Codex:

```
Fetch and follow instructions from https://raw.githubusercontent.com/joseph-bing-han/superpowers/refs/heads/openspec/.codex/INSTALL.md
```

This is the team-maintained Codex installation path. Unless you have a special reason not to, install the `openspec` branch from the team fork.
That install path now bootstraps both the skills symlink and the repo-managed `model_instructions_file` configuration for Superpowers.

## Manual Installation

### Prerequisites

- OpenAI Codex CLI
- Git

### Steps

1. Clone the repo:
   ```bash
   git clone --branch openspec --single-branch https://github.com/joseph-bing-han/superpowers.git ~/.codex/superpowers
   ```

2. Run the installer:
   ```bash
   bash ~/.codex/superpowers/.codex/install-codex.sh
   ```

   This creates the skills symlink and configures:
   ```toml
   model_instructions_file = "~/.codex/superpowers/.codex/instruction.md"
   ```

   If `~/.codex/config.toml` already points `model_instructions_file` somewhere else, the installer stops and asks you to merge it manually instead of overwriting your existing global setup.

3. Restart Codex.

4. **For reviewer subagents** (optional): Dispatching reviewer subagents requires Codex's multi-agent feature. Add to your Codex config:
   ```toml
   [features]
   multi_agent = true
   ```

### Windows

Use a junction instead of a symlink (works without Developer Mode):

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
cmd /c mklink /J "$env:USERPROFILE\.agents\skills\superpowers" "$env:USERPROFILE\.codex\superpowers\skills"
```

Then add this line to `$env:USERPROFILE\.codex\config.toml` if it is not already present:

```toml
model_instructions_file = "C:/Users/<you>/.codex/superpowers/.codex/instruction.md"
```

## How It Works

Codex has native skill discovery — it scans `~/.agents/skills/` at startup, parses SKILL.md frontmatter, and loads skills on demand. Superpowers skills are made visible through a single symlink:

```
~/.agents/skills/superpowers/ → ~/.codex/superpowers/skills/
```

The `using-superpowers` skill is discovered automatically and enforces skill usage discipline — no additional configuration needed.
All discoverable skills, including `spec-governed-development`, live under the `skills/` tree at `~/.codex/superpowers/skills`; no separate root-level skill copy is required for Codex discovery.
The workflow bootstrap is stored in the repository at `~/.codex/superpowers/.codex/instruction.md` and is activated through `model_instructions_file` in the user's Codex config.

说明：`spec-governed-development` 是当前 Superpowers `openspec` 分支提供的 OpenSpec 治理入口 skill，用于先决定是否进入 OpenSpec lane。它不是 `openspec-apply-change` 的改名；后者仍然是独立的 OpenSpec 执行 skill，会在进入 OpenSpec lane 后继续接手实现阶段。

## Usage

Direct Mode is the default for ordinary questions and non-behavioral text edits.
Use a named skill or the skill matching the current design, planning, debugging,
review or execution request. A lightweight subtask does not inherit a full
workflow. Behavior-shaping Markdown changes still need relevant validation.

Read a selected skill entrypoint when needed, then load references on demand.
Reuse unchanged context. See [using-superpowers](../skills/using-superpowers/SKILL.md)
for the shared routing, authorization and completion rules.

OpenSpec is for existing governed changes, explicit/project-required governance
or material risks needing durable decisions, not every feature or multi-step edit.
The current request can finish while a larger change remains open. Archive follows
change completion, required integration and authorization.

## Choice-Based Interaction

Ask only about missing information, material tradeoffs or new authority.
Use request_user_input when available and permitted for the question; otherwise
ask a concise plain-text question. Use the client's free-text fallback when
provided, without duplicating it. Follow the host's confirmation rules for
high-risk actions. A skill does not grant commit, push, PR or merge permission.

## Autonomous Continuation

Continue safe, authorized work across routine summaries and phase boundaries.
Conditional authorization becomes effective once its condition is satisfied.
Do not pause merely because a plan was saved or a check passed.

Completed requests, including reviews and reports, finish directly with evidence
and limitations. Do not ask the user to choose end/continue after completion.
Before reporting a blocker, investigate safely and complete independent work.

## Legacy Endgate Compatibility

Version 1 packets remain supported for explicitly enabled legacy integrations
and transcript replay, not by default for all workflows. A compatible consumer
and available, permitted request_user_input tool are prerequisites.
The [packet specification](../openspec/specs/endgate-state-packet/spec.md)
defines its unchanged schema and pairings. Structured carriers are preferred;
visible tail blocks remain a fallback. The optional wrapper only hides packet
rendering; it does not enable strict mode.

Normal completion does not emit a version 1 packet or send a new DONE enum to an
old consumer. If an integration is unavailable, disclose the limit and use the
normal completion/decision path where permitted.

## Reviewer Subagents

Independent read-only review is useful for shared behavior and high-risk changes,
not mandatory for every edit. Provide scoped artifacts and the complete task diff,
including staged, unstaged and untracked work. Use supported runtime capabilities;
do not change global configuration just to satisfy a default review gate.
If independent review is unavailable, self-review and disclose the limitation.
A specifically required external approval can block integration, not reporting
or preservation of the work.

## Execution Workspace

Implementation-oriented Superpowers flows should continue in the current workspace by default.

- Planning and execution should stay in the current workspace unless the user explicitly requests an isolated workspace or worktree.
- If an isolated workspace was explicitly requested, reuse it instead of creating nested worktrees.
- `executing-plans` may run in that isolated workspace only when it was explicitly requested.
- `finishing-a-development-branch` should treat isolated workspace cleanup as a conditional step, not as the default branch-completion path.

### Personal Skills

Create your own skills in `~/.agents/skills/`:

```bash
mkdir -p ~/.agents/skills/my-skill
```

Create `~/.agents/skills/my-skill/SKILL.md`:

```markdown
---
name: my-skill
description: Use when [condition] - [what it does]
---

# My Skill

[Your skill content here]
```

The `description` field is how Codex decides when to activate a skill automatically — write it as a clear trigger condition.

## Updating

```bash
cd ~/.codex/superpowers && git pull origin openspec
bash ~/.codex/superpowers/.codex/install-codex.sh
```

Skills update instantly through the symlink.

## Uninstalling

```bash
rm ~/.agents/skills/superpowers
```

**Windows (PowerShell):**
```powershell
Remove-Item "$env:USERPROFILE\.agents\skills\superpowers"
```

Optionally delete the clone: `rm -rf ~/.codex/superpowers` (Windows: `Remove-Item -Recurse -Force "$env:USERPROFILE\.codex\superpowers"`).

## Troubleshooting

### Skills not showing up

1. Verify the symlink: `ls -la ~/.agents/skills/superpowers`
2. Check skills exist: `ls ~/.codex/superpowers/skills`
3. Verify the instruction bootstrap: `rg -n '^model_instructions_file = ' ~/.codex/config.toml`
4. Restart Codex — skills are discovered at startup

### Windows junction issues

Junctions normally work without special permissions. If creation fails, try running PowerShell as administrator.

## Getting Help

- Report issues: https://github.com/joseph-bing-han/superpowers/issues
- Main documentation: https://github.com/joseph-bing-han/superpowers
