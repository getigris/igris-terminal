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

  # Render template to IG_HOME/config/git/, symlink stays internal
  local template="${IG_HOME}/modules/git/gitconfig.tmpl"
  ig_render_managed_config "git" "$template" "gitconfig" "${IG_HOME}/config/git/gitconfig"

  # Tell git to include our config
  local include_path="${IG_HOME}/config/git/gitconfig"
  if ! git config --global --get-all include.path 2>/dev/null | grep -qF "$include_path"; then
    git config --global --add include.path "$include_path"
    ig_debug "Added ig-term gitconfig to git includes"
  fi

  # LFS support (if installed)
  if ig_has git-lfs; then
    git lfs install --skip-repo &>/dev/null
  fi

  ig_success "Git configured (user identity untouched)"
}

_configure_git
