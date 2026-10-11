# Pi on this machine

For Pi's generic configuration and documentation, load the `pi-config` skill. This file covers how
this machine sets Pi up.

## Files and owners

Pi's agent directory is `~/.pi/agent/` (or `$PI_CODING_AGENT_DIR`).

| Path | Owner | Change it by |
| --- | --- | --- |
| `AGENTS.md` | Generated from dotfiles `agents/` | Editing dotfiles `agents/` (its `README.md`) |
| `settings.json`, `mcp.json`, `auth.json`, `models-store.json`, `sessions/` | Pi; untracked | `pi install`, `pi remove`, `pi mcp`, `/mcp` |
| `skills/context7-mcp` | A link to ctx7's Claude Code skill, written by `./setup.sh pi` | `./setup.sh pi` |

Only `AGENTS.md` is tracked; the sync never deletes Pi's own files. The binary comes from Nix.

## Skills, packages and MCP servers

- `./setup.sh pi` installs the user-level packages with `pi install <dir>`: dotfiles `agents/`
  (for `my-machine-configs`), tapppi/skills `tapppi/pi-config`, and `frontend-design` from Claude
  Code's clone of its marketplace. It also adds context7 to `mcp.json` when the entry is missing;
  context7 inherits `CONTEXT7_API_KEY` from the environment.
- A repo's own Pi config (`.pi/settings.json`) loads only after `/trust` in that repo, an owner
  step.

Deeper: `~/project/github/tapppi/macos-setup/docs/skills.md` and
`~/project/github/tapppi/macos-setup/docs/harnesses.md`.
