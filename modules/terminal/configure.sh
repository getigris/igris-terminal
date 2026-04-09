#!/usr/bin/env bash
# ig-term :: modules/terminal/configure.sh

source "${IG_HOME}/core/log.sh"
source "${IG_HOME}/core/config.sh"
source "${IG_HOME}/core/symlink.sh"
source "${IG_HOME}/core/state.sh"
source "${IG_HOME}/core/logger.sh"

_configure_terminal() {
  # Export template variables from user config
  export IG_TERMINAL_FONT_FAMILY="$(ig_config "terminal.font_family" "Hack Nerd Font")"
  export IG_TERMINAL_FONT_SIZE="$(ig_config "terminal.font_size" "16")"
  export IG_TERMINAL_OPACITY="$(ig_config "terminal.opacity" "0.95")"

  # Render main template
  local template="${IG_HOME}/modules/terminal/ghostty/config.tmpl"
  local rendered
  rendered="$(ig_render_template "$template")"

  # Append platform-specific config
  local platform_conf="${IG_HOME}/modules/terminal/ghostty/platform/$(ig_os).conf"
  if [[ -f "$platform_conf" ]]; then
    rendered+=$'\n\n'"# Platform-specific ($(ig_os))"$'\n'
    rendered+="$(cat "$platform_conf")"
  fi

  # Write to IG_HOME/config/terminal/, symlink to system path
  ig_managed_config "terminal" "ghostty.conf" "${HOME}/.config/ghostty/config" "$rendered"

  ig_success "Ghostty configured"
}

_configure_terminal
