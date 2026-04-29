# Anthropics Skills — Customisation

Upstream: <https://github.com/anthropics/skills> (branch `main`).

Vendored as a `git subtree` at `config/agent-skills/anthropics/`. See
`config/agent-skills/README.md` for the sync workflow.

## Adopted skills

Symlinks live in `dotfiles/home/.claude/skills/<name>` and
`dotfiles/config/opencode/skills/<name>` pointing at
`anthropics/skills/<name>`:

- `skill-creator`
- `pdf`
- `pptx`
- `docx`
- `xlsx`

## Local patches

None yet.

When adding a local patch, append a bullet here noting:
- File(s) touched
- Reason for the patch
- Whether it should be upstreamed

This list drives conflict checks on `sync-upstream.sh` runs.
