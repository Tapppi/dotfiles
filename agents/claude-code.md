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
- Tool-written parts are restored by re-running the tool, not by editing: herdr's SessionStart
  hook in the live `settings.json` and `~/.claude/hooks/`, and ctx7's
  `~/.claude/skills/context7-mcp/` and `~/.claude/rules/context7.md`. macos-setup's
  `./setup.sh context7` (an owner step; it needs sudo) restores ctx7's files and keeps the
  context7 MCP entry on `CONTEXT7_API_KEY`. Never run a plain `ctx7 setup`, which writes the key
  into `~/.claude.json`; `ctx7 setup --claude --oauth` restores the skill and rule but also
  replaces the context7 entry with a keyless one, so follow a hand run with
  `./setup.sh context7` to put the `CONTEXT7_API_KEY` form back.
- claude.ai sync writes `~/.claude/skills/synced/` and `~/.claude/plugins/synced/`, and
  `skillOverrides` in `settings.json` hides synced skills by name.

## Plugins, hooks and permissions

- Marketplaces are registered in `extraKnownMarketplaces`, with the tapppi-skills and ikeh
  checkouts as directory sources. A small user-scope set is enabled in `enabledPlugins`, which
  Cursor also reads. Other plugins are enabled per repo (committed `enabledPlugins`, or local
  scope) and installed on each machine with
  `claude plugin install <plugin>@<marketplace> --scope local`; a user-scope install would enable
  the plugin everywhere.
- User-level hooks are herdr's SessionStart and those of the user-scope plugins. Repos add hooks
  through their plugins and document them.
- Permissions are configured in `settings.json` `permissions` and in each repo's
  `.claude/settings.json`; this file does not restate them.
