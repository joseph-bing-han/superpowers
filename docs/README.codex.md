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

If the user asked for end-to-end completion, Superpowers should continue automatically when no clarification or confirmation is needed.

- Do not stop after summaries, checkpoints, or phase completions just to ask whether to continue.
- Summaries, checkpoints, and phase completions are progress updates, not automatic stop points.
- If the next action is already implied and safe, take it.
- Pause only when missing information would change the work, a destructive or external action needs confirmation, or a material tradeoff still needs the user's decision.

## Session-Scoped Subagent Consent

Superpowers tracks session-scoped subagent consent as `unknown`, `granted`, or `denied`.

When a reviewer or implementer subagent would materially help and the state is `unknown`, the workflow should ask once through `request_user_input` before dispatching it. It should not silently downgrade first or explain the missing authorization after the fact.

If that session-level consent is `granted`, those workflows can keep using helpful subagents without asking again for the rest of the session. If it is `denied`, the workflow stays inline for the rest of the session unless the user explicitly reopens the choice.
In the writing-plans execution handoff, choosing `Subagent-Driven` sets the shared session consent state to `granted` for implementation subagents in the rest of the session.

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
