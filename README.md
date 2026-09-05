# Superpowers

Superpowers is a complete software development methodology for your coding agents, built on top of a set of composable skills and some initial instructions that make sure your agent uses them.

## How it works

Superpowers loads a bootstrap when the coding agent starts and selects skills according to the task. When design is needed, it clarifies consequential unknowns and develops an agreed design. An existing design or a clear, low-risk request can proceed without repeating that conversation.

For work that benefits from a plan, the agent records actionable steps and acceptance checks. Once implementation is authorized, it works through the agreed scope, verifies the affected behavior, and reviews the complete change before reporting the outcome. Missing information only interrupts work that actually depends on it.

There's a bunch more to it, but that's the core of the system. In the current model, lightweight tasks stay direct by default. Superpowers workflow kicks in when you explicitly ask for a skill or use a clear workflow keyword such as design, planning, debugging, review, or implementation coordination.


## Sponsorship

If Superpowers has helped you do stuff that makes money and you are so inclined, I'd greatly appreciate it if you'd consider [sponsoring my opensource work](https://github.com/sponsors/obra).

Thanks! 

- Jesse


## Installation

**Note:** Installation differs by platform. 

### Claude Code Official Marketplace

Superpowers is available via the [official Claude plugin marketplace](https://claude.com/plugins/superpowers)

Install the plugin from Anthropic's official marketplace:

```bash
/plugin install superpowers@claude-plugins-official
```

### Claude Code (Superpowers Marketplace)

The Superpowers marketplace provides Superpowers and some other related plugins for Claude Code.

In Claude Code, register the marketplace first:

```bash
/plugin marketplace add obra/superpowers-marketplace
```

Then install the plugin from this marketplace:

```bash
/plugin install superpowers@superpowers-marketplace
```

### OpenAI Codex CLI

- Open plugin search interface

```bash
/plugins
```

Search for Superpowers

```bash
superpowers
```

Select `Install Plugin`

### OpenAI Codex App

- In the Codex app, click on Plugins in the sidebar.
- You should see `Superpowers` in the Coding section. 
- Click the `+` next to Superpowers and follow the prompts.


### Cursor (via Plugin Marketplace)

In Cursor Agent chat, install from marketplace:

```text
/add-plugin superpowers
```

or search for "superpowers" in the plugin marketplace.

### Codex

Tell Codex:

```
Fetch and follow instructions from https://raw.githubusercontent.com/joseph-bing-han/superpowers/refs/heads/openspec/.codex/INSTALL.md
```

This Codex path installs the team-maintained `openspec` branch.
It also bootstraps the repo-managed Codex instruction file via `model_instructions_file`, so first-time installs do not need a separate manual config edit.

**Detailed docs:** [docs/README.codex.md](docs/README.codex.md)
### OpenCode

Tell OpenCode:

```
Fetch and follow instructions from https://raw.githubusercontent.com/joseph-bing-han/superpowers/refs/heads/openspec/.opencode/INSTALL.md
```

This OpenCode path installs the team-maintained `openspec` branch.
It loads the repo plugin, registers the repo `skills/` tree, injects the `using-superpowers` bootstrap, and exposes newer skills such as `spec-governed-development`.

**Detailed docs:** [docs/README.opencode.md](docs/README.opencode.md)

### GitHub Copilot CLI

```bash
copilot plugin marketplace add obra/superpowers-marketplace
copilot plugin install superpowers@superpowers-marketplace
```

### Gemini CLI

```bash
gemini extensions install https://github.com/obra/superpowers
```

To update:

```bash
gemini extensions update superpowers
```

### Verify Installation

Start a new session in your chosen platform and ask for something with clear workflow intent (for example, "help me plan this feature" or "let's debug this issue"), or explicitly name a skill. Lightweight tasks such as plain Q&A, translation, or copy-only edits should stay direct instead of triggering the heavyweight workflow.

## The Basic Workflow

1. **brainstorming** - Refines requests that need design work. Asks consequential questions, considers relevant alternatives, and records a design when useful or required by project governance.

2. **writing-plans** - Turns an agreed design into an actionable plan with affected files, dependencies, acceptance checks, and risks. Detail scales with the handoff needs.

3. **executing-plans** - Activates with plan. Works through tasks in the current workspace, running each task's verifications as it goes.

4. **test-driven-development** - Uses RED-GREEN-REFACTOR for testable behavior changes. Preserve existing work while adding reproduction and regression evidence; commits require authorization.

5. **requesting-code-review** - Reviews the complete task diff, including uncommitted changes, against the requirements. Material issues block approval of the affected change, not unrelated authorized work.

6. **finishing-a-development-branch** - Handles a requested integration or cleanup outcome. Reuses the user's chosen outcome and asks only when a real decision or authorization is missing.

Skills apply when triggered by the task; references are read on demand. A completed request ends with its result, verification evidence, and limitations, without a mandatory end/continue confirmation.

## What's Inside

### Skills Library

**Testing**
- **test-driven-development** - RED-GREEN-REFACTOR cycle (includes testing anti-patterns reference)

**Debugging**
- **systematic-debugging** - 4-phase root cause process (includes root-cause-tracing, defense-in-depth, condition-based-waiting techniques)
- **verification-before-completion** - Ensure it's actually fixed

**Collaboration** 
- **brainstorming** - Socratic design refinement
- **writing-plans** - Detailed implementation plans
- **executing-plans** - Task execution with batch review before finishing
- **requesting-code-review** - Review the completed work against the plan
- **receiving-code-review** - Responding to feedback
- **finishing-a-development-branch** - Merge/PR decision workflow
- **spec-governed-development** - OpenSpec governance entrypoint for larger changes

**Meta**
- **writing-skills** - Create new skills following best practices (includes testing methodology)
- **using-superpowers** - Introduction to the skills system

## Philosophy

- **Test-Driven Development** - Establish failing evidence before implementing testable behavior changes
- **Systematic over ad-hoc** - Process over guessing
- **Complexity reduction** - Simplicity as primary goal
- **Evidence over claims** - Verify before declaring success

Read [the original release announcement](https://blog.fsck.com/2025/10/09/superpowers/).

## Contributing

This repository maintains the `openspec` fork. Start with [AGENTS.md](AGENTS.md) for project rules and [docs/testing.md](docs/testing.md) for checks matched to the change. There is no root `npm test` script.

For an authorized contribution, verify the target repository and its current base branch rather than assuming `dev`, `main`, or `master`. Use `writing-skills` for skill changes and scale evaluation to whether the edit changes behavior. Before opening a PR, follow the target repository's template, search related open and closed PRs, and obtain human approval of the complete diff.

Upstream `obra/superpowers` has separate core-scope requirements. General-purpose, zero-dependency behavior belongs in core; fork-only customizations and domain-specific integrations should not be submitted as upstream sync changes. Editing locally does not authorize a commit, push, PR, merge, or release.

## Updating

Superpowers updates are somewhat coding-agent dependent, but are often automatic.

## License

MIT License - see LICENSE file for details

## Community

Superpowers is built by [Jesse Vincent](https://blog.fsck.com) and the rest of the folks at [Prime Radiant](https://primeradiant.com).

For community support, questions, and sharing what you're building with Superpowers, join us on [Discord](https://discord.gg/Jd8Vphy9jq).

## Support

- **Discord**: [Join us on Discord](https://discord.gg/Jd8Vphy9jq)
- **Issues**: https://github.com/joseph-bing-han/superpowers/issues
- **Release announcements**: [Sign up](https://primeradiant.com/superpowers/) to get notified about new versions
- **Marketplace**: https://github.com/obra/superpowers-marketplace
