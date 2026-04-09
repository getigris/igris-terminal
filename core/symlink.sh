#!/usr/bin/env bash
# ig-term :: core/symlink.sh - Symlink management with backup/restore

_IG_SYMLINK_LOADED="${_IG_SYMLINK_LOADED:-}"
[[ -n "$_IG_SYMLINK_LOADED" ]] && return 0
_IG_SYMLINK_LOADED=1

# Create a symlink with automatic backup of existing files
# Usage: ig_link <source> <target>
#   source: file inside ig-term (e.g., $IG_HOME/modules/prompt/presets/default.toml)
#   target: destination path (e.g., ~/.config/starship.toml)
ig_link() {
  local source="$1"
  local target="$2"

  if [[ ! -e "$source" ]]; then
    ig_error "Source does not exist: $source"
    return 1
  fi

  # If target already exists and is NOT our symlink, back it up
  if [[ -e "$target" ]] || [[ -L "$target" ]]; then
    if [[ -L "$target" ]]; then
      local current_target
      current_target="$(readlink "$target")"
      if [[ "$current_target" == "$source" ]]; then
        ig_debug "Symlink already correct: $target -> $source"
        return 0
      fi
    fi
    ig_backup "$target"
    rm -f "$target"
  fi

  # Ensure parent directory exists
  mkdir -p "$(dirname "$target")"

  ln -s "$source" "$target"
  ig_debug "Linked: $target -> $source"
}

# Backup a file before overwriting
ig_backup() {
  local file="$1"
  [[ -e "$file" ]] || return 0

  local backup_dir="${IG_BACKUP_DIR:-${HOME}/.config/ig-term/backups}"
  mkdir -p "$backup_dir"

  local basename
  basename="$(basename "$file")"
  local timestamp
  timestamp="$(date +%Y%m%d-%H%M%S)"
  local backup_path="${backup_dir}/${basename}.${timestamp}.bak"

  cp -a "$file" "$backup_path"
  ig_info "Backed up: $file -> $backup_path"
}

# Restore the most recent backup of a file
ig_restore() {
  local target="$1"
  local backup_dir="${IG_BACKUP_DIR:-${HOME}/.config/ig-term/backups}"
  local basename
  basename="$(basename "$target")"

  # Find the most recent backup
  local latest
  latest="$(ls -t "${backup_dir}/${basename}".*.bak 2>/dev/null | head -1)"

  if [[ -z "$latest" ]]; then
    ig_warn "No backup found for: $basename"
    return 1
  fi

  # Remove current file/symlink
  rm -f "$target"

  # Restore
  cp -a "$latest" "$target"
  ig_success "Restored: $latest -> $target"
}

# Remove a symlink that points into ig-term (safe: won't remove non-ig-term files)
ig_unlink() {
  local target="$1"

  if [[ ! -L "$target" ]]; then
    ig_debug "Not a symlink, skipping: $target"
    return 0
  fi

  local link_target
  link_target="$(readlink "$target")"

  if [[ "$link_target" == *"ig-term"* ]]; then
    rm -f "$target"
    ig_debug "Removed symlink: $target"
    ig_restore "$target" 2>/dev/null || true
  else
    ig_warn "Symlink does not point to ig-term, skipping: $target -> $link_target"
  fi
}

# Render a .tmpl template file by substituting {{VAR}} with environment variables
# Usage: ig_render_template "path/to/file.tmpl"
# Supported syntax: {{VAR_NAME}} is replaced with the value of $VAR_NAME
ig_render_template() {
  local template="$1"

  if [[ ! -f "$template" ]]; then
    ig_error "Template not found: $template"
    return 1
  fi

  local content
  content="$(cat "$template")"

  # Find all {{VAR}} patterns and substitute with env var values
  while [[ "$content" =~ \{\{([A-Za-z_][A-Za-z0-9_]*)\}\} ]]; do
    local var_name="${BASH_REMATCH[1]}"
    local var_value="${!var_name:-}"
    content="${content//"{{${var_name}}}"/"${var_value}"}"
  done

  printf '%s\n' "$content"
}

# Render a template and write it as a managed config (real file in IG_HOME, symlinked to system)
# Usage: ig_render_managed_config <module> <template_path> <filename> <system_path>
ig_render_managed_config() {
  local module="$1"
  local template="$2"
  local filename="$3"
  local system_path="$4"

  local rendered
  rendered="$(ig_render_template "$template")" || return 1

  ig_managed_config "$module" "$filename" "$system_path" "$rendered"
}

# Copy a file (for configs that don't support symlinks well)
ig_copy() {
  local source="$1"
  local target="$2"

  if [[ ! -e "$source" ]]; then
    ig_error "Source does not exist: $source"
    return 1
  fi

  if [[ -e "$target" ]]; then
    ig_backup "$target"
  fi

  mkdir -p "$(dirname "$target")"
  cp -a "$source" "$target"
  ig_debug "Copied: $source -> $target"
}

# Write content to a file inside IG_HOME/config/ and symlink it to the system path
# Usage: ig_managed_config <module> <filename> <system_path> <content>
# Example: ig_managed_config "terminal" "ghostty.conf" "$HOME/.config/ghostty/config" "$content"
ig_managed_config() {
  local module="$1"
  local filename="$2"
  local system_path="$3"
  local content="$4"

  local config_dir="${IG_HOME}/config/${module}"
  mkdir -p "$config_dir"

  local source_path="${config_dir}/${filename}"

  # Write the real file inside IG_HOME
  printf '%s\n' "$content" > "$source_path"
  ig_debug "Wrote config: $source_path"

  # Symlink from system path to our file
  ig_link "$source_path" "$system_path"

  # Track in state
  ig_state_config_track "$module" "$source_path" "$system_path"
  ig_log_configure "config:${module}/${filename}" "${system_path}"
}

# Write content to a file directly (legacy, for non-symlinkable cases)
ig_write_config() {
  local target="$1"
  local content="$2"

  if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
    local first_line
    first_line="$(head -1 "$target" 2>/dev/null || true)"
    if [[ "$first_line" != *"ig-term"* ]]; then
      ig_backup "$target"
    fi
  fi

  mkdir -p "$(dirname "$target")"
  printf '%s\n' "$content" > "$target"
  ig_debug "Wrote config: $target"
}
