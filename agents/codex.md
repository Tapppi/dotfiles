# Codex: user-level instructions

Generated from dotfiles `agents/`; a hand edit here is lost at the next sync. The ChatGPT/Codex
app's custom-instructions pane edits this file too, and the next sync overwrites a pane save, so
make changes in dotfiles.

## Codex

- `workspace-write` blocks writes outside the workspace, such as `~/.config`, and keeps `.git`
  read-only, so a commit needs an approved escalation and then runs, and signs, outside the
  sandbox. Inside it, 1Password's signer fails with `Could not connect to socket`: that is the
  sandbox, not an unanswered prompt, so escalate, and use `--no-gpg-sign` only under the
  autonomous-work rule below. Ask for approval rather than work around any block.
- Git guard hooks that repos enable for Claude Code do not run here, but the repo's documented
  rules still apply.
- context7 is configured as an MCP server for current library, framework, SDK, API and CLI
  documentation; prefer it to web search for those.
- Never run `ctx7 setup --codex`, which appends to this file.
- Where Codex's configuration layers, plugins, skills, MCP servers and hooks live: the
  `my-machine-configs` skill, `references/codex.md`.
