# ig-term :: functions/cdd.sh - FZF directory picker

cdd() {
  local dir
  dir="$(ls -d -- */ 2>/dev/null | fzf --prompt="dir > ")" || return
  cd "$dir" || return
}
