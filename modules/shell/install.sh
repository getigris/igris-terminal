#!/usr/bin/env bash
# ig-term :: modules/shell/install.sh

source "${IG_HOME}/core/log.sh"
source "${IG_HOME}/core/platform.sh"
source "${IG_HOME}/core/state.sh"
source "${IG_HOME}/core/logger.sh"

_install_shell() {
  # Install ZSH if not present
  if ! ig_has zsh; then
    ig_info "Installing ZSH..."
    ig_install zsh
    ig_log_install "tool:zsh"
  fi

  local ver
  ver="$(_ig_tool_version zsh)"
  ig_state_tool_installed "zsh" "$ver"

  # Install Zim framework
  local zim_home="${IG_CONFIG_DIR}/zim"
  if [[ ! -d "$zim_home" ]]; then
    ig_info "Installing Zim framework..."
    curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | ZIM_HOME="$zim_home" zsh
    ig_log_install "tool:zim" "framework"
  else
    ig_debug "Zim already installed"
  fi

  # Set ZSH as default shell if not already
  local current_shell
  current_shell="$(ig_current_shell)"
  if [[ "$current_shell" != "zsh" ]]; then
    local zsh_path
    zsh_path="$(which zsh)"
    ig_info "Setting ZSH as default shell..."
    if ! grep -q "$zsh_path" /etc/shells; then
      echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi
    chsh -s "$zsh_path"
    ig_log_event "config" "default-shell" "changed to zsh"
  fi
}

_install_shell
