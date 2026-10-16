#!/usr/bin/env bash
# Marks what Claude Code is doing, for the window tab number (tmux.conf,
# @tab_number_format) and the Windows Terminal taskbar icon to show. Claude hooks
# call it with the pane's new state; tmux hooks call it with "seen" to drop the
# waiting / done mark of the pane you just focused, and with "refresh" after a
# pane or window closes. The theme poller calls it with "sync" every 5 seconds
# to drop marks of turns that were cancelled. A pane you are in never gets a
# waiting or done mark: you are already looking at it.
#
# Each pane keeps its own state in @claude_pane_state, and the time it was set
# (epoch milliseconds) in @claude_pane_since. The window gets the most
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
    tmux set-option -p -t "$TMUX_PANE" @claude_pane_since "$(date +%s%3N)"
  fi
  mark_window "$(tmux display-message -p -t "$TMUX_PANE" '#{window_id}')"
  taskbar
}

# Drops the waiting / done mark of the pane you just focused.
seen() {
  local pane="$1"
  case "$(tmux display-message -p -t "$pane" '#{@claude_pane_state}')" in
    waiting|done) tmux set-option -p -u -t "$pane" @claude_pane_state ;;
  esac
  mark_window "$(tmux display-message -p -t "$pane" '#{window_id}')"
  taskbar
}

# Drops working and waiting marks that no hook will replace. A cancelled turn
# (Esc, a rejected tool) runs no Stop hook, so its pane keeps the mark. Claude
# Code writes each session's status and tmux pane to
# ~/.claude/sessions/<pid>.json; a session that went idle after the mark was
# set has no turn running. Files of sessions that have exited stay there and
# can name the same pane id, so only a live pid counts. The status field is not
# documented and may change in a later Claude Code version.
sync() {
  local marks pane since file pid status updated changed=
  marks=$(tmux list-panes -a -F '#{pane_id} #{@claude_pane_state} #{@claude_pane_since}' | grep -E '^%[0-9]+ (working|waiting) ') || return 0
  while read -r pane _ since; do
    for file in $(grep -l "\"tmux\":\"[^\"]*\.$pane\"" ~/.claude/sessions/*.json || true); do
      # Claude may be rewriting the file; the next run reads it.
      read -r pid status updated < <(jq -r '[.pid, .status, .statusUpdatedAt] | @tsv' "$file" 2>/dev/null) || continue
      kill -0 "$pid" 2>/dev/null || continue
      # Marks set before @claude_pane_since existed have no time: any idle counts.
      if [ "$status" = idle ] && [ "$updated" -gt "${since:-0}" ]; then
        tmux set-option -p -u -t "$pane" @claude_pane_state
        mark_window "$(tmux display-message -p -t "$pane" '#{window_id}')"
        changed=1
      fi
    done
  done <<<"$marks"
  [ -z "$changed" ] || taskbar
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
  seen) seen "${2:?pane id}" ;;
  refresh) refresh ;;
  sync) sync ;;
  *) echo "usage: ${0##*/} working|waiting|done|clear | seen <pane-id> | refresh | sync" >&2; exit 2 ;;
esac
