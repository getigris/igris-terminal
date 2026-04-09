#!/usr/bin/env bash
# ig-term :: core/config.sh - Configuration management with 3-layer merge

_IG_CONFIG_LOADED="${_IG_CONFIG_LOADED:-}"
[[ -n "$_IG_CONFIG_LOADED" ]] && return 0
_IG_CONFIG_LOADED=1

# Resolve IG_HOME and IG_CONFIG_DIR
IG_HOME="${IG_HOME:-${HOME}/.local/share/ig-term}"
IG_CONFIG_DIR="${IG_CONFIG_DIR:-${HOME}/.config/ig-term}"
IG_BACKUP_DIR="${IG_BACKUP_DIR:-${IG_CONFIG_DIR}/backups}"

# Source dependencies
source "${IG_HOME}/lib/toml-parser.sh"
source "${IG_HOME}/core/log.sh"

# Load configuration with 3-layer merge:
#   1. templates/ig.toml (defaults)
#   2. ~/.config/ig-term/ig.toml (user)
#   3. ~/.config/ig-term/local.toml (machine-local)
ig_config_load() {
  local defaults="${IG_HOME}/templates/ig.toml"
  local user_config="${IG_CONFIG_DIR}/ig.toml"
  local local_config="${IG_CONFIG_DIR}/local.toml"

  # Layer 1: defaults (required)
  if [[ ! -f "$defaults" ]]; then
    ig_die "Default config not found: $defaults"
  fi
  toml_parse "$defaults"
  ig_debug "Loaded defaults from $defaults"

  # Layer 2: user config (optional)
  if [[ -f "$user_config" ]]; then
    toml_merge "$user_config"
    ig_debug "Merged user config from $user_config"
  fi

  # Layer 3: local overrides (optional)
  if [[ -f "$local_config" ]]; then
    toml_merge "$local_config"
    ig_debug "Merged local config from $local_config"
  fi
}

# Initialize user config directory and files
ig_config_init() {
  mkdir -p "$IG_CONFIG_DIR"
  mkdir -p "$IG_BACKUP_DIR"

  # Copy default config if user config doesn't exist
  if [[ ! -f "${IG_CONFIG_DIR}/ig.toml" ]]; then
    cp "${IG_HOME}/templates/ig.toml" "${IG_CONFIG_DIR}/ig.toml"
    ig_info "Created config at ${IG_CONFIG_DIR}/ig.toml"
  else
    ig_debug "User config already exists"
  fi

  # Create local.toml template if it doesn't exist
  if [[ ! -f "${IG_CONFIG_DIR}/local.toml" ]]; then
    cp "${IG_HOME}/templates/local.toml" "${IG_CONFIG_DIR}/local.toml"
    ig_info "Created local overrides at ${IG_CONFIG_DIR}/local.toml"
  fi
}

# Get a config value with convenience wrapper
# Usage: ig_config "section.key" [default]
ig_config() {
  toml_get "$1" "${2:-}"
}

# Check if a module is enabled
ig_module_enabled() {
  local module="$1"
  local value
  value="$(ig_config "modules.${module}" "false")"
  [[ "$value" == "true" ]]
}

# Export theme colors as IG_COLOR_* environment variables
ig_export_theme_colors() {
  local theme_name
  theme_name="$(ig_config "theme.name" "tokyo-night")"

  local theme_file="${IG_HOME}/themes/${theme_name}/theme.toml"
  if [[ ! -f "$theme_file" ]]; then
    ig_warn "Theme '${theme_name}' not found, falling back to tokyo-night"
    theme_file="${IG_HOME}/themes/tokyo-night/theme.toml"
  fi

  [[ -f "$theme_file" ]] || ig_die "No theme file found"

  # Parse theme into a separate namespace
  local -A _TOML_THEME=()
  local -A _TOML_BACKUP=()

  # Backup current config data
  for key in "${!_TOML_DATA[@]}"; do
    _TOML_BACKUP["$key"]="${_TOML_DATA[$key]}"
  done

  # Parse theme
  toml_parse "$theme_file"

  # Export color vars
  export IG_COLOR_BG="$(toml_get "colors.background")"
  export IG_COLOR_FG="$(toml_get "colors.foreground")"
  export IG_COLOR_CURSOR="$(toml_get "colors.cursor")"
  export IG_COLOR_SELECTION_BG="$(toml_get "colors.selection_bg")"
  export IG_COLOR_SELECTION_FG="$(toml_get "colors.selection_fg")"

  export IG_COLOR_BLACK="$(toml_get "colors.normal.black")"
  export IG_COLOR_RED="$(toml_get "colors.normal.red")"
  export IG_COLOR_GREEN="$(toml_get "colors.normal.green")"
  export IG_COLOR_YELLOW="$(toml_get "colors.normal.yellow")"
  export IG_COLOR_BLUE="$(toml_get "colors.normal.blue")"
  export IG_COLOR_MAGENTA="$(toml_get "colors.normal.magenta")"
  export IG_COLOR_CYAN="$(toml_get "colors.normal.cyan")"
  export IG_COLOR_WHITE="$(toml_get "colors.normal.white")"

  export IG_COLOR_BRIGHT_BLACK="$(toml_get "colors.bright.black")"
  export IG_COLOR_BRIGHT_RED="$(toml_get "colors.bright.red")"
  export IG_COLOR_BRIGHT_GREEN="$(toml_get "colors.bright.green")"
  export IG_COLOR_BRIGHT_YELLOW="$(toml_get "colors.bright.yellow")"
  export IG_COLOR_BRIGHT_BLUE="$(toml_get "colors.bright.blue")"
  export IG_COLOR_BRIGHT_MAGENTA="$(toml_get "colors.bright.magenta")"
  export IG_COLOR_BRIGHT_CYAN="$(toml_get "colors.bright.cyan")"
  export IG_COLOR_BRIGHT_WHITE="$(toml_get "colors.bright.white")"

  export IG_COLOR_ACCENT_PRIMARY="$(toml_get "colors.accent.primary")"
  export IG_COLOR_ACCENT_SECONDARY="$(toml_get "colors.accent.secondary")"
  export IG_COLOR_ACCENT_INFO="$(toml_get "colors.accent.info")"
  export IG_COLOR_ACCENT_SUCCESS="$(toml_get "colors.accent.success")"
  export IG_COLOR_ACCENT_WARNING="$(toml_get "colors.accent.warning")"
  export IG_COLOR_ACCENT_ERROR="$(toml_get "colors.accent.error")"

  ig_debug "Exported theme colors for '${theme_name}'"

  # Restore config data
  _TOML_DATA=()
  for key in "${!_TOML_BACKUP[@]}"; do
    _TOML_DATA["$key"]="${_TOML_BACKUP[$key]}"
  done
}
