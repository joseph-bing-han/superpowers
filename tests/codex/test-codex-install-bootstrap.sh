#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INSTALL_SCRIPT="$REPO_ROOT/.codex/install-codex.sh"
EXPECTED_SKILLS_TARGET="$REPO_ROOT/skills"
EXPECTED_INSTRUCTION_PATH="$REPO_ROOT/.codex/instruction.md"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

pass() {
  echo "PASS: $1"
}

assert_file_exists() {
  local path="$1"
  local description="$2"

  if [[ -f "$path" ]]; then
    pass "$description"
  else
    fail "$description (missing $path)"
  fi
}

assert_symlink_target() {
  local path="$1"
  local expected="$2"
  local description="$3"
  local actual

  if [[ ! -L "$path" ]]; then
    fail "$description ($path is not a symlink)"
  fi

  actual="$(readlink "$path")"
  if [[ "$actual" == "$expected" ]]; then
    pass "$description"
  else
    fail "$description (expected $expected, got $actual)"
  fi
}

assert_config_contains_instruction() {
  local path="$1"
  local description="$2"

  if grep -Fq "model_instructions_file = \"$EXPECTED_INSTRUCTION_PATH\"" "$path"; then
    pass "$description"
  else
    fail "$description"
  fi
}

assert_single_instruction_line() {
  local path="$1"
  local description="$2"
  local count

  count="$(grep -Ec '^[[:space:]]*model_instructions_file[[:space:]]*=' "$path")"
  if [[ "$count" == "1" ]]; then
    pass "$description"
  else
    fail "$description (expected 1, got $count)"
  fi
}

run_with_home() {
  local home_dir="$1"
  HOME="$home_dir" bash "$INSTALL_SCRIPT"
}

test_fresh_install_bootstraps_instruction() {
  local tmpdir
  local config_path
  local skills_link

  tmpdir="$(mktemp -d)"
  config_path="$tmpdir/.codex/config.toml"
  skills_link="$tmpdir/.agents/skills/superpowers"

  run_with_home "$tmpdir"

  assert_file_exists "$config_path" "installer creates Codex config for a fresh install"
  assert_config_contains_instruction "$config_path" "installer bootstraps model_instructions_file for a fresh install"
  assert_single_instruction_line "$config_path" "installer adds only one model_instructions_file line on a fresh install"
  assert_symlink_target "$skills_link" "$EXPECTED_SKILLS_TARGET" "installer creates the Codex skills symlink"
}

test_repeated_install_is_idempotent() {
  local tmpdir
  local config_path

  tmpdir="$(mktemp -d)"
  config_path="$tmpdir/.codex/config.toml"

  run_with_home "$tmpdir"
  run_with_home "$tmpdir"

  assert_single_instruction_line "$config_path" "installer remains idempotent on repeated runs"
  assert_config_contains_instruction "$config_path" "installer preserves the expected model_instructions_file on repeated runs"
}

test_conflicting_instruction_path_is_not_overwritten() {
  local tmpdir
  local config_path

  tmpdir="$(mktemp -d)"
  config_path="$tmpdir/.codex/config.toml"
  mkdir -p "$(dirname "$config_path")"

  cat >"$config_path" <<'EOF'
model_instructions_file = "/tmp/other-instruction.md"
EOF

  if run_with_home "$tmpdir" >/tmp/codex-install-bootstrap-conflict.log 2>&1; then
    fail "installer rejects conflicting model_instructions_file values"
  fi

  if grep -Fq 'model_instructions_file = "/tmp/other-instruction.md"' "$config_path"; then
    pass "installer preserves the existing conflicting model_instructions_file"
  else
    fail "installer preserves the existing conflicting model_instructions_file"
  fi
}

test_fresh_install_bootstraps_instruction
test_repeated_install_is_idempotent
test_conflicting_instruction_path_is_not_overwritten

echo "All Codex install bootstrap checks passed."
