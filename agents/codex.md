# Codex: user-level instructions

Generated from dotfiles `agents/`: edit there, run `agents/render.sh`, then sync. The
ChatGPT/Codex app's custom-instructions pane edits this same file, and a pane save holds only
until the next sync overwrites it, so make changes in dotfiles. A `~/.codex/AGENTS.override.md`
would replace this file; none is used.

## Codex configuration

- `/etc/codex/config.toml` comes from systems (`modules/darwin/codex.nix`). `~/.codex/config.toml`
  is Codex-owned and untracked and is changed through Codex. It overrides the system layer key by
  key, so read a setting's effective value there; sandbox, approvals and any execpolicy `rules/`
  are not restated here. A project `.codex/config.toml` loads only in a trusted project.
- `workspace-write` blocks writes outside the workspace, such as `~/.config`, and keeps `.git`
  read-only, so a commit needs an approved escalation and then runs, and signs, outside the
  sandbox. Inside it, 1Password's signer fails with `Could not connect to socket`: that is the
  sandbox, not an unanswered prompt, so escalate, and use `--no-gpg-sign` only under the
  autonomous-work rule below. Ask for approval rather than work around any block.
- Hooks are enabled by the config layers; tool-written hooks are restored by re-running the tool,
  not by editing. A new or changed hook needs review in `/hooks`, which stores trust as a hash in
  `~/.codex/config.toml`, so any edit sends it back for review.
  Git guard hooks that repos enable for Claude Code do not run here, but the repo's documented
  rules still apply; repos and plugins that add Codex hooks document them.
- Marketplaces and plugin enablement live in `~/.codex/config.toml` (`codex plugin`), and an
  enabled plugin applies in every project. Skills come from `~/.agents/skills`, a repo's
  `.agents/skills` (not `.claude/skills`) and plugins, among others.
- MCP servers are configured in `~/.codex/config.toml`. macos-setup's `./setup.sh context7` (an
  owner step; it needs sudo and refuses while Codex is running) re-asserts the context7 entry.
  Never run `ctx7 setup --codex`, which appends to this file.
- Codex reads `AGENTS.md` (or `AGENTS.override.md`) from the repo root down to the working
  directory, in trusted projects only, and never `CLAUDE.md`; repos here keep their rules in
  `AGENTS.md`.
