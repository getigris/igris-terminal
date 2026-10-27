# ig-term :: exports/linux.sh - Linux-specific environment

# Homebrew on Linux (Linuxbrew)
if [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# pnpm
if [[ -d "$HOME/.local/share/pnpm" ]]; then
  export PNPM_HOME="$HOME/.local/share/pnpm"
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
