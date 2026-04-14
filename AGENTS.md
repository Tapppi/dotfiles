# AGENTS.md - dotfiles

Shell dotfiles and configs for macOS. Synced to `~` via `bootstrap.sh`.

Parent repo: [macos-setup](https://github.com/tapppi/macos-setup) — see its
AGENTS.md for the full setup automation context.

## Repository Structure

```
dotfiles/
  home/                       # rsync → ~/
    .bash_profile             # Sources ~/.config/bash/.bash_profile
    .bashrc                   # Delegates to .bash_profile for interactive shells
    .claude/                  # Claude Code config (no XDG support)
    .hammerspoon/init.lua     # Per-app keyboard layout forcing
    .hushlogin                # Suppress login banner
    .parallel/will-cite       # Silence GNU parallel citation warning
  config/                     # rsync → ~/.config/
    bash/.aliases             # Shell aliases (g=git)
    bash/.exports             # Environment variables, XDG dirs (EDITOR=nvim)
    bash/.functions           # Shell utility functions
    bash/.bash_profile        # Main profile (sources all the above + activates mise, zoxide)
    bash/.bash_prompt         # Solarized Dark prompt with git status
    curlrc                    # curl config
    fd/                       # fd ignore patterns
    ghostty/                  # Ghostty terminal config
    git/config                # Git aliases, diff-so-fancy, 1Password SSH signing
    git/ignore                # Global gitignore
    karabiner/                # Karabiner-Elements keyboard remapping
    lazygit/                  # Lazygit TUI config
    micro/                    # Micro editor settings
    mise/                     # Mise runtime version manager config
    nnn/                      # nnn file manager plugins
    opencode/                 # OpenCode AI agent config + AGENTS.md (user-level context)
    readline/inputrc          # Readline key bindings and completion settings
    ripgrep/                  # Ripgrep defaults
    terminal/                 # Terminal.app Solarized themes
    tmux/tmux.conf            # tmux with Ctrl+A prefix, vim keys, pbcopy
    wgetrc                    # wget config
  bootstrap.sh                # Two rsyncs: home/→~/ and config/→~/.config/
  keyboard-layouts/           # Custom Finnish Programmer keyboard layout
```

## Build / Lint

No build system or test suite. Validate shell scripts with:

```sh
shellcheck bootstrap.sh config/bash/.functions
```

## Syncing to Home Directory

`bootstrap.sh` runs two rsyncs:
1. `home/` → `~/` (home-level dotfiles that don't support XDG)
2. `config/` → `~/.config/` (XDG-compliant config)

Keyboard layouts are copied separately to `~/Library/Keyboard Layouts/`.

## Code Style

See the parent repo's AGENTS.md for full shell script conventions. Key points:

- `#!/usr/bin/env bash` shebang
- Quote all variable expansions: `"${variable}"`
- Use `[[ ]]` for conditionals
- Lowercase with underscores for function/variable names
- EditorConfig: tabs (width 2), UTF-8, LF, trim trailing whitespace

## Git Conventions

- This repo uses `master` branch
- GPG signing via 1Password SSH agent (`gpg.format = ssh`)
- Commit messages: imperative mood, concise (e.g. "Update Ghostty config")
- After committing here, update the parent repo submodule pointer:
  ```sh
  cd .. && git add dotfiles && git commit -m "Update dotfiles"
  ```

### Git Identity and Attribution

- **NEVER** add AI attribution to commits (no `Co-authored-by`, no
  `Ultraworked with`, no agent signatures in commit bodies or trailers).
  Commits must look like normal developer commits.
- **NEVER** change `user.name`, `user.email`, or any git identity
  configuration. The repository owner's identity must remain on all commits.
- **Exception — unattended workflows**: If the agent must commit in an
  unattended context (e.g. CI, cron, background automation) where the
  owner's signing key is unavailable, it may temporarily set a placeholder
  identity to allow the commit to proceed. In this case:
  1. Clearly inform the user that commits were made with a placeholder identity.
  2. Note that these commits need `git rebase` / `git commit --amend` to
     restore the correct author before pushing to a shared remote.

### Do Not Run Setup Scripts

- **NEVER** run `bootstrap.sh` automatically. This script
  syncs files to `~`. The user must always run it manually.

### Files to Never Commit

- `.credentials`, API keys, tokens, passwords
- `.DS_Store`, `Thumbs.db`, `._*`
- Backup tarballs
