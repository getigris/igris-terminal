#!/usr/bin/env bash
# ig-term :: core/logger.sh - File-based operation logging

_IG_LOGGER_LOADED="${_IG_LOGGER_LOADED:-}"
[[ -n "$_IG_LOGGER_LOADED" ]] && return 0
_IG_LOGGER_LOADED=1

IG_LOG_DIR="${IG_CONFIG_DIR:-${HOME}/.config/ig-term}/logs"

# Ensure log directory exists
_ig_logger_init() {
  mkdir -p "$IG_LOG_DIR"
}

# Get current log file (one per day)
_ig_log_file() {
  _ig_logger_init
  echo "${IG_LOG_DIR}/ig-term-$(date +%Y-%m-%d).log"
}

# Write an entry to the log file
# Usage: ig_log_event <action> <target> [detail]
# Actions: install, configure, update, remove, enable, disable, error
ig_log_event() {
  local action="$1"
  local target="$2"
  local detail="${3:-}"
  local timestamp
  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  local log_file
  log_file="$(_ig_log_file)"

  local entry="${timestamp} [${action}] ${target}"
  [[ -n "$detail" ]] && entry="${entry} -- ${detail}"

  echo "$entry" >> "$log_file"
}

# Convenience wrappers
ig_log_install()   { ig_log_event "install"   "$@"; }
ig_log_configure() { ig_log_event "configure" "$@"; }
ig_log_update()    { ig_log_event "update"    "$@"; }
ig_log_remove()    { ig_log_event "remove"    "$@"; }
ig_log_enable()    { ig_log_event "enable"    "$@"; }
ig_log_disable()   { ig_log_event "disable"   "$@"; }
ig_log_err()       { ig_log_event "error"     "$@"; }

# Show recent log entries
# Usage: ig_log_show [count]
ig_log_show() {
  local count="${1:-50}"
  _ig_logger_init

  # Collect all log files, most recent first
  local -a log_files
  mapfile -t log_files < <(ls -t "${IG_LOG_DIR}"/ig-term-*.log 2>/dev/null)

  if [[ ${#log_files[@]} -eq 0 ]]; then
    ig_info "No logs found"
    return 0
  fi

  local lines_shown=0
  for log_file in "${log_files[@]}"; do
    local remaining=$(( count - lines_shown ))
    (( remaining <= 0 )) && break

    local -a entries
    mapfile -t entries < <(tail -n "$remaining" "$log_file" 2>/dev/null)

    for entry in "${entries[@]}"; do
      (( lines_shown >= count )) && break
      _ig_log_format_entry "$entry"
      (( lines_shown++ ))
    done
  done
}

# Format a log entry with colors
_ig_log_format_entry() {
  local entry="$1"

  # Parse: timestamp [action] target -- detail
  local timestamp action rest
  timestamp="${entry%% *}"
  rest="${entry#* }"

  if [[ "$rest" =~ ^\[([a-z]+)\][[:space:]](.+)$ ]]; then
    action="${BASH_REMATCH[1]}"
    rest="${BASH_REMATCH[2]}"
  else
    action="?"
    rest="$entry"
  fi

  # Color by action
  local color
  case "$action" in
    install)   color="${_IG_GREEN}"   ;;
    configure) color="${_IG_BLUE}"    ;;
    update)    color="${_IG_CYAN}"    ;;
    remove)    color="${_IG_YELLOW}"  ;;
    enable)    color="${_IG_GREEN}"   ;;
    disable)   color="${_IG_DIM}"     ;;
    error)     color="${_IG_RED}"     ;;
    *)         color="${_IG_RESET}"   ;;
  esac

  # Format timestamp to readable
  local display_date
  display_date="${timestamp%%T*}"
  local display_time
  display_time="${timestamp#*T}"
  display_time="${display_time%%Z*}"

  printf "  ${_IG_DIM}%s %s${_IG_RESET}  ${color}%-10s${_IG_RESET}  %s\n" \
    "$display_date" "$display_time" "[$action]" "$rest"
}

# Show logs filtered by action
ig_log_filter() {
  local action="$1"
  local count="${2:-50}"
  _ig_logger_init

  local -a log_files
  mapfile -t log_files < <(ls -t "${IG_LOG_DIR}"/ig-term-*.log 2>/dev/null)

  local lines_shown=0
  for log_file in "${log_files[@]}"; do
    while IFS= read -r entry; do
      (( lines_shown >= count )) && break
      _ig_log_format_entry "$entry"
      (( lines_shown++ ))
    done < <(grep "\[${action}\]" "$log_file" 2>/dev/null | tail -n "$count")
  done
}

# Rotate old logs (keep last 30 days)
ig_log_rotate() {
  _ig_logger_init
  local cutoff
  cutoff="$(date -v-30d +%Y-%m-%d 2>/dev/null || date -d '30 days ago' +%Y-%m-%d 2>/dev/null)"

  [[ -z "$cutoff" ]] && return 0

  for log_file in "${IG_LOG_DIR}"/ig-term-*.log; do
    [[ -f "$log_file" ]] || continue
    local file_date
    file_date="$(basename "$log_file" | sed 's/ig-term-\(.*\)\.log/\1/')"
    if [[ "$file_date" < "$cutoff" ]]; then
      rm -f "$log_file"
      ig_debug "Rotated old log: $log_file"
    fi
  done
}
