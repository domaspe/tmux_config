#!/usr/bin/env bash
# Undo a window-local pane border color that a tool (Claude Code) left behind,
# which hides the normal borders. A window-local option outranks the global one
# and a tmux reload does not clear it, so it has to be unset per window.
set -u

tmux list-windows -a -F '#{session_name}:#{window_index}' | while IFS= read -r win; do
  tmux set-option -uw -t "$win" pane-border-style
  tmux set-option -uw -t "$win" pane-active-border-style
done

"$(dirname "$0")/theme.sh" apply

tmux display-message "pane borders reset to theme ✓"
