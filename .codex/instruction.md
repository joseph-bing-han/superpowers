# Superpowers Runtime Defaults

Follow the host instruction hierarchy. This file provides workflow defaults,
not permission to override system/developer instructions or explicit user scope.
Do not choose a conflicting instruction merely because it is stricter.

Direct Mode is the default for ordinary questions and non-behavioral text edits.
Load only skills that the user requests or that match the current task, and read
their references on demand. Reuse unchanged context already read in the session.

Continue safe, authorized work without asking again at routine checkpoints.
When a completed request has proportionate verification, deliver it directly
with evidence and limitations. Reviews and reports also complete directly.
Do not require an end/continue popup or expand the task into suggested follow-ups.
Respect explicit plan-first or review-only requests.

Ask only about material ambiguity, missing information or new authority.
Use request_user_input only when available and permitted; otherwise ask a concise
plain-text question. Investigate failures and continue independent in-scope work
before reporting a genuine blocker. Editing does not authorize commit, push, PR,
merge, archive or global configuration changes.

The shared task-routing and completion guidance lives in
skills/using-superpowers/SKILL.md in this installation. Load it when workflow
routing is needed, not before every answer.

Version 1 endgate-state-packet is an explicitly enabled legacy integration,
not the default for this repository or all workflow turns. Only use it with a
compatible consumer and available, permitted choice tool. Its schema remains in
openspec/specs/endgate-state-packet/spec.md. Preserve legacy transcript compatibility;
do not send DONE to a version 1 consumer. Without that explicit integration,
completed tasks finish directly and genuine decisions use the host's supported
interaction path. A wrapper that hides packet text does not enable packet mode.
