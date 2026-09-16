# agent-skills

Canonical tree for agent skills, synced to `~/.config/agent-skills/`.
[README.md](README.md) is the full reference — layout, adoption workflow,
upstream sync, licence posture and customisation. This file is the summary
agents load.

## The tree

- `tapppi/` — my own skills (source of truth for `browser`,
  `subrepo-permissions`).
- `anthropics/` — `git subtree` of an upstream skill repo. Adopted skills are
  published as plugins; non-adopted upstream content stays on disk but is not
  exposed.
- `softaworks/` — sparse vendor (single `jira` skill, not a full subtree).
- `sync-upstream.sh` — pulls upstream subtrees, refreshes sparse vendors, and
  prints per-skill diffs for review. It honours each vendor's excluded-paths
  list: upstream content this public repo has no right to redistribute is
  filtered out of the squash commit itself, so a pull can never re-add it, and
  the pull is refused outright if an excluded path is no longer where upstream
  had it. Never `git subtree pull` such a vendor by hand. See the vendor's
  `CUSTOMISATION.md`.
- `.claude-plugin/marketplace.json` — the `tapppi-skills` marketplace. It
  publishes **plugins only**; a bare skill directory is not a publishable unit.
- Per-vendor `CUSTOMISATION.md` — adopted skills, excluded paths, upstream
  licence provenance, local patches. A vendored copy carries its upstream
  licence.

## How this tree is consumed

Claude Code and Cursor reach it as marketplace plugins, enabled at user scope
or per project. OpenCode reaches it through the `config/opencode/skills/`
symlinks, which make a skill globally available in every session — OpenCode
also reads a repo's committed `.claude/skills/` and `.agents/skills/` natively
and recursively, so a repo that commits its own skills needs no symlink here.

That asymmetry matters in one direction: a skill reached by *naming* an
upstream marketplace rather than vendoring it is Claude-Code-only, because
OpenCode has no notion of `enabledPlugins`. Do not answer that gap by
vendoring the skill.

## Reaching a skill without vendoring it

Not everything wanted has to live in this tree. A skill this public repo may
not carry is reached by naming its upstream marketplace in the tracked
`home/.claude/settings.json` — an `extraKnownMarketplaces` entry plus an
`enabledPlugins` key — and letting Claude Code fetch the plugin itself.

That is how Anthropic's document skills arrive:
`extraKnownMarketplaces.anthropic-agent-skills` (repo `anthropics/skills`) and
`"document-skills@anthropic-agent-skills": true`. A plugin namespaces its
skills under the *plugin* name, so they are `document-skills:docx`, `:pdf`,
`:pptx`, `:xlsx`.

Naming a marketplace copies nothing into this repo, which is exactly why it is
legitimate where vendoring is not. It is machine-local and sync-gated: the
setting is committed, but reaches a machine only on the next `bootstrap.sh`
run, and the plugin is fetched at use time.

**Prefer this route over vendoring for any upstream content whose licence does
not clearly permit redistribution — and for content shipped with no licence at
all, it is the only route.**
