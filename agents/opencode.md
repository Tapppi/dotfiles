# OpenCode: user-level instructions

Generated from dotfiles `agents/`: edit there, run `agents/render.sh`, then sync. While this
file exists, OpenCode does not read `~/.claude/CLAUDE.md`.

## OpenCode configuration

- `opencode.json` is synced from dotfiles `config/opencode/` and loads no npm plugins. herdr owns
  its own plugin and TUI files in that directory. The binary comes from Nix.
- Provider credentials live in the untracked `~/.local/share/opencode/auth.json`; never copy them
  into a repository.
- Skills come from a repo's `.agents/skills` and `.claude/skills`, `~/.agents/skills`,
  `~/.claude/skills` and the directories configured in `opencode.json`. ikeh-development's route
  agents and hook have no OpenCode form, so its route dispatch does not resolve here.

## Claude Code compatibility

- OpenCode reads Claude Code's skill directories, and `~/.claude/CLAUDE.md` when this file is
  absent. It loads no Claude Code plugins, hooks or MCP servers; its own MCP servers are configured
  in `opencode.json`.
- Synced claude.ai skills that depend on claude.ai's app or connectors are denied here; do not load
  one through its slash command, which bypasses the deny.

## Permissions and hooks

- Permission rules live in `opencode.json`; this file does not restate them.
- Claude hooks do not run here, so git guard hooks that repos enable for Claude Code do not apply,
  but the repo's documented rules still do.
