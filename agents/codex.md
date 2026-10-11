# Codex: user-level instructions

## Codex

- `workspace-write` blocks writes outside the workspace, such as `~/.config`, and keeps `.git`
  read-only, so a commit needs an approved escalation and then runs, and signs, outside the
  sandbox. Inside it, 1Password's signer fails with `Could not connect to socket`: that is the
  sandbox, not an unanswered prompt, so escalate, and use `--no-gpg-sign` only under the
  autonomous-work rule below. Ask for approval rather than work around any block.
- context7 is configured as an MCP server for current library, framework, SDK, API and CLI
  documentation; prefer it to web search for those.
- Never run `ctx7 setup --codex`, which appends to this file.
- Machine specifics: the `my-machine-configs` skill, `references/codex.md`.
