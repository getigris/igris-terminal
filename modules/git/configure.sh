#!/usr/bin/env bash
# ig-term :: modules/git/configure.sh
# Uses git include.path so user identity (name/email/signing key) is untouched

source "${IG_HOME}/core/log.sh"
source "${IG_HOME}/core/config.sh"
source "${IG_HOME}/core/symlink.sh"
source "${IG_HOME}/core/state.sh"
source "${IG_HOME}/core/logger.sh"

_configure_git() {
  # Export template variables
  export IG_GIT_DEFAULT_BRANCH="$(ig_config "git.default_branch" "main")"

  local pull_strategy
  pull_strategy="$(ig_config "git.pull_strategy" "rebase")"
  if [[ "$pull_strategy" == "rebase" ]]; then
    export IG_GIT_PULL_REBASE="true"
  else
    export IG_GIT_PULL_REBASE="false"
  fi

  # Render template directly to IG_HOME/config/git/
  # No symlink needed - git includes this file via include.path
  local template="${IG_HOME}/modules/git/gitconfig.tmpl"
  local config_dir="${IG_HOME}/config/git"
  local config_file="${config_dir}/gitconfig"
  mkdir -p "$config_dir"

  local rendered
  rendered="$(ig_render_template "$template")"
  printf '%s\n' "$rendered" > "$config_file"
  ig_debug "Wrote git config: $config_file"

  # Track in state (no symlink, just the file)
  ig_state_config_track "git" "$config_file" "git:include.path"
  ig_log_configure "config:git/gitconfig"

  # Tell git to include our config
  if ! git config --global --get-all include.path 2>/dev/null | grep -qF "$config_file"; then
    git config --global --add include.path "$config_file"
    ig_debug "Added ig-term gitconfig to git includes"
  fi

  # LFS support (if installed)
  if ig_has git-lfs; then
    git lfs install --skip-repo &>/dev/null
  fi

  ig_success "Git configured (user identity untouched)"
}

_configure_git
