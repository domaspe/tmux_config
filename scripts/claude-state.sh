#!/usr/bin/env bash
# Marks what Claude Code is doing, for the window tab number (tmux.conf,
# @tab_number_format) and the Windows Terminal taskbar icon to show. Claude hooks
# call it with the pane's new state; tmux hooks call it with "seen" to drop the
# done marks of the window you just opened, and with "refresh" after a pane or
# window closes.
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

# Shows the most urgent state of all windows on the Windows Terminal taskbar
# icon and tab, with the progress escape code OSC 9;4: pulsing green working,
# yellow waiting, red done, cleared when no state is left. Written straight to
# each client's terminal rather than through a pane, so tmux does not need
# allow-passthrough all and a Claude in a session that is not shown still
# reaches it. Sent every time, not only on a change, so a newly attached client
# catches up on the next hook.
taskbar() {
  local code tty
  case "$(tmux list-windows -a -F '#{@claude_state}' | most_urgent)" in
    working) code='3;0' ;;
    waiting) code='4;100' ;;
    done) code='2;100' ;;
    '') code='0;0' ;;
  esac
  tmux list-clients -F '#{client_tty}' | while read -r tty; do
    printf '\e]9;4;%s\a' "$code" > "$tty"
  done
}

set_pane() {
  # Claude run outside tmux: nothing to mark.
  [ -n "${TMUX_PANE:-}" ] || exit 0
  if [ "$1" = clear ]; then
    tmux set-option -p -u -t "$TMUX_PANE" @claude_pane_state
  else
    tmux set-option -p -t "$TMUX_PANE" @claude_pane_state "$1"
  fi
  mark_window "$(tmux display-message -p -t "$TMUX_PANE" '#{window_id}')"
  taskbar
}

seen() {
  local window="$1" pane state
  tmux list-panes -t "$window" -F '#{pane_id} #{@claude_pane_state}' | while read -r pane state; do
    if [ "$state" = done ]; then
      tmux set-option -p -u -t "$pane" @claude_pane_state
    fi
  done
  mark_window "$window"
  taskbar
}

refresh() {
  local window
  tmux list-windows -a -F '#{window_id}' | while read -r window; do
    mark_window "$window"
  done
  taskbar
}

case "${1:-}" in
  working|waiting|done|clear) set_pane "$1" ;;
  seen) seen "${2:?window id}" ;;
  refresh) refresh ;;
  *) echo "usage: ${0##*/} working|waiting|done|clear | seen <window-id> | refresh" >&2; exit 2 ;;
esac
