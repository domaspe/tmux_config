#!/usr/bin/env bash
set -eu

# ----- macOS variant: Ghostty follows the system appearance, so mode() reads
# AppleInterfaceStyle. main's variant reads Windows Terminal's settings.json
# and also toggles (origin/main:scripts/theme.sh) -----

mode() {
  if defaults read -g AppleInterfaceStyle 2>/dev/null | grep -qF Dark; then
    echo dark
  else
    echo light
  fi
}

apply() {
  local m="${1:-$(mode)}"
  tmux set-option -g @theme "$m"
  if [ "$m" = dark ]; then
    tmux set-option -g pane-border-style        "fg=#5e5c64,reverse"
    tmux set-option -g pane-active-border-style "fg=#57e389,reverse,bold"
  else
    tmux set-option -g pane-border-style        "fg=#c0bfbc,reverse"
    tmux set-option -g pane-active-border-style "fg=#2ec27e,reverse,bold"
  fi
}

case "${1:-}" in
  mode|apply) "$@" ;;
  *) echo "usage: ${0##*/} mode|apply" >&2; exit 2 ;;
esac
