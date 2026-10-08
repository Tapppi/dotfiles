# Claude Code: user-level instructions

Generated from dotfiles `agents/`: edit there, run `agents/render.sh`, then sync. A hand edit
here is lost at the next sync.

## Claude Code configuration

- `settings.json`, `keybindings.json` and `statusline-command.sh` are synced from dotfiles
  `home/.claude/`, whose README explains the choices. A setting changed inside Claude Code
  (`/model`, effort, `/skills`) lands in the live `settings.json`, and the next sync overwrites it
  unless dotfiles carries it too.
- `~/.claude.json` holds MCP servers and session state and is not tracked. Its context7 entry
  reads the key from the environment.
- Tools write their own parts, and re-running the tool restores them, rather than editing: herdr's
  SessionStart hook in the live `settings.json` and `~/.claude/hooks/`; ctx7's
  `~/.claude/skills/context7-mcp/`, `~/.claude/rules/context7.md` and context7 MCP entry.
  Re-running `ctx7 setup` writes the plain key back into `~/.claude.json`.
- claude.ai sync writes `~/.claude/skills/synced/` and `~/.claude/plugins/synced/`, and
  `skillOverrides` in `settings.json` hides synced skills by name.

## Plugins, hooks and permissions

- Marketplaces are registered in `extraKnownMarketplaces`, with the tapppi-skills and ikeh
  checkouts as directory sources. A small user-scope set is enabled in `enabledPlugins`, where an
  explicit `false` also keeps a plugin off in OpenCode and Cursor. Other plugins are enabled per
  repo (committed `enabledPlugins`, or local scope) and installed on each machine with
  `claude plugin install <plugin>@<marketplace> --scope local`; a user-scope install would enable
  the plugin everywhere.
- User-level hooks are herdr's SessionStart and those of the user-scope plugins. Repos add hooks
  through their plugins and document them.
- Permissions are configured in `settings.json` `permissions` and in each repo's
  `.claude/settings.json`; this file does not restate them.
