#!/usr/bin/env bash
set -eu

# Ghostty follows the macOS system appearance, so mode() reads AppleInterfaceStyle.

mode() {
  if defaults read -g AppleInterfaceStyle 2>/dev/null | grep -qF Dark; then
    echo dark
  else
    echo light
  fi
}

# Claude Code follows active.json while its theme is custom:active; plain > keeps
# the inode its watcher follows.
claude_theme() {
  sed 's/"name": *"[^"]*"/"name": "Auto (terminal-synced)"/' \
    "$HOME/.claude/themes/$1" > "$HOME/.claude/themes/active.json"
}

apply() {
  tmux has-session 2>/dev/null || return 0

  local m="${1:-$(mode)}"
  local previous
  previous="$(tmux show-options -gv @theme 2>/dev/null || true)"

  if [ "$previous" != "$m" ] || [ ! -f "$HOME/.claude/themes/active.json" ]; then
    claude_theme "adwaita-$m.json"
  fi

  tmux set-option -g @theme "$m"
  if [ "$m" = dark ]; then
    tmux set-option -g pane-border-style        "fg=#5e5c64,reverse"
    tmux set-option -g pane-active-border-style "fg=#57e389,reverse,bold"
    tmux set-option -g status-style             "bg=#241f31,fg=#f6f5f4"
    tmux set-option -g window-status-style      "bg=#241f31,fg=#f6f5f4"
    tmux set-option -g window-status-current-style "bg=#51a1ff,fg=#241f31,bold"
    tmux set-option -g @window-zoomed-style "fg=#f8e45c,bold,underscore"
    tmux set-option -g @window-current-zoomed-style "bg=#f8e45c,fg=#241f31,bold,underscore"
  else
    tmux set-option -g pane-border-style        "fg=#c0bfbc,reverse"
    tmux set-option -g pane-active-border-style "fg=#2ec27e,reverse,bold"
    tmux set-option -g status-style             "bg=#51a1ff,fg=#241f31"
    tmux set-option -g window-status-style      "bg=#51a1ff,fg=#241f31"
    tmux set-option -g window-status-current-style "bg=#241f31,fg=#f6f5f4,bold"
    tmux set-option -g @window-zoomed-style "fg=#241f31,bold,underscore"
    tmux set-option -g @window-current-zoomed-style "bg=#e8b504,fg=#241f31,bold,underscore"
  fi
}

case "${1:-}" in
  mode|apply) "$@" ;;
  *) echo "usage: ${0##*/} mode|apply" >&2; exit 2 ;;
esac
