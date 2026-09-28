---
description: Port new origin/main (WSL) commits onto the mac branch, translated for macOS
---

Port every `origin/main` commit not yet recorded in `.claude/main-imports.md` onto
`mac`. `main` is the WSL config, `mac` the macOS one (AGENTS.md → Branches).

## Rules

- Never merge, cherry-pick or rebase between the branches; never add a check that
  detects the machine. Rewrite each change by hand in its mac form.
- The ledger `.claude/main-imports.md` is the source of truth: a listed commit is
  done, never redo it. Its Standing decisions are the user's answers: apply them,
  don't ask again.
- Port only what the main commit changed; no drive-by fixes.
- Follow AGENTS.md: read `tmux.conf` and touched scripts first, check
  `~/.config/nvim/` for key clashes, never edit `SHORTCUTS.md`.
- Leave the changes uncommitted for the user to review.

## Steps

1. Require branch `mac` and a clean tree, else stop and say why. Run
   `git fetch origin`.
2. Pending = `git log --reverse --format='%h %s' mac..origin/main`, minus the hashes
   in the ledger. None → report "nothing to import" and stop.
3. Per commit, oldest first: `git show <sha>`, then compare with mac's current files
   (`git diff origin/main -- <file>`). mac often has the change already, and a later
   main commit may supersede an earlier one: port the final state once. Classify each
   commit as already / port / wsl-only / needs decision.
4. Translate via the mapping below. No clear mac form, or a design choice (colors,
   new keys, new platform scripts) → AskUserQuestion with a recommended option, then
   add the answer to Standing decisions.
5. Apply. Keep main's comments where they still hold on mac; reword the
   platform-specific parts.
6. Verify, then add one ledger entry per commit and summarize to the user.

## WSL → mac mapping

- Theme mode: `reg.exe` AppsUseLightTheme → `defaults read -g AppleInterfaceStyle`.
- Clipboard: `clip.exe` → `pbcopy`, always via `copy-pipe*` (tmux 3.6 drops the
  command argument of `copy-selection*`).
- Terminal: Windows Terminal `settings.json` → Ghostty `~/.config/ghostty/config`
  (`macos-option-as-alt = true`, so Option+key reaches tmux as `M-key`).
- `M-f` scratch-session popup → the tmux-floax plugin; keep the floax lines.
- Palette Snazzy / Alabaster → Adwaita. Backgrounds: dark `#1d1d20`
  (`~/.config/ghostty/themes/adwaita-dark-soft.conf`), light `#ffffff` (built-in
  Adwaita). Claude themes `snazzy.json` / `alabaster.json` → `adwaita-dark.json` /
  `adwaita-light.json`.
- `/mnt/c/...` paths and WSL interop fixes (e.g. `reg.exe` eating stdin) → wsl-only.

## Verify

- `tmux source-file ~/.config/tmux/tmux.conf` reports no errors.
- If `theme.sh` changed: `tmux set -gu @theme; ~/.config/tmux/scripts/theme.sh apply`.
  `apply` returns early while the mode is unchanged, so a reload alone shows nothing
  new.
- `tmux list-keys | grep` for every key added or removed.
- `git diff origin/main --stat`: every remaining difference is explained by the
  ledger.
- `awk 'length > 90' .claude/main-imports.md` prints nothing.

## Ledger format

One entry per commit under Commits: `- <sha> <outcome> — <note>`, where outcome is
`ported`, `already`, `partial`, `wsl-only` or `declined`. Wrap past 90 columns with a
two-space indent.
