#!/usr/bin/env bash
# ig-term :: modules/prompt/configure.sh

source "${IG_HOME}/core/log.sh"
source "${IG_HOME}/core/config.sh"
source "${IG_HOME}/core/symlink.sh"
source "${IG_HOME}/core/state.sh"
source "${IG_HOME}/core/logger.sh"

_configure_prompt() {
  local preset
  preset="$(ig_config "prompt.preset" "default")"
  local preset_file="${IG_HOME}/modules/prompt/presets/${preset}.toml"

  if [[ ! -f "$preset_file" ]]; then
    ig_warn "Preset '${preset}' not found, using default"
    preset_file="${IG_HOME}/modules/prompt/presets/default.toml"
  fi

  # Preset file lives in IG_HOME/modules/prompt/presets/, symlink to system path
  ig_link "$preset_file" "${HOME}/.config/starship.toml"
  ig_state_config_track "prompt" "$preset_file" "${HOME}/.config/starship.toml"

  ig_success "Prompt configured (preset: ${preset})"
}

_configure_prompt
