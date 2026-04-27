# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Shell dotfiles and configs for macOS. Synced to `~` via `bootstrap.sh`. This is a git submodule of
[macos-setup](https://github.com/tapppi/macos-setup) — see its CLAUDE.md for the full setup
automation context.

## Commands

```sh
# Lint (the only validation available)
shellcheck bootstrap.sh config/bash/.functions
```

## Architecture

- **`bootstrap.sh`** — Two rsyncs: `home/` → `~/` and `config/` → `~/.config/`. Keyboard layouts
  are copied separately to `~/Library/Keyboard Layouts/`.
- **`home/`** — Files that must live in `~/` (no XDG support): `.bash_profile`, `.bashrc`,
  `.claude/` (Claude Code config), `.cursor/` (Cursor Agent CLI config), `.hammerspoon/`,
  `.hushlogin`, `.parallel/`.
- **`config/bash/`** — Shell configuration sourced by `.bash_profile`:
  `.aliases`, `.exports`, `.functions`, `.bash_prompt` (Solarized Dark with git status).
  The parent repo's `.extra` and `.path` are also copied to `~/.config/bash/` during install.
- **`config/gh/`** — GitHub CLI config. `config.yml` sets ssh protocol, disables interactive
  prompts. Auth state (`hosts.yml`) is not tracked — managed by `gh auth login`.
- **`config/git/`** — Git config and global ignore. `config` has aliases, diff-so-fancy, 1Password
  SSH signing. `ignore` is the global gitignore (read automatically by git from XDG).
- **`config/tmux/tmux.conf`** — tmux with `Ctrl+A` prefix, vim keys, pbcopy integration.
- **`config/btop/`** — btop system monitor config and catppuccin mocha theme.
- **`config/opencode/`** — OpenCode AI agent config. `AGENTS.md` here is rsynced to
  `~/.config/opencode/AGENTS.md` as user-level agent context.
- **`keyboard-layouts/`** — Custom Finnish Programmer keyboard layout bundle.

### Agent CLI config locations

| Agent       | User-level config dir | Settings file       | User-level rules          | MCP config           |
|-------------|----------------------|---------------------|--------------------------|---------------------|
| Claude Code | `home/.claude/`      | `settings.json`     | `CLAUDE.md`              | `~/.claude.json` (untracked) |
| Cursor CLI  | `home/.cursor/`      | `cli-config.json`   | N/A (project-level only) | `home/.cursor/mcp.json` |
| OpenCode    | `config/opencode/`   | `opencode.json`     | `AGENTS.md`              | via oh-my-openagent plugin |

## Rules

### Do Not Run Setup Scripts
**NEVER** run `bootstrap.sh` automatically. It syncs files to `~`.

### Edit Source Files Here, Not in `~/`
**NEVER** edit deployed files directly in `~/`, `~/.claude/`, `~/.cursor/`, or `~/.config/`. Always edit the
source in this repo (`home/` or `config/` directories) and then copy the changed file to its
destination (e.g., `cp home/.claude/foo ~/.claude/foo`). The home directory copies are deployment
targets — this repo is the source of truth.

### Git Identity and Attribution
- **NEVER** add AI attribution to commits (no `Co-authored-by`, no agent signatures).
  Commits must look like normal developer commits.
- **NEVER** change `user.name`, `user.email`, or any git identity configuration.
- **Exception**: In unattended contexts where the signing key is unavailable, a placeholder identity
  may be used temporarily — inform the user and note that commits need rebase/amend before pushing.

### Files to Never Commit
`.credentials`, `.DS_Store`, `Thumbs.db`, `._*`, API keys/tokens/passwords, backup tarballs.

## Code Style

### EditorConfig (enforced)
Tabs (width 2), UTF-8, LF line endings, trim trailing whitespace, insert final newline.

### Shell Scripts
- Shebang: `#!/usr/bin/env bash`
- Quote all variable expansions: `"${variable}"`
- Use `[[ ]]` for conditionals
- Lowercase with underscores for function/variable names

### Git Conventions
- This repo uses `master` branch
- GPG signing via 1Password SSH agent (`gpg.format = ssh`)
- Commit messages: imperative mood, concise
- After committing here, update the parent repo submodule pointer. Use
  `git -C ..` so the shell CWD stays in the submodule:
  ```sh
  git -C .. add dotfiles
  git -C .. commit -m "Update dotfiles"
  ```
