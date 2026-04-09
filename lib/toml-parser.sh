#!/usr/bin/env bash
# ig-term :: lib/toml-parser.sh - Minimal TOML parser for config files
#
# Supports: key = "value", [sections], [section.subsection], booleans, arrays of strings
# Does NOT support: inline tables, multi-line strings, dates, nested arrays
#
# Usage:
#   toml_parse "path/to/file.toml"         # Loads into TOML_* vars
#   toml_get "section.key"                  # Returns value
#   toml_get "section.key" "default"        # Returns value or default
#   toml_has "section.key"                  # Returns 0 if exists

declare -gA _TOML_DATA=()

# Parse a TOML file into the _TOML_DATA associative array
# Keys are stored as "section.key" (dot-separated)
toml_parse() {
  local file="$1"
  local section=""

  [[ -f "$file" ]] || return 1

  _TOML_DATA=()

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Strip leading/trailing whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"

    # Strip comments only if # is not inside quotes
    if [[ "$line" != *\"*#*\"* ]]; then
      line="${line%%#*}"
      line="${line%"${line##*[![:space:]]}"}"
    fi

    # Skip empty lines
    [[ -z "$line" ]] && continue

    # Section header: [section] or [section.subsection]
    if [[ "$line" =~ ^\[([a-zA-Z0-9._-]+)\]$ ]]; then
      section="${BASH_REMATCH[1]}"
      continue
    fi

    # Key-value pair
    if [[ "$line" =~ ^([a-zA-Z0-9_-]+)[[:space:]]*=[[:space:]]*(.+)$ ]]; then
      local key="${BASH_REMATCH[1]}"
      local value="${BASH_REMATCH[2]}"

      # Build full key with section prefix
      local full_key
      if [[ -n "$section" ]]; then
        full_key="${section}.${key}"
      else
        full_key="$key"
      fi

      # Parse value type
      value="$(_toml_parse_value "$value")"
      _TOML_DATA["$full_key"]="$value"
    fi
  done < "$file"
}

# Parse a TOML value (string, bool, number, array)
_toml_parse_value() {
  local raw="$1"

  # Strip trailing whitespace
  raw="${raw%"${raw##*[![:space:]]}"}"

  # Quoted string (double quotes)
  if [[ "$raw" == \"*\" ]]; then
    raw="${raw#\"}"
    raw="${raw%\"}"
    echo "$raw"
    return
  fi

  # Quoted string (single quotes)
  if [[ "$raw" == \'*\' ]]; then
    raw="${raw#\'}"
    raw="${raw%\'}"
    echo "$raw"
    return
  fi

  # Boolean
  if [[ "$raw" == "true" ]]; then
    echo "true"
    return
  fi
  if [[ "$raw" == "false" ]]; then
    echo "false"
    return
  fi

  # Array of strings: ["a", "b", "c"]
  if [[ "$raw" =~ ^\[.*\]$ ]]; then
    # Remove brackets
    local inner="${raw#\[}"
    inner="${inner%\]}"
    # Parse comma-separated values
    local result=""
    local IFS=','
    for item in $inner; do
      item="${item#"${item%%[![:space:]]*}"}"
      item="${item%"${item##*[![:space:]]}"}"
      # Remove quotes
      item="${item#\"}"
      item="${item%\"}"
      item="${item#\'}"
      item="${item%\'}"
      if [[ -n "$result" ]]; then
        result="${result}:${item}"
      else
        result="$item"
      fi
    done
    echo "$result"
    return
  fi

  # Number or bare value
  echo "$raw"
}

# Get a value from parsed TOML data
toml_get() {
  local key="$1"
  local default="${2:-}"
  local value="${_TOML_DATA[$key]:-}"

  if [[ -n "$value" ]]; then
    echo "$value"
  elif [[ -n "$default" ]]; then
    echo "$default"
  fi
}

# Check if a key exists
toml_has() {
  [[ -n "${_TOML_DATA[$1]+x}" ]]
}

# Get all keys matching a prefix
# Usage: toml_keys "modules" -> lists all keys starting with "modules."
toml_keys() {
  local prefix="$1"
  for key in "${!_TOML_DATA[@]}"; do
    if [[ "$key" == "${prefix}."* ]] || [[ "$key" == "$prefix" ]]; then
      echo "$key"
    fi
  done | sort
}

# Get all section names at a given level
# Usage: toml_sections "modules" -> "shell", "prompt", "terminal", etc.
toml_sections() {
  local prefix="$1"
  local -A seen=()
  for key in "${!_TOML_DATA[@]}"; do
    if [[ "$key" == "${prefix}."* ]]; then
      local rest="${key#${prefix}.}"
      local section="${rest%%.*}"
      if [[ -z "${seen[$section]+x}" ]]; then
        seen["$section"]=1
        echo "$section"
      fi
    fi
  done | sort
}

# Merge another TOML file on top of current data (overlay)
toml_merge() {
  local file="$1"
  local -A backup=()

  # Save current data
  for key in "${!_TOML_DATA[@]}"; do
    backup["$key"]="${_TOML_DATA[$key]}"
  done

  # Parse overlay file
  toml_parse "$file"

  # Merge: overlay wins, backup fills gaps
  for key in "${!backup[@]}"; do
    if [[ -z "${_TOML_DATA[$key]+x}" ]]; then
      _TOML_DATA["$key"]="${backup[$key]}"
    fi
  done
}

# Debug: dump all parsed data
toml_dump() {
  for key in $(echo "${!_TOML_DATA[@]}" | tr ' ' '\n' | sort); do
    printf "%s = %s\n" "$key" "${_TOML_DATA[$key]}"
  done
}
