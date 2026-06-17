#!/usr/bin/env bash

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

opt_get() {
    local key="$1"
    local fallback="$2"
    local val
    val="$(tmux show-option -gqv "$key")"
    if [[ -z "$val" ]]; then
        printf '%s\n' "$fallback"
    else
        printf '%s\n' "$val"
    fi
}

opt_on() {
    local key="$1"
    local fallback="$2"
    local val
    val="$(opt_get "$key" "$fallback")"
    [[ "$val" == "on" || "$val" == "true" || "$val" == "1" || "$val" == "yes" ]]
}

tmux_supports_popup() {
    local ver raw maj min
    raw="$(tmux -V 2>/dev/null | awk '{print $2}')"
    raw="${raw%%[a-zA-Z]*}"
    maj="${raw%%.*}"
    min="${raw#*.}"
    [[ "$maj" =~ ^[0-9]+$ ]] || return 1
    [[ "$min" =~ ^[0-9]+$ ]] || min=0
    (( maj > 3 || (maj == 3 && min >= 2) ))
}

key="$(opt_get '@tmux-worktree-manager-key' 'C-;')"
prefixless="$(opt_get '@tmux-worktree-manager-prefixless' 'on')"
width="$(opt_get '@tmux-worktree-manager-popup-width' '80%')"
height="$(opt_get '@tmux-worktree-manager-popup-height' '80%')"
title="$(opt_get '@tmux-worktree-manager-popup-title' 'Worktrees')"

if ! tmux_supports_popup; then
    tmux display-message 'tmux-worktree-manager requires tmux 3.2+ (display-popup)'
    exit 0
fi

# Escape semicolons for tmux (tmux treats ';' as a command separator)
key="${key//;/\\;}"

cmd_args=(
    display-popup
    -S "fg=blue"
    -T " ${title} "
    -E -xC -yC
    -w "${width}"
    -h "${height}"
    -d "#{pane_current_path}"
    "$CURRENT_DIR/scripts/popup.sh"
)

if [[ "$prefixless" == "on" || "$prefixless" == "true" || "$prefixless" == "1" || "$prefixless" == "yes" ]]; then
    tmux bind-key -n "$key" "${cmd_args[@]}"
else
    tmux bind-key "$key" "${cmd_args[@]}"
fi
