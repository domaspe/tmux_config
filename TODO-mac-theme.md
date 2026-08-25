# TODO: make this machine set the `@theme` tmux option

Delete this file once it is done.

## What and why

The Neovim config is shared across machines and must not know which machine it runs on.
It decides light vs dark by reading one tmux option:

    tmux show-options -gv @theme     # must print exactly `dark` or `light`

That read lives in `lua/plugins/colorscheme.lua` in the nvim repo
(`git@github-domaspe:domaspe/nvim_lazy.git`), in the function `tmux_background`.
Anything that is not exactly `light` counts as dark, so an unset option is not an
error — nvim simply stays dark, which is what happens on this machine today.

Each machine's own theme code is responsible for setting `@theme`. On WSL (`main`
branch) `scripts/theme.sh` does it in `apply()`, which is the single point that the
toggle, the tmux config load, and `fix-borders.sh` all pass through.

This machine does not set it yet. That is the whole task.

## Decide first

The theme switch here is `zshrc_term_theme` in `~/.zshrc`, with `zshrc_term_borders`
repainting the pane borders (called from `tmux.conf`, see the `run-shell` line under
PANE BORDERS). Read both functions before choosing:

- **If the terminal's look follows the macOS system appearance** — add a
  `scripts/theme.sh` to this branch mirroring the WSL one, with `mode()` built on
  `defaults read -g AppleInterfaceStyle` (prints `Dark`, exits non-zero when light),
  and call it from `tmux.conf` the way `main` does. This keeps the logic in the repo,
  where it can be reviewed and changed later.

- **If `zshrc_term_theme` flips the terminal's own config independently of the macOS
  setting** — then only that function knows the mode. Add one line to
  `zshrc_term_borders` in `~/.zshrc`, using whichever variable already holds the mode:

      tmux set-option -g @theme "$mode"   # exactly "dark" or "light"

  `zshrc_term_borders` is the right place because it already runs both on tmux config
  load and whenever `zshrc_term_theme` flips the theme.

## Verify

1. `tmux show-options -gv @theme` prints `dark` or `light`, matching the terminal.
2. Toggle the theme, run it again, confirm it flipped.
3. Open nvim, `:echo &background` matches. `:lua print(vim.g.onedark_config.style)`
   gives `light` in light mode and `darker` in dark mode.
4. Toggle back.

nvim reads `@theme` only at startup, by choice. An nvim that is already open does not
change when you toggle.
