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

## Structure

Two sync directories plus standalone files at the repo root:

- `home/` — rsynced to `~/` (files that don't support XDG):
  `.bash_profile`, `.bashrc`, `.claude/`, `.hammerspoon/`, `.hushlogin`, `.parallel/`
- `config/` — rsynced to `~/.config/` (XDG-compliant config):
  `bash/`, `git/`, `tmux/`, `readline/`, `curlrc`, `wgetrc`, `ghostty/`, `karabiner/`,
  `lazygit/`, `micro/`, `mise/`, `nnn/`, `opencode/`, `ripgrep/`, `fd/`, `terminal/`
- `bootstrap.sh` — two rsyncs: `home/` → `~/` and `config/` → `~/.config/`
- `keyboard-layouts/` — custom Finnish Programmer keyboard layout (copied separately)

## What's inside

- `config/bash/` — aliases, exports, functions, prompt, nnn config
- `config/ghostty/` — Ghostty terminal config
- `config/git/` — Git aliases, diff-so-fancy, 1Password SSH signing, global gitignore
- `config/karabiner/` — Karabiner-Elements keyboard remapping
  - Caps Lock → Esc (alone) / Ctrl (held)
  - Right Cmd + hjkl → arrow keys
  - Tab → Hyper (Cmd+Ctrl+Opt+Shift) when held, Tab when tapped
- `config/lazygit/` — Lazygit TUI config
- `config/mise/` — Mise runtime version manager config
- `config/opencode/` — OpenCode AI agent config, including the `oh-my-openagent` plugin entrypoint
- `config/ripgrep/` — Ripgrep defaults
- `config/tmux/tmux.conf` — tmux with Ctrl+A prefix, vim keys, pbcopy
- `home/.claude/` — Claude Code user-level config (settings, keybindings, statusline)
- `home/.hammerspoon/` — Per-app US keyboard layout forcing, Ghostty dropdown toggle (Hyper+S)
- `keyboard-layouts/` — Custom Finnish Programmer keyboard layout

## Application hotkeys

Managed via [Hammerspoon](home/.hammerspoon/init.lua) with
[Karabiner Tab→Hyper](config/karabiner/) (Cmd+Ctrl+Opt+Shift).

| Hotkey | Application |
|--------|-------------|
| Hyper+S | Ghostty |
| Hyper+B | Brave |
| Hyper+V | Safari |
| Hyper+K | Slack |
| Hyper+I | Microsoft Teams |
| Hyper+F | Finder |
| Hyper+C | Calendar |
| Hyper+J | Obsidian |
| Hyper+M | Spotify |

## OpenCode / OpenAgent notes

- `config/opencode/opencode.json` is the synced OpenCode entrypoint and loads
  `oh-my-openagent@latest` plus `opencode-claude-auth`.
- `config/opencode/oh-my-openagent.json` is the tracked companion config for
  agent/category model choices and plugin-managed behavior.
- `config/opencode/AGENTS.md` is synced to `~/.config/opencode/AGENTS.md` as
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
