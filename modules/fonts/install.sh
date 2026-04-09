#!/usr/bin/env bash
# ig-term :: modules/fonts/install.sh

source "${IG_HOME}/core/log.sh"
source "${IG_HOME}/core/platform.sh"
source "${IG_HOME}/core/state.sh"
source "${IG_HOME}/core/logger.sh"

_install_fonts() {
  local family
  family="$(ig_config "fonts.family" "Hack")"

  local font_name="font-${family,,}-nerd-font"

  case "$(ig_os)" in
    macos)
      if ! brew list --cask "$font_name" &>/dev/null; then
        ig_info "Installing ${family} Nerd Font..."
        brew install --cask "$font_name"
        ig_state_tool_installed "nerd-font-${family,,}" "latest"
        ig_log_install "tool:nerd-font" "${family}"
      else
        ig_debug "${family} Nerd Font already installed"
        ig_state_tool_installed "nerd-font-${family,,}" "latest"
      fi
      ;;
    linux)
      if ! fc-list | grep -qi "${family}.*Nerd" 2>/dev/null; then
        ig_info "Installing ${family} Nerd Font..."
        ig_install "fonts-hack-ttf" --apt "fonts-hack-ttf"
        ig_state_tool_installed "nerd-font-${family,,}" "latest"
        ig_log_install "tool:nerd-font" "${family}"
      else
        ig_debug "${family} Nerd Font already installed"
        ig_state_tool_installed "nerd-font-${family,,}" "latest"
      fi
      ;;
  esac
}

_install_fonts
