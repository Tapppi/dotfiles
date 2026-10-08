# OpenCode: user-level instructions

Generated from dotfiles `agents/`: edit there, run `agents/render.sh`, then sync. While this
file exists, OpenCode does not read `~/.claude/CLAUDE.md`.

## OpenCode configuration

- `opencode.json` (default `model` and `small_model`, `skills.paths`, the context7 `mcp` entry,
  `permission.skill`, TUI) is synced from dotfiles `config/opencode/` and loads no npm plugins.
  herdr writes `plugins/herdr-agent-state.js`, `herdr-tui-session.js`, `herdr-opencode/` and
  `tui.jsonc`. The binary comes from Nix.
- Providers are ChatGPT (`openai`, OpenCode's built-in OAuth) and z.ai (`zai-coding-plan`),
  logged in with `opencode auth login`; their credentials stay in the untracked
  `~/.local/share/opencode/auth.json`.
- Skills come from a repo's `.agents/skills` and `.claude/skills`, `~/.agents/skills`,
  `~/.claude/skills`, and the `skills.paths` directories: `browser`, `frontend-design` and the
  ikeh-development plugin's skills from the ikeh checkout. Only the skills come across: the
  plugin's route agents and hook have no OpenCode form, so its route dispatch does not resolve here.

## Claude Code compatibility

- OpenCode reads Claude Code's skill directories, and `~/.claude/CLAUDE.md` when this file is
  absent. It loads no Claude Code plugins, hooks or MCP servers: context7 is its own `mcp` entry,
  which inherits `CONTEXT7_API_KEY` from the environment and runs anonymously without it.
- It also reads the claude.ai-synced skills in `~/.claude/skills/synced/`, which `skillOverrides`
  does not hide. `permission.skill` denies the ones that depend on claude.ai's app or connectors,
  which drops them from the skill list and refuses them in the `skill` tool; every skill is also a
  slash command, and a slash command can still load a denied one.

## Permissions and hooks

- Permission rules live in `opencode.json`; this file does not restate them.
- Claude hooks do not run here, so git guard hooks that repos enable for Claude Code do not apply,
  but the repo's documented rules still do. herdr's own OpenCode plugin runs.
