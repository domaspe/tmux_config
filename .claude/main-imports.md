# Imports from main

Ledger of `origin/main` commits handled on `mac` by `/import-main`. A listed commit is
done.

## Standing decisions

- Status bar: keep mac's "Blocks" design (Adwaita colors; solid accent = selected,
  tinted yellow/orange = zoomed, no window flags); don't adopt main's palette, bar
  layout or underline-only zoom. (2026-09-28)
- Font-size toggle (`prefix t f`, `scripts/font.sh`): skip; Ghostty has Cmd+= /
  Cmd+- / Cmd+0. (2026-09-25)

## Commits

- 97790e2 already — `@theme` write landed with 9221cca.
- e432647 partial — mac already polls AppleInterfaceStyle; ported `apply()`'s early
  return and the `t e` theme menu without the toggle. `reg.exe` `mode()` is wsl-only.
- 41c57f0 already — y/Y already pipe to `pbcopy`; Alt+Arrow already unbound.
- b632927 already — `fix-borders.sh` identical.
- 43fcbb1 already — README identical; floax lines are mac's own and stay.
- f7fd6e9 ported — removed dead commented-out config (AI popups, mocha hook, yank,
  cpu).
- 7c84a39 already — AGENTS.md, CLAUDE.md, `.opencode/.gitignore` identical.
- 302e499 wsl-only — `reg.exe` stdin fix.
- 2cd331d ported — `unbind -q -T theme t`.
- d8a1021 already — poller already runs every 5s.
- a134d62 partial — ported `M-l` ls and `MouseDragEnd1Pane` → `pbcopy`; `font.sh`
  declined; the status colors stay mac's own; status-bottom and centered list were
  superseded by a81f872.
- a81f872 partial — ported `M-7`/`M-8`/`M-9`/`M-0`, their unbinds, `unbind -q O`,
  `window-style` background and comments. `shortcuts.sh`, prefix `C-a` and status-top
  were already on mac; the status palette was declined.
- c1131f6 partial — ported `claude-state.sh` without the Windows Terminal OSC 9;4
  taskbar, the blinking number cell (Adwaita green/yellow/red, blinking to the bar
  color rather than the tab color), `status-interval 1` and the seen/refresh hooks;
  mac's `seen` works per pane: focusing a pane (also `after-select-pane`) drops its
  waiting and done marks, and the focused pane never gets one;
  Claude hooks added to `~/.claude/settings.json`. Main's separate grey number cell
  and tab palette declined (Blocks design stays); M-7/8/9/0 swap not ported yet;
  `.agents/local/` gitignore skipped.
