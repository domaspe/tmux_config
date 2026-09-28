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

# Owns every themed color: pane borders and the status line. tmux.conf sets none
# of them, so they survive a config reload; only a new server needs the first
# apply, which tmux.conf runs.
# window-style carries Ghostty's background so tmux answers a program's
# background query (OSC 11, used by hunk) with the current color; without it tmux
# answers with the color the terminal had when the client attached.
# Returns early when the mode is unchanged, because the poller calls this every
# few seconds and each claude_theme write retriggers Claude Code's file watcher.
apply() {
  tmux has-session 2>/dev/null || return 0
  local m
  m="$(mode)"
  [ "$m" = "$(tmux show-options -gqv @theme)" ] && return 0
  tmux set-option -g @theme "$m"
  if [ "$m" = dark ]; then
    claude_theme adwaita-dark.json
    tmux set-option -g pane-border-style        "fg=#5e5c64,reverse"
    tmux set-option -g pane-active-border-style "fg=#57e389,reverse,bold"
    tmux set-option -g status-style             "bg=#241f31,fg=#f6f5f4"
    tmux set-option -g window-status-style      "bg=#241f31,fg=#f6f5f4"
    tmux set-option -g window-status-current-style "bg=#51a1ff,fg=#241f31,bold"
    tmux set-option -g @window-zoomed-style "fg=#f8e45c,bold,underscore"
    tmux set-option -g @window-current-zoomed-style "bg=#f8e45c,fg=#241f31,bold,underscore"
    tmux set-option -g window-style             "bg=#1d1d20"
  else
    claude_theme adwaita-light.json
    tmux set-option -g pane-border-style        "fg=#c0bfbc,reverse"
    tmux set-option -g pane-active-border-style "fg=#2ec27e,reverse,bold"
    tmux set-option -g status-style             "bg=#1c71d8,fg=#ffffff"
    tmux set-option -g window-status-style      "bg=#1c71d8,fg=#ffffff"
    tmux set-option -g window-status-current-style "bg=#241f31,fg=#f6f5f4,bold"
    tmux set-option -g @window-zoomed-style "fg=#f8e45c,bold,underscore"
    tmux set-option -g @window-current-zoomed-style "fg=#f8e45c,bold,underscore"
    tmux set-option -g window-style             "bg=#ffffff"
  fi
}

case "${1:-}" in
  mode|apply) "$@" ;;
  *) echo "usage: ${0##*/} mode|apply" >&2; exit 2 ;;
esac
