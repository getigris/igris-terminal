#!/usr/bin/env bash
# ig-term :: core/log.sh - Logging utilities

# Colors (only when stdout is a terminal)
if [[ -t 1 ]]; then
  _IG_RED='\033[0;31m'
  _IG_GREEN='\033[0;32m'
  _IG_YELLOW='\033[0;33m'
  _IG_BLUE='\033[0;34m'
  _IG_MAGENTA='\033[0;35m'
  _IG_CYAN='\033[0;36m'
  _IG_DIM='\033[2m'
  _IG_BOLD='\033[1m'
  _IG_RESET='\033[0m'
else
  _IG_RED='' _IG_GREEN='' _IG_YELLOW='' _IG_BLUE=''
  _IG_MAGENTA='' _IG_CYAN='' _IG_DIM='' _IG_BOLD='' _IG_RESET=''
fi

IG_LOG_LEVEL="${IG_LOG_LEVEL:-info}"

_ig_should_log() {
  local level="$1"
  local -A levels=([debug]=0 [info]=1 [warn]=2 [error]=3)
  local current="${levels[$IG_LOG_LEVEL]:-1}"
  local target="${levels[$level]:-1}"
  (( target >= current ))
}

ig_log() {
  local level="$1"; shift
  _ig_should_log "$level" || return 0

  local prefix color
  case "$level" in
    debug)   prefix="DBG" ; color="$_IG_DIM"     ;;
    info)    prefix="---" ; color="$_IG_BLUE"     ;;
    warn)    prefix="!!!" ; color="$_IG_YELLOW"   ;;
    error)   prefix="ERR" ; color="$_IG_RED"      ;;
    success) prefix=" ok" ; color="$_IG_GREEN"    ;;
    *)       prefix="---" ; color="$_IG_RESET"    ;;
  esac

  printf "${color}${_IG_BOLD}[%s]${_IG_RESET}${color} %s${_IG_RESET}\n" "$prefix" "$*" >&2
}

ig_debug()   { ig_log debug "$@"; }
ig_info()    { ig_log info "$@"; }
ig_warn()    { ig_log warn "$@"; }
ig_error()   { ig_log error "$@"; }
ig_success() { ig_log success "$@"; }

ig_header() {
  printf "\n${_IG_MAGENTA}${_IG_BOLD}  %s${_IG_RESET}\n\n" "$*" >&2
}

ig_step() {
  local current="$1" total="$2"; shift 2
  printf "${_IG_CYAN}${_IG_BOLD}[%d/%d]${_IG_RESET} %s\n" "$current" "$total" "$*" >&2
}

ig_die() {
  ig_error "$@"
  exit 1
}

ig_confirm() {
  local prompt="${1:-Continue?}"
  printf "${_IG_YELLOW}${_IG_BOLD}[???]${_IG_RESET} %s [y/N] " "$prompt" >&2
  local reply
  read -r reply
  [[ "$reply" =~ ^[Yy]$ ]]
}
