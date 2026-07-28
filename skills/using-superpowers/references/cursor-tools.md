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

Reviewers are the only subagents this repository still dispatches. In Cursor they
MUST be dispatched through a preset subagent file, never by negotiating a model
at dispatch time.

**Why preset files are mandatory:** Cursor caps the reasoning effort of
subagents spawned on the fly from chat at the parent agent's current effort. A
parent running at `high` cannot spawn an `xhigh` subagent that way. Preset
subagent files in `agents/` are not subject to that cap. Dispatching a reviewer
inline and asking for higher effort silently downgrades instead of failing.

**Never dispatch a reviewer through `explore`.** The built-in `explore` subagent
is deliberately bound to a fast, small model for parallel search. It does not
inherit the parent model, so a review dispatched through it lands below even the
fallback tier.

### Tiers

Reviewer selection is fail-closed: a review must never silently drop to a fast,
small model. Each preset reviewer file pins a strong default slug in frontmatter
and then, in its body, instructs the reviewer to run at the highest thinking
budget of the current conversation model.

| Tier | Condition | Behavior |
|------|-----------|----------|
| 1 | Conversation model is a strong reviewer-grade model (for example Opus 5, Opus 4.8) | Run on that model at its highest thinking budget (`max` for Opus 5 / Opus 4.8) |
| 2 | Conversation model is `gpt-5.6-sol` | Run `gpt-5.6-sol` at `xhigh` |
| 3 | Neither is available (admin restriction, plan exclusion, legacy request-based plan without Max Mode) | Fall back to `general-purpose` rather than a fast/small model |

Do NOT use `model: inherit` for reviewers. `inherit` copies the parent's
*current* effort, so it cannot raise a low-effort parent to a reviewer-grade
budget and gives no fail-closed floor. Instead pin a concrete strong slug in
frontmatter and let the body guidance follow the conversation model at its
highest budget.

On legacy request-based plans without Max Mode, subagents run on Composer
regardless of the `model` field; that is the tier-3 fallback boundary.

### Frontmatter Model Field

Each preset reviewer pins a concrete strong slug so review never degrades to a
fast model:

```yaml
model: gpt-5.6-sol
readonly: true
```

The body then carries a `Reviewer Model And Thinking Budget` section telling the
reviewer to run at the highest thinking level of the current conversation model
(Opus 5 / Opus 4.8 use `max`, `gpt-5.6-sol` uses `xhigh`) and to never run on a
Fast preset, an `Explore` / `explorer` agent, or `model: fast`.

Bracket parameters can also set effort explicitly on a slug:

```yaml
model: gpt-5.6-sol[effort=xhigh]
model: claude-opus-5[effort=max]
```

Two caveats on bracket syntax:

- Cursor labels it as not yet officially documented, so treat it as subject to change.
- It does not work with the CLI `--model` flag. The CLI needs a full slug such as
  `gpt-5.3-codex-xhigh`.

### Preset Reviewer Files

| Reviewer | File | Used by |
|----------|------|---------|
| Plan document | `agents/plan-reviewer.md` | `writing-plans` |
| Spec document | `agents/spec-reviewer.md` | `brainstorming` |
| Code | `agents/code-reviewer.md` | `requesting-code-review` |

All three run with `readonly: true`. A reviewer that can edit files can silently
fix what it should be reporting.

Model IDs live only in this file and in the `agents/` frontmatter. Skill bodies
reference the tiers, never a specific model ID, so platform churn stays confined
here.
