# ig-term :: .zshenv - Environment setup (loaded first for every zsh session)

# ig-term paths
export IG_HOME="${IG_HOME:-${HOME}/.local/share/ig-term}"
export IG_CONFIG_DIR="${IG_CONFIG_DIR:-${HOME}/.config/ig-term}"

# ig-term CLI
export PATH="${IG_HOME}/bin:${PATH}"
export MANPATH="${IG_HOME}/man:${MANPATH}"

# Zim home
export ZIM_HOME="${IG_CONFIG_DIR}/zim"

# Platform-specific exports
case "$OSTYPE" in
  darwin*) [[ -f "${IG_HOME}/modules/shell/exports/macos.sh" ]] && source "${IG_HOME}/modules/shell/exports/macos.sh" ;;
  linux*)  [[ -f "${IG_HOME}/modules/shell/exports/linux.sh" ]] && source "${IG_HOME}/modules/shell/exports/linux.sh" ;;
esac

# Common exports
[[ -f "${IG_HOME}/modules/shell/exports/common.sh" ]] && source "${IG_HOME}/modules/shell/exports/common.sh"
