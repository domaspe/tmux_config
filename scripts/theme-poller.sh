#!/bin/sh

pidfile="/tmp/tmux-theme-poller.pid"
echo $$ > "$pidfile"

# Only clear the pidfile if it is still ours. A reload kills this poller and
# starts a new one, and TERM is not handled until the sleep returns, so by then
# the pidfile belongs to the replacement.
cleanup() { [ "$(cat "$pidfile" 2>/dev/null)" = "$$" ] && rm -f "$pidfile"; exit 0; }
trap cleanup INT TERM

while true; do
  "$HOME/.config/tmux/scripts/theme.sh" apply
  "$HOME/.config/tmux/scripts/claude-state.sh" sync
  sleep 5
done
