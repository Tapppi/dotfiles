# Google Skills — Customisation

Upstream: <https://github.com/google/skills> (branch `main`).

Vendored as a `git subtree` at `config/agent-skills/google/`. See
`config/agent-skills/README.md` for the sync workflow.

## Adopted skills

Symlinks live in `dotfiles/home/.claude/skills/<name>` and
`dotfiles/config/opencode/skills/<name>` pointing at
`google/skills/cloud/<name>`:

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
