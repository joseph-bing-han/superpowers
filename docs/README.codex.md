# Superpowers for Codex

Guide for using Superpowers with OpenAI Codex via native skill discovery.

## Quick Install

Tell Codex:

```
Fetch and follow instructions from https://raw.githubusercontent.com/joseph-bing-han/superpowers/refs/heads/openspec/.codex/INSTALL.md
```

This is the team-maintained Codex installation path. Unless you have a special reason not to, install the `openspec` branch from the team fork.

## Manual Installation

### Prerequisites

- OpenAI Codex CLI
- Git

### Steps

1. Clone the repo:
   ```bash
   git clone --branch openspec --single-branch https://github.com/joseph-bing-han/superpowers.git ~/.codex/superpowers
   ```

2. Create the skills symlink:
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/superpowers/skills ~/.agents/skills/superpowers
   ```

3. Restart Codex.

4. **For subagent skills** (optional): Skills like `dispatching-parallel-agents` and `subagent-driven-development` require Codex's multi-agent feature. Add to your Codex config:
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

## How It Works

Codex has native skill discovery — it scans `~/.agents/skills/` at startup, parses SKILL.md frontmatter, and loads skills on demand. Superpowers skills are made visible through a single symlink:

```
~/.agents/skills/superpowers/ → ~/.codex/superpowers/skills/
```

The `using-superpowers` skill is discovered automatically and enforces skill usage discipline — no additional configuration needed.

## Usage

Skills are discovered automatically. Codex activates them when:
- You mention a skill by name (e.g., "use brainstorming")
- The task matches a skill's description
- The `using-superpowers` skill directs Codex to use one

## Choice-Based Interaction

Superpowers skill prompts use structured numbered choices by default for user-choice moments instead of requiring natural-language approval phrases.

- Put the recommended option in slot `1`.
- Prefer 2-4 options.
- For non-dangerous, enumerable choices, use `request_user_input` by default when available so the user gets a tool-backed choice UI instead of a prose-only numbered reply prompt.
- Keep a final free-text fallback when the scenario allows additional input beyond the listed choices.
- When the assistant writes prose-numbered options or text fallbacks itself, use ASCII `1. `, `2. `, and `3. ` numbering instead of `1。`.
- For dangerous or destructive enumerable choices, use two-stage confirmation by default: a numbered choice first, then a second numbered confirmation step.
- In the second destructive step, put the safe exit in slot `1` and put the final destructive confirmation in slot `2` of the second step.
- If a dangerous action still requires typed text, show the exact text as copyable text.

This does not mean Superpowers can force raw single-key submit inside Codex CLI. True "press one key and continue immediately" behavior still depends on the Codex input layer, not the skill documents.
The automatic numbering prefix shown inside a `request_user_input` popup belongs to the Codex UI/input-layer boundary, not to the skill documents.

## Autonomous Continuation

If the user asked for end-to-end completion, Superpowers should keep advancing the workflow according to the turn-end gate below whenever no clarification is needed.

- Before ending a workflow turn, classify the turn as `auto-continue`, `needs-user-decision`, or `terminal-choice`.
- `auto-continue`: the next safe step is already implied; execute it immediately.
- `needs-user-decision`: the workflow cannot safely continue until the user chooses among concrete options; use `request_user_input`.
- `terminal-choice`: the requested work appears complete, but do not end directly; use `request_user_input` with:
  1. 结束
  2. 继续
  3. 自由输入
- For checkpoint, handoff, and terminal-choice nodes driven by `request_user_input`, the `request_user_input` call and its transcript event are the machine contract; surrounding prose is explanatory only.
- When the turn reaches `terminal-choice`, the next action is the popup itself. The very next action must be `request_user_input`.
- Do not produce a plain final-answer-style closeout before the terminal-choice popup.
- A settled recommendation, final draft, or final summary is still not permission to end directly.
- Do not call `task_complete` or otherwise end the turn while the terminal-choice popup is still pending.
- Do not stop after summaries, checkpoints, or phase completions just to ask whether to continue.
- Summaries, checkpoints, and phase completions are progress updates, not automatic stop points.
- These terminal endgate rules apply across all local skills in this repository, not only the core workflow skills that first introduced them.
- Contingent authorization counts as prior authorization. If the user says `如果没问题就继续下一阶段`, `如果设计合理就开始实现`, or `if this is sound, continue to phase 2`, then a positive judgment means the condition is satisfied and the turn is `auto-continue`, not a new approval gate.
- Do not stop after announcing that judgment. Headings or conclusion blocks such as `最终判断`, `现在可以把结论更新为`, `项目现在可以稳妥进入 signing 阶段`, or similar "this can now safely move to the next phase" language are still prose-only endings if they are followed by `task_complete` instead of the already-authorized next step.
- A typed free-form stop request, approval word, or natural-language "continue/stop" reply prompt must not replace the `terminal-choice` popup when the workflow is truly complete.
- If the next action is already implied and safe, take it.
- If a bug belongs to an active OpenSpec change, recover that governed context before proposing fixes by reading `proposal.md`, `design.md`, `specs/*`, and `tasks.md`.
- If the current turn already knows the next OpenSpec lane, keep it in `auto-continue`: remaining governed work should continue into `openspec-apply-change`, and a complete archive-compatible active OpenSpec change should continue into `openspec-archive-change`.
- If the only remaining real decision is continue vs stop, ask that through `request_user_input`; otherwise ask the more specific next-step choice instead of collapsing it into a generic continue/stop prompt.
- Non-terminal workflow stages must not end with a prose-only follow-up or declarative prose-only next-step proposal such as `if you agree`, `if this direction looks good`, `the next best step is X`, or `I can directly prepare X next`.
- This also includes judgment-framed, comparative, or recommendation-framed next-step proposals, including Chinese variants such as `如果按我的判断，下一步应该先……`, `下一步最值得做的不是 A，而是 B`, `接下来更值得做的是……`, or `我建议先……`.
- A non-terminal turn must not end with `task_complete` after only a summary, recommendation, judgment, comparison, or suggestion about what to do next.
- If the assistant can already describe the next safe step concretely, it should do it rather than narrating and stopping.
- Either continue automatically or use `request_user_input` when a real decision remains and the choices are enumerable.
- Pause only when missing information would change the work, a destructive or external action needs confirmation, or a material tradeoff still needs the user's decision.

## Session-Scoped Subagent Consent

Superpowers tracks session-scoped subagent consent as `unknown`, `granted`, or `denied`.

When a reviewer or implementer subagent would materially help and the state is `unknown`, the workflow should ask once through `request_user_input` before dispatching it. It should not silently downgrade first or explain the missing authorization after the fact.

If that session-level consent is `granted`, those workflows can keep using helpful subagents without asking again for the rest of the session. If it is `denied`, the workflow stays inline for the rest of the session unless the user explicitly reopens the choice.
In the writing-plans execution handoff, choosing `Subagent-Driven` sets the shared session consent state to `granted` for implementation subagents in the rest of the session.

## Worktree Lifecycle

Implementation-oriented Superpowers flows should run inside a dedicated git worktree for isolation.

- If the workflow is about to move from design into planning or execution and no dedicated worktree is active yet, it should invoke `using-git-worktrees` first.
- If a dedicated worktree is already active for that implementation lane, the workflow should reuse it instead of creating a nested worktree.
- `subagent-driven-development` and `executing-plans` should execute inside that dedicated worktree, not in the shared primary workspace.
- `finishing-a-development-branch` is the standard convergence path for worktree cleanup:
  - Merge locally or discard: remove the worktree
  - Push PR or keep as-is: preserve the worktree for follow-up review or fixes

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
3. Restart Codex — skills are discovered at startup

### Windows junction issues

Junctions normally work without special permissions. If creation fails, try running PowerShell as administrator.

## Getting Help

- Report issues: https://github.com/joseph-bing-han/superpowers/issues
- Main documentation: https://github.com/joseph-bing-han/superpowers
