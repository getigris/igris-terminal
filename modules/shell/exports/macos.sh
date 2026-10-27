# ig-term :: exports/macos.sh - macOS-specific environment

# Homebrew
if [[ -d "/opt/homebrew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -d "/usr/local/Homebrew" ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# pnpm
if [[ -d "$HOME/Library/pnpm" ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
  case ":$PATH:" in
    *":$PNPM_HOME/bin:"*) ;;
    *) export PATH="$PNPM_HOME/bin:$PATH" ;;
  esac
fi

# bun
if [[ -d "$HOME/.bun" ]]; then
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
fi

# pyenv
if command -v pyenv &>/dev/null; then
  eval "$(pyenv init --path)"
fi

# Docker
[[ -d "$HOME/.docker/bin" ]] && export PATH="$HOME/.docker/bin:$PATH"
