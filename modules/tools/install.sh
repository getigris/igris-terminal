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
  if ! ig_install "$name" --brew "$brew_name" --apt "$apt_name"; then
    ig_warn "Failed to install $name; not recording in state"
    return 1
  fi

  local ver
  ver="$(_ig_tool_version "$name")"
  ig_state_tool_installed "$name" "$ver"
  ig_log_install "tool:${name}" "v${ver}"
}

_install_tool_tap() {
  # name: short identifier used for state/log keys
  # tap_ref: fully-qualified brew formula (e.g. getigris/tap/foo)
  # bin_name: actual executable shipped by the formula (defaults to $name)
  local name="$1" tap_ref="$2" bin_name="${3:-$1}"

  if ig_has "$bin_name"; then
    ig_debug "$name already installed (bin: $bin_name)"
    local ver
    ver="$(_ig_tool_version "$bin_name")"
    ig_state_tool_installed "$name" "$ver"
    return 0
  fi

  if ! ig_has brew; then
    ig_warn "$name requires Homebrew; skipping on this platform"
    return 0
  fi

  ig_info "Installing $name from $tap_ref..."
  if ! brew install "$tap_ref"; then
    ig_warn "Failed to install $name from $tap_ref; not recording in state"
    return 1
  fi

  local ver
  ver="$(_ig_tool_version "$bin_name")"
  ig_state_tool_installed "$name" "$ver"
  ig_log_install "tool:${name}" "v${ver}"
}

# Persist a flag under [tools] in the user's ig.toml so future `ig apply`
# runs don't re-prompt. Mirrors the shape of bin/ig::_ig_config_set_module.
_set_tools_flag() {
  local key="$1" value="$2"
  local config_file="${IG_CONFIG_DIR}/ig.toml"

  [[ -f "$config_file" ]] || return 0

  if grep -q "^${key} = " "$config_file" 2>/dev/null; then
    sed -i'' -e "s/^${key} = .*/${key} = ${value}/" "$config_file"
  else
    sed -i'' -e "/^\[tools\]/a\\
${key} = ${value}
" "$config_file"
  fi
}

_maybe_install_igris_memory() {
  local current
  current="$(ig_config "tools.igris_memory" "")"

  case "$current" in
    true)
      _install_tool_tap igris-memory getigris/tap/igris-memory igmem
      ;;
    false)
      ig_debug "igris-memory disabled by user config"
      ;;
    *)
      # Skip silently when no TTY is attached (e.g. `curl ... | bash`).
      # Leaving the flag unset means the next interactive `ig sync` will prompt.
      if [[ ! -t 0 ]]; then
        ig_info "igris-memory is opt-in; run 'ig sync' interactively to decide"
        return 0
      fi
      if ig_confirm "Install igris-memory (cross-session memory MCP from getigris/tap)?"; then
        _set_tools_flag "igris_memory" "true"
        _install_tool_tap igris-memory getigris/tap/igris-memory igmem
      else
        _set_tools_flag "igris_memory" "false"
        ig_info "Skipping igris-memory; re-enable later by setting tools.igris_memory = true in ig.toml"
      fi
      ;;
  esac
}

_install_tools() {
  [[ "$(ig_config "tools.bat" "true")" == "true" ]]    && _install_tool bat
  [[ "$(ig_config "tools.lsd" "true")" == "true" ]]    && _install_tool lsd
  [[ "$(ig_config "tools.fzf" "true")" == "true" ]]    && _install_tool fzf
  [[ "$(ig_config "tools.zoxide" "true")" == "true" ]] && _install_tool zoxide
  [[ "$(ig_config "tools.mole" "true")" == "true" ]]   && _install_tool mole
  _maybe_install_igris_memory
}

_install_tools
