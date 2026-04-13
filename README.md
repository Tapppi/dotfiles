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
- `.config/opencode/` — OpenCode AI agent config, including the `oh-my-openagent` plugin entrypoint
- `.config/ripgrep/` — Ripgrep defaults
- `.hammerspoon/` — Per-app US keyboard layout forcing, Ghostty dropdown toggle (Hyper+S)
- `.gitconfig` — Git aliases, diff-so-fancy, 1Password SSH signing
- `.tmux.conf` — tmux with Ctrl+A prefix, vim keys, pbcopy
- `keyboard-layouts/` — Custom Finnish Programmer keyboard layout

## OpenCode / OpenAgent notes

- `.config/opencode/opencode.json` is the synced OpenCode entrypoint and loads
  `oh-my-openagent@latest` plus `opencode-claude-auth`.
- `.config/opencode/oh-my-openagent.json` is the tracked companion config for
  agent/category model choices and plugin-managed behavior.
- `.config/opencode/AGENTS.md` is synced to `~/.config/opencode/AGENTS.md` as
  the user-level instruction file.
- This repo intentionally keeps the OpenCode-side customisation focused on the
  plugin entrypoint, companion config, and user-level instructions. MCP server
  inventory and bundled skills come from `oh-my-openagent` itself rather than a
  second hand-copied local mirror here.
- Claude-specific auth remains explicit through the separate
  `opencode-claude-auth` plugin entry in `opencode.json`.
- No extra tmux/git-specific OpenCode wrapper config is tracked here. The repo
  relies on the platform's built-in git/browser/tooling capabilities plus the
  shared OpenAgent config instead of copying parallel custom wrappers into this
  dotfiles repo.

## Attribution

Forked from [Mathias Bynens' dotfiles](https://github.com/mathiasbynens/dotfiles),
which provided the original structure and many of the shell functions/aliases.
Heavily customised since.
