#!/usr/bin/env bash
# ig-term :: lib/semver.sh - Semantic version comparison

# Parse a semver string into major, minor, patch
# Usage: semver_parse "1.2.3" -> sets _SV_MAJOR=1 _SV_MINOR=2 _SV_PATCH=3
semver_parse() {
  local version="$1"
  version="${version#v}"  # Strip leading 'v'

  _SV_MAJOR="${version%%.*}"
  local rest="${version#*.}"
  _SV_MINOR="${rest%%.*}"
  _SV_PATCH="${rest#*.}"
  _SV_PATCH="${_SV_PATCH%%[-+]*}"  # Strip pre-release/build metadata
}

# Compare two semver strings
# Returns: 0 if equal, 1 if a > b, 2 if a < b
semver_compare() {
  local a="$1" b="$2"

  semver_parse "$a"
  local a_major="$_SV_MAJOR" a_minor="$_SV_MINOR" a_patch="$_SV_PATCH"

  semver_parse "$b"
  local b_major="$_SV_MAJOR" b_minor="$_SV_MINOR" b_patch="$_SV_PATCH"

  if (( a_major > b_major )); then return 1; fi
  if (( a_major < b_major )); then return 2; fi
  if (( a_minor > b_minor )); then return 1; fi
  if (( a_minor < b_minor )); then return 2; fi
  if (( a_patch > b_patch )); then return 1; fi
  if (( a_patch < b_patch )); then return 2; fi
  return 0
}

# Check if version a is newer than version b
semver_gt() {
  semver_compare "$1" "$2"
  [[ $? -eq 1 ]]
}

# Check if version a is older than version b
semver_lt() {
  semver_compare "$1" "$2"
  [[ $? -eq 2 ]]
}

# Check if version a equals version b
semver_eq() {
  semver_compare "$1" "$2"
  [[ $? -eq 0 ]]
}
