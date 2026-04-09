# ig-term :: functions/killport.sh - Kill process on a given port

killport() {
  local port="$1"
  if [[ -z "$port" ]]; then
    echo "Usage: killport <port>"
    return 1
  fi

  local pids
  pids="$(lsof -ti ":${port}" 2>/dev/null)"
  if [[ -z "$pids" ]]; then
    echo "No process found on port ${port}"
    return 0
  fi

  echo "$pids" | xargs kill -9
  echo "Killed process(es) on port ${port}"
}
