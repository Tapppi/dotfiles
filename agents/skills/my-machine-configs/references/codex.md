# Codex on this machine

## Configuration layers

| Layer | Owner | Holds |
| --- | --- | --- |
| `/etc/codex/config.toml` | systems `modules/darwin/codex.nix` | Model, effort, sandbox, approvals, the hooks feature; no self-update for the Nix binary |
| `~/.codex/config.toml` | Codex; untracked | Project trust, TUI, hook trust hashes, marketplaces, plugins, MCP servers |
| `<repo>/.codex/config.toml` | The repo | Per-repo plugins; loads only in a trusted project |

The user file overrides the system layer key by key, so read a setting's effective value there.
Change it through Codex (`codex plugin`, `codex mcp`, the TUI), never by copying it into dotfiles.
Sandbox, approvals and any execpolicy `rules/` are not restated in the instructions. The `codex`
binary comes from Nix.

## Instructions

`~/.codex/AGENTS.md` is generated from dotfiles `agents/`. The ChatGPT/Codex app's
custom-instructions pane writes the same file, and the next sync overwrites a pane save. A
`~/.codex/AGENTS.override.md` would replace it; none is used. Codex reads `AGENTS.md` (or
`AGENTS.override.md`) from the repo root down to the working directory, in trusted projects only,
and never `CLAUDE.md`.

## Plugins, skills and MCP servers

- `./setup.sh codex` installs the user-level `frontend-design` plugin. The ikeh method reaches
  Codex from ikeh's own installer, an owner step run from the ikeh checkout, never from
  macos-setup: it installs `ikeh@ikeh-codex`, the roles in `~/.codex/agents/` and the `ikeh` MCP
  server. `browser@tapppi-skills` and `ikeh-git@ikeh` stay installed but `enabled = false` at user
  level; a repo turns one on in its committed `.codex/config.toml`. A hand-run `codex plugin add`
  or the `/plugins` UI sets it back to enabled until `./setup.sh codex` re-asserts the flag.
- Skills come from `~/.codex/skills/` (links to `my-machine-configs` and ctx7's `context7-mcp`;
  Codex calls this root deprecated), its bundled `~/.codex/skills/.system`, a repo's
  `.agents/skills` (not `.claude/skills`) and plugins.
- The context7 MCP entry reads `CONTEXT7_API_KEY` through `env_vars`. `./setup.sh context7`
  re-asserts it; never run `ctx7 setup --codex`, which appends to `~/.codex/AGENTS.md`.

## Hooks

The config layers enable hooks. herdr writes `~/.codex/herdr-agent-state.sh` and
`~/.codex/hooks.json`; restore them with `./setup.sh herdr`. A new or changed hook needs review in
`/hooks`, which stores its trust as a hash in `~/.codex/config.toml`, so any edit sends it back for
review.

`./setup.sh codex` and `./setup.sh context7` refuse while Codex is running.

Deeper: `~/project/github/tapppi/macos-setup/docs/harnesses.md`,
`~/project/github/tapppi/macos-setup/docs/skills.md` and systems `modules/darwin/codex.nix`.
