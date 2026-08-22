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

- **`bootstrap.sh`** — Two rsyncs: `home/` → `~/` and `config/` → `~/.config/`. Then three
  **scoped `--delete` mirror** rsyncs for the agent-skill dirs (`~/.claude/skills/`,
  `~/.config/opencode/skills/`, `~/.config/agent-skills/`) so de-adopted skills are pruned, not
  just added. `--delete` is **never** applied to the whole `home/`/`config/` sync (it would wipe
  untracked files in `~`). The `~/.claude/skills/` mirror excludes `context7-mcp/` — that skill
  (and `~/.claude/rules/context7.md`) is owned by `ctx7 setup --claude`, run from macos-setup's
  `tasks/install.sh`, not tracked here. Keyboard layouts are copied separately to
  `~/Library/Keyboard Layouts/`.
- **`home/`** — Files that must live in `~/` (no XDG support): `.bash_profile`, `.bashrc`,
  `.claude/` (Claude Code config), `.cursor/` (Cursor Agent CLI: `mcp.json`, `rules/`,
  and a fallback copy of `cli-config.json`), `.hammerspoon/`,
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
- **`config/cursor/`** — Cursor CLI settings (`cli-config.json`: permissions, approval
  mode, attribution). Lives here because `cursor-agent` resolves this one file via
  `XDG_CONFIG_HOME`; see "Cursor CLI splits its config across two directories" below.
- **`config/opencode/`** — OpenCode AI agent config. `AGENTS.md` here is rsynced to
  `~/.config/opencode/AGENTS.md` as user-level agent context.
- **`keyboard-layouts/`** — Custom Finnish Programmer keyboard layout bundle.

### Agent CLI config locations

| Agent       | User-level config dir | Settings file       | User-level rules          | MCP config           |
|-------------|----------------------|---------------------|--------------------------|---------------------|
| Claude Code | `home/.claude/`      | `settings.json`     | `CLAUDE.md`              | `~/.claude.json` (untracked) |
| Cursor CLI  | `home/.cursor/` **and** `config/cursor/` | `config/cursor/cli-config.json` | `home/.cursor/rules/*.mdc` | `home/.cursor/mcp.json` |
| OpenCode    | `config/opencode/`   | `opencode.json`     | `AGENTS.md`              | via oh-my-openagent plugin |

#### Cursor CLI splits its config across two directories

`cursor-agent` does **not** resolve all of its config from one place, and getting
this wrong silently disables the file rather than erroring:

- **`cli-config.json` follows XDG.** The lookup is
  `$CURSOR_CONFIG_DIR` → `$XDG_CONFIG_HOME/cursor` → `~/.cursor`. `.exports` sets
  `XDG_CONFIG_HOME=~/.config`, so the live file is **`~/.config/cursor/cli-config.json`**,
  synced from `config/cursor/`. An identical copy is kept at `home/.cursor/cli-config.json`
  so the fallback path matches when `XDG_CONFIG_HOME` is unset (e.g. a GUI-launched
  process); keep the two byte-identical.
- **Everything else is hardcoded to `~/.cursor/`** regardless of XDG: `mcp.json`,
  `rules/`, `skills/`, `agents/`, `commands/`, `hooks.json`. These come from `home/.cursor/`.

Cursor reads a lot of the Claude Code setup natively, so most of it needs no
mirroring: repo `CLAUDE.md`/`CLAUDE.local.md`, `.claude/skills/**/SKILL.md`,
`.claude/agents/**`, `~/.claude/commands/`, `enabledPlugins` from
`.claude/settings*.json`, and hooks + `permissions` from `.claude/settings.json`.
Two things it does **not** read: `~/.claude/CLAUDE.md` (hence
`home/.cursor/rules/*.mdc`, which the ancestor walk picks up for any repo under
`~`), and Claude's `Bash(...)` permission entries — those load but never match,
because Cursor's shell tool is `Shell(...)`.

#### Shell permission syntax: spaces, not colons

Verified empirically against `cursor-agent 2026.08.11`:

- `Shell(<cmd>)` matches that command with **any** arguments — `Shell(tree)`
  permits `tree -L 1`.
- Subcommands are **space-separated and prefix-matched**: `Shell(git status)`
  matches `git status --short`.
- **The colon form does nothing for `Shell`.** `Shell(git:push)` never matches
  `git push` — it silently permits/denies nothing. Colons are only for
  `Mcp(server:tool)`. An earlier version of this config was written entirely in
  colon form, so none of its allow or deny entries had any effect.
- `deny` beats `allow`, so the broad `Shell(git)` allow plus a narrow
  `Shell(git push)` deny works as intended.
- Denies are **not** bypassed by chaining: `git log … && git status …` is blocked
  when `Shell(git status)` is denied.

When changing these, verify rather than assume — a malformed entry fails open
(silently unmatched), it does not error.

**A project `.cursor/cli.json` replaces the global permission set, it does not
merge with it.** A repo-local permissions file must therefore restate every
global allow or the repo silently loses them. Prefer keeping one global set.

Cursor rewrites `~/.config/cursor/cli-config.json` on startup, appending
generated state next to the managed keys (`authInfo`, `selectedModel`, `model`,
`sandbox`, `network`, `runEverythingSettingsPromptStreak`, …). Two consequences:

- `bootstrap.sh` overwrites that state. This is safe — the auth *token* lives in
  the macOS keychain, so you stay logged in and `authInfo` repopulates on next
  launch — but it does reset model choice and display prefs.
- **Never copy the live file back into the repo.** Its `authInfo` carries
  `email`, `userId`, `teamId` and `teamName`. `config/cursor/cli-config.json` is
  hand-maintained and deliberately contains only managed keys.

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
keep the push on its own line, unquoted, and follow up in a separate command. The
one exception is `cd <dir> && git push …`, which the guard normalizes and judges as
the push it is — the approval then covers the whole command, `cd` included.

The guard decides how you may push, never whether — push only when the request
calls for it, and never restructure a command to dodge a prompt.

Enforced by `.claude/hooks/git-push-guard.sh`, registered in `.claude/settings.json`
— both committed, so the rule and the permission travel with the repo rather than
living on one machine. This repo sets no `branchPrefixes`, so the list above is
the guard's own built-in default rather than anything named in `settings.json`. That file also carries an `ask`
rule on `master` destinations, so a push that names the default branch is refused
even when the hook does not run at all. That rule matches the command text, so
it only catches a push that spells `master` out: `git push origin HEAD`, a bare
`git push`, or `git push origin` with no refspec still reach `master` without
matching it. The hook catches those; the floor is a second line, not an equal one.
