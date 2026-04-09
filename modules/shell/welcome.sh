# ig-term :: welcome.sh - Optional welcome screen on terminal open

_ig_welcome() {
  [[ -o interactive ]] || return 0
  [[ -z "${IG_WELCOME_SHOWN:-}" ]] || return 0
  export IG_WELCOME_SHOWN=1

  local blue='\033[38;2;122;162;247m'
  local dim='\033[2m'
  local bold='\033[1m'
  local reset='\033[0m'

  local _os="$OSTYPE"
  case "$_os" in
    darwin*) _os="macos" ;;
    linux*)  _os="linux" ;;
  esac

  printf "\n"
  printf "${blue}${bold}    ┬┌─┐   ┌┬┐┌─┐┬─┐┌┬┐${reset}\n"
  printf "${blue}${bold}    ││ ┬ ── │ ├┤ ├┬┘│││${reset}\n"
  printf "${blue}${bold}    ┴└─┘    ┴ └─┘┴└─┴ ┴${reset}\n"
  printf "\n"
  printf "${dim}    Terminal ready.${reset}\n"
  printf "${dim}    %s  %s  %s${reset}\n" "$_os" "$(uname -m)" "zsh ${ZSH_VERSION:-}"
  printf "\n"
}

_ig_welcome
