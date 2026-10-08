---
description: This machine's environment and the owner's working baseline, for every session.
alwaysApply: true
---

# Cursor: user-level rules

Generated from dotfiles `agents/`: edit there, run `agents/render.sh`, then sync. Cursor does
not read `~/.claude/CLAUDE.md`, so this rule carries the shared core.

## Cursor configuration

- `cli-config.json` is XDG-resolved (`~/.config/cursor/`); `mcp.json` and `rules/` are in
  `~/.cursor/`. Cursor writes state into the live `cli-config.json`, which is never copied back
  into dotfiles.
- Cursor reads a repo's `AGENTS.md` and `CLAUDE.md` (following its `@` imports),
  `.claude/skills`, `.claude/agents`, and `enabledPlugins` and hooks from `.claude/settings*.json`
  natively. At user level it also reads `~/.claude/skills` and `~/.agents/skills` and enabled
  Claude plugins. It honours `enabledPlugins` `false` but ignores `skillOverrides`, so the synced
  skills hidden from Claude Code are listed here.
- Permissions are `Shell(...)` entries in `cli-config.json` and are not restated here; Claude's
  `Bash(...)` entries never match.
- Repos' Claude hooks run as above.
