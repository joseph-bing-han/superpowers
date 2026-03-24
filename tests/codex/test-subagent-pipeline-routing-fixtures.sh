#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
POSITIVE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/pipeline-sdd-overlap-positive.jsonl"
NEGATIVE_FIXTURE="$REPO_ROOT/tests/codex/fixtures/pipeline-sdd-conflict-group-negative.jsonl"

assert_positive_fixture() {
  if jq -s -e '
    def has_implementer_overlap:
      any(.[]; .role == "implementer" and .overlap_key == "implementing-window")
      and any(.[]; .role == "preflight" and .overlaps_role == "implementer" and .overlap_key == "implementing-window");

    def has_reviewer_overlap:
      any(.[]; .role == "reviewer" and .overlap_key == "review-window")
      and any(.[]; .role == "preflight" and .overlaps_role == "reviewer" and .overlap_key == "review-window");

    has_implementer_overlap and has_reviewer_overlap
  ' "$POSITIVE_FIXTURE" >/dev/null; then
    echo "PASS: positive fixture proves implementer + preflight overlap"
    echo "PASS: positive fixture proves reviewer + preflight overlap"
  else
    echo "FAIL: positive fixture does not prove both required Pipeline SDD overlaps"
    exit 1
  fi
}

assert_negative_fixture_is_rejected() {
  if jq -s -e '
    group_by(.conflict_group + "|" + .overlap_key)
    | any(.[]; length > 1 and all(.[]; .role == "implementer" and .write_access == "write"))
  ' "$NEGATIVE_FIXTURE" >/dev/null; then
    echo "PASS: negative fixture is correctly rejected for same Conflict Group double-write"
  else
    echo "FAIL: negative fixture did not trigger the same Conflict Group double-write guard"
    exit 1
  fi
}

assert_positive_fixture
assert_negative_fixture_is_rejected

echo "All subagent pipeline routing fixture checks passed."
