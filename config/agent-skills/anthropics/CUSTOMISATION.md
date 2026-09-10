# Anthropics Skills — Customisation

Upstream: <https://github.com/anthropics/skills> (branch `main`).

Vendored as a `git subtree` at `config/agent-skills/anthropics/`. See
`config/agent-skills/README.md` for the sync workflow. **Sync this vendor
only through `sync-upstream.sh`, never with a bare `git subtree pull`** —
see "Excluded upstream content" below for why.

## Adopted skills

For OpenCode, symlinks live in `dotfiles/config/opencode/skills/<name>`
pointing at `anthropics/skills/<name>`. For Claude Code, each is listed
as a plugin in the `tapppi-skills` marketplace
(`config/agent-skills/.claude-plugin/marketplace.json`) and enabled
globally via `claude plugin install <name>@tapppi-skills --scope user`
— no symlink or local patch to this vendored tree required:

- `skill-creator`

## Excluded upstream content — do not re-add

Five paths are deliberately absent from this tree, and `sync-upstream.sh`
keeps them out (the excluded-paths field of its vendor table):
`skills/docx`, `skills/pdf`, `skills/pptx`, `skills/xlsx` and
`skills/doc-coauthoring`. The first four carry a licence that forbids
redistribution; the fifth carries no licence at all. Different symptoms,
one diagnosis: this public repo holds no grant to redistribute either, and
publishing it would be redistribution.

### The four document skills — a licence that forbids it

`skills/docx`, `skills/pdf`, `skills/pptx` and `skills/xlsx` are **not**
open source. Each ships a `LICENSE.txt` reading "© 2025 Anthropic, PBC. All
rights reserved." whose additional restrictions say users may not:

> Extract these materials from the Services or retain copies of these
> materials outside the Services; Reproduce or copy these materials;
> Create derivative works based on these materials; Distribute,
> sublicense, or transfer these materials to any third party.

(Full text: <https://github.com/anthropics/skills/blob/main/skills/docx/LICENSE.txt>;
the other three are identical. Upstream's README calls them
"source-available, not open source".) The `dotfiles` repo is public, so
carrying them here redistributes them to every reader — the one thing that
licence forbids outright. Every skill under `skills/` that carries an
Apache-2.0 `LICENSE.txt` is fine to vendor; the exception with neither
that nor a prohibition is `doc-coauthoring`, below.

Want the document skills back? Install them from Anthropic's own
marketplace instead of vendoring them, which is what upstream's README
tells users to do and keeps the copy machine-local. That is what
`home/.claude/settings.json` now does: an `extraKnownMarketplaces` entry
for `anthropic-agent-skills` (source `github`, repo `anthropics/skills`)
plus `"document-skills@anthropic-agent-skills": true` in `enabledPlugins`
— the equivalent of `claude plugin marketplace add anthropics/skills` and
`claude plugin install document-skills@anthropic-agent-skills --scope user`,
but committed rather than typed. The skills arrive namespaced under the
*plugin* name — `document-skills:docx`, `:pdf`, `:pptx`, `:xlsx`, where the
retired per-skill `tapppi-skills` entries gave `docx:docx` and so on — and
are fetched by Claude Code onto the machine at use time. Naming a
marketplace and enabling a plugin redistributes nothing, which is exactly
why it is legitimate where vendoring was not. It reaches the live machine
only on the next `bootstrap.sh` sync.

### `skills/doc-coauthoring` — no licence at all

`skills/doc-coauthoring` ships no licence file, upstream included: the
directory contains only `SKILL.md`, and `anthropics/skills` has no
repo-root `LICENSE` to fall back on either (verified against the upstream
API, 2026-09). Every other adopted skill under `skills/` carries its own
Apache-2.0 `LICENSE.txt`; this one carries nothing.

Absence of a grant is not permission. Copyright subsists by default, so an
unlicensed file conveys no right to redistribute it — and a public repo is
redistribution. It is therefore excluded on the same footing as the four
document skills, even though the reason is silence rather than a
prohibition. If upstream later adds a licence that permits redistribution,
this is the paragraph to revisit; until then the path stays on the list.

Unlike the document skills there is no marketplace substitute to point at:
upstream lists `doc-coauthoring` under its own `example-skills` plugin, so
installing that plugin from `anthropic-agent-skills` is the way to reach it
machine-locally if it is ever wanted.

### `.claude-plugin/` — upstream's own marketplace manifest

Upstream ships a `.claude-plugin/marketplace.json` advertising its plugins,
including `document-skills`, whose sources are the four excluded paths. It is
excluded outright rather than kept and patched.

Keeping it forced a hand-maintained deletion of the `document-skills` entry and
the `doc-coauthoring` array member, which conflicted on every upstream edit to
that file, and left the vendored manifest advertising a plugin whose source was
not on disk. Nothing registers vendored marketplaces, so the file served no
purpose here; excluding it removes both.

It also removes one source of a name collision. Upstream's manifest declares
`anthropic-agent-skills`, the same name `~/.claude/settings.json` binds to
GitHub `anthropics/skills`. The parent repo's `projects_ensure_marketplaces`
registers only the root manifest, which prevents that collision structurally
whatever a vendor tree happens to contain; excluding the file removes the
instance as well. Both are kept deliberately — the exclusion is not a
replacement for the narrowing.

### Why the sync script has to know

Rather than this just being a `git rm`: a stock `git subtree pull --squash`
writes a squash commit whose tree is the *entire* upstream tree. Even if
the merge then dropped these paths from the worktree, every pull would
re-add them to reachable history and the next push would publish them
again. `sync-upstream.sh` therefore builds the squash commit from a
filtered tree (`subtree_pull_excluding`): the paths never enter any *new*
squash commit or merge, and the squash commit message records what was
excluded. That is also why this vendor must not be pulled by hand.

This stops the content being added again; it does not remove what is already
there. The original unfiltered squash stays reachable from `master`, and each
filtered squash is parented onto it, so a clone of this public repo still carries
the excluded trees in history. Clearing that needs a `git filter-repo` rewrite of
this repository and a force-push — planned separately, and not something this
mechanism achieves.

## Local patches

- `skills/skill-creator/references/agent-skills-spec.md` (added) +
  `skills/skill-creator/SKILL.md` (references-section bullet added) —
  Surface <https://agentskills.io/specification> from inside the skill
  so authors don't have to discover the URL via the repo-root
  `spec/agent-skills-spec.md` pointer. Could be upstreamed.

When adding a local patch, append a bullet here noting:
- File(s) touched
- Reason for the patch
- Whether it should be upstreamed

This list drives conflict checks on `sync-upstream.sh` runs.
