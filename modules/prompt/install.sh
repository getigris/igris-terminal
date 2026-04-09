#!/usr/bin/env bash
# ig-term :: modules/prompt/install.sh

source "${IG_HOME}/core/log.sh"
source "${IG_HOME}/core/platform.sh"
source "${IG_HOME}/core/state.sh"
source "${IG_HOME}/core/logger.sh"

_install_prompt() {
  if ig_has starship; then
    ig_debug "Starship already installed"
    local ver
    ver="$(_ig_tool_version starship)"
    ig_state_tool_installed "starship" "$ver"
    return 0
  fi

  ig_info "Installing Starship..."
  case "$(ig_pkg)" in
    brew) brew install starship ;;
    *)    curl -sS https://starship.rs/install.sh | sh -s -- --yes ;;
  esac

  local ver
  ver="$(_ig_tool_version starship)"
  ig_state_tool_installed "starship" "$ver"
  ig_log_install "tool:starship" "v${ver}"
}

_install_prompt
