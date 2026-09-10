#!/usr/bin/env bash
set -eu

settings="/mnt/c/Users/DomasPetkevičius/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
# The bigger number is the laptop's because the external runs at 150% scaling,
# where a point buys more pixels. Both land on whole-pixel cells; Terminal pads a
# gap between letters at the sizes either side of them.
laptop=12
external=10

current() {
  python3 -c '
import json, sys
print(json.load(open(sys.argv[1], encoding="utf-8"))["profiles"]["defaults"]["font"]["size"])
' "$settings"
}

# Replaces only the number rather than rewriting the JSON, because settings.json
# belongs to Windows Terminal: a round-trip would reflow its formatting and drop
# the comments it is allowed to carry.
resize() {
  python3 -c '
import re, sys
path, size = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
new, hits = re.subn(
    r"(\"defaults\"\s*:\s*\{.*?\"font\"\s*:\s*\{[^}]*?\"size\"\s*:\s*)\d+",
    r"\g<1>" + size, text, count=1, flags=re.S)
if hits != 1:
    sys.exit("no font size in profiles.defaults")
open(path, "w", encoding="utf-8").write(new)
' "$settings" "$1"
}

toggle() {
  local next
  [ "$(current)" = "$laptop" ] && next="$external" || next="$laptop"
  resize "$next"
  tmux display-message "font size $next ✓"
}

case "${1:-}" in
  current|toggle) "$@" ;;
  *) echo "usage: ${0##*/} current|toggle" >&2; exit 2 ;;
esac
