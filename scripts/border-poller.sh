#!/bin/sh

pidfile="/tmp/tmux-border-poller.pid"
echo $$ > "$pidfile"

cleanup() { rm -f "$pidfile"; exit 0; }
trap cleanup INT TERM

while true; do
  if defaults read -g AppleInterfaceStyle 2>/dev/null | grep -qF Dark; then
    tmux set -g pane-border-style 'fg=#5e5c64,reverse'
    tmux set -g pane-active-border-style 'fg=#57e389,reverse,bold'
  else
    tmux set -g pane-border-style 'fg=#c0bfbc,reverse'
    tmux set -g pane-active-border-style 'fg=#2ec27e,reverse,bold'
  fi
  sleep 7
done
