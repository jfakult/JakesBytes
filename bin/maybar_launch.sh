#!/bin/bash
# Launches maybar with theme colours from system_styles.sh exposed as env vars (config uses ${MAYBAR_*}).
# maybar wants rrggbbaa, so strip the leading '#'.
source ~/.config/system_styles.sh
export MAYBAR_BG=${COLOR_DARK_BACKGROUND:1}
export MAYBAR_TEXT=${COLOR_DARK_TEXT:1}
export MAYBAR_TEXT_DIM=${COLOR_DARK_TEXT_ALT:1}
export MAYBAR_TEXT_ERROR=${COLOR_DARK_TEXT_ERROR:1}
exec /usr/bin/maybar "$@"
