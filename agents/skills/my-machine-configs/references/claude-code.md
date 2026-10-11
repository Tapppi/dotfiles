# Claude Code on this machine

## Files and owners

| Path | Owner | Change it by |
| --- | --- | --- |
| `~/.claude/settings.json`, `keybindings.json`, `statusline-command.sh` | dotfiles `home/.claude/` (its `README.md` explains the choices) | Editing dotfiles, then syncing |
| `~/.claude/CLAUDE.md` | Generated from dotfiles `agents/` | Editing `agents/`, then `agents/render.sh` |
| `~/.claude.json` | Claude Code: user-scope MCP servers, session state | `claude mcp …`; never copy it into dotfiles |
| `~/.claude/hooks/` and the `hooks` key of the live `settings.json` | herdr | `./setup.sh herdr` |
| `~/.claude/skills/context7-mcp/`, `~/.claude/rules/context7.md` | ctx7 | `./setup.sh context7` |
| `~/.claude/skills/my-machine-configs` | A link into dotfiles' main checkout, written by `./setup.sh dotfiles` and `install` | Editing `agents/skills/` |
| `~/.claude/skills/synced/`, `~/.claude/plugins/synced/` | The claude.ai account sync | claude.ai; `skillOverrides` in `settings.json` hides synced skills by name |

A setting changed inside Claude Code (`/model`, effort, `/skills`, `/config`) lands in the live
`settings.json`, and the next sync overwrites it unless dotfiles carries it. Harness env vars go
in the `env` block of the tracked `settings.json`. The tracked file has no `hooks` key while the
live one does: herdr writes it back after every sync.

The context7 MCP entry in `~/.claude.json` takes its key from `CONTEXT7_API_KEY` in the
environment, never a literal. A plain `ctx7 setup` writes the key into that file; never run it.

## Plugins, skills and permissions

- Marketplaces are declared in `extraKnownMarketplaces` in the tracked `settings.json`; the
  user-level `enabledPlugins` there holds the small set every repo gets.
- A plugin for one repo is enabled in that repo's committed `.claude/settings.json`
  `enabledPlugins`; `browser@tapppi-skills` is enabled this way in macos-setup, tieto and ikeh.
  `claude plugin install` defaults to user scope, which enables a plugin in every repo, so pass
  `--scope project` or `--scope local`. macos-setup `docs/skills.md` has the per-machine steps.
- A workspace manifest (`.tapppi-project.json`) can enable plugins at local scope in its repos
  through `./setup.sh projects`; see the header of macos-setup `tasks/projects.sh`.
- Permissions live in `settings.json` `permissions` and in each repo's `.claude/settings.json`.
- Repos add hooks through their plugins, such as `ikeh-git`'s push and worktree guards.

Deeper: `~/project/github/tapppi/macos-setup/docs/harnesses.md` (what `install` does for Claude
Code) and `~/project/github/tapppi/macos-setup/docs/skills.md`.
