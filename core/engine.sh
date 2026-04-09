#!/usr/bin/env bash
# ig-term :: core/engine.sh - Module discovery, dependency resolution, lifecycle

_IG_ENGINE_LOADED="${_IG_ENGINE_LOADED:-}"
[[ -n "$_IG_ENGINE_LOADED" ]] && return 0
_IG_ENGINE_LOADED=1

# Discover all available modules
# Returns module names (directory names under modules/)
ig_modules_available() {
  local modules_dir="${IG_HOME}/modules"
  local custom_dir="${IG_CONFIG_DIR}/modules"

  # Built-in modules
  if [[ -d "$modules_dir" ]]; then
    for dir in "$modules_dir"/*/; do
      [[ -f "${dir}module.toml" ]] && basename "$dir"
    done
  fi

  # Custom user modules
  if [[ -d "$custom_dir" ]]; then
    for dir in "$custom_dir"/*/; do
      [[ -f "${dir}module.toml" ]] && basename "$dir"
    done
  fi
}

# Get the path to a module directory
ig_module_path() {
  local name="$1"
  local builtin="${IG_HOME}/modules/${name}"
  local custom="${IG_CONFIG_DIR}/modules/${name}"

  if [[ -d "$custom" ]] && [[ -f "${custom}/module.toml" ]]; then
    echo "$custom"
  elif [[ -d "$builtin" ]] && [[ -f "${builtin}/module.toml" ]]; then
    echo "$builtin"
  else
    return 1
  fi
}

# Read a module's metadata
# Sets: _MOD_NAME, _MOD_DESC, _MOD_VERSION, _MOD_DEFAULT, _MOD_REQUIRES, _MOD_PLATFORMS
ig_module_meta() {
  local name="$1"
  local mod_path
  mod_path="$(ig_module_path "$name")" || {
    ig_error "Module not found: $name"
    return 1
  }

  # Save and restore global TOML state
  local -A _saved=()
  for key in "${!_TOML_DATA[@]}"; do
    _saved["$key"]="${_TOML_DATA[$key]}"
  done

  toml_parse "${mod_path}/module.toml"

  _MOD_NAME="$(toml_get "module.name" "$name")"
  _MOD_DESC="$(toml_get "module.description" "")"
  _MOD_VERSION="$(toml_get "module.version" "0.0.0")"
  _MOD_DEFAULT="$(toml_get "module.default" "false")"
  _MOD_REQUIRES="$(toml_get "dependencies.requires" "")"
  _MOD_PLATFORMS="$(toml_get "platforms.supported" "macos:linux")"

  # Restore global TOML state
  _TOML_DATA=()
  for key in "${!_saved[@]}"; do
    _TOML_DATA["$key"]="${_saved[$key]}"
  done
}

# Check if a module supports the current platform
ig_module_supports_platform() {
  local name="$1"
  ig_module_meta "$name" || return 1

  local current_os
  current_os="$(ig_os)"
  [[ "$_MOD_PLATFORMS" == *"$current_os"* ]]
}

# Resolve module dependencies and return install order
# Simple topological sort (no cycles expected in our module set)
ig_modules_resolve_order() {
  local -a enabled=()
  local -a ordered=()
  local -A visited=()

  # Collect enabled modules
  for mod in $(ig_modules_available); do
    if ig_module_enabled "$mod"; then
      enabled+=("$mod")
    fi
  done

  # Recursive dependency walker
  _resolve() {
    local mod="$1"
    [[ -n "${visited[$mod]+x}" ]] && return 0
    visited["$mod"]=1

    ig_module_meta "$mod" 2>/dev/null || return 0

    # Resolve dependencies first
    if [[ -n "$_MOD_REQUIRES" ]]; then
      local IFS=':'
      for dep in $_MOD_REQUIRES; do
        _resolve "$dep"
      done
    fi

    ordered+=("$mod")
  }

  for mod in "${enabled[@]}"; do
    _resolve "$mod"
  done

  printf '%s\n' "${ordered[@]}"
}

# Run a module's install script
ig_module_install() {
  local name="$1"
  local mod_path
  mod_path="$(ig_module_path "$name")" || return 1

  local install_script="${mod_path}/install.sh"
  if [[ ! -f "$install_script" ]]; then
    ig_debug "No install script for module: $name"
    return 0
  fi

  if ! ig_module_supports_platform "$name"; then
    ig_warn "Module '$name' does not support $(ig_os), skipping install"
    return 0
  fi

  ig_info "Installing module: $name"
  (
    set +e
    export IG_MODULE_NAME="$name"
    export IG_MODULE_PATH="$mod_path"
    source "$install_script"
  ) || {
    ig_warn "Install script had errors for: $name"
  }

  ig_state_module_installed "$name"
  ig_log_install "module:${name}"
}

# Run a module's configure script
ig_module_configure() {
  local name="$1"
  local mod_path
  mod_path="$(ig_module_path "$name")" || return 1

  local configure_script="${mod_path}/configure.sh"
  if [[ ! -f "$configure_script" ]]; then
    ig_debug "No configure script for module: $name"
    return 0
  fi

  ig_info "Configuring module: $name"
  (
    set +e
    export IG_MODULE_NAME="$name"
    export IG_MODULE_PATH="$mod_path"
    source "$configure_script"
  ) || {
    ig_warn "Configure script had errors for: $name"
  }

  ig_state_module_configured "$name"
  ig_log_configure "module:${name}"
}

# Run hooks from a directory
ig_run_hooks() {
  local hook_dir="$1"

  # Check built-in hooks
  local builtin_dir="${IG_HOME}/hooks/${hook_dir}"
  local user_dir="${IG_CONFIG_DIR}/hooks/${hook_dir}"

  for dir in "$builtin_dir" "$user_dir"; do
    [[ -d "$dir" ]] || continue
    for script in "$dir"/*.sh; do
      [[ -f "$script" ]] || continue
      ig_debug "Running hook: $script"
      if ! source "$script"; then
        ig_error "Hook failed: $script"
        return 1
      fi
    done
  done
}

# Full install: run install + configure for all enabled modules in order
ig_install_all() {
  ig_header "ig-term install"

  ig_run_hooks "pre-install.d" || return 1

  local -a modules
  mapfile -t modules < <(ig_modules_resolve_order)
  local total=${#modules[@]}

  if (( total == 0 )); then
    ig_warn "No modules enabled"
    return 0
  fi

  local i=0
  for mod in "${modules[@]}"; do
    i=$(( i + 1 ))
    ig_step "$i" "$total" "Module: $mod"
    ig_module_install "$mod" || ig_warn "Install failed for: $mod"
    ig_module_configure "$mod" || ig_warn "Configure failed for: $mod"
  done

  ig_run_hooks "post-install.d" || true
  ig_success "All modules installed and configured"
}

# Apply only: re-run configure for all enabled modules (no package installs)
ig_apply_all() {
  ig_header "ig-term apply"

  ig_export_theme_colors

  local -a modules
  mapfile -t modules < <(ig_modules_resolve_order)
  local total=${#modules[@]}

  local i=0
  for mod in "${modules[@]}"; do
    i=$(( i + 1 ))
    ig_step "$i" "$total" "Configuring: $mod"
    ig_module_configure "$mod" || ig_warn "Configure failed for: $mod"
  done

  ig_success "Configuration applied"
}
