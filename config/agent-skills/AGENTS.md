# agent-skills (OpenCode and other agents)

Canonical tree for agent skills, synced to `~/.config/agent-skills/`.
`~/.config/opencode/skills/<skill>` symlinks into here. (Claude Code no
longer uses these symlinks for its own skills — it delivers them as
plugins instead; see CLAUDE.md. `home/.claude/skills/` stays empty.)

- `tapppi/` — my own skills (source of truth for `browser`,
  `subrepo-permissions`, etc.)
- `anthropics/`, `google/` — `git subtree` of upstream skill repos.
  Adopted skills are symlinked into the agent skill dirs; non-adopted
  upstream content stays on disk but isn't exposed.
- `softaworks/` — sparse vendor (single `jira` skill, not a full subtree).
- `sync-upstream.sh` — pulls upstream subtrees (and refreshes sparse
  vendors) and prints per-skill diffs for review. Honours each vendor's
  excluded-paths list: upstream content this public repo has no right to
  redistribute — `anthropics/skills/{docx,pdf,pptx,xlsx}` (proprietary
  licence) and `anthropics/skills/doc-coauthoring` (no licence file at
  all, upstream included; absence of a grant is not permission) — is
  filtered out of the squash commit itself, so a pull can never re-add
  it, and the pull is refused outright if an excluded path is no longer
  where upstream had it (a likely rename — a human must look first). See
  `anthropics/CUSTOMISATION.md`. Never `git subtree pull` such a vendor
  by hand.
- Per-vendor `CUSTOMISATION.md` lists adopted skills, excluded paths,
  upstream licence provenance and local patches. A vendored copy carries
  the upstream licence: `google/LICENSE` and `anthropics/skills/*/LICENSE.txt`
  arrive with the subtree, and `softaworks/LICENSE` is copied in by hand
  because the sparse vendor takes only `skills/jira` while upstream keeps
  its MIT licence at the repo root.

OpenCode 1.15.12 reads a repo's `.claude/skills/` and `.agents/skills/`
natively and recursively, so per-project delivery does work there — a skill
committed in a repo is picked up with no symlink and no config. It also has its
own JS/TS plugin system under `.opencode/plugins/`, though that is an
event-hook module format, not a skill bundle.

The symlinks in `config/opencode/skills/` therefore make a skill *globally*
available in every OpenCode session; they are not the only way to reach it.
`jira` and the Google Cloud skills carry no such symlink, so they are not global
in OpenCode — but a repo that commits them reaches OpenCode like any other
harness.

An excluded skill is reachable in Claude Code without being vendored, by naming
its upstream marketplace in `home/.claude/settings.json` — that is how
Anthropic's document skills come back (see CLAUDE.md). **That route does not
reach OpenCode**, which has no notion of Claude Code's `enabledPlugins`. In
OpenCode those skills are simply unavailable, and the fix is not to vendor them.

See [README.md](README.md) for the full layout, adoption workflow,
upstream-sync process, and customisation guidance.
