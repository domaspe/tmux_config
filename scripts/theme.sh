#!/usr/bin/env bash
set -eu

# Windows Terminal is the live terminal. To go back to Alacritty: comment out
# this block and uncomment the one near the bottom — both define `config`,
# `mode`, `swap` and `toggle`.

config="/mnt/c/Users/DomasPetkevičius/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"

mode() {
  if grep -q '"theme": "dark"' "$config"; then
    echo dark
  else
    echo light
  fi
}

# Writes through powershell.exe rather than sed because the config lives on the
# Windows drive and the terminal watches it to reload. A write from inside WSL
# never raises the Windows file-change notification, so the file updates but the
# running terminal only picks it up after a restart. A native Windows write does.
#
# PowerShell builds the path from a Windows env var so the non-ASCII profile path
# never crosses the WSL boundary, and writes UTF-8 with no BOM so the file's line
# endings survive. The script is passed as base64 to avoid cross-shell quoting.
#
# Args come in pairs: FROM TO [FROM TO ...], applied as literal replacements in a
# single Windows write. Values contain double quotes, so .Replace() gets
# single-quoted PowerShell strings — no value of ours contains a single quote.
#
# Progress records are silenced because PowerShell writes them to stderr as CLIXML
# and tmux's run-shell shows stderr, so they would pop up on every switch.
swap() {
  local ps='$ProgressPreference = "SilentlyContinue"
$p = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$c = [System.IO.File]::ReadAllText($p)'
  while (( $# >= 2 )); do
    ps+=$'\n'"\$c = \$c.Replace('$1','$2')"
    shift 2
  done
  ps+=$'\n''[System.IO.File]::WriteAllText($p, $c, (New-Object System.Text.UTF8Encoding $false))'
  powershell.exe -NoProfile -NonInteractive \
    -EncodedCommand "$(printf '%s' "$ps" | iconv -t UTF-16LE | base64 -w0)" \
    >/dev/null
}

# Only the global "theme" value is rewritten: every profile's colorScheme is
# already the pair { "light": "Alabaster", "dark": "Snazzy" }, so this one value
# picks the palette and flips the title bar together — hence no Dark/Light pair
# to pass, unlike the Alacritty version.
toggle() {
  if [ "$(mode)" = dark ]; then
    swap '"theme": "dark"' '"theme": "light"'
    claude_theme alabaster.json
    apply light
    echo "Switched to light theme (Alabaster)"
  else
    swap '"theme": "light"' '"theme": "dark"'
    claude_theme snazzy.json
    apply dark
    echo "Switched to dark theme (Snazzy)"
  fi
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

# toggle passes the mode it just set, because the Windows write may not be
# visible to a re-read yet.
apply() {
  tmux has-session 2>/dev/null || return 0
  local m="${1:-$(mode)}"
  tmux set-option -g @theme "$m"
  if [ "$m" = dark ]; then
    tmux set-option -g pane-border-style        "fg=#6f5c69,reverse"
    tmux set-option -g pane-active-border-style "fg=#d68ebb,reverse,bold"
  else
    tmux set-option -g pane-border-style        "fg=#c2d0c4,reverse"
    tmux set-option -g pane-active-border-style "fg=#7fa98c,reverse,bold"
  fi
}

# ============================================================================
# Alacritty — dormant. Uncomment to use; see the note at the top of the file.
# ============================================================================
# config="/mnt/c/Users/DomasPetkevičius/AppData/Roaming/alacritty/alacritty.toml"
#
# mode() {
#   if grep -q "snazzy.toml" "$config"; then
#     echo dark
#   else
#     echo light
#   fi
# }
#
# # Pairs are the imported theme file and the title-bar Dark/Light variant. No
# # value here contains a double quote, so no PowerShell escaping is needed.
# swap() {
#   local ps='$ProgressPreference = "SilentlyContinue"
# $p = Join-Path $env:APPDATA "alacritty\alacritty.toml"
# $c = [System.IO.File]::ReadAllText($p)'
#   while (( $# >= 2 )); do
#     ps+=$'\n'"\$c = \$c.Replace(\"$1\",\"$2\")"
#     shift 2
#   done
#   ps+=$'\n''[System.IO.File]::WriteAllText($p, $c, (New-Object System.Text.UTF8Encoding $false))'
#   powershell.exe -NoProfile -NonInteractive \
#     -EncodedCommand "$(printf '%s' "$ps" | iconv -t UTF-16LE | base64 -w0)" \
#     >/dev/null
# }
#
# toggle() {
#   if [ "$(mode)" = dark ]; then
#     swap snazzy.toml alabaster.toml Dark Light
#     claude_theme alabaster.json
#     apply light
#     echo "Switched to light theme (alabaster.toml)"
#   else
#     swap alabaster.toml snazzy.toml Light Dark
#     claude_theme snazzy.json
#     apply dark
#     echo "Switched to dark theme (snazzy.toml)"
#   fi
# }

case "${1:-}" in
  mode|toggle|apply) "$@" ;;
  *) echo "usage: ${0##*/} mode|toggle|apply" >&2; exit 2 ;;
esac
