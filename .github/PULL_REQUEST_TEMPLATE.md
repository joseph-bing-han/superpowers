<!--
Use the target repository's current template. Complete applicable sections with
specific evidence; mark genuinely inapplicable sections N/A with a reason.
Obtain human review of the complete diff before submitting.
-->

## What problem are you trying to solve?

<!-- Describe the observed failure, reproducible defect, or concrete workflow
     conflict. Include a reproduction or relevant session evidence. Do not invent
     a user experience or report unrun checks as passing. -->

## What does this PR change?

<!-- Briefly describe the change and its scope. -->

## Is this change appropriate for the target repository?

<!-- Identify whether this targets the maintained fork or upstream core.
     Upstream core is general-purpose and zero-dependency except for accepted
     harness support. Domain-specific integrations and personal configuration
     belong in separate plugins; fork-only customizations are not upstream syncs. -->

## What alternatives did you consider?

<!-- Explain meaningful tradeoffs. For a narrow correction, explain why no
     additional design exploration was needed. -->

## Does this PR contain multiple unrelated changes?

<!-- Keep one coherent problem per PR; explain dependencies between changed areas. -->

## Existing PRs

- [ ] I searched relevant open and closed PRs for duplicates and prior approaches
- Search scope and related PRs: <!-- queries/repository, #number, or none found -->

<!-- Explain overlap with related work and why this is not a duplicate. -->

## Validation

| Change / affected contract | Command or scenario | Result | Environment / prerequisites |
| --- | --- | --- | --- |
| | | | |

<!-- Select verification by risk:
     - Non-behavioral text: relevant content/link checks and diff formatting.
     - Local behavior: reproduction, focused regression, affected consumers.
     - Shared skill/workflow semantics: contracts, positive/negative scenarios,
       representative before/after behavioral evaluation.
     - Harness integration: clean-session end-to-end evidence.

     State skipped/unavailable checks and residual risk. Existing evidence may be
     reused when its inputs, environment, and contract are unchanged.
     Zero tests and fixture parsing alone are not live-harness success. -->

## New harness support

<!-- Required only when adding a harness; otherwise mark N/A.
     Record harness/version and model/version. Include clean-session transcripts
     proving bootstrap loading, explicit skill invocation, a lightweight task
     staying direct, correct workflow/governance routing, authorized continuation,
     and direct completion. Do not use a fixed todo-list prompt as a universal
     requirement to invoke brainstorming. -->

<details>
<summary>Clean-session transcript and environment</summary>

<!-- Link or paste the actual transcript when applicable. -->

</details>

## Skill behavior evaluation

<!-- For behavior-shaping changes, describe:
     - The initial scenario and before-change behavior.
     - Positive, negative, and pressure cases exercised after the change.
     - Actual observed outcomes, session count, and harness/model versions.
     - Any unavailable live evaluation and what local checks do and do not prove.

     For spelling/link/format-only changes, state why behavior is unchanged.
     A model upgrade or alignment with another style guide is not sufficient
     evidence to remove an effective safeguard. -->

- [ ] Applicable skill changes followed `superpowers:writing-skills`
- [ ] Validation covers the changed behavior and meaningful failure cases, or limitations are stated

## Human review

- [ ] A human has reviewed the COMPLETE proposed diff before submission

<!-- If human review is incomplete, do not submit. Commit/push/PR/merge/release
     are distinct actions and require the corresponding authorization. -->
