# AGENTS.md - dotfiles

Shell dotfiles, harness config and the user-level agent instructions for a Mac, synced into `~` by
`bootstrap.sh`. It is the `dotfiles` submodule of
[macos-setup](https://github.com/Tapppi/macos-setup), whose install runs the sync and the tool
steps around it; that repo's `AGENTS.md` covers the setup automation. The tracked files declare
what the live config should be. This repo is public: keep private values, account details and
secrets out of it.

## Layout

- `home/`: rsynced to `~/`, for files without XDG support (bash entry points, `.claude/`,
  `.codex/`, `.cursor/`, `.pi/` and a few more).
- `config/`: rsynced to `~/.config/` (bash, git, tmux, mise, OpenCode, Cursor and more).
- `agents/`: not synced. The sources of the user-level agent instructions, `render.sh`, which
  writes the five generated instruction files under `home/` and `config/`, and the user-level
  `my-machine-configs` skill. [agents/README.md](agents/README.md) explains them.
- `bootstrap.sh`: the two rsyncs, which never `--delete`; `keyboard-layouts/`.

[README.md](README.md) describes what is inside. [docs/harnesses.md](docs/harnesses.md) has each
agent harness's config locations, what this repo tracks, which files the tools own, and Cursor's
two config directories and permission syntax.

## Rules

- **Edit sources here, never the deployed copies** in `~/`, `~/.claude/`, `~/.codex/`,
  `~/.cursor/`, `~/.pi/` or `~/.config/`. Copy a changed file into place
  (`cp home/.claude/foo ~/.claude/foo`) or leave the sync to the owner.
- **Generated instruction files are edited in `agents/`.** Run `agents/render.sh` and commit
  sources and outputs together; never hand-edit an output.
- **Never vendor tool-written config.** herdr and ctx7 write into paths this repo tracks, and
  macos-setup re-runs them after every sync. Re-run the writing command (`./setup.sh herdr`,
  `./setup.sh context7`) instead of copying its output into `home/`.
- **Tool-owned files stay untracked**: `~/.claude.json`, `~/.codex/config.toml`, and Pi's
  `settings.json`, `mcp.json`, `auth.json`, `models-store.json` and `sessions/`.
- Dotfiles track nothing under `~/.claude/skills/` or `~/.claude/hooks/`, and bootstrap leaves
  both alone. Their entries belong to the tools that write them; the one exception is the
  `my-machine-configs` link, which macos-setup's install points back at `agents/skills/`.
- **Never copy Cursor's live `cli-config.json` back**: Cursor writes account details into it. Keep
  the two tracked `cli-config.json` copies byte-identical.
- **Never run `bootstrap.sh`**: it syncs into `~`, and the owner runs it.
- Never commit `.credentials`, API keys, tokens, passwords, `.DS_Store`, `Thumbs.db`, `._*` or
  backup tarballs.

## Checks

No build system or test suite. Validate shell scripts, and check that the generated instruction
files match their sources:

```sh
shellcheck bootstrap.sh config/bash/.functions agents/render.sh
agents/render.sh --check
```

## Style

`.editorconfig` sets the formatting: tabs (width 2) for code; for Markdown (`.md`, `.mdc`) spaces
with two-space list indentation, prose wrapped at 100 columns and fenced code with a language.
Shell scripts follow macos-setup's `docs/conventions.md`: `#!/usr/bin/env bash`, quoted
`"${variable}"` expansions, `[[ ]]`, lowercase names with underscores.

## Git

Git work here follows the `ikeh-git:git-workflows` skill from the `ikeh-git` plugin, which
`.claude/settings.json` enables; load it before the first commit. This repo uses `master`.
Commits are SSH-signed through 1Password, and messages are imperative and concise ("Update
Ghostty config"). Use the configured git identity, never change it, and add no AI attribution.
Once a change lands on `master`, macos-setup records the new submodule pointer (`git add dotfiles`,
commit "Update dotfiles").

The plugin's guards:

- **Push guard.** What it denies, asks about and lets through is in the skill's
  [push guard reference](https://github.com/mantadevoy/ikeh/blob/main/plugins/ikeh-git/skills/git-workflows/references/push-guard.md).
  This repo opts in with the plugin's default branch prefixes (`agent/` among them, since it sets
  no `branchPrefixes`) and `requireWorktree` off. Name the branch on each push, and keep `main` and
  `master` out of agent branch names: the `ask` rules prompt for any push whose text contains them.
- **Worktree guard.** Whole-tree staging in the main checkout is denied, and so is any rebase of
  `master`. `requireWorktree` is off, so a small change may be committed from the main checkout by
  explicit path.

The guard decides how you may push, never whether: push only when the request calls for it, and
answer a prompt rather than reshaping the command until it stops. Committed enablement installs
nothing: on a new machine, run `claude plugin install ikeh-git@ikeh --scope local` in this repo.
