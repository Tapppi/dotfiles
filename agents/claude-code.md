# Claude Code: user-level instructions

## Claude Code

- Never run a plain `ctx7 setup`: it writes the context7 key into `~/.claude.json`.
  `ctx7 setup --claude --oauth` restores ctx7's skill and rule but replaces the context7 MCP entry
  with a keyless one, so after such a run the owner restores it with macos-setup's
  `./setup.sh context7`.
- Machine specifics: the `my-machine-configs` skill, `references/claude-code.md`.
