#!/usr/bin/env bash
# ig-term :: modules/git/install.sh

source "${IG_HOME}/core/log.sh"
source "${IG_HOME}/core/platform.sh"
source "${IG_HOME}/core/state.sh"
source "${IG_HOME}/core/logger.sh"

_install_git() {
  if ig_has git; then
    ig_debug "Git already installed"
    local ver
    ver="$(_ig_tool_version git)"
    ig_state_tool_installed "git" "$ver"
    return 0
  fi

  ig_info "Installing Git..."
  ig_install git

  local ver
  ver="$(_ig_tool_version git)"
  ig_state_tool_installed "git" "$ver"
  ig_log_install "tool:git" "v${ver}"
}

_install_git
