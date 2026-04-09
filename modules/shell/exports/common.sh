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

# Rust/Cargo
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Local binaries
export PATH="$HOME/.local/bin:$PATH"
