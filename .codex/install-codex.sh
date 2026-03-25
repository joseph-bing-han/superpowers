#!/usr/bin/env bash
set -euo pipefail

# 解析仓库与用户目录位置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOME_DIR="${HOME:?HOME is required}"

CODEX_DIR="$HOME_DIR/.codex"
AGENTS_SKILLS_DIR="$HOME_DIR/.agents/skills"
CONFIG_PATH="$CODEX_DIR/config.toml"
SKILLS_LINK="$AGENTS_SKILLS_DIR/superpowers"
SKILLS_TARGET="$REPO_ROOT/skills"
INSTRUCTION_PATH="$REPO_ROOT/.codex/instruction.md"
MODEL_LINE="model_instructions_file = \"$INSTRUCTION_PATH\""

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

ensure_instruction_file() {
  [[ -f "$INSTRUCTION_PATH" ]] || fail "Missing canonical instruction file: $INSTRUCTION_PATH"
}

ensure_skills_symlink() {
  mkdir -p "$AGENTS_SKILLS_DIR"

  if [[ -L "$SKILLS_LINK" ]]; then
    local actual_target
    actual_target="$(readlink "$SKILLS_LINK")"

    if [[ "$actual_target" == "$SKILLS_TARGET" ]]; then
      echo "Skills symlink already configured: $SKILLS_LINK"
      return
    fi

    fail "Existing skills symlink points elsewhere: $SKILLS_LINK -> $actual_target"
  fi

  if [[ -e "$SKILLS_LINK" ]]; then
    fail "Existing path blocks skills symlink creation: $SKILLS_LINK"
  fi

  ln -s "$SKILLS_TARGET" "$SKILLS_LINK"
  echo "Created skills symlink: $SKILLS_LINK -> $SKILLS_TARGET"
}

write_new_config() {
  mkdir -p "$CODEX_DIR"
  cat >"$CONFIG_PATH" <<EOF
$MODEL_LINE
EOF
  echo "Created Codex config with Superpowers instruction bootstrap: $CONFIG_PATH"
}

insert_instruction_line() {
  local tmp_file

  tmp_file="$(mktemp "$CODEX_DIR/config.toml.XXXXXX")"
  awk -v line="$MODEL_LINE" '
    BEGIN {
      inserted = 0
    }

    !inserted && $0 ~ /^\[[^]]+\]/ {
      print line
      print ""
      inserted = 1
    }

    {
      print
    }

    END {
      if (!inserted) {
        if (NR > 0) {
          print ""
        }
        print line
      }
    }
  ' "$CONFIG_PATH" >"$tmp_file"

  mv "$tmp_file" "$CONFIG_PATH"
}

ensure_instruction_config() {
  mkdir -p "$CODEX_DIR"

  if [[ ! -f "$CONFIG_PATH" ]]; then
    write_new_config
    return
  fi

  if grep -Eq '^[[:space:]]*model_instructions_file[[:space:]]*=' "$CONFIG_PATH"; then
    if grep -Fq "$MODEL_LINE" "$CONFIG_PATH"; then
      echo "Codex model_instructions_file already configured for Superpowers."
      return
    fi

    fail "Existing model_instructions_file points elsewhere. Please merge manually in $CONFIG_PATH"
  fi

  insert_instruction_line
  echo "Configured model_instructions_file in $CONFIG_PATH"
}

main() {
  ensure_instruction_file
  ensure_skills_symlink
  ensure_instruction_config
  echo "Restart Codex to load the updated skills and instruction bootstrap."
}

main "$@"
