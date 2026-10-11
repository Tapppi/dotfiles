# Cursor on this machine

## Files and owners

| Path | Owner | Notes |
| --- | --- | --- |
| `~/.config/cursor/cli-config.json` | dotfiles `config/cursor/` | Settings and `Shell(...)`/`Mcp(...)` permissions; XDG-resolved |
| `~/.cursor/cli-config.json` | dotfiles `home/.cursor/` | Fallback copy when `XDG_CONFIG_HOME` is unset; byte-identical to the first |
| `~/.cursor/mcp.json` | dotfiles `home/.cursor/` | No user-level MCP servers |
| `~/.cursor/rules/00-environment.mdc` | Generated from dotfiles `agents/` | Cursor does not read `~/.claude/CLAUDE.md` |
| `~/.cursor/hooks.json`, `~/.cursor/herdr-agent-state.sh` | herdr | `./setup.sh herdr` |

Cursor rewrites the live `cli-config.json` at start with generated state (`authInfo`, model,
sandbox and more). The sync overwrites that state, which is safe, but never copy the live file
back into dotfiles: `authInfo` carries account details.

## What Cursor reads

- From a repo: `AGENTS.md` and `CLAUDE.md` (following `@` imports), `.claude/skills`,
  `.claude/agents`, and `enabledPlugins` and hooks from `.claude/settings*.json`.
- At user level: `~/.claude/skills`, `~/.agents/skills`, `~/.codex/skills`, `~/.claude/commands/`
  and enabled Claude Code plugins, so it lists `my-machine-configs` and `context7-mcp` twice. It
  honours `enabledPlugins: false` but ignores `skillOverrides`.
- A repo's Claude Code plugin loads in Cursor only through an install record made in the repo's
  main checkout (macos-setup `docs/skills.md`); in worktrees it may not load. Claude's
  `Bash(...)` permission entries never match Cursor's `Shell(...)` tool.

## Known gaps

A Cursor configuration refresh (duplicate skills, plugins in worktrees, ctx7's skill pointing at
a server Cursor no longer has) is pending as a separate task.

After `brew upgrade --cask cursor-cli`, the cask is quarantined again and every `cursor-agent`
run fails with `library load disallowed by system policy`. The owner clears it with
`xattr -dr com.apple.quarantine "$(brew --prefix)/Caskroom/cursor-cli"`.

Deeper: `~/project/github/tapppi/macos-setup/dotfiles/docs/harnesses.md` (the two config
directories and the `Shell(...)` permission syntax).
