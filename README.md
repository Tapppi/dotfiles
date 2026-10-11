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
  `.bash_profile`, `.bashrc`, `.claude/`, `.codex/`, `.cursor/`, `.hushlogin`, `.parallel/`,
  `.pi/`
- `config/` — rsynced to `~/.config/` (XDG-compliant config):
  `bash/`, `btop/`, `claude/`, `containers/`, `cursor/`, `fd/`, `gh/`, `ghostty/`, `git/`,
  `karabiner/`, `lazygit/`, `micro/`, `mise/`, `nnn/`, `opencode/`, `readline/`, `ripgrep/`,
  `terminal/`, `tmux/`, `curlrc`, `wgetrc`
- `bootstrap.sh` — two rsyncs (`home/` → `~/` and `config/` → `~/.config/`), nothing
  mirrored with `--delete`, which would wipe every untracked file in `~` and `~/.config`. A
  failing rsync is reported and becomes the script's exit status, which macos-setup's
  `install_dotfiles` gates its tool steps on; the remaining sync still runs
- `keyboard-layouts/` — custom Finnish Programmer keyboard layout (copied separately to
  `~/Library/Keyboard Layouts/`)
- `agents/` — sources of the user-level agent instructions: a shared core, one header per
  harness, and `render.sh`, which writes the generated files for Claude Code, Codex, OpenCode,
  Cursor and Pi (`agents/render.sh --check` reports drift). It also holds the user-level
  `my-machine-configs` skill. See [agents/README.md](agents/README.md)
- `docs/harnesses.md` — each agent harness's config locations, what is tracked here, and the
  config that tools write into tracked paths

macos-setup's `.extra` and `.path` are not in this repo but land beside these files:
`install_dotfiles` copies them into `~/.config/bash/` during install.

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
- `config/opencode/` — OpenCode AI agent config (`opencode.json` and the generated `AGENTS.md`)
- `config/ripgrep/` — Ripgrep defaults
- `config/tmux/tmux.conf` — tmux with Ctrl+A prefix, vim keys, pbcopy
- `home/.claude/` — Claude Code user-level config (settings, keybindings, statusline, generated
  `CLAUDE.md`)
- `home/.codex/` — the generated Codex user-level `AGENTS.md`
- `home/.cursor/` — Cursor CLI config and the generated `rules/00-environment.mdc`
- `home/.pi/` — the generated Pi user-level `agent/AGENTS.md`
- `keyboard-layouts/` — Custom Finnish Programmer keyboard layout

## Application hotkeys

[Karabiner Tab→Hyper](config/karabiner/) (Cmd+Ctrl+Opt+Shift) maps the modifier;
the hotkeys themselves live in [tapppi/systems](https://github.com/Tapppi/systems),
which owns Hammerspoon and its configuration.

The table below is the pre-migration set and no longer matches the running
config — `v` and `c` now select browser profiles, and Calendar moved to `x`.

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

## OpenCode notes

- `config/opencode/opencode.json` is the synced OpenCode config, and `tui.json` beside it holds the
  TUI settings and keybinds. The global config loads no npm plugins: skills come from
  `skills.paths` and the Claude Code and `.agents` skill directories, and context7 is a native
  `mcp` entry that inherits `CONTEXT7_API_KEY` from the environment (anonymous when unset). The
  `browser` plugin is enabled per repo, through a root `opencode.json` in each repo that loads
  the plugin's own OpenCode module.
- Providers (ChatGPT through OpenCode's built-in OAuth, and z.ai) are logged
  in with `opencode auth login`; their credentials stay in the untracked
  `~/.local/share/opencode/auth.json`.
- `config/opencode/AGENTS.md` is synced to `~/.config/opencode/AGENTS.md` as
  the user-level instruction file. It is generated from `agents/`; edit there.
- herdr writes its own plugin and TUI files (`tui.jsonc` among them) into
  `~/.config/opencode/`; they are not tracked here.
- oh-my-openagent is not part of this config. A setup that layers it on
  OpenCode keeps its own config directory instead of editing these files.
- No extra tmux/git-specific OpenCode wrapper config is tracked here.

## Attribution

Forked from [Mathias Bynens' dotfiles](https://github.com/mathiasbynens/dotfiles),
which provided the original structure and many of the shell functions/aliases.
Heavily customised since.
