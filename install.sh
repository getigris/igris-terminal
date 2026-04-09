#!/usr/bin/env bash
# ig-term :: install.sh - One-line installer
# Usage: curl -fsSL https://raw.githubusercontent.com/getigris/igris-terminal/main/install.sh | bash
set -euo pipefail

# ── Config ────────────────────────────────────────────────
IG_REPO="https://github.com/getigris/igris-terminal.git"
IG_HOME="${IG_HOME:-${HOME}/.local/share/ig-term}"
IG_BRANCH="${IG_BRANCH:-main}"

# ── Colors ────────────────────────────────────────────────
if [[ -t 1 ]]; then
  RED='\033[0;31m'  GREEN='\033[0;32m'  YELLOW='\033[0;33m'
  BLUE='\033[0;34m' BOLD='\033[1m'      RESET='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' BOLD='' RESET=''
fi

info()    { printf "${BLUE}${BOLD}[---]${RESET}${BLUE} %s${RESET}\n" "$*"; }
success() { printf "${GREEN}${BOLD}[ ok]${RESET}${GREEN} %s${RESET}\n" "$*"; }
warn()    { printf "${YELLOW}${BOLD}[!!!]${RESET}${YELLOW} %s${RESET}\n" "$*"; }
error()   { printf "${RED}${BOLD}[ERR]${RESET}${RED} %s${RESET}\n" "$*"; exit 1; }

# ── Checks ────────────────────────────────────────────────
command -v git &>/dev/null || error "git is required. Install it first."
command -v curl &>/dev/null || error "curl is required. Install it first."

# ── Detect OS ─────────────────────────────────────────────
OS="unknown"
case "$OSTYPE" in
  darwin*) OS="macos" ;;
  linux*)  OS="linux" ;;
esac

ARCH="$(uname -m)"

printf "\n${BOLD}  ig-term installer${RESET}\n\n"
info "OS: ${OS} (${ARCH})"

# ── Install Homebrew (macOS) ──────────────────────────────
if [[ "$OS" == "macos" ]] && ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ "$ARCH" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  success "Homebrew installed"
fi

# ── Clone or update ig-term ──────────────────────────────
if [[ -d "$IG_HOME" ]]; then
  info "ig-term already installed at ${IG_HOME}, updating..."
  git -C "$IG_HOME" pull --rebase origin "$IG_BRANCH" || warn "Could not update, using existing version"
else
  info "Cloning ig-term..."
  git clone --depth 1 --branch "$IG_BRANCH" "$IG_REPO" "$IG_HOME"
  success "Cloned to ${IG_HOME}"
fi

# ── Make CLI available ────────────────────────────────────
chmod +x "${IG_HOME}/bin/ig"

# Add to PATH for current session
export PATH="${IG_HOME}/bin:${PATH}"

# ── Run init ──────────────────────────────────────────────
info "Running ig init..."
"${IG_HOME}/bin/ig" init

# ── Add to shell profile ─────────────────────────────────
_add_to_profile() {
  local line="export PATH=\"${IG_HOME}/bin:\$PATH\""
  local profile="$1"

  if [[ -f "$profile" ]] && grep -qF "ig-term" "$profile" 2>/dev/null; then
    return 0
  fi

  printf '\n# ig-term\n%s\n' "$line" >> "$profile"
  info "Added ig-term to ${profile}"
}

# Detect which profile to modify
if [[ -f "${HOME}/.zshrc" ]]; then
  # ig-term manages .zshrc, PATH is set via zshenv
  # Just ensure bin is reachable if user sources a different profile
  :
elif [[ -f "${HOME}/.bashrc" ]]; then
  _add_to_profile "${HOME}/.bashrc"
elif [[ -f "${HOME}/.profile" ]]; then
  _add_to_profile "${HOME}/.profile"
fi

# ── Done ──────────────────────────────────────────────────
printf "\n"
success "ig-term is installed!"
printf "\n"
info "Restart your terminal or run:"
printf "\n    ${BOLD}exec zsh${RESET}\n\n"
info "Commands:"
printf "    ${BOLD}ig doctor${RESET}      Health check\n"
printf "    ${BOLD}ig module list${RESET}  See modules\n"
printf "    ${BOLD}ig theme list${RESET}   See themes\n"
printf "    ${BOLD}ig help${RESET}         All commands\n"
printf "\n"
