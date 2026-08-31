#!/usr/bin/env bash
set -eu

personalize='HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'

mode() {
  local v
  v="$(reg.exe query "$personalize" /v AppsUseLightTheme 2>/dev/null \
       | tr -d '\r' | awk '/AppsUseLightTheme/ {print $3}')"
  case "$v" in
    0x1) echo light ;;
    0x0) echo dark ;;
    *) echo "cannot read AppsUseLightTheme from the Windows registry" >&2; return 1 ;;
  esac
}

# Writes ~/.claude/themes/active.json, the file Claude Code follows when its theme
# is set to custom:active. Forces the name "Auto (terminal-synced)" so it never
# matches a real theme file — a shared name lets picking a theme in /theme re-pin
# Claude to a static one. The plain `>` (not cp/sed -i/mv) keeps the same inode,
# which is what Claude Code's file watcher follows.
claude_theme() {
  sed 's/"name": *"[^"]*"/"name": "Auto (terminal-synced)"/' \
    "$HOME/.claude/themes/$1" > "$HOME/.claude/themes/active.json"
}

# Returns early when the mode is unchanged, because the poller calls this every
# few seconds and each claude_theme write retriggers Claude Code's file watcher.
apply() {
  tmux has-session 2>/dev/null || return 0
  local m
  m="$(mode)"
  [ "$m" = "$(tmux show-options -gqv @theme)" ] && return 0
  tmux set-option -g @theme "$m"
  if [ "$m" = dark ]; then
    claude_theme snazzy.json
    tmux set-option -g pane-border-style        "fg=#6f5c69,reverse"
    tmux set-option -g pane-active-border-style "fg=#d68ebb,reverse,bold"
  else
    claude_theme alabaster.json
    tmux set-option -g pane-border-style        "fg=#c2d0c4,reverse"
    tmux set-option -g pane-active-border-style "fg=#7fa98c,reverse,bold"
  fi
}

case "${1:-}" in
  mode|apply) "$@" ;;
  *) echo "usage: ${0##*/} mode|apply" >&2; exit 2 ;;
esac
