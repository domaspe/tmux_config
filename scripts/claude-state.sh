#!/usr/bin/env bash
# Marks what Claude Code is doing, for the window tab number to show (tmux.conf,
# @claude_number_style). Claude hooks call it with the pane's new state; tmux
# hooks call it with "seen" to drop the waiting / done mark of the pane you just
# focused, and with "refresh" after a pane or window closes. A pane you are in
# never gets a waiting or done mark: you are already looking at it.
#
# Each pane keeps its own state in @claude_pane_state. The window gets the most
# urgent one in @claude_state: waiting > done > working. The names differ
# because a pane option would hide the window option of the same name in the
# tab format.
set -eu

# Prints the most urgent of the states read from stdin, or nothing.
most_urgent() {
  local states candidate
  states=$(cat)
  for candidate in waiting done working; do
    if grep -qx "$candidate" <<<"$states"; then
      echo "$candidate"
      return
    fi
  done
}

# Recomputes the window's state from its panes.
mark_window() {
  local window="$1" state
  state=$(tmux list-panes -t "$window" -F '#{@claude_pane_state}' | most_urgent)
  if [ -n "$state" ]; then
    tmux set-option -w -t "$window" @claude_state "$state"
  else
    tmux set-option -w -u -t "$window" @claude_state
  fi
}

# True when the pane is the one a client is looking at: the active pane of the
# active window of an attached session.
focused() {
  [ "$(tmux display-message -p -t "$1" '#{&&:#{session_attached},#{&&:#{window_active},#{pane_active}}}')" = 1 ]
}

set_pane() {
  local state="$1"
  # Claude run outside tmux: nothing to mark.
  [ -n "${TMUX_PANE:-}" ] || exit 0
  case "$state" in
    waiting|done) focused "$TMUX_PANE" && state=clear ;;
  esac
  if [ "$state" = clear ]; then
    tmux set-option -p -u -t "$TMUX_PANE" @claude_pane_state
  else
    tmux set-option -p -t "$TMUX_PANE" @claude_pane_state "$state"
  fi
  mark_window "$(tmux display-message -p -t "$TMUX_PANE" '#{window_id}')"
}

seen() {
  local pane="$1"
  case "$(tmux display-message -p -t "$pane" '#{@claude_pane_state}')" in
    waiting|done) tmux set-option -p -u -t "$pane" @claude_pane_state ;;
  esac
  mark_window "$(tmux display-message -p -t "$pane" '#{window_id}')"
}

refresh() {
  local window
  tmux list-windows -a -F '#{window_id}' | while read -r window; do
    mark_window "$window"
  done
}

case "${1:-}" in
  working|waiting|done|clear) set_pane "$1" ;;
  seen) seen "${2:?pane id}" ;;
  refresh) refresh ;;
  *) echo "usage: ${0##*/} working|waiting|done|clear | seen <pane-id> | refresh" >&2; exit 2 ;;
esac
