#!/usr/bin/env bash
# ig-term :: modules/theme/configure.sh
# Exports theme colors as IG_COLOR_* env vars for other modules

source "${IG_HOME}/core/log.sh"
source "${IG_HOME}/core/config.sh"

ig_export_theme_colors

local theme_name
theme_name="$(ig_config "theme.name" "tokyo-night")"
ig_success "Theme loaded: ${theme_name}"
