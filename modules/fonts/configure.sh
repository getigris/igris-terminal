#!/usr/bin/env bash
# ig-term :: modules/fonts/configure.sh
# Fonts don't need config files - just verify installation

source "${IG_HOME}/core/log.sh"

local family
family="$(ig_config "fonts.family" "Hack")"

ig_debug "Font module configured: ${family} Nerd Font"
