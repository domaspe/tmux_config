# Imports from main

Ledger of `origin/main` commits handled on `mac` by `/import-main`. A listed commit is
done.

## Standing decisions

- Status bar colors: keep mac's Adwaita colors and yellow zoom styles; don't adopt
  main's palette or its underline-only zoom. (2026-09-25)
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
