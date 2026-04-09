#!/usr/bin/env bash
# ig-term :: core/state.sh - State management for installed tools and modules

_IG_STATE_LOADED="${_IG_STATE_LOADED:-}"
[[ -n "$_IG_STATE_LOADED" ]] && return 0
_IG_STATE_LOADED=1

IG_STATE_FILE="${IG_CONFIG_DIR:-${HOME}/.config/ig-term}/state.toml"

# Ensure state file exists
_ig_state_init() {
  local dir
  dir="$(dirname "$IG_STATE_FILE")"
  mkdir -p "$dir"
  if [[ ! -f "$IG_STATE_FILE" ]]; then
    cat > "$IG_STATE_FILE" <<'EOF'
# ig-term state file - managed automatically
# Do not edit manually

[meta]
version = "0.1.0"
initialized = ""
last_updated = ""
EOF
    ig_debug "Created state file: $IG_STATE_FILE"
  fi
}

# Get current ISO timestamp
_ig_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Read a value from state file
ig_state_get() {
  local key="$1"
  local default="${2:-}"
  _ig_state_init

  # Save current TOML data, parse state, read, restore
  local -A _state_backup=()
  for k in "${!_TOML_DATA[@]}"; do
    _state_backup["$k"]="${_TOML_DATA[$k]}"
  done

  toml_parse "$IG_STATE_FILE"
  local value
  value="$(toml_get "$key" "$default")"

  _TOML_DATA=()
  for k in "${!_state_backup[@]}"; do
    _TOML_DATA["$k"]="${_state_backup[$k]}"
  done

  echo "$value"
}

# Write/update a key-value pair in the state file
# Uses sed for atomic updates without full reparse
ig_state_set() {
  local section="$1"
  local key="$2"
  local value="$3"
  _ig_state_init

  local full_key="${section}.${key}"
  local escaped_value
  escaped_value="$(printf '%s' "$value" | sed 's/[&/\]/\\&/g')"

  # Check if section exists
  if ! grep -q "^\[${section}\]" "$IG_STATE_FILE" 2>/dev/null; then
    # Add section and key
    printf '\n[%s]\n%s = "%s"\n' "$section" "$key" "$value" >> "$IG_STATE_FILE"
  elif grep -q "^${key} = " "$IG_STATE_FILE" 2>/dev/null; then
    # Update existing key within the right section context
    # Simple approach: rewrite the file
    _ig_state_rewrite "$section" "$key" "$value"
  else
    # Add key after section header
    sed -i'' -e "/^\[${section}\]/a\\
${key} = \"${escaped_value}\"
" "$IG_STATE_FILE"
  fi

  # Update last_updated timestamp
  if [[ "$section" != "meta" ]]; then
    _ig_state_rewrite "meta" "last_updated" "$(_ig_now)"
  fi
}

# Rewrite a specific key in the state file
_ig_state_rewrite() {
  local target_section="$1"
  local target_key="$2"
  local new_value="$3"

  local temp_file="${IG_STATE_FILE}.tmp"
  local current_section=""
  local found=false

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Track section
    if [[ "$line" =~ ^\[([a-zA-Z0-9._-]+)\]$ ]]; then
      current_section="${BASH_REMATCH[1]}"
    fi

    # Replace matching key in matching section
    if [[ "$current_section" == "$target_section" ]] && [[ "$line" =~ ^${target_key}[[:space:]]*= ]]; then
      echo "${target_key} = \"${new_value}\""
      found=true
    else
      echo "$line"
    fi
  done < "$IG_STATE_FILE" > "$temp_file"

  # If key wasn't found, add it
  if [[ "$found" == "false" ]]; then
    if grep -q "^\[${target_section}\]" "$temp_file" 2>/dev/null; then
      sed -i'' -e "/^\[${target_section}\]/a\\
${target_key} = \"${new_value}\"
" "$temp_file"
    else
      printf '\n[%s]\n%s = "%s"\n' "$target_section" "$target_key" "$new_value" >> "$temp_file"
    fi
  fi

  mv "$temp_file" "$IG_STATE_FILE"
}

# Remove a section from state file
ig_state_remove_section() {
  local section="$1"
  _ig_state_init

  local temp_file="${IG_STATE_FILE}.tmp"
  local current_section=""
  local skip=false

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^\[([a-zA-Z0-9._-]+)\]$ ]]; then
      current_section="${BASH_REMATCH[1]}"
      if [[ "$current_section" == "$section" ]]; then
        skip=true
        continue
      else
        skip=false
      fi
    fi

    if [[ "$skip" == "false" ]]; then
      echo "$line"
    fi
  done < "$IG_STATE_FILE" > "$temp_file"

  mv "$temp_file" "$IG_STATE_FILE"
}

# ── High-level state operations ──────────────────────────

# Record a module as installed
ig_state_module_installed() {
  local module="$1"
  local now
  now="$(_ig_now)"

  ig_state_set "modules.${module}" "status" "installed"
  ig_state_set "modules.${module}" "installed_at" "$now"
  ig_state_set "modules.${module}" "updated_at" "$now"
}

# Record a module as configured
ig_state_module_configured() {
  local module="$1"
  ig_state_set "modules.${module}" "configured" "true"
  ig_state_set "modules.${module}" "updated_at" "$(_ig_now)"
}

# Record a module as removed
ig_state_module_removed() {
  local module="$1"
  ig_state_remove_section "modules.${module}"
}

# Record a tool as installed
ig_state_tool_installed() {
  local tool="$1"
  local version="${2:-unknown}"
  local now
  now="$(_ig_now)"

  ig_state_set "tools.${tool}" "version" "$version"
  ig_state_set "tools.${tool}" "installed_at" "$now"
  ig_state_set "tools.${tool}" "updated_at" "$now"
}

# Record a tool as removed
ig_state_tool_removed() {
  local tool="$1"
  ig_state_remove_section "tools.${tool}"
}

# Get tool version from system
_ig_tool_version() {
  local tool="$1"
  local ver=""
  case "$tool" in
    zsh)      ver="$(zsh --version 2>/dev/null | awk '{print $2}')" ;;
    starship) ver="$(starship --version 2>/dev/null | awk '{print $2}')" ;;
    ghostty)  ver="$(ghostty --version 2>/dev/null | awk '{print $2}')" ;;
    bat)      ver="$(bat --version 2>/dev/null | awk '{print $2}')" ;;
    lsd)      ver="$(lsd --version 2>/dev/null | awk '{print $2}')" ;;
    fzf)      ver="$(fzf --version 2>/dev/null | awk '{print $1}')" ;;
    zoxide)   ver="$(zoxide --version 2>/dev/null | awk '{print $2}')" ;;
    git)      ver="$(git --version 2>/dev/null | awk '{print $3}')" ;;
    *)        ver="$(command -v "$tool" &>/dev/null && echo "installed" || echo "")" ;;
  esac
  echo "${ver:-unknown}"
}

# Check if a module is tracked as installed in state
ig_state_module_is_installed() {
  local status
  status="$(ig_state_get "modules.${1}.status")"
  [[ "$status" == "installed" ]]
}

# Record initialization
ig_state_mark_initialized() {
  ig_state_set "meta" "initialized" "$(_ig_now)"
  ig_state_set "meta" "version" "$IG_VERSION"
}

# ── Config file tracking ──────────────────────────────────

# Record a managed config file (source in IG_HOME, symlink at system path)
# Usage: ig_state_config_track <module> <source> <symlink>
ig_state_config_track() {
  local module="$1"
  local source="$2"
  local symlink="$3"

  # Use a counter-based key to support multiple configs per module
  local idx=0
  while ig_state_get "configs.${module}.${idx}.source" &>/dev/null && \
        [[ -n "$(ig_state_get "configs.${module}.${idx}.source")" ]]; do
    # If this source is already tracked, update it
    local existing
    existing="$(ig_state_get "configs.${module}.${idx}.source")"
    if [[ "$existing" == "$source" ]]; then
      ig_state_set "configs.${module}.${idx}" "symlink" "$symlink"
      return 0
    fi
    (( idx++ ))
  done

  ig_state_set "configs.${module}.${idx}" "source" "$source"
  ig_state_set "configs.${module}.${idx}" "symlink" "$symlink"
}

# Get all tracked configs for a module
# Outputs: source|symlink per line
ig_state_configs_for_module() {
  local module="$1"
  local idx=0
  while true; do
    local src
    src="$(ig_state_get "configs.${module}.${idx}.source")"
    [[ -z "$src" ]] && break
    local sym
    sym="$(ig_state_get "configs.${module}.${idx}.symlink")"
    echo "${src}|${sym}"
    (( idx++ ))
  done
}

# Remove all tracked configs for a module
ig_state_configs_remove() {
  local module="$1"
  ig_state_remove_section "configs.${module}"
}

# Print state summary
ig_state_summary() {
  _ig_state_init

  local -A _state_backup=()
  for k in "${!_TOML_DATA[@]}"; do
    _state_backup["$k"]="${_TOML_DATA[$k]}"
  done

  toml_parse "$IG_STATE_FILE"

  echo "  Modules:"
  for key in $(toml_keys "modules" | grep '\.status$'); do
    local mod="${key#modules.}"
    mod="${mod%.status}"
    local status
    status="$(toml_get "modules.${mod}.status")"
    local date
    date="$(toml_get "modules.${mod}.installed_at" "?")"
    printf "    %-14s %s  (%s)\n" "$mod" "$status" "$date"
  done

  echo ""
  echo "  Tools:"
  for key in $(toml_keys "tools" | grep '\.version$'); do
    local tool="${key#tools.}"
    tool="${tool%.version}"
    local ver
    ver="$(toml_get "tools.${tool}.version")"
    local date
    date="$(toml_get "tools.${tool}.installed_at" "?")"
    printf "    %-14s v%s  (%s)\n" "$tool" "$ver" "$date"
  done

  echo ""
  echo "  Managed configs:"
  local found_configs=false
  for key in $(toml_keys "configs" | grep '\.source$'); do
    found_configs=true
    local prefix="${key%.source}"
    local src
    src="$(toml_get "${key}")"
    local sym
    sym="$(toml_get "${prefix}.symlink")"
    # Show relative paths for readability
    local short_src="${src/#$IG_HOME\//\$IG_HOME/}"
    local short_sym="${sym/#$HOME/~}"
    printf "    ${_IG_CYAN}%s${_IG_RESET} -> %s\n" "$short_sym" "$short_src"
  done
  if [[ "$found_configs" == "false" ]]; then
    printf "    ${_IG_DIM}(none tracked)${_IG_RESET}\n"
  fi

  _TOML_DATA=()
  for k in "${!_state_backup[@]}"; do
    _TOML_DATA["$k"]="${_state_backup[$k]}"
  done
}
