#!/usr/bin/env bash
# Hides a pane by moving it into the background session _hidden, where it keeps
# running; prefix + u (tmux.conf) lists the hidden panes and joins one back.
# _hidden is created on first use and disappears when its last pane is restored.
set -eu

pane="${1:?pane id}"

# Moving out the last pane would destroy its session, and detach-on-destroy off
# would then switch the client into _hidden.
if [ "$(tmux display-message -p -t "$pane" '#{&&:#{==:#{session_windows},1},#{==:#{window_panes},1}}')" = 1 ]; then
  tmux display-message "Can't hide the last pane of a session"
  exit 0
fi

if tmux has-session -t =_hidden 2>/dev/null; then
  tmux break-pane -d -s "$pane" -t =_hidden:
else
  # A new session starts with a shell window; drop it so only hidden panes remain.
  starter=$(tmux new-session -d -s _hidden -P -F '#{window_id}')
  tmux break-pane -d -s "$pane" -t =_hidden:
  tmux kill-window -t "$starter"
fi

# break-pane fires none of the hooks that recount Claude state.
"$HOME/.config/tmux/scripts/claude-state.sh" refresh
