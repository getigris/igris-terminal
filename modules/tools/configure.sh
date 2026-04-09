#!/usr/bin/env bash
# ig-term :: modules/tools/configure.sh

source "${IG_HOME}/core/log.sh"
source "${IG_HOME}/core/config.sh"
source "${IG_HOME}/core/symlink.sh"
source "${IG_HOME}/core/state.sh"
source "${IG_HOME}/core/logger.sh"

_configure_tools() {
  # bat config
  if command -v bat &>/dev/null; then
    local template="${IG_HOME}/modules/tools/bat.conf.tmpl"
    ig_render_managed_config "tools" "$template" "bat.conf" "${HOME}/.config/bat/config"
  fi

  ig_success "Tools configured"
}

_configure_tools
