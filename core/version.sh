#!/usr/bin/env bash
# ig-term :: core/version.sh - Version tracking and update checks

_IG_VERSION_LOADED="${_IG_VERSION_LOADED:-}"
[[ -n "$_IG_VERSION_LOADED" ]] && return 0
_IG_VERSION_LOADED=1

IG_VERSION="0.3.0"

ig_version() {
  echo "$IG_VERSION"
}

ig_version_full() {
  local git_hash=""
  if [[ -d "${IG_HOME}/.git" ]]; then
    git_hash="$(git -C "$IG_HOME" rev-parse --short HEAD 2>/dev/null || echo "unknown")"
  fi
  echo "ig-term ${IG_VERSION} (${git_hash})"
}

# Check if an update is available
ig_update_check() {
  if [[ ! -d "${IG_HOME}/.git" ]]; then
    ig_warn "Not a git installation, cannot check for updates"
    return 1
  fi

  ig_info "Checking for updates..."
  git -C "$IG_HOME" fetch origin main --quiet 2>/dev/null || {
    ig_warn "Could not reach remote, skipping update check"
    return 1
  }

  local local_head remote_head
  local_head="$(git -C "$IG_HOME" rev-parse HEAD)"
  remote_head="$(git -C "$IG_HOME" rev-parse origin/main)"

  if [[ "$local_head" == "$remote_head" ]]; then
    ig_success "ig-term is up to date ($(ig_version))"
    return 0
  else
    local behind
    behind="$(git -C "$IG_HOME" rev-list HEAD..origin/main --count)"
    ig_info "Update available: ${behind} commit(s) behind"
    return 2
  fi
}

# Pull latest and re-apply
ig_update() {
  if [[ ! -d "${IG_HOME}/.git" ]]; then
    ig_die "Not a git installation, cannot update"
  fi

  ig_header "ig-term update"

  ig_run_hooks "pre-update.d" || return 1

  ig_info "Pulling latest changes..."
  git -C "$IG_HOME" pull --rebase origin main || {
    ig_error "Failed to pull updates"
    return 1
  }

  # Re-load config (new defaults may have been added)
  ig_config_load

  # Re-apply all module configurations
  ig_apply_all

  ig_run_hooks "post-update.d" || true
  ig_success "Updated to $(ig_version_full)"
}
