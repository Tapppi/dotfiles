# OpenCode: user-level instructions

Generated from dotfiles `agents/`: edit there, run `agents/render.sh`, then sync. While this
file exists, OpenCode does not read `~/.claude/CLAUDE.md`.

## OpenCode configuration

- `opencode.json` (plugins `oh-my-openagent` and `opencode-claude-auth`, skill paths, TUI) and
  `oh-my-openagent.json` (agent and category models, Claude Code compatibility) are synced from
  dotfiles `config/opencode/`. herdr writes `plugins/herdr-*.js` and `tui.jsonc`. The binary comes
  from Nix.
- npm plugins are listed in `opencode.json`; OpenCode has no marketplace. Skills come from a
  repo's `.agents/skills` and `.claude/skills`, `~/.agents/skills`, `~/.claude/skills`, and the
  `skills.paths` in `opencode.json`, which bring in `browser` and `frontend-design`.

## Claude Code compatibility

- oh-my-openagent loads Claude Code plugins, user-scope ones everywhere and a local-scope one only
  in the project of its first recorded install, unless the user `settings.json` or its
  `plugins_override` sets them `false`; a repo's local enablement is not read. Here `codex` is
  off, and the document skills, `browser` and `frontend-design` are available.
- It also loads MCP servers from `~/.claude.json` and `.mcp.json` files (context7 among them) and
  Claude hooks, herdr's included.
- OpenCode itself reads `~/.claude/skills/`, claude.ai-synced skills included, which
  `skillOverrides` does not hide.

## Permissions and hooks

- Permission rules would live in `opencode.json`; this file does not restate them.
- Claude hooks run here: a hook's deny blocks the call, but an `ask` verdict does not prompt, so
  the command runs. herdr's own OpenCode plugin also runs.
