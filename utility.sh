#!/usr/bin/env bash
set -u

want_pid="${1:-}"

header_printed=0

print_header() {
  printf "%-7s %-10s %-4s %-7s %-12s %-10s %-10s %s\n" \
    "PID" "USER" "FD" "TYPE" "DEVICE" "SIZE" "NODE" "NAME"
}

uid_to_user() {
  local uid="$1"
  local u
  u="$(getent passwd "$uid" 2>/dev/null | cut -d: -f1)"
  if [[ -n "${u:-}" ]]; then
    printf "%s" "$u"
  else
    printf "%s" "$uid"
  fi
}

mode_to_type() {
  local mode="$1"
  case "$mode" in
    01*) echo "FIFO" ;;
    02*) echo "CHR"  ;;
    04*) echo "DIR"  ;;
    06*) echo "BLK"  ;;
    08*) echo "REG"  ;;
    0a*) echo "LNK"  ;;
    0c*) echo "SOCK" ;;
    *)   echo "unknown" ;;
  esac
}

get_user_for_pid() {
  local pid="$1"
  local uid
  uid="$(awk '/^Uid:/{print $2; exit}' "/proc/$pid/status" 2>/dev/null || true)"
  if [[ -z "${uid:-}" ]]; then
    echo "?"
    return
  fi
  uid_to_user "$uid"
}

emit_fd_line() {
  local pid="$1" user="$2" fd="$3" target="$4" fdpath="$5"

  local st_out
  st_out="$(stat -Lc "%f %D %s %i" "$fdpath" 2>/dev/null || true)"

  local mode_hex dev_hex size inode
  if [[ -n "$st_out" ]]; then
    mode_hex="$(awk '{print $1}' <<<"$st_out")"
    dev_hex="$(awk '{print $2}' <<<"$st_out")"
    size="$(awk '{print $3}' <<<"$st_out")"
    inode="$(awk '{print $4}' <<<"$st_out")"
  else
    mode_hex=""
    dev_hex=""
    size=""
    inode=""
  fi

  local type device
  if [[ -n "$mode_hex" ]]; then
    type="$(mode_to_type "$mode_hex")"
  else
    type="unknown"
  fi

  if [[ -n "$dev_hex" ]]; then
    local dev_dec
    dev_dec=$(( 16#$dev_hex ))
    local major minor
    major=$(( (dev_dec >> 8) & 0xfff ))
    minor=$(( (dev_dec & 0xff) | ((dev_dec >> 12) & 0xfff00) ))
    device="${major},${minor}"
  else
    device="?"
  fi

  printf "%-7s %-10s %-4s %-7s %-12s %-10s %-10s %s\n" \
    "$pid" "$user" "$fd" "$type" "$device" "${size:-?}" "${inode:-?}" "$target"
}

process_pid() {
  local pid="$1"

  [[ -r "/proc/$pid/status" ]] || return 0
  [[ -d "/proc/$pid/fd" ]] || return 0

  local user
  user="$(get_user_for_pid "$pid")"

  local fdpath fd target
  shopt -s nullglob
  for fdpath in /proc/"$pid"/fd/*; do
    fd="${fdpath##*/}"
    target="$(readlink -e "$fdpath" 2>/dev/null || readlink "$fdpath" 2>/dev/null || true)"
    [[ -n "$target" ]] || continue

    if [[ $header_printed -eq 0 ]]; then
      print_header
      header_printed=1
    fi

    emit_fd_line "$pid" "$user" "$fd" "$target" "$fdpath"
  done
  shopt -u nullglob
}

main() {
  if [[ -n "$want_pid" ]]; then
    if [[ ! "$want_pid" =~ ^[0-9]+$ ]]; then
      echo "Usage: $0 [PID]" >&2
      exit 2
    fi
    process_pid "$want_pid"
  else
    local p
    for p in /proc/[0-9]*; do
      process_pid "${p##*/}"
    done
  fi
}

main