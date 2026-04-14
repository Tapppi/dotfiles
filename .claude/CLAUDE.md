# User-level Claude Code configuration

## Claude Code config ownership

- `settings.json` is the synced entrypoint for Claude Code user-level settings
  (effort level, status line).
- `keybindings.json` is the customized keyboard binding configuration.
- `statusline-command.sh` is the status line script showing model, directory,
  and context window usage with Solarized Dark colors.
- User-level MCP servers (e.g. context7) are managed via `claude mcp add
  --scope user` and stored in `~/.claude.json`; that file is not tracked because
  it contains auto-generated state. The `macos-setup` repo configures these
  via `tasks/config.sh`.
- This repo does not keep MCP servers that duplicate Claude Code built-in
  capabilities (git, tmux, SSH, web search, file operations all work natively
  via the Bash tool).

## Git Identity and Attribution

- **NEVER** add AI attribution to commits (no `Co-authored-by`, no
  `Ultraworked with`, no agent signatures in commit bodies or trailers).
  Commits must look like normal developer commits.
- **NEVER** change `user.name`, `user.email`, or any git identity
  configuration. The repository owner's identity must remain on all commits.
- **Exception — unattended workflows**: If the agent must commit in an
  unattended context (e.g. CI, cron, background automation) where the
  owner's signing key is unavailable, it may temporarily set a placeholder
  identity to allow the commit to proceed. In this case:
  1. Clearly inform the user that commits were made with a placeholder identity.
  2. Note that these commits need `git rebase` / `git commit --amend` to
     restore the correct author before pushing to a shared remote.
