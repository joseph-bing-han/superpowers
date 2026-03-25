#!/usr/bin/env bash
set -euo pipefail

# 这是一个显式 opt-in 的过渡 wrapper：只负责隐藏终端渲染中的 ENDGATE_* 行。
# 它不会替代 transcript carrier，也不会把 sidecar 升级为 canonical contract。

WRAPPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_RUNTIME_DIR="$WRAPPER_DIR/.runtime"
CODEX_BIN="${CODEX_BIN:-codex}"
CODEX_ENDGATE_RUNTIME_DIR="${CODEX_ENDGATE_RUNTIME_DIR:-$DEFAULT_RUNTIME_DIR}"
CODEX_ENDGATE_WRITE_DEBUG_MIRROR="${CODEX_ENDGATE_WRITE_DEBUG_MIRROR:-0}"
SCRIPT_BIN="${SCRIPT_BIN:-script}"

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

line_can_still_be_endgate_candidate() {
  local line="$1"
  local prefix="ENDGATE_"

  line="${line%$'\r'}"

  if [ -z "$line" ]; then
    return 0
  fi

  if [[ "$prefix" == "$line"* ]]; then
    return 0
  fi

  [[ "$line" == ENDGATE_* ]]
}

line_is_hidden_endgate() {
  local line="$1"

  line="${line%$'\r'}"
  [[ "$line" =~ ^ENDGATE_[A-Z_]+:\ .*$ ]]
}

is_canonical_endgate_block() {
  local -a lines=("$@")
  local -a expected_keys=(
    "ENDGATE_PROTOCOL_VERSION"
    "ENDGATE_STATE"
    "ENDGATE_CHOICE_KIND"
    "ENDGATE_NEXT_ACTION"
  )
  local index=0
  local line=""
  local expected_key=""
  local value=""

  if [ "${#lines[@]}" -ne 4 ]; then
    return 1
  fi

  for ((index = 0; index < 4; index++)); do
    line="${lines[$index]%$'\r'}"
    expected_key="${expected_keys[$index]}"

    if [[ "$line" != "$expected_key: "* ]]; then
      return 1
    fi

    value="${line#"$expected_key: "}"
    if [ -z "$value" ]; then
      return 1
    fi
  done

  return 0
}

startup_prefix_still_possible() {
  local buffer="$1"
  local raw_prefix=$'\004\b\b'
  local rendered_prefix='^D'$'\b\b'

  [[ "$raw_prefix" == "$buffer"* ]] || [[ "$rendered_prefix" == "$buffer"* ]]
}

startup_prefix_is_complete() {
  local buffer="$1"
  local raw_prefix=$'\004\b\b'
  local rendered_prefix='^D'$'\b\b'

  [[ "$buffer" == "$raw_prefix" || "$buffer" == "$rendered_prefix" ]]
}

process_stream() {
  local stream="$1"
  local line=""
  local startup_buffer=""
  local startup_filter_active=1
  local candidate_buffer=""
  local ordinary_mode=0
  local -a packet_lines=()

  emit_visible_byte() {
    local char="$1"
    printf '%s' "$char"
  }

  emit_visible_text() {
    local text="$1"
    local index=0
    local char=""

    for ((index = 0; index < ${#text}; index++)); do
      char="${text:index:1}"
      emit_visible_byte "$char"
    done
  }

  flush_visible_cr() {
    :
  }

  flush_hidden_packet_lines() {
    if [ "${#packet_lines[@]}" -gt 0 ]; then
      if is_canonical_endgate_block "${packet_lines[@]}"; then
        flush_endgate_block "$stream" "${packet_lines[@]}"
      fi

      packet_lines=()
    fi
  }

  process_render_char() {
    local char="$1"
    local candidate_line=""

    if [ "$ordinary_mode" -eq 1 ]; then
      emit_visible_byte "$char"

      if [ "$char" = $'\r' ] || [ "$char" = $'\n' ]; then
        ordinary_mode=0
      fi

      return 0
    fi

    candidate_buffer+="$char"

    if [ "$char" = $'\r' ] || [ "$char" = $'\n' ]; then
      candidate_line="${candidate_buffer%$'\n'}"
      candidate_line="${candidate_line%$'\r'}"

      if line_is_hidden_endgate "$candidate_line"; then
        packet_lines+=("$candidate_line")
      else
        flush_hidden_packet_lines
        emit_visible_text "$candidate_buffer"
      fi

      candidate_buffer=""
      ordinary_mode=0
      return 0
    fi

    if ! line_can_still_be_endgate_candidate "$candidate_buffer"; then
      flush_hidden_packet_lines
      emit_visible_text "$candidate_buffer"
      candidate_buffer=""
      ordinary_mode=1
    fi
  }

  while IFS= read -r -n 1 line || [ -n "$line" ]; do
    if [ "$startup_filter_active" -eq 1 ]; then
      startup_buffer+="$line"

      if startup_prefix_is_complete "$startup_buffer"; then
        startup_buffer=""
        continue
      fi

      if startup_prefix_still_possible "$startup_buffer"; then
        continue
      fi

      startup_filter_active=0

      while [ -n "$startup_buffer" ]; do
        process_render_char "${startup_buffer:0:1}"
        startup_buffer="${startup_buffer:1}"
      done
      continue
    fi

    process_render_char "$line"
  done

  while [ -n "$startup_buffer" ]; do
    startup_filter_active=0
    process_render_char "${startup_buffer:0:1}"
    startup_buffer="${startup_buffer:1}"
  done

  if [ -n "$candidate_buffer" ]; then
    local candidate_line="${candidate_buffer%$'\r'}"

    if [ "$ordinary_mode" -eq 0 ] && line_is_hidden_endgate "$candidate_line"; then
      packet_lines+=("$candidate_line")
    else
      flush_hidden_packet_lines
      emit_visible_text "$candidate_buffer"
    fi

    candidate_buffer=""
  else
    if [ "$ordinary_mode" -eq 1 ]; then
      ordinary_mode=0
    fi
  fi

  flush_hidden_packet_lines
  flush_visible_cr
}

list_child_pids() {
  local pid="$1"

  if ! command -v pgrep >/dev/null 2>&1; then
    return 0
  fi

  pgrep -P "$pid" 2>/dev/null || true
}

signal_process_tree() {
  local signal_name="$1"
  local pid="$2"
  local child_pid=""

  if [ -z "$pid" ]; then
    return 0
  fi

  while IFS= read -r child_pid; do
    if [ -n "$child_pid" ]; then
      signal_process_tree "$signal_name" "$child_pid"
    fi
  done < <(list_child_pids "$pid")

  kill -s "$signal_name" "$pid" >/dev/null 2>&1 || true
}

main() {
  local runtime_dir=""
  local transcript_pipe=""
  local keepalive_pid=""
  local reader_pid=""
  local launcher_pid=""
  local status=0
  local launcher_rc=0

  runtime_dir="$(mktemp -d "${TMPDIR:-/tmp}/codex-endgate-wrapper.XXXXXX")"
  transcript_pipe="$runtime_dir/terminal-render.pipe"

  close_render_pipeline() {
    local force_reader_kill="${1:-0}"

    if [ -n "$keepalive_pid" ]; then
      kill "$keepalive_pid" >/dev/null 2>&1 || true
      wait "$keepalive_pid" >/dev/null 2>&1 || true
      keepalive_pid=""
    fi

    if [ -n "$reader_pid" ]; then
      if [ "$force_reader_kill" = "1" ]; then
        kill "$reader_pid" >/dev/null 2>&1 || true
      fi
      wait "$reader_pid" >/dev/null 2>&1 || true
      reader_pid=""
    fi
  }

  cleanup() {
    close_render_pipeline

    rm -rf "$runtime_dir"
  }

  terminate_wrapper() {
    local signal_name="$1"
    local exit_code="$2"

    if [ -n "$launcher_pid" ]; then
      signal_process_tree "$signal_name" "$launcher_pid"
      sleep 0.2
      signal_process_tree KILL "$launcher_pid"
      wait "$launcher_pid" >/dev/null 2>&1 || true
      launcher_pid=""
    fi

    close_render_pipeline 1
    exit "$exit_code"
  }

  trap cleanup EXIT
  trap 'terminate_wrapper INT 130' INT
  trap 'terminate_wrapper TERM 143' TERM

  mkfifo "$transcript_pipe"

  tail -f /dev/null > "$transcript_pipe" &
  keepalive_pid="$!"

  process_stream terminal_render < "$transcript_pipe" &
  reader_pid="$!"

  exec 9<&0
  "$SCRIPT_BIN" -qF "$transcript_pipe" "$CODEX_BIN" "$@" <&9 >/dev/null 2>&1 &
  launcher_pid="$!"

  wait "$launcher_pid" || launcher_rc=$?
  status="$launcher_rc"
  launcher_pid=""
  exec 9<&-

  sleep 0.1
  close_render_pipeline 0

  exit "$status"
}

main "$@"
