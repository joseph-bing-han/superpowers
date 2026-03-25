#!/usr/bin/env bash
set -euo pipefail

# 这是一个显式 opt-in 的过渡 wrapper：只负责隐藏终端渲染中的 ENDGATE_* 行。
# 它不会替代 transcript carrier，也不会把 sidecar 升级为 canonical contract。

WRAPPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_RUNTIME_DIR="$WRAPPER_DIR/.runtime"
CODEX_BIN="${CODEX_BIN:-codex}"
CODEX_ENDGATE_RUNTIME_DIR="${CODEX_ENDGATE_RUNTIME_DIR:-$DEFAULT_RUNTIME_DIR}"
CODEX_ENDGATE_WRITE_DEBUG_MIRROR="${CODEX_ENDGATE_WRITE_DEBUG_MIRROR:-0}"

is_truthy() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|on|ON)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

json_escape() {
  local value="${1-}"

  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}
  value=${value//$'\t'/\\t}

  printf '%s' "$value"
}

raw_lines_to_json() {
  local first=1
  local line

  printf '['
  for line in "$@"; do
    if [ "$first" -eq 0 ]; then
      printf ','
    fi
    printf '"%s"' "$(json_escape "$line")"
    first=0
  done
  printf ']'
}

carrier_json_from_block() {
  local protocol_version=""
  local state=""
  local choice_kind=""
  local next_action=""
  local line=""
  local value=""

  if [ "$#" -ne 4 ]; then
    return 1
  fi

  for line in "$@"; do
    case "$line" in
      ENDGATE_PROTOCOL_VERSION:*)
        value="${line#ENDGATE_PROTOCOL_VERSION: }"
        [ -z "$protocol_version" ] || return 1
        protocol_version="$value"
        ;;
      ENDGATE_STATE:*)
        value="${line#ENDGATE_STATE: }"
        [ -z "$state" ] || return 1
        state="$value"
        ;;
      ENDGATE_CHOICE_KIND:*)
        value="${line#ENDGATE_CHOICE_KIND: }"
        [ -z "$choice_kind" ] || return 1
        choice_kind="$value"
        ;;
      ENDGATE_NEXT_ACTION:*)
        value="${line#ENDGATE_NEXT_ACTION: }"
        [ -z "$next_action" ] || return 1
        next_action="$value"
        ;;
      *)
        return 1
        ;;
    esac
  done

  [ -n "$protocol_version" ] || return 1
  [ -n "$state" ] || return 1
  [ -n "$choice_kind" ] || return 1
  [ -n "$next_action" ] || return 1

  printf '{"ENDGATE_PROTOCOL_VERSION":"%s","ENDGATE_STATE":"%s","ENDGATE_CHOICE_KIND":"%s","ENDGATE_NEXT_ACTION":"%s"}' \
    "$(json_escape "$protocol_version")" \
    "$(json_escape "$state")" \
    "$(json_escape "$choice_kind")" \
    "$(json_escape "$next_action")"
}

write_debug_mirror() {
  local stream="$1"
  shift

  if ! is_truthy "$CODEX_ENDGATE_WRITE_DEBUG_MIRROR"; then
    return 0
  fi

  if [ "$#" -eq 0 ]; then
    return 0
  fi

  local raw_lines_json
  local carrier_json=""
  local record_json
  local timestamp
  local state_log
  local latest_file
  local tmp_file

  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  raw_lines_json="$(raw_lines_to_json "$@")"
  carrier_json="$(carrier_json_from_block "$@" 2>/dev/null || true)"

  record_json=$(printf '{"recorded_at":"%s","source":"codex-endgate-wrapper","debug_mirror":true,"contract_role":"debug_mirror","stream":"%s","raw_lines":%s' \
    "$(json_escape "$timestamp")" \
    "$(json_escape "$stream")" \
    "$raw_lines_json")

  if [ -n "$carrier_json" ]; then
    record_json="${record_json},\"carrier\":${carrier_json},\"canonical_carrier_present\":true}"
  else
    record_json="${record_json},\"canonical_carrier_present\":false}"
  fi

  mkdir -p "$CODEX_ENDGATE_RUNTIME_DIR" || return 0

  state_log="$CODEX_ENDGATE_RUNTIME_DIR/endgate-state.jsonl"
  latest_file="$CODEX_ENDGATE_RUNTIME_DIR/latest-endgate.json"
  printf '%s\n' "$record_json" >> "$state_log" || return 0

  tmp_file="$latest_file.tmp.$$"
  printf '%s\n' "$record_json" > "$tmp_file" || {
    rm -f "$tmp_file"
    return 0
  }
  mv "$tmp_file" "$latest_file" || {
    rm -f "$tmp_file"
    return 0
  }
}

emit_visible_line() {
  local stream="$1"
  local line="$2"

  if [ "$stream" = "stderr" ]; then
    printf '%s\n' "$line" >&2
  else
    printf '%s\n' "$line"
  fi
}

flush_endgate_block() {
  local stream="$1"
  shift

  if [ "$#" -eq 0 ]; then
    return 0
  fi

  write_debug_mirror "$stream" "$@"
}

process_stream() {
  local stream="$1"
  local line=""
  local normalized_line=""
  local -a packet_lines=()

  while IFS= read -r line || [ -n "$line" ]; do
    normalized_line="${line%$'\r'}"

    case "$normalized_line" in
      ENDGATE_[A-Z_]*:*)
        packet_lines+=("$normalized_line")
        ;;
      *)
        if [ "${#packet_lines[@]}" -gt 0 ]; then
          flush_endgate_block "$stream" "${packet_lines[@]}"
          packet_lines=()
        fi
        emit_visible_line "$stream" "$normalized_line"
        ;;
    esac
  done

  if [ "${#packet_lines[@]}" -gt 0 ]; then
    flush_endgate_block "$stream" "${packet_lines[@]}"
  fi
}

main() {
  local pipe_dir=""
  local stdout_pipe=""
  local stderr_pipe=""
  local stdout_pid=""
  local stderr_pid=""
  local status=0

  pipe_dir="$(mktemp -d "${TMPDIR:-/tmp}/codex-endgate-wrapper.XXXXXX")"
  stdout_pipe="$pipe_dir/stdout.pipe"
  stderr_pipe="$pipe_dir/stderr.pipe"

  cleanup() {
    rm -rf "$pipe_dir"
  }

  trap cleanup EXIT

  mkfifo "$stdout_pipe" "$stderr_pipe"

  process_stream stdout < "$stdout_pipe" &
  stdout_pid="$!"

  process_stream stderr < "$stderr_pipe" >&2 &
  stderr_pid="$!"

  "$CODEX_BIN" "$@" > "$stdout_pipe" 2> "$stderr_pipe" || status=$?

  wait "$stdout_pid" || true
  wait "$stderr_pid" || true
  exit "$status"
}

main "$@"
