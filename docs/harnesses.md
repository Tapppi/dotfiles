# Agent harness config

Where each agent harness keeps its user-level config, which parts this repo tracks, and which
parts the harness or another tool owns. How macos-setup installs the harnesses is in its
`docs/harnesses.md`, and how skills and plugins reach a repo is in its `docs/skills.md`.

## Config locations

| Agent | Tracked here | Settings | User-level rules | MCP config |
| --- | --- | --- | --- | --- |
| Claude Code | `home/.claude/` | `settings.json` | `CLAUDE.md` (generated) | `~/.claude.json` (untracked) |
| Codex | `home/.codex/` (only `AGENTS.md`) | `~/.codex/config.toml` (untracked, Codex-owned) over systems' `/etc/codex/config.toml` | `AGENTS.md` (generated) | `~/.codex/config.toml` |
| Cursor CLI | `home/.cursor/` and `config/cursor/` | `config/cursor/cli-config.json` | `home/.cursor/rules/00-environment.mdc` (generated) | `home/.cursor/mcp.json` (no servers) |
| OpenCode | `config/opencode/` | `opencode.json`, `tui.json` | `AGENTS.md` (generated) | `opencode.json` (`mcp`) |
| Pi | `home/.pi/agent/` (only `AGENTS.md`) | `~/.pi/agent/settings.json` (untracked, Pi-owned) | `AGENTS.md` (generated) | `~/.pi/agent/mcp.json` (untracked, Pi-owned) |

Codex has two layers. systems' `modules/darwin/codex.nix` writes `/etc/codex/config.toml` (model,
effort, sandbox, approvals, the hooks feature, no self-update for the Nix binary), and Codex itself
writes `~/.codex/config.toml` (project trust, TUI, hook trust hashes, marketplaces, plugins, MCP
servers), whose keys override the system layer one by one.

Pi owns everything in `~/.pi/agent/` except `AGENTS.md`: `settings.json`, `mcp.json`, `auth.json`,
`models-store.json` and `sessions/`. The rsync never deletes them.

Skills are not in the table: this repo tracks none of the harnesses' skill directories. The one
user-level skill it holds, `agents/skills/my-machine-configs/`, reaches the harnesses through
links and packages that macos-setup's install writes ([agents/README.md](../agents/README.md)).

## Tool-owned config inside tracked paths

Some tools write their own config into paths this repo tracks:

- `ctx7 setup --claude --oauth` writes `~/.claude/skills/context7-mcp/` and
  `~/.claude/rules/context7.md`. macos-setup's install runs it only in that form and then points
  the context7 MCP entry at `CONTEXT7_API_KEY`; a plain `ctx7 setup` writes the key into
  `~/.claude.json`, and `--codex` appends to `~/.codex/AGENTS.md`.
- `herdr integration install claude` writes `~/.claude/hooks/herdr-agent-state.sh` and a
  `SessionStart` entry in `~/.claude/settings.json`.
- `herdr integration install codex` writes `~/.codex/herdr-agent-state.sh` and
  `~/.codex/hooks.json`, beside the tracked `~/.codex/AGENTS.md`.
- `herdr integration install cursor` writes `~/.cursor/herdr-agent-state.sh` and a
  `sessionStart` entry in `~/.cursor/hooks.json`.
- `herdr integration install opencode` writes `plugins/herdr-agent-state.js`,
  `herdr-tui-session.js`, `herdr-opencode/` and `tui.jsonc` in `~/.config/opencode/`.

None of it is vendored here. These commands run from macos-setup's `tasks/install.sh` **after**
`bootstrap.sh`, so the sync drops the tool's key and the tool writes it straight back. That
ordering is the whole mechanism, and it is why the tracked `settings.json` carries no `hooks` key
while the live one does.

Do not copy a tool-written key into `home/`: that tracks a hook path and payload the tool owns and
rewrites between versions, which goes stale silently on the next upgrade. If one is missing from
`~`, re-run the writing command through macos-setup instead (`./setup.sh herdr` for herdr,
`./setup.sh context7` for ctx7 and the context7 MCP entries).

## Cursor CLI config splits across two directories

`cursor-agent` does not resolve all its config from one place, and getting this wrong silently
disables the file rather than erroring:

- **`cli-config.json` follows XDG**: `$CURSOR_CONFIG_DIR`, then `$XDG_CONFIG_HOME/cursor`, then
  `~/.cursor`. `.exports` sets `XDG_CONFIG_HOME=~/.config`, so the live file is
  `~/.config/cursor/cli-config.json` (synced from `config/cursor/`). An identical copy at
  `home/.cursor/cli-config.json` covers the fallback path when `XDG_CONFIG_HOME` is unset; keep the
  two byte-identical.
- **Everything else is hardcoded to `~/.cursor/`** regardless of XDG: `mcp.json`, `rules/`,
  `skills/`, `agents/`, `commands/`, `hooks.json`. Of these, only `mcp.json` and `rules/` (plus
  the `cli-config.json` fallback copy) are tracked in `home/.cursor/`; `hooks.json` is herdr's, and
  the others are not managed here.

Cursor natively reads much of the Claude Code setup: a repo's `AGENTS.md` and `CLAUDE.md`
(following its `@` imports), `.claude/skills/**/SKILL.md`, `.claude/agents/**`,
`~/.claude/commands/`, and `enabledPlugins` and hooks from `.claude/settings*.json`. So it needs no
mirroring. It does **not** read `~/.claude/CLAUDE.md` (hence the generated
`home/.cursor/rules/00-environment.mdc`) or Claude's `Bash(...)` permission entries.

### Shell permission syntax: spaces, not colons

Verified empirically against `cursor-agent 2026.08.11`:

- `Shell(<cmd>)` matches that command with any arguments (`Shell(tree)` permits `tree -L 1`).
- Subcommands are space-separated and prefix-matched: `Shell(git status)` matches
  `git status --short`.
- **The colon form does nothing for `Shell`**: `Shell(git:push)` never matches `git push`. Colons
  are only for `Mcp(server:tool)`.
- `deny` beats `allow`, and chaining (`a && b`) does not bypass a deny.

A malformed entry fails open (silently unmatched) rather than erroring, so verify changes instead
of assuming. A project `.cursor/cli.json` **replaces** the global permission set rather than
merging with it, so prefer one global set over repo-local deltas.

Cursor rewrites `~/.config/cursor/cli-config.json` on startup, appending generated state
(`authInfo`, `selectedModel`, `model`, `sandbox`, `network` and more) beside the managed keys.
`bootstrap.sh` overwrites that state, which is safe (the auth token lives in the macOS keychain, so
you stay logged in), but it resets model and display preferences. **Never copy the live file back
into the repo**: its `authInfo` carries account details.
