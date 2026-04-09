#!/usr/bin/env bash
# ig-term :: modules/terminal/install.sh

source "${IG_HOME}/core/log.sh"
source "${IG_HOME}/core/platform.sh"
source "${IG_HOME}/core/state.sh"
source "${IG_HOME}/core/logger.sh"

_install_terminal() {
  if ig_has ghostty; then
    ig_debug "Ghostty already installed"
    local ver
    ver="$(_ig_tool_version ghostty)"
    ig_state_tool_installed "ghostty" "$ver"
    return 0
  fi

  case "$(ig_os)" in
    macos)
      ig_info "Installing Ghostty..."
      ig_install_cask ghostty
      local ver
      ver="$(_ig_tool_version ghostty)"
      ig_state_tool_installed "ghostty" "$ver"
      ig_log_install "tool:ghostty" "v${ver}"
      ;;
    linux)
      ig_warn "Ghostty on Linux: please install from https://ghostty.org/download"
      ;;
  esac
}

_install_terminal
