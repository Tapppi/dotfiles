# AGENTS.md

## OpenCode config ownership

- `opencode.json` is the synced entrypoint that loads `oh-my-openagent` and
  `opencode-claude-auth`.
- `oh-my-openagent.json` is the tracked companion config for agent/category
  model selection.
- This repo does not keep a separate hand-maintained mirror of every bundled
  MCP server or skill shipped by `oh-my-openagent`; those stay plugin-managed.
- Claude auth stays explicit via the dedicated `opencode-claude-auth` plugin.
- No extra tmux/git-specific wrapper config is tracked here; the setup relies
  on built-in platform capabilities and the shared OpenAgent config.

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
