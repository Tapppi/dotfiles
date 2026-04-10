# AGENTS.md - dotfiles

Shell dotfiles and configs for macOS. Synced to `~` via `bootstrap.sh`.
This file is also synced to `~/AGENTS.md` so agents operating in the home
directory context see these instructions.

Parent repo: [macos-setup](https://github.com/tapppi/macos-setup) — see its
AGENTS.md for the full setup automation context.

## Repository Structure

```
dotfiles/
  .config/
    bash/.aliases         # Shell aliases (g=git)
    bash/.exports         # Environment variables (EDITOR=nvim)
    bash/.functions       # Shell utility functions
    bash/.bash_profile    # Main profile (sources all the above + activates mise, zoxide)
    bash/.bash_prompt     # Solarized Dark prompt with git status
    ghostty/              # Ghostty terminal config
    karabiner/            # Karabiner-Elements keyboard remapping
    lazygit/              # Lazygit TUI config
    mise/                 # Mise runtime version manager config
    opencode/             # OpenCode AI agent config
    ripgrep/              # Ripgrep defaults
  .hammerspoon/init.lua   # Per-app keyboard layout forcing
  .gitconfig              # Git aliases, diff-so-fancy, 1Password SSH signing
  .tmux.conf              # tmux with Ctrl+A prefix, vim keys, pbcopy
  .macos                  # macOS system preferences script
  bootstrap.sh            # Rsyncs dotfiles to ~, copies lazygit config
  keyboard-layouts/       # Custom Finnish Programmer keyboard layout
  AGENTS.md               # This file (synced to ~/AGENTS.md)
```

## Build / Lint

No build system or test suite. Validate shell scripts with:

```sh
shellcheck bootstrap.sh .config/bash/.functions
```

## Syncing to Home Directory

`bootstrap.sh` rsyncs this repo to `~`, excluding `.git`, `.macos`,
`bootstrap.sh`, `README.md`, `LICENSE-MIT.txt`, and `keyboard-layouts/`.
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
- Commit messages: imperative mood, concise (e.g. "Add mouse settings to .macos")
- After committing here, update the parent repo submodule pointer:
  ```sh
  cd .. && git add dotfiles && git commit -m "Update dotfiles"
  ```

## AI Agent Rules

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

### Files to Never Commit

- `.credentials`, API keys, tokens, passwords
- `.DS_Store`, `Thumbs.db`, `._*`
- Backup tarballs
