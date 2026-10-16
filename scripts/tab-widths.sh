#!/usr/bin/env bash
# Fits every tab's pane name into the window list, like Chrome tabs. The current
# tab's format (tmux.conf) runs this once per redraw with the client width and
# the rendered width of status-left and status-right. It sets @tab_name_width on
# each window: how many columns of the pane name (@tab_pane_name) its tab shows.
#
# Space goes by water-filling: names that fit their fair share keep it whole and
# hand the rest to longer ones; the long ones split what is left equally and are
# cut with "…". Prints nothing, so the format that runs it renders nothing.
set -eu

session="$1" client_width="$2"
left=$(( $3 < $4 ? $3 : $4 ))   # status-left is cut at status-left-length
right=$(( $5 < $6 ? $5 : $6 ))
avail=$(( client_width - left - right ))

# One line per window: id, width of the tab without its name (" #I " and
# " #W "), width of the name. tmux measures, so wide characters count as they render.
windows=$(tmux list-windows -t "$session" \
  -F '#{window_id} #{e|+|:#{n:window_index},#{w:window_name}} #{w:#{E:@tab_pane_name}} #{@tab_name_width}')

args=()
while read -r id width; do
  args+=(set-option -w -t "$id" @tab_name_width "$width" \;)
done < <(awk -v avail="$avail" '
  {
    id[NR] = $1; name[NR] = $3; old[NR] = $4
    budget -= $2 + 4
    # A name also takes ": " before it.
    demand[NR] = $3 > 0 ? $3 + 2 : 0
  }
  END {
    n = NR
    # One window-status-separator column between neighbouring tabs.
    budget += avail - (n - 1)
    # Hand out the budget smallest demand first; once one does not fit its
    # equal share of what is left, every remaining tab gets that share.
    for (i = 1; i <= n; i++) order[i] = i
    for (i = 2; i <= n; i++)
      for (j = i; j > 1 && demand[order[j]] < demand[order[j - 1]]; j--) {
        t = order[j]; order[j] = order[j - 1]; order[j - 1] = t
      }
    left = n; cap = -1
    for (k = 1; k <= n; k++) {
      i = order[k]
      share = budget > 0 ? int(budget / left) : 0
      if (cap < 0 && demand[i] <= share) {
        width[i] = name[i]; budget -= demand[i]; left--
      } else {
        if (cap < 0) cap = share
        # ": " before the name and "…" after the cut.
        width[i] = cap - 3 > 0 ? cap - 3 : 0
      }
    }
    for (i = 1; i <= n; i++)
      if (width[i] != old[i]) print id[i], width[i]
  }' <<<"$windows")

[ ${#args[@]} -eq 0 ] || tmux "${args[@]}"
