---
description: This machine's environment and the owner's working baseline, for every session.
alwaysApply: true
---

# Cursor: user-level rules

Generated from dotfiles `agents/`: edit there, run `agents/render.sh`, then sync. Cursor does
not read `~/.claude/CLAUDE.md`, so this rule carries the shared core.

## Cursor configuration

- `cli-config.json` is XDG-resolved (`~/.config/cursor/`, with an identical fallback copy in
  `~/.cursor/`); `mcp.json` and `rules/` are in `~/.cursor/`. Cursor writes state into the live
  `cli-config.json`, which is never copied back into dotfiles.
- Cursor reads a repo's `CLAUDE.md`, `.claude/skills`, `.claude/agents`, and `enabledPlugins` and
  hooks from `.claude/settings*.json` natively.
- Permissions are `Shell(...)` entries in `cli-config.json` and are not restated here; Claude's
  `Bash(...)` entries never match.
- herdr's `sessionStart` hook is in `~/.cursor/hooks.json` (herdr-owned, untracked); repos' Claude
  hooks run as above.
