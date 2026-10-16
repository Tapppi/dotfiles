# OpenCode on this machine

For OpenCode's generic configuration, use its built-in `customize-opencode` skill.

## Files and owners

| Path | Owner | Notes |
| --- | --- | --- |
| `~/.config/opencode/opencode.json`, `tui.json` | dotfiles `config/opencode/` | Models, providers, `skills.paths`, MCP servers, permissions; TUI settings (default keybinds) |
| `~/.config/opencode/AGENTS.md` | Generated from dotfiles `agents/` | While it exists, OpenCode does not read `~/.claude/CLAUDE.md` |
| `plugins/herdr-agent-state.js`, `herdr-tui-session.js`, `herdr-opencode/`, `tui.jsonc` there | herdr | `./setup.sh herdr` |
| `~/.local/share/opencode/auth.json` | OpenCode; untracked | Provider logins through `opencode providers login`; never copied anywhere |
| `<repo>/opencode.json` | The repo | Per-repo config, such as plugins |

The binary comes from Nix. `./setup.sh opencode` checks the installed setup and prints hints; it
writes no OpenCode state.

## Skills, plugins and MCP servers

- Skills come from a repo's `.agents/skills` and `.claude/skills`, `~/.agents/skills`,
  `~/.claude/skills` (so `my-machine-configs` and ctx7's `context7-mcp` reach it from there) and
  the `skills.paths` in `opencode.json`, which add `frontend-design` and the `ikeh` plugin's skills.
- OpenCode loads no Claude Code plugins, hooks or MCP servers. Its own plugins are JS modules
  listed under `plugin`; the global config loads none, and a repo's root `opencode.json` can add
  some.
- MCP servers are `mcp` entries in `opencode.json`; context7 inherits `CONTEXT7_API_KEY` from the
  environment.
- `permission` in `opencode.json` holds the permission rules; `permission.skill` denies the synced
  claude.ai skills that need claude.ai's app or connectors.

Deeper: `~/project/github/tapppi/macos-setup/dotfiles/README.md` (OpenCode notes) and
`~/project/github/tapppi/macos-setup/docs/skills.md`.
