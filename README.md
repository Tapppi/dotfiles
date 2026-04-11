# dotfiles

Shell dotfiles and configs for macOS. Bash 5, Solarized Dark prompt, GNU
coreutils, and a bunch of aliases/functions accumulated over the years.

Bootstrapped via [macos-setup](https://github.com/tapppi/macos-setup) — see
that repo for the full setup automation.

## Usage

```bash
# Bootstrap: rsync dotfiles to ~ and reload shell
./bootstrap.sh -f
```

## What's inside

- `.config/bash/` — aliases, exports, functions, prompt, nnn config
- `.config/ghostty/` — Ghostty terminal config
- `.config/karabiner/` — Karabiner-Elements keyboard remapping
  - Caps Lock → Esc (alone) / Ctrl (held)
  - Right Cmd + hjkl → arrow keys
  - Tab → Hyper (Cmd+Ctrl+Opt+Shift) when held, Tab when tapped
- `.config/lazygit/` — Lazygit TUI config
- `.config/mise/` — Mise runtime version manager config
- `.config/opencode/` — OpenCode AI agent config
- `.config/ripgrep/` — Ripgrep defaults
- `.hammerspoon/` — Per-app US keyboard layout forcing, Ghostty dropdown toggle (Hyper+S)
- `.gitconfig` — Git aliases, diff-so-fancy, 1Password SSH signing
- `.tmux.conf` — tmux with Ctrl+A prefix, vim keys, pbcopy
- `keyboard-layouts/` — Custom Finnish Programmer keyboard layout

## Attribution

Forked from [Mathias Bynens' dotfiles](https://github.com/mathiasbynens/dotfiles),
which provided the original structure and many of the shell functions/aliases.
Heavily customised since.
