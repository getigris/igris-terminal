# ig-term :: exports/common.sh - Cross-platform environment exports

# GPG
export GPG_TTY=$(tty)

# History
export HISTSIZE=10000
export SAVEHIST=10000

# Editor
export EDITOR="${EDITOR:-vim}"
command -v nvim &>/dev/null && export EDITOR="nvim"

# Language
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# Go
if [[ -d "$HOME/.go" ]]; then
  export GOPATH="$HOME/.go"
  export PATH="$GOPATH/bin:$PATH"
fi

# Node via nvm: put the default version on PATH without loading nvm.sh,
# so non-interactive shells and editors also find node/npm/npx
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [[ -d "$NVM_DIR/versions/node" ]]; then
  _ig_nvm_alias="default"
  for _ in 1 2 3 4 5; do
    [[ -f "$NVM_DIR/alias/$_ig_nvm_alias" ]] || break
    _ig_nvm_alias="$(<"$NVM_DIR/alias/$_ig_nvm_alias")"
  done
  case "${_ig_nvm_alias#v}" in
    default|node|stable) _ig_nvm_glob="v*(N/nOn)" ;;
    *) _ig_nvm_glob="v${_ig_nvm_alias#v}(|.*)(N/nOn)" ;;
  esac
  _ig_nvm_dirs=( "$NVM_DIR"/versions/node/${~_ig_nvm_glob} )
  if (( ${#_ig_nvm_dirs} )); then
    case ":$PATH:" in
      *":${_ig_nvm_dirs[1]}/bin:"*) ;;
      *) export PATH="${_ig_nvm_dirs[1]}/bin:$PATH" ;;
    esac
  fi
  unset _ig_nvm_alias _ig_nvm_glob _ig_nvm_dirs
fi

# Rust/Cargo
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Local binaries
export PATH="$HOME/.local/bin:$PATH"
