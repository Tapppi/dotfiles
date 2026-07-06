# Google Skills — Customisation

Upstream: <https://github.com/google/skills> (branch `main`).

Vendored as a `git subtree` at `config/agent-skills/google/`. See
`config/agent-skills/README.md` for the sync workflow.

## Adopted skills

Not symlinked anywhere (not in OpenCode's `config/opencode/skills/`
either) — only reachable from Claude Code, where each is listed as a
plugin in the `tapppi-skills` marketplace
(`config/agent-skills/.claude-plugin/marketplace.json`) and enabled
per-project via a workspace `.tapppi-project.json` manifest's `plugins`
block (e.g. the `cadmatic` workspace's `gcp-iac-staging` repo), applied
by `macos-setup`'s `./setup.sh projects` task:

- `cloud-run-basics`
- `cloud-sql-basics`
- `gke-basics`
- `google-cloud-waf-cost-optimization`
- `google-cloud-waf-reliability`
- `google-cloud-waf-security`
- `bigquery-basics`
- `google-cloud-networking-observability`
- `google-cloud-recipe-auth`

## Local patches

None yet.

When adding a local patch, append a bullet here noting:
- File(s) touched
- Reason for the patch
- Whether it should be upstreamed

This list drives conflict checks on `sync-upstream.sh` runs.
