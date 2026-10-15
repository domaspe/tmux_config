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
# The Claude state colors (tab number cell in tmux.conf) are the Ghostty
# palette's green, yellow and red, the same the Claude theme uses for success,
# warning and error. @claude_off_style is the bar color the number blinks back
# to, so the blink shows on a tab whose own color is close to the state color.
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
    tmux set-option -g status-style             "bg=#2a2a2e,fg=#9a9996"
    tmux set-option -g window-status-style      "bg=#2a2a2e,fg=#9a9996"
    tmux set-option -g window-status-current-style "bg=#3584e4,fg=#ffffff,bold"
    tmux set-option -g @window-zoomed-style     "bg=#3a3620,fg=#f8e45c"
    tmux set-option -g @window-current-zoomed-style "bg=#f8e45c,fg=#1d1d20,bold"
    tmux set-option -g @status-session-style    "bg=#57e389,fg=#1d1d20,bold"
    tmux set-option -g @status-prefix-style     "bg=#c061cb,fg=#ffffff,bold"
    tmux set-option -g @claude_working_style    "bg=#57e389,fg=#1d1d20,bold"
    tmux set-option -g @claude_waiting_style    "bg=#f5c211,fg=#1d1d20,bold"
    tmux set-option -g @claude_done_style       "bg=#ed333b,fg=#1d1d20,bold"
    tmux set-option -g @claude_off_style        "bg=#2a2a2e,fg=#9a9996,bold"
    tmux set-option -g window-style             "bg=#1d1d20"
  else
    claude_theme adwaita-light.json
    tmux set-option -g pane-border-style        "fg=#c0bfbc,reverse"
    tmux set-option -g pane-active-border-style "fg=#2ec27e,reverse,bold"
    tmux set-option -g status-style             "bg=#ebebed,fg=#77767b"
    tmux set-option -g window-status-style      "bg=#ebebed,fg=#77767b"
    tmux set-option -g window-status-current-style "bg=#3584e4,fg=#ffffff,bold"
    tmux set-option -g @window-zoomed-style     "bg=#fde6d3,fg=#c64600"
    tmux set-option -g @window-current-zoomed-style "bg=#c64600,fg=#ffffff,bold"
    tmux set-option -g @status-session-style    "bg=#2ec27e,fg=#241f31,bold"
    tmux set-option -g @status-prefix-style     "bg=#9141ac,fg=#ffffff,bold"
    tmux set-option -g @claude_working_style    "bg=#2ec27e,fg=#241f31,bold"
    tmux set-option -g @claude_waiting_style    "bg=#e8b504,fg=#241f31,bold"
    tmux set-option -g @claude_done_style       "bg=#c01c28,fg=#ffffff,bold"
    tmux set-option -g @claude_off_style        "bg=#ebebed,fg=#77767b,bold"
    tmux set-option -g window-style             "bg=#ffffff"
  fi
}

case "${1:-}" in
  mode|apply) "$@" ;;
  *) echo "usage: ${0##*/} mode|apply" >&2; exit 2 ;;
esac
