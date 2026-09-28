#!/usr/bin/env bash
set -eu

personalize='HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'

# reg.exe reads stdin to exhaustion, which would swallow the input of a caller
# that pipes data through this script, so it is given /dev/null instead.
mode() {
  local v
  v="$(reg.exe query "$personalize" /v AppsUseLightTheme 2>/dev/null </dev/null \
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

# Owns every themed color: pane borders and the status line. tmux.conf sets none
# of them, so they survive a config reload; only a new server needs the first
# apply, which tmux.conf runs.
# The status line uses only colors the terminal scheme and the Claude theme
# already have: the bar is Claude's userMessageBackground, a plain tab and the
# grey number cell are the scheme's background / selection, the current tab is
# the scheme's blue, zoom is its purple. Text is the theme's own text /
# inverseText color, whichever contrasts with the fill it sits on; every pair is
# at least 5:1 except Alabaster's purple on its selection color (4.8:1). Written
# as hex, not as the names white/black, because Alabaster maps white to #BBBBBB
# grey and neither name is tied to the scheme's background.
# The Claude state colors (number cell in tmux.conf) are a green, yellow and
# red at least 5:1 with the digit: Snazzy's own green and yellow, its red
# lightened from #ff5c57 (4.7:1). Alabaster's yellow takes the dark text, because
# a yellow dark enough for light text reads as brown.
# window-style carries the scheme's background so tmux answers a program's
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
    claude_theme snazzy.json
    tmux set-option -g pane-border-style        "fg=#6f5c69,reverse"
    tmux set-option -g pane-active-border-style "fg=#d68ebb,reverse,bold"
    tmux set-option -g status-style             "bg=#1e1f29,fg=#eff0eb"
    tmux set-option -g @tab_style               "bg=#282a36,fg=#eff0eb"
    tmux set-option -g @tab_zoomed_style        "bg=#282a36,fg=#ff6ac1"
    tmux set-option -g @tab_current_style       "bg=#57c7ff,fg=#282a36,bold"
    tmux set-option -g @tab_current_zoomed_style "bg=#ff6ac1,fg=#282a36,bold"
    tmux set-option -g @tab_number_style        "bg=#44475a,fg=#eff0eb"
    tmux set-option -g window-style             "bg=#282a36"
    tmux set-option -g @claude_working_style    "bg=#5af78e,fg=#282a36"
    tmux set-option -g @claude_waiting_style    "bg=#f3f99d,fg=#282a36"
    tmux set-option -g @claude_done_style       "bg=#ff6e67,fg=#282a36"
  else
    claude_theme alabaster.json
    tmux set-option -g pane-border-style        "fg=#c2d0c4,reverse"
    tmux set-option -g pane-active-border-style "fg=#7fa98c,reverse,bold"
    tmux set-option -g status-style             "bg=#eeeeee,fg=#434343"
    tmux set-option -g @tab_style               "bg=#cfd8dc,fg=#434343"
    tmux set-option -g @tab_zoomed_style        "bg=#cfd8dc,fg=#7a3e9d"
    tmux set-option -g @tab_current_style       "bg=#325cc0,fg=#f7f7f7,bold"
    tmux set-option -g @tab_current_zoomed_style "bg=#7a3e9d,fg=#f7f7f7,bold"
    tmux set-option -g @tab_number_style        "bg=#bbbbbb,fg=#1c1c1c"
    tmux set-option -g window-style             "bg=#f7f7f7"
    tmux set-option -g @claude_working_style    "bg=#2a7030,fg=#f7f7f7"
    tmux set-option -g @claude_waiting_style    "bg=#f5c518,fg=#434343"
    tmux set-option -g @claude_done_style       "bg=#b3261e,fg=#f7f7f7"
  fi
}

case "${1:-}" in
  mode|apply) "$@" ;;
  *) echo "usage: ${0##*/} mode|apply" >&2; exit 2 ;;
esac
