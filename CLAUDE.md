@AGENTS.md

# Claude Code specifics

- **User-level Claude config is `home/.claude/`** — `settings.json`,
  `CLAUDE.md`, `keybindings.json`, `statusline-command.sh`. MCP servers live in
  `~/.claude.json`, which is untracked because it carries generated state; the
  parent repo's `tasks/install.sh` writes them.
- **Cursor reads much of this setup natively** (repo `CLAUDE.md`,
  `.claude/skills/**/SKILL.md`, `.claude/agents/**`, `~/.claude/commands/`,
  `enabledPlugins` and hooks from `.claude/settings*.json`), so most of it needs
  no Cursor-specific mirror.
