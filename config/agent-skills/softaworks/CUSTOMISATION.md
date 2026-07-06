# softaworks — vendored skills

Unlike `anthropics/` and `google/` (full `git subtree` mirrors), this vendor
holds only a **sparse** copy of selected skills from
[`softaworks/agent-toolkit`](https://github.com/softaworks/agent-toolkit) — the
upstream repo is a 40+ skill collection and we want just one. The sparse copy is
refreshed by `sync-upstream.sh` (see its `sparse_vendors` table), not by
`git subtree pull`.

## Adopted skills

- `jira/` — Jira via the `ankitpokhrel/jira-cli` (`jira`) CLI, with an Atlassian
  MCP fallback. Upstream path: `skills/jira`.

  **Project-scoped, not global.** Not symlinked anywhere (not exposed to
  OpenCode). For Claude Code it's listed as a plugin in the `tapppi-skills`
  marketplace (`config/agent-skills/.claude-plugin/marketplace.json`) and
  enabled per repo by the parent `macos-setup` repo's `./setup.sh projects`
  task, driven by a gitignored `.tapppi-project.json` workspace manifest's
  `plugins` block. The Jira instance and API token are provisioned per
  workspace via a generated, gitignored `mise.local.toml` that loads a local
  0600 dotenv file.

## Provenance

- Source: `https://github.com/softaworks/agent-toolkit`
- Branch: `main`
- Last synced commit: `3027f20f3181758385a1bb8c022d4041dfb4de84`
- License: MIT (upstream `LICENSE`)

## Local patches

(none)
