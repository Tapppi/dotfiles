# OpenCode: user-level instructions

Generated from dotfiles `agents/`; a hand edit here is lost at the next sync.

## OpenCode

- Provider credentials live in the untracked `~/.local/share/opencode/auth.json`; never copy them
  into a repository.
- Claude Code hooks do not run here, so git guard hooks that repos enable for Claude Code do not
  apply, but the repo's documented rules still do.
- ikeh-development's route agents and hook have no OpenCode form, so its route dispatch does not
  resolve here.
- Synced claude.ai skills that depend on claude.ai's app or connectors are denied here; do not load
  one through its slash command, which bypasses the deny.
- context7 is configured as an MCP server for current library, framework, SDK, API and CLI
  documentation; prefer it to web search for those.
- Where OpenCode's configuration, skills, plugins and MCP servers live: the `my-machine-configs`
  skill, `references/opencode.md`.
