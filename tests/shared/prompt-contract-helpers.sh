#!/usr/bin/env bash

# 调用方提供 REPO_ROOT；统一处理换行，避免仅因 Markdown 折行导致契约失败。
assert_contract() {
  local expected="$1" file="$2" heading="$3" pattern="$4" description="$5"
  local content status=0

  if [[ ! -f "$REPO_ROOT/$file" ]]; then
    echo "FAIL: $description (missing $file)"
    return 1
  fi

  if [[ -n "$heading" ]]; then
    content="$(awk -v heading="$heading" '
      $0 == heading { found = 1; next }
      found && /^## / { exit }
      found { print }
    ' "$REPO_ROOT/$file")" || {
      echo "FAIL: $description (cannot read section: $heading in $file)"
      return 1
    }
    if [[ -z "${content//[[:space:]]/}" ]]; then
      echo "FAIL: $description (missing or empty section: $heading in $file)"
      return 1
    fi
  else
    content="$(cat "$REPO_ROOT/$file")" || {
      echo "FAIL: $description (cannot read $file)"
      return 1
    }
  fi

  content="$(
    set -o pipefail
    printf '%s' "$content" | tr '\r\n\t' '   ' | sed -E 's/[[:space:]]+/ /g'
  )" || {
    echo "FAIL: $description (cannot normalize $file)"
    return 1
  }
  rg -qi -- "$pattern" <<< "$content" || status=$?
  if { [[ "$expected" == present && "$status" -eq 0 ]]; } ||
     { [[ "$expected" == absent && "$status" -eq 1 ]]; }; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "  File: $file"
    echo "  Pattern: $pattern (expected $expected, search exit $status)"
    return 1
  fi
}

assert_file_contains() { assert_contract present "$1" '' "$2" "$3"; }
assert_file_not_contains() { assert_contract absent "$1" '' "$2" "$3"; }
assert_section_contains() { assert_contract present "$1" "$2" "$3" "$4"; }
assert_section_not_contains() { assert_contract absent "$1" "$2" "$3" "$4"; }

assert_file_exists() {
  if [[ -f "$REPO_ROOT/$1" ]]; then
    echo "PASS: $2"
  else
    echo "FAIL: $2 (missing $1)"
    return 1
  fi
}
