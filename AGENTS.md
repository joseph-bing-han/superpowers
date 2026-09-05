# Superpowers Project Rules

This repository is the team-maintained `openspec` fork of Superpowers. These rules
cover project-specific development and contribution requirements; the host's
instruction hierarchy and applicable global rules still apply.

## Project Map and Task Entry

- `skills/*/SKILL.md`: behavior-shaping skill entrypoints and their references.
- `agents/`: reviewer definitions; `hooks/` and platform directories: harness integration.
- `openspec/specs/`: current workflow contracts. `openspec/changes/archive/` and dated
  design/plan records are historical context, not new task gates.
- `tests/prompt-contracts/`, `tests/shared/`, `tests/codex/`: local contracts and fixtures.
- `tests/claude-code/`: live Claude integration tests and runner regression tests.
- `docs/testing.md`: current verification commands and prerequisites, followed by
  explicitly labeled historical evidence.

Read the applicable skill entrypoint when the task triggers that skill, then
expand only the references and current contracts affected by the task. Reuse
unchanged material already read in the current context. A copy edit does not
require reading every skill, historical proposal, or PR template.

For skill behavior changes, use `writing-skills`; preserve effective safeguards
unless evidence supports a change. A model upgrade alone is not evidence that
TDD, independent review, or validation can be removed.

## Validation and Completion

Choose checks by the changed contract and its consumers:

| Change | Required evidence |
| --- | --- |
| Non-behavioral spelling, links, comments, or documentation | Relevant content/link checks and `git diff --check` |
| Local script or skill behavior | Reproduction or before/after example, focused regression, affected call-site checks |
| Shared workflow, trigger, authorization, or completion semantics | Affected prompt contracts and transcript fixtures, positive/negative scenarios, representative before/after behavioral evaluation |
| Harness integration | Local integration checks plus clean-session end-to-end transcript on that harness |
| Merge or release | Applicable project checks and the authorization for that stage |

Run `bash tests/claude-code/test-run-skill-tests.sh` when changing the Claude runner.
There is no root `npm test` script. Select the actual affected shell tests from
`docs/testing.md`; no-test selections, skipped checks, and unavailable harnesses
are not passing evidence. Contract text checks alone do not prove live behavior.

The requested task is complete when its agreed scope is handled, proportionate
checks have run, the full task diff has been reviewed (including uncommitted and
untracked work), and limitations are reported. Reuse reliable evidence if its
inputs, environment, and contract are unchanged. Continue authorized work through
fixes and validation; ask only for a material unresolved decision or authorization.
A complete report may be delivered directly without an extra end/continue prompt.
Completing this request does not imply completing every open OpenSpec task,
merging a branch, or archiving a change.

## Contribution Targets and Authorization

Local edits do not authorize commits, pushes, PR creation, merges, or releases.
Before a requested PR, inspect the target repository's current contribution rules,
base branch, and full PR template. Do not assume `dev`, `main`, or `master`;
this fork currently tracks `origin/openspec`. Verify the target when submitting.

For a PR to this fork, use `.github/PULL_REQUEST_TEMPLATE.md` and provide:
a real problem or reproducible defect, one coherent scope, proportionate evidence,
a relevant search of open and closed PRs, and human approval of the complete diff.
A related PR calls for explaining the overlap or coordinating an update, not
silently submitting a duplicate. Review findings are valid motivation when backed
by reproducible evidence; do not fabricate experiences or results.

For a PR to upstream `obra/superpowers`, additionally confirm current upstream
policy: core is general-purpose and zero-dependency, apart from explicitly
accepted harness support. Domain-specific integrations and personal configuration
belong in separate plugins; fork-only customizations are not upstream sync PRs.
Keep one problem per PR and obtain human review of the complete proposed diff.
Changes to behavior-shaping skills need outcome evidence, not cosmetic compliance
with a different skill-writing guide.

## New Harness Acceptance

A new harness must load `using-superpowers` at session start and expose applicable
skills without a per-session opt-in. Include clean-session transcripts showing:

- Bootstrap loading and an explicitly requested skill being invoked.
- A lightweight task staying direct without unnecessary design or planning.
- A workflow request entering the appropriate skill or governance route.
- Authorized execution continuing and completed work ending without a spurious gate.

Use representative prompts for the advertised capabilities. Do not require a
fixed todo-list prompt to always invoke brainstorming. Record harness/model
versions, observed behavior, and any unavailable validation; do not infer success
from files merely being present on disk.
