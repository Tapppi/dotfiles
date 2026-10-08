# OpenCode: user-level instructions

Generated from dotfiles `agents/`: edit there, run `agents/render.sh`, then sync. While this
file exists, OpenCode does not read `~/.claude/CLAUDE.md`.

## OpenCode configuration

- `opencode.json` (plugins `oh-my-openagent` and `opencode-claude-auth`, `skills.paths`,
  `permission.skill`, TUI) and `oh-my-openagent.json` (agent and category models, Claude Code
  compatibility, `skills.sources`, `mcp_env_allowlist`) are synced from dotfiles
  `config/opencode/`. herdr writes `plugins/herdr-agent-state.js`, `herdr-tui-session.js`,
  `herdr-opencode/` and `tui.jsonc`. The binary comes from Nix.
- npm plugins are listed in `opencode.json`; OpenCode has no marketplace. Skills come from a
  repo's `.agents/skills` and `.claude/skills`, `~/.agents/skills`, `~/.claude/skills`, and the
  `browser` and `frontend-design` directories named in both `skills.paths` and `skills.sources`
  (oh-my-openagent's `skill` tool reads only the latter).

## Claude Code compatibility

- oh-my-openagent loads Claude Code plugins, user-scope ones everywhere and a local-scope one only
  in the project of its first recorded install, unless the user `settings.json` or its
  `plugins_override` sets them `false`; a repo's local enablement is not read. Here `codex` and
  the `document-skills` plugin are off; the claude.ai-synced document skills, `browser` and
  `frontend-design` are available.
- It also loads MCP servers from `~/.claude.json` and `.mcp.json` files (context7 among them) and
  Claude hooks, herdr's included. An MCP `${VAR}` whose name looks secret (`KEY`, `TOKEN` and the
  like) expands empty unless `mcp_env_allowlist` names it, as it does `CONTEXT7_API_KEY`.
- OpenCode reads `~/.claude/skills/`, claude.ai-synced skills included (named
  `synced/<bucket>/<name>`), which `skillOverrides` does not hide. Instead, `permission.skill`
  denies the synced skills that depend on claude.ai's app or connectors; they may still be listed.

## Permissions and hooks

- Permission rules live in `opencode.json`; this file does not restate them.
- Claude hooks run here: a hook's deny blocks the call, but an `ask` verdict does not prompt, so
  the command runs. herdr's own OpenCode plugin also runs.
