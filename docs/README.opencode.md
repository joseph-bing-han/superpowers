# Superpowers for OpenCode

Complete guide for using Superpowers with [OpenCode.ai](https://opencode.ai).

## Installation

Add superpowers to the `plugin` array in your `opencode.json` (global or project-level):

```json
{
  "plugin": [
    "superpowers@git+https://github.com/joseph-bing-han/superpowers.git#openspec"
  ]
}
```

Restart OpenCode.

This OpenCode installation path uses the team-maintained fork and the `openspec`
branch, so you get the current repo changes and newly added skills/bootstrap content.

On startup, the plugin will:

- load `.opencode/plugins/superpowers.js` from the repo
- register the repo `skills/` tree with OpenCode
- inject the `using-superpowers` bootstrap automatically
- expose newer skills such as `spec-governed-development`

The OpenSpec governance entry point exposed by this branch is
`spec-governed-development`. It decides whether the current task should enter an
OpenSpec lane. It is not a rename of `openspec-apply-change`, which still
remains a separate execution skill used after a task has already entered the
OpenSpec lane and is ready for implementation.

### Migrating from older installs

If you previously installed superpowers using symlinks, a local clone, or the
upstream `obra/superpowers` repository, remove the old setup:

```bash
# Remove old symlinks
rm -f ~/.config/opencode/plugins/superpowers.js
rm -rf ~/.config/opencode/skills/superpowers

# Optionally remove the cloned repo
rm -rf ~/.config/opencode/superpowers
```

Then update `opencode.json`:

1. Replace any `obra/superpowers` plugin entry with
   `joseph-bing-han/superpowers.git#openspec`
2. Remove any old `skills.paths` entry that still points at an outdated
   superpowers clone or skills directory
3. Restart OpenCode

## Usage

### Finding Skills

Use OpenCode's native `skill` tool to list all available skills:

```
use skill tool to list skills
```

### Loading a Skill

```
use skill tool to load superpowers/brainstorming
use skill tool to load superpowers/spec-governed-development
```

You usually do not need to manually load `using-superpowers`, because it is
already injected by the plugin bootstrap.

### Personal Skills

Create your own skills in `~/.config/opencode/skills/`:

```bash
mkdir -p ~/.config/opencode/skills/my-skill
```

Create `~/.config/opencode/skills/my-skill/SKILL.md`:

```markdown
---
name: my-skill
description: Use when [condition] - [what it does]
---

# My Skill

[Your skill content here]
```

### Project Skills

Create project-specific skills in `.opencode/skills/` within your project.

**Skill Priority:** Project skills > Personal skills > Superpowers skills

## Updating

OpenCode re-resolves the git plugin source when it restarts.

As long as your `opencode.json` still points to:

```json
{
  "plugin": [
    "superpowers@git+https://github.com/joseph-bing-han/superpowers.git#openspec"
  ]
}
```

Restarting OpenCode keeps you on the current team-maintained `openspec` branch.

To pin a specific revision, replace `#openspec` with a specific commit SHA.

## How It Works

The plugin does two things:

1. **Injects bootstrap context** via the `experimental.chat.system.transform` hook, adding superpowers awareness to every conversation.
2. **Registers the skills directory** via the `config` hook, so OpenCode discovers all superpowers skills without symlinks or manual config.

### Tool Mapping

Skills written for Claude Code are automatically adapted for OpenCode:

- `TodoWrite` → `todowrite`
- `Task` with subagents → OpenCode's `@mention` system
- `Skill` tool → OpenCode's native `skill` tool
- File operations → Native OpenCode tools

## Troubleshooting

### Plugin not loading

1. Check OpenCode logs: `opencode run --print-logs "hello" 2>&1 | grep -i superpowers`
2. Verify the plugin line in your `opencode.json` points to `joseph-bing-han/superpowers.git#openspec`
3. Make sure you're running a recent version of OpenCode

### Skills not found

1. Use OpenCode's `skill` tool to list available skills
2. Check that the plugin is loading (see above)
3. Check whether an old `skills.paths` entry or outdated local directory is shadowing the current install
4. Restart OpenCode

### Bootstrap not appearing

1. Check OpenCode version supports `experimental.chat.system.transform` hook
2. Restart OpenCode after config changes

## Getting Help

- Report issues: https://github.com/joseph-bing-han/superpowers/issues
- Main documentation: https://github.com/joseph-bing-han/superpowers
- OpenCode docs: https://opencode.ai/docs/
