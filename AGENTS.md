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
    .cursor/                  # Cursor CLI: mcp.json, rules/*.mdc, cli-config.json (fallback copy)
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
    cursor/cli-config.json    # Cursor CLI settings/permissions (live copy; XDG-resolved)
    fd/                       # fd ignore patterns
    gh/config.yml             # GitHub CLI config (ssh protocol, no prompts)
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
  bootstrap.sh                # rsync home/→~/ and config/→~/.config/, then --delete-mirror skill dirs
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

Then three scoped `--delete` mirror rsyncs prune de-adopted agent skills
(`~/.claude/skills/`, `~/.config/opencode/skills/`, `~/.config/agent-skills/`).
The `~/.claude/skills/` mirror excludes `context7-mcp/` — that skill (and
`~/.claude/rules/context7.md`) is owned by `ctx7 setup --claude`, run from
macos-setup's `tasks/install.sh`, not tracked here.

Keyboard layouts are copied separately to `~/Library/Keyboard Layouts/`.

## Cursor CLI config splits across two directories

`cursor-agent` does not resolve all its config from one place, and getting this
wrong silently disables the file rather than erroring:

- **`cli-config.json` follows XDG**: `$CURSOR_CONFIG_DIR` → `$XDG_CONFIG_HOME/cursor`
  → `~/.cursor`. `.exports` sets `XDG_CONFIG_HOME=~/.config`, so the live file is
  `~/.config/cursor/cli-config.json` (synced from `config/cursor/`). An identical
  copy at `home/.cursor/cli-config.json` covers the fallback path when
  `XDG_CONFIG_HOME` is unset — keep the two byte-identical.
- **Everything else is hardcoded to `~/.cursor/`** regardless of XDG: `mcp.json`,
  `rules/`, `skills/`, `agents/`, `commands/`, `hooks.json` (from `home/.cursor/`).

Cursor natively reads much of the Claude Code setup — repo `CLAUDE.md`,
`.claude/skills/**/SKILL.md`, `.claude/agents/**`, `~/.claude/commands/`,
`enabledPlugins` and hooks from `.claude/settings*.json` — so it needs no
mirroring. It does **not** read `~/.claude/CLAUDE.md` (hence
`home/.cursor/rules/*.mdc`) or Claude's `Bash(...)` permission entries (Cursor's
shell tool is `Shell(...)`, so those load but never match).

### Shell permission syntax: spaces, not colons

Verified empirically against `cursor-agent 2026.08.11`:

- `Shell(<cmd>)` matches that command with any arguments (`Shell(tree)` permits
  `tree -L 1`).
- Subcommands are space-separated and prefix-matched: `Shell(git status)` matches
  `git status --short`.
- **The colon form does nothing for `Shell`** — `Shell(git:push)` never matches
  `git push`. Colons are only for `Mcp(server:tool)`.
- `deny` beats `allow`, and chaining (`a && b`) does not bypass a deny.

A malformed entry fails open (silently unmatched) rather than erroring, so verify
changes instead of assuming.

A project `.cursor/cli.json` **replaces** the global permission set rather than
merging with it, so prefer one global set over repo-local deltas.

Cursor rewrites `~/.config/cursor/cli-config.json` on startup, appending generated
state (`authInfo`, `selectedModel`, `model`, `sandbox`, `network`, …) alongside the
managed keys. `bootstrap.sh` overwrites that state, which is safe — the auth token
lives in the macOS keychain, so you stay logged in — but it resets model/display
prefs. **Never copy the live file back into the repo**: its `authInfo` carries
`email`, `userId`, `teamId` and `teamName`.

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
- After committing here, update the parent repo submodule pointer. Use
  `git -C ..` so the shell CWD stays in the submodule:
  ```sh
  git -C .. add dotfiles
  git -C .. commit -m "Update dotfiles"
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

## Pushing branches

Pushes to agent branches on `origin` are pre-approved here and run without prompting —
`agent/`, any conventional-commit prefix, plus `debug/` and `backup/` —
including `--force-with-lease --force-if-includes` for rebase and squash cleanups:

```bash
git push -u origin agent/<name>
git push origin agent/<name>
git push --force-with-lease --force-if-includes origin agent/<name>
```

Name the branch every time: a bare `git push` prompts even after `-u` has set
the upstream, because the guard approves a destination it can read rather than
one it would have to infer.

The lease stops being pre-approved once the branch has an open PR carrying a
review or comment: cleaning up your own history is fine, rewriting what someone
has already read is not. It must be paired with `--force-if-includes` — the guard
refuses a bare lease, because a background fetch refreshes the remote-tracking
ref and degrades it into a plain force.

Everything else prompts, and that is not only `master`: any destination outside the
prefixes above — `release/1.2`, `hotfix-3` — prompts too, as do plain
`--force`/`-f`, deletes and a different remote. `HEAD` is resolved to the branch
you are on and judged by that same prefix rule. A push routed through
`--git-dir`, `--work-tree`, `-c` or another option that redirects where it lands
always prompts; plain `git -C <path> push` is evaluated exactly like a direct push.

The guard reads one unquoted `git push` at a time. Quoting the branch
(`git push origin "agent/$name"`) or chaining onto it (`git push … && gh pr create`)
puts the command past what it will parse, so it prompts instead of pre-approving —
keep the push on its own line, unquoted, and follow up in a separate command.

The guard decides how you may push, never whether — push only when the request
calls for it, and never restructure a command to dodge a prompt.

Enforced by `.claude/hooks/git-push-guard.sh`, registered in `.claude/settings.json`
— both committed, so the rule and the permission travel with the repo rather than
living on one machine. This repo sets no `branchPrefixes`, so the list above is
the guard's own built-in default rather than anything named in `settings.json`. That file also carries an `ask`
rule on `master` destinations, so the default branch stays protected even when the
hook cannot run — on a machine without `jq`, for instance, where the guard prompts
and says why rather than going quiet.
