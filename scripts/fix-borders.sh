#!/usr/bin/env bash
set -u

tmux list-windows -a -F '#{session_name}:#{window_index}' | while IFS= read -r win; do
  tmux set-option -uw -t "$win" pane-border-style
  tmux set-option -uw -t "$win" pane-active-border-style
done

zsh -ic 'typeset -f zshrc_term_borders >/dev/null 2>&1 && zshrc_term_borders' 2>/dev/null || true

tmux display-message "pane borders reset to theme ✓"
