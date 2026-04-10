# ig-term :: functions/recent-dirs.sh - Navigate recent directories with fzf

recent-dirs() {
  if ! command -v fzf &>/dev/null; then
    echo "fzf is required for recent-dirs"
    return 1
  fi

  local escaped_home
  escaped_home="$(echo "$HOME" | sed 's/\//\\\//g')"

  local selected
  selected="$(dirs -p | sort -u | fzf --prompt="recent > ")" || return

  cd "$(echo "$selected" | sed "s/\~/$escaped_home/")" || return
}
