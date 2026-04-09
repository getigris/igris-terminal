#!/usr/bin/env bash
# ig-term :: core/platform.sh - Platform detection and abstraction

_IG_PLATFORM_LOADED="${_IG_PLATFORM_LOADED:-}"
[[ -n "$_IG_PLATFORM_LOADED" ]] && return 0
_IG_PLATFORM_LOADED=1

# Detect operating system
ig_os() {
  case "$OSTYPE" in
    darwin*)  echo "macos"  ;;
    linux*)   echo "linux"  ;;
    *)        echo "unknown" ;;
  esac
}

# Detect CPU architecture
ig_arch() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64)  echo "x86_64"  ;;
    arm64|aarch64) echo "arm64" ;;
    *)       echo "$arch"   ;;
  esac
}

# Detect available package manager
ig_pkg() {
  if command -v brew &>/dev/null; then
    echo "brew"
  elif command -v apt-get &>/dev/null; then
    echo "apt"
  elif command -v dnf &>/dev/null; then
    echo "dnf"
  elif command -v pacman &>/dev/null; then
    echo "pacman"
  else
    echo "unknown"
  fi
}

# Check if a command exists
ig_has() {
  command -v "$1" &>/dev/null
}

# Install a package using the detected package manager
# Usage: ig_install <package> [--brew <name>] [--apt <name>] [--dnf <name>] [--pacman <name>]
ig_install() {
  local pkg="$1"; shift
  local brew_name="$pkg" apt_name="$pkg" dnf_name="$pkg" pacman_name="$pkg"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --brew)   brew_name="$2";   shift 2 ;;
      --apt)    apt_name="$2";    shift 2 ;;
      --dnf)    dnf_name="$2";    shift 2 ;;
      --pacman) pacman_name="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  local manager
  manager="$(ig_pkg)"

  case "$manager" in
    brew)   brew install "$brew_name"   ;;
    apt)    sudo apt-get install -y "$apt_name"    ;;
    dnf)    sudo dnf install -y "$dnf_name"        ;;
    pacman) sudo pacman -S --noconfirm "$pacman_name" ;;
    *)
      ig_error "No supported package manager found"
      return 1
      ;;
  esac
}

# Install a cask (macOS only, falls back to regular install on Linux)
ig_install_cask() {
  local pkg="$1"
  if [[ "$(ig_os)" == "macos" ]] && ig_has brew; then
    brew install --cask "$pkg"
  else
    ig_warn "Cask install not available on $(ig_os), skipping $pkg"
  fi
}

# Ensure Homebrew is installed (macOS)
ig_ensure_brew() {
  if ig_has brew; then
    ig_debug "Homebrew already installed"
    return 0
  fi

  if [[ "$(ig_os)" != "macos" ]]; then
    ig_debug "Not macOS, skipping Homebrew"
    return 0
  fi

  ig_info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add to PATH for current session
  if [[ "$(ig_arch)" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

# Get the user's default shell
ig_current_shell() {
  basename "$SHELL"
}

# Check if running inside a supported terminal
ig_terminal() {
  if [[ -n "${GHOSTTY_RESOURCES_DIR:-}" ]]; then
    echo "ghostty"
  elif [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
    echo "iterm2"
  elif [[ -n "${KITTY_PID:-}" ]]; then
    echo "kitty"
  elif [[ "$TERM_PROGRAM" == "WarpTerminal" ]]; then
    echo "warp"
  elif [[ "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
    echo "apple-terminal"
  else
    echo "unknown"
  fi
}
