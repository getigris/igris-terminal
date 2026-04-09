#!/usr/bin/env bash
# ig-term :: modules/tools/install.sh

source "${IG_HOME}/core/log.sh"
source "${IG_HOME}/core/platform.sh"
source "${IG_HOME}/core/config.sh"
source "${IG_HOME}/core/state.sh"
source "${IG_HOME}/core/logger.sh"

_install_tool() {
  local name="$1"
  local brew_name="${2:-$name}"
  local apt_name="${3:-$name}"

  if ig_has "$name"; then
    ig_debug "$name already installed"
    # Still track it in state
    local ver
    ver="$(_ig_tool_version "$name")"
    ig_state_tool_installed "$name" "$ver"
    return 0
  fi

  ig_info "Installing $name..."
  ig_install "$name" --brew "$brew_name" --apt "$apt_name"

  local ver
  ver="$(_ig_tool_version "$name")"
  ig_state_tool_installed "$name" "$ver"
  ig_log_install "tool:${name}" "v${ver}"
}

_install_tools() {
  [[ "$(ig_config "tools.bat" "true")" == "true" ]]    && _install_tool bat
  [[ "$(ig_config "tools.lsd" "true")" == "true" ]]    && _install_tool lsd
  [[ "$(ig_config "tools.fzf" "true")" == "true" ]]    && _install_tool fzf
  [[ "$(ig_config "tools.zoxide" "true")" == "true" ]] && _install_tool zoxide
}

_install_tools
