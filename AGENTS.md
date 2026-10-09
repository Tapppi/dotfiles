# AGENTS.md - dotfiles

Shell dotfiles and configs for macOS. Synced to `~` via `bootstrap.sh`.

Parent repo: [macos-setup](https://github.com/tapppi/macos-setup) — see its
AGENTS.md for the full setup automation context.

## Repository Structure

```text
dotfiles/
  home/                       # rsync → ~/
    .bash_profile             # Sources ~/.config/bash/.bash_profile
    .bashrc                   # Delegates to .bash_profile for interactive shells
    .claude/                  # Claude Code: settings.json, keybindings.json, statusline-command.sh,
                              # CLAUDE.md (generated from agents/); no XDG support
    .codex/AGENTS.md          # Codex user-level instructions (generated from agents/)
    .cursor/                  # Cursor CLI: mcp.json, cli-config.json (fallback copy),
                              # rules/00-environment.mdc (generated from agents/)
    .hushlogin                # Suppress login banner
    .parallel/will-cite       # Silence GNU parallel citation warning
    .pi/agent/AGENTS.md       # Pi user-level instructions (generated from agents/)
  config/                     # rsync → ~/.config/
    bash/.aliases             # Shell aliases (g=git)
    bash/.exports             # Environment variables, XDG dirs (EDITOR=nvim)
    bash/.functions           # Shell utility functions
    bash/.bash_profile        # Main profile (sources all the above + activates mise, zoxide)
    bash/.bash_prompt         # Solarized Dark prompt with git status
    curlrc                    # curl config
    cursor/cli-config.json    # Cursor CLI settings/permissions (live copy; XDG-resolved)
    fd/                       # fd ignore patterns
    gh/config.yml             # GitHub CLI config (ssh protocol, no prompts).
                              # Auth state (hosts.yml) is untracked — `gh auth login` owns it.
    ghostty/                  # Ghostty terminal config
    git/config                # Git aliases, diff-so-fancy, 1Password SSH signing
    git/ignore                # Global gitignore
    karabiner/                # Karabiner-Elements keyboard remapping
    lazygit/                  # Lazygit TUI config
    micro/                    # Micro editor settings
    mise/                     # Mise runtime version manager config
    nnn/                      # nnn file manager plugins
    opencode/                 # OpenCode config + AGENTS.md (generated from agents/)
    readline/inputrc          # Readline key bindings and completion settings
    ripgrep/                  # Ripgrep defaults
    terminal/                 # Terminal.app Solarized themes
    tmux/tmux.conf            # tmux with Ctrl+A prefix, vim keys, pbcopy
    wgetrc                    # wget config
  agents/                     # Sources of the user-level agent instructions + render.sh
  bootstrap.sh                # rsync home/→~/ and config/→~/.config/
  keyboard-layouts/           # Custom Finnish Programmer keyboard layout
```

The parent repo's `.extra` and `.path` are not in this repo but land in the same
place: `install_dotfiles` copies them into `~/.config/bash/` during install.

## Build / Lint

No build system or test suite. Validate shell scripts, and check that the generated agent
instructions match their sources:

```sh
shellcheck bootstrap.sh config/bash/.functions agents/render.sh
agents/render.sh --check
```

## Generated agent instructions

The user-level instruction files are rendered from `agents/`: `core.md` is the shared
environment core, and `claude-code.md`, `codex.md`, `opencode.md`, `cursor.md` and `pi.md` are the
harness headers. `agents/render.sh` writes header plus core into each output, and the outputs
are committed and deployed by the ordinary sync:

| Header | Output | Deployed to |
| --- | --- | --- |
| `claude-code.md` | `home/.claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `codex.md` | `home/.codex/AGENTS.md` | `~/.codex/AGENTS.md` |
| `opencode.md` | `config/opencode/AGENTS.md` | `~/.config/opencode/AGENTS.md` |
| `cursor.md` | `home/.cursor/rules/00-environment.mdc` | `~/.cursor/rules/00-environment.mdc` |
| `pi.md` | `home/.pi/agent/AGENTS.md` | `~/.pi/agent/AGENTS.md` |

- Edit `agents/`, run `agents/render.sh`, and commit the sources and outputs together. Never
  edit an output by hand: `agents/render.sh --check` fails on a hand edit or a stale render.
- Harness permissions live in harness config (`settings.json`, `cli-config.json`, Codex's config
  layers). The instruction files say where they are configured, never what the rules are.
- The ChatGPT/Codex app's custom-instructions pane writes `~/.codex/AGENTS.md`, and the next
  sync overwrites that edit; carry a wanted change into `agents/`.
- Pi reads one user-level context file, `AGENTS.override.md`, `AGENTS.md` or `CLAUDE.md` (first
  match) in `~/.pi/agent/` (or `$PI_CODING_AGENT_DIR`), then one per directory from the
  filesystem root down to the working directory, all concatenated. It never reads
  `~/.claude/CLAUDE.md` or follows `@` imports, and `--no-context-files` turns discovery off.
  `/reload` re-reads the files in a running session. Only `AGENTS.md` is tracked under
  `home/.pi/agent/`: `settings.json`, `auth.json`, `models-store.json` and `sessions/` belong to
  Pi, and the plain rsync never deletes them. Do not render `SYSTEM.md` or `APPEND_SYSTEM.md`,
  which replace or extend Pi's own system prompt.

## Syncing to Home Directory

`bootstrap.sh` runs two rsyncs:
1. `home/` → `~/` (home-level dotfiles that don't support XDG)
2. `config/` → `~/.config/` (XDG-compliant config)

`--delete` is never applied to either sync — it would wipe untracked files in
`~` and `~/.config`. dotfiles no longer writes any global OpenCode skills
directory; where the harnesses look for skills is documented in the parent
`macos-setup` repo's `docs/skills.md`, not restated here.

Keyboard layouts are copied separately to `~/Library/Keyboard Layouts/`.

Every rsync's exit status is checked and the script exits with the first
failure's own rsync code, which macos-setup's `install_dotfiles` gates its
tool-integration steps on. `bootstrap.sh` has the details.

### Tool-owned config inside tracked files

Some tools write their own config into paths this repo tracks:

- `ctx7 setup --claude --oauth` writes `~/.claude/skills/context7-mcp/` and
  `~/.claude/rules/context7.md`. macos-setup's install runs it only in that form and then
  points the context7 MCP entry at `CONTEXT7_API_KEY`; a plain `ctx7 setup` writes the
  key into `~/.claude.json`, and `--codex` appends to `~/.codex/AGENTS.md`.
- `herdr integration install claude` writes
  `~/.claude/hooks/herdr-agent-state.sh` and a `SessionStart` entry in
  `~/.claude/settings.json`.
- `herdr integration install codex` writes `~/.codex/herdr-agent-state.sh` and
  `~/.codex/hooks.json`, beside the tracked `~/.codex/AGENTS.md`.
- `herdr integration install cursor` writes `~/.cursor/herdr-agent-state.sh` and a
  `sessionStart` entry in `~/.cursor/hooks.json`.
- `herdr integration install opencode` writes `plugins/herdr-agent-state.js`,
  `herdr-tui-session.js`, `herdr-opencode/` and `tui.jsonc` in `~/.config/opencode/`.

None of it is vendored here. These commands run from macos-setup's
`tasks/install.sh` **after** `bootstrap.sh`, so the sync drops the tool's key and
the tool writes it straight back. That ordering is the whole mechanism, and it is
why the tracked `settings.json` carries no `hooks` key while the live one does.

Do not copy a tool-written key into `home/` — that means tracking a hook path and
payload the tool owns and rewrites between versions, which goes stale silently on
the next upgrade. If one is missing from `~`, re-run the writing command through
macos-setup instead (`./setup.sh herdr` for herdr, `./setup.sh context7` for ctx7 and the
context7 MCP entries).

**`~/.claude/skills/` and `~/.claude/hooks/` are not dotfiles' to manage.** The
tools that write them own them, this repo tracks neither, and bootstrap leaves
both alone — so no mirror and no mirror exclude is needed for either.

## Agent CLI config locations

| Agent       | User-level config dir | Settings file       | User-level rules          | MCP config           |
|-------------|----------------------|---------------------|--------------------------|---------------------|
| Claude Code | `home/.claude/`      | `settings.json`     | `CLAUDE.md` (generated)  | `~/.claude.json` (untracked) |
| Codex       | `home/.codex/`       | `~/.codex/config.toml` (untracked, Codex-owned) over systems' `/etc/codex/config.toml` | `AGENTS.md` (generated) | `~/.codex/config.toml` (untracked) |
| Cursor CLI  | `home/.cursor/` **and** `config/cursor/` | `config/cursor/cli-config.json` | `home/.cursor/rules/00-environment.mdc` (generated) | `home/.cursor/mcp.json` |
| OpenCode    | `config/opencode/`   | `opencode.json`     | `AGENTS.md` (generated)  | `opencode.json` (`mcp`) |
| Pi          | `home/.pi/agent/` (only `AGENTS.md`) | `~/.pi/agent/settings.json` (untracked, Pi-owned) | `AGENTS.md` (generated) | `~/.pi/agent/mcp.json` (Pi-owned, untracked) |

Codex's two layers: systems' `modules/darwin/codex.nix` writes `/etc/codex/config.toml` (model,
effort, sandbox, approvals, the hooks feature, no self-update for the Nix binary), and Codex itself
writes `~/.codex/config.toml` (project trust, TUI, hook trust hashes, marketplaces, plugins, MCP
servers), whose keys override the system layer one by one.

Agent skills are not in that table: they are not dotfiles' to manage. See
[Tapppi/skills](https://github.com/Tapppi/skills) for the shared bundles, and
the parent `macos-setup` repo's `docs/skills.md` for how capability reaches a
repo.

## Cursor CLI config splits across two directories

`cursor-agent` does not resolve all its config from one place, and getting this
wrong silently disables the file rather than erroring:

- **`cli-config.json` follows XDG**: `$CURSOR_CONFIG_DIR` → `$XDG_CONFIG_HOME/cursor`
  → `~/.cursor`. `.exports` sets `XDG_CONFIG_HOME=~/.config`, so the live file is
  `~/.config/cursor/cli-config.json` (synced from `config/cursor/`). An identical
  copy at `home/.cursor/cli-config.json` covers the fallback path when
  `XDG_CONFIG_HOME` is unset — keep the two byte-identical.
- **Everything else is hardcoded to `~/.cursor/`** regardless of XDG: `mcp.json`,
  `rules/`, `skills/`, `agents/`, `commands/`, `hooks.json`. Of these, only `mcp.json`
  and `rules/` (plus the `cli-config.json` fallback copy) are tracked in `home/.cursor/`;
  `hooks.json` is herdr's, and the others are not managed here.

Cursor natively reads much of the Claude Code setup — repo `AGENTS.md` and
`CLAUDE.md` (following its `@` imports), `.claude/skills/**/SKILL.md`,
`.claude/agents/**`, `~/.claude/commands/`,
`enabledPlugins` and hooks from `.claude/settings*.json` — so it needs no
mirroring. It does **not** read `~/.claude/CLAUDE.md` (hence the generated
`home/.cursor/rules/00-environment.mdc`) or Claude's `Bash(...)` permission entries
(Cursor's shell tool is `Shell(...)`, so those load but never match).

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
- Markdown (`.md`, `.mdc`): spaces, two-space list indentation, prose wrapped at 100 columns
  (tables and a single long link or code span may overflow), fenced code with a language

## Git Conventions

- This repo uses `master` branch
- Commits are SSH-signed through 1Password (`gpg.format = ssh`, `op-ssh-sign`)
- Commit messages: imperative mood, concise (e.g. "Update Ghostty config")
- Once a change lands on `master` here, the parent macos-setup repo records the new
  submodule pointer (`git add dotfiles`, commit "Update dotfiles").

### Git Identity and Attribution

- **NEVER** add AI attribution to commits (no `Co-authored-by`, no
  `Ultraworked with`, no agent signatures in commit bodies or trailers).
  Commits must look like normal developer commits.
- **NEVER** change `user.name`, `user.email`, or any git identity
  configuration. The repository owner's identity must remain on all commits.
- A commit that cannot be signed follows the user-level *Commit signing* rules
  (generated from `agents/core.md`); the identity never changes.

### Do Not Run Setup Scripts

- **NEVER** run `bootstrap.sh` automatically. This script
  syncs files to `~`. The user must always run it manually.

### Edit Source Files Here, Not in `~/`

**NEVER** edit deployed files directly in `~/`, `~/.claude/`, `~/.codex/`,
`~/.cursor/` or `~/.config/`. Edit the source in `home/` or `config/` here, then copy the
changed file to its destination (`cp home/.claude/foo ~/.claude/foo`). The home
directory copies are deployment targets; this repo is the source of truth.

The generated instruction files are edited one step further back, in `agents/`
(see *Generated agent instructions*). The exception is config a tool writes into
a path this repo tracks (see *Tool-owned config inside tracked files* above),
which the tool re-asserts and this repo never vendors.

### Files to Never Commit

- `.credentials`, API keys, tokens, passwords
- `.DS_Store`, `Thumbs.db`, `._*`
- Backup tarballs

## Git workflows and pushing branches

Git work here follows the `ikeh-git:git-workflows` skill from the `ikeh-git`
plugin, which `.claude/settings.json` enables; load it before the first commit.
The plugin's two guards run on every Bash call:

- **Push guard.** A push to `origin` of an agent branch — `agent/`, any
  conventional-commit prefix, `debug/` or `backup/`, the plugin's default list,
  since this repo sets no `branchPrefixes` — runs without a prompt, including
  `--force-with-lease --force-if-includes` until the branch's PR carries a review
  or comment. Every other push prompts: `master`, other destinations, plain
  `--force`/`-f`, deletes, another remote. Name the branch on each push. The
  `ask` rules on `master` still prompt for any push whose text contains `main`
  or `master`, so keep those words out of agent branch names.
- **Worktree guard.** Whole-tree staging (`git add -A`, `git commit -a` and their
  relatives) in the main checkout is denied, and so is any rebase of `master`.
  `requireWorktree` is off here, so a small change may still be committed from the
  main checkout by explicit path.

```bash
git push -u origin agent/<name>
git push --force-with-lease --force-if-includes origin agent/<name>
```

The guard decides how you may push, never whether: push only when the request
calls for it, and answer a prompt rather than reshaping the command until it
stops. The `ask` rules on `master` in `.claude/settings.json` are a backstop for
when the hook does not run, not a rule to reason from.

Committed enablement installs nothing. On a new machine, run
`claude plugin install ikeh-git@ikeh --scope local` in this repo; the parent
macos-setup `tasks/install.sh` registers the `ikeh` marketplace.
