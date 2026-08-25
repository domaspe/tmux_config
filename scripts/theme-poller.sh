#!/bin/sh

pidfile="/tmp/tmux-theme-poller.pid"
echo $$ > "$pidfile"

cleanup() { rm -f "$pidfile"; exit 0; }
trap cleanup INT TERM

while true; do
  "$HOME/.config/tmux/scripts/theme.sh" apply
  sleep 7
done
