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

  **Project-scoped, not global.** This skill is intentionally *not* symlinked
  into `home/.claude/skills/` or `config/opencode/skills/` (it is not globally
  active). It is linked per repo by the parent `macos-setup` repo's
  `./setup.sh projects` task, driven by a gitignored `.tapppi-project.json`
  workspace manifest. The Jira instance and API token are provisioned per
  workspace via a generated, gitignored `mise.local.toml` that loads a local
  0600 dotenv file.

## Provenance

- Source: `https://github.com/softaworks/agent-toolkit`
- Branch: `main`
- Last synced commit: `3027f20f3181758385a1bb8c022d4041dfb4de84`
- License: MIT (upstream `LICENSE`)

## Local patches

(none)
