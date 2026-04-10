# ig-term :: functions/rmk.sh - Secure file deletion

rmk() {
  local file="$1"
  if [[ -z "$file" ]]; then
    echo "Usage: rmk <file>"
    return 1
  fi

  if [[ ! -e "$file" ]]; then
    echo "File not found: $file"
    return 1
  fi

  # macOS uses gshred (from coreutils), Linux uses shred
  if command -v scrub &>/dev/null; then
    scrub -p dod "$file"
  fi

  if command -v gshred &>/dev/null; then
    gshred -zun 10 -v "$file"
  elif command -v shred &>/dev/null; then
    shred -zun 10 -v "$file"
  else
    echo "No shred command found. Install coreutils."
    return 1
  fi
}
