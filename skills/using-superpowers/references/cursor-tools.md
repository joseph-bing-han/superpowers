# Cursor Tool Mapping

Skills use Claude Code tool names. When you encounter these in a skill, use your platform equivalent:

| Skill references | Cursor equivalent |
|-----------------|-------------------|
| `Task` tool (dispatch subagent) | `Task` tool with `subagent_type`, or `/name` for a preset subagent |
| `TodoWrite` (task tracking) | `TodoWrite` |
| `Skill` tool (invoke a skill) | Skills load natively — just follow the instructions |
| `Read`, `Write`, `Edit` (files) | Use your native file tools |
| `Bash` (run commands) | Use your native shell tools |
| `Grep`, `Glob` (search) | Use your native search tools |

## Reviewer Model Routing

Use the configured read-only reviewer presets when they are available and
appropriate for the review risk. Confirm supported model and effort settings
through the actual runtime configuration; prompt text cannot switch the model
or increase the thinking budget of an already running reviewer.

The model in each preset is a local default, not a promise that every account,
Cursor version or CLI accepts it. Do not silently substitute a search-only or
lightweight agent for a required independent review. If the configured preset
is unavailable, use an available reviewer-grade route or report the limitation
and perform a scoped self-review. Do not install models, change global settings
or refuse to report completed work just to satisfy a model preference.

A specifically required external review can block integration until provided;
an optional reviewer preference cannot block a low-risk edit.

| Reviewer | File | Used by |
|----------|------|---------|
| Plan document | agents/plan-reviewer.md | writing-plans |
| Spec document | agents/spec-reviewer.md | brainstorming |
| Code | agents/code-reviewer.md | requesting-code-review |

All three presets retain readonly: true. Provide only relevant artifacts and
the full task diff, including uncommitted files when applicable. Use the host's
supported dispatch fields rather than undocumented model-slug syntax.
