# agent-skills

Source-of-truth tree for dotfiles-managed agent skills used by Claude Code and OpenCode.
Synced to `~/.config/agent-skills/` by `bootstrap.sh`. The two agents expose
skills differently:

- **OpenCode** (1.15.12) reads a repo's `.claude/skills/` and `.agents/skills/`
  natively and recursively, so per-project delivery works with no symlink. It
  also has its own JS/TS plugin system under `.opencode/plugins/` — an
  event-hook module format, not a skill bundle. A symlink into
  `~/.config/opencode/skills/<skill>` makes a skill *global* in every OpenCode
  session; it is not the only route to reaching one.
- **Claude Code** delivers every adopted skill as a plugin from the
  `tapppi-skills` local marketplace (`.claude-plugin/marketplace.json` at
  this directory's root — see "Plugin marketplace" below), not a symlink.
  Plugins are enabled either:
  - **Globally** (active in every project) — `claude plugin install
    <name>@tapppi-skills --scope user`, e.g. `skill-creator`,
    `subrepo-permissions`.
  - **Per-project** (active only in opted-in projects) — a *workspace*
    directory carries a gitignored `.tapppi-project.json` manifest and the
    parent `macos-setup` repo's `./setup.sh projects` task enables each
    repo's named plugins at local scope (and provisions shared per-workspace
    env). Used for skills that should not be globally active, e.g. `jira`,
    See "Per-project setup" below.

  Claude Code has no `enabledSkills` toggle for a raw (unpackaged) skill.
  Packaging this tree's adopted skills as plugins supports settings-based
  enablement at user or project scope. Repo-committed skills are independently
  discovered in place through route 3 below.

Agent capability reaches a repo by exactly three routes:

1. Always-on user-level skills, installed once for the machine and active everywhere.
2. Plugins from a marketplace — capability someone else publishes is consumed
   from their marketplace rather than copied here. Which configuration switches
   a plugin on belongs to the harness and to the repo, not to this document.
3. Repo-committed `.agents/skills` or `.claude/skills`, discovered in place. In the
   owner's repos, `.agents/skills/<bundle>/` holds `.claude-plugin/plugin.json`
   and `skills/<name>/SKILL.md`; a committed relative symlink at
   `.claude/skills/<bundle>` points to `../../.agents/skills/<bundle>`.
   Read other people's committed skill layouts as-is under their own conventions.

`tasks/projects.sh` writes a repo's gitignored local plugin list. It does not
link skills.
Only the root `tapppi-skills` marketplace under `~/.config/agent-skills/` is
registered by that task. A vendored tree's own `.claude-plugin/marketplace.json`
is not: it declares its publisher's marketplace name — `anthropic-agent-skills`,
for one — and the tracked `~/.claude/settings.json` already binds that name to
the publisher's own GitHub source.

Google's cloud skills are **not vendored**. Following that repo's release pace is a burden we do not want, and each project sets them up on its own per Google's instructions instead.

## Layout

```
agent-skills/
  CLAUDE.md  AGENTS.md  README.md       # this file is the canonical doc
  sync-upstream.sh                      # subtree pull (minus excluded paths) + per-skill diff
  tapppi/                               # my own skills
    browser/  subrepo-permissions/  ...
  anthropics/                           # git subtree of anthropics/skills (squashed)
    CUSTOMISATION.md                    # adopted skills, excluded paths, local patches
    skills/                             # upstream layout preserved
      skill-creator/  ...               # each carries its own Apache-2.0 LICENSE.txt
                                        # docx/ pdf/ pptx/ xlsx/ excluded: proprietary licence
                                        # doc-coauthoring/ excluded: no licence at all
    spec/  template/  README.md  ...    # other upstream content (not symlinked)
  softaworks/                           # sparse vendor (single skill, not a subtree)
    CUSTOMISATION.md                    # provenance + sync commit + licence note
    LICENSE                             # upstream MIT, verbatim — vendor level, see below
    jira/  SKILL.md  references/         # project-scoped (drives ankitpokhrel/jira-cli)
```

The vendor directories preserve the upstream repo layout exactly so
`git subtree pull` is conflict-free for unmodified content. Adopted
skills are surfaced as `tapppi-skills` marketplace plugins for Claude
Code and as symlinks in `dotfiles/config/opencode/skills/` for OpenCode;
non-adopted upstream content stays on disk but isn't exposed to either
agent. Dotfiles has no `home/.claude/skills/` route — see *Tool-owned config
inside tracked files* in the repo's `AGENTS.md`.

## Adopting / dropping a skill (global)

Adopt, for Claude Code: add an entry to `.claude-plugin/marketplace.json`
whose `source` points at a **plugin** — a directory carrying its own
`.claude-plugin/plugin.json`, as `./tapppi/browser` does — then
`claude plugin install <name>@tapppi-skills --scope user`. The marketplace
publishes plugins and nothing else: a plugin carries its skills *and* the
rest of its config (MCP, hooks, agents), which a bare skill directory cannot.

Three of the four current entries predate that rule and still point at bare
directories with `"strict": false` supplying name and description inline.
They work, and giving each a manifest is open work — but do not add a fourth.

`browser` is the entry that shows why the rule exists: its `.mcp.json` ships
the Playwright and Chrome DevTools MCP servers the skill needs, namespaced
`browser-playwright` and `browser-chrome-devtools` so they cannot collide with
another plugin's server of the same purpose. A bare skill directory could carry
none of that — and because the bundle carries Playwright itself, nothing needs
to install the official `playwright` plugin alongside it.

Adopt, for OpenCode: add a symlink at `config/opencode/skills/<name>`
pointing into the same directory. Use the upstream skill name verbatim in
both — it keeps customisations and upstream references aligned.

Drop: remove the marketplace entry (and the `enabledPlugins` key in
`home/.claude/settings.json`) and the OpenCode symlink. `bootstrap.sh`
mirrors `~/.config/opencode/skills/` with `rsync --delete`, so a dropped
symlink is pruned on the next sync rather than lingering (a plain rsync
only adds). The upstream content stays in the subtree so the skill can be
re-adopted later without re-fetching — unless it is on the vendor's
excluded-paths list, in which case it is not on disk at all and the route
back is a marketplace, not a re-adoption (see "Getting an excluded skill
back, without vendoring it").

## Per-project setup (`.tapppi-project`)

Some skills should be active only in specific projects, not globally — e.g.
`jira` (driven by `ankitpokhrel/jira-cli`). These
are vendored here but **not** symlinked into the global skill dirs. Instead, a
*workspace* directory (a folder containing one or more related repos, e.g.
`~/project/acme/`) carries a gitignored manifest:

```json
{
  "plugins": {
    "service-a": ["jira@tapppi-skills"],
    "service-b": ["jira@tapppi-skills"]
  },
  "jira": {
    "installation": "local",
    "server": "https://jira.example.com",
    "login": "me@example.com",
    "auth_type": "bearer",
    "project": "PROJ",
    "board": "",
    "token_op_ref": "op://Vault/Item/field",
    "env_file": "project.env"
  }
}
```

Running `./setup.sh projects` (in the parent `macos-setup` repo) scans
`~/project` for these manifests and, per workspace:

1. **Plugins (per repo).** For each `repo -> [plugin@marketplace]` entry,
   enables the plugin at local scope (`claude plugin install --scope local`),
   recorded in that repo's gitignored `.claude/settings.local.json`. This is
   how a marketplace plugin gets per-project scoping. Per repo, because Claude
   Code only discovers project skills up to a repo's git root.

   This task does not link skills. A skill lives committed in the repo that
   uses it, as `.agents/skills/<bundle>/` plus a committed *relative* symlink
   at `.claude/skills/<bundle>` — see the parent `macos-setup` repo's
   `docs/skills.md`.
2. **Shared env (per workspace).** If `jira.env_file` is set, renders
   `<workspace>/mise.local.toml` with a single `[env]` `_.file = "<env_file>"`.
   mise walks **up** the directory tree (ignoring git boundaries), so every repo
   under the workspace inherits the env — set once, used everywhere.
3. If a `jira` block is present, prints the one-time setup commands (it does
   not run them — they need 1Password and reach the Jira server).

The execution context is plain shell env: mise's directory hook
(`mise activate bash`) exports the workspace `[env]` in any repo beneath it, so
any agent (Claude Code / Codex / OpenCode) launched there inherits
`JIRA_API_TOKEN` / `JIRA_CONFIG_FILE` etc. The manifest filename is in the
global gitignore (`config/git/ignore`); the workspace dir is typically not a
git repo, so its generated files are never committed.

### How the token reaches mise without blocking

mise evaluates `[env]` **synchronously on every `cd`/prompt**, so anything that
runs there must be instant. A blocking `op read` (network/unlock) would freeze
the shell. So the manifest points mise at a local **`0600` dotenv file**
(`jira.env_file`, in the workspace dir) via `_.file`; mise just reads it
(instant; a missing file is skipped, no error). That one file holds the
non-secret config (`JIRA_CONFIG_FILE`, `JIRA_AUTH_TYPE`) and the secret
`JIRA_API_TOKEN` together. `jira-cli` reads `JIRA_API_TOKEN` from the env (its
lookup order is env → config → `.netrc` → keychain, so env wins).
`./setup.sh projects` prints two ready-to-run commands (skipped once each is
done):

1. **Write the dotenv file from 1Password** (one `op read`, run when you can
   reach 1Password — `eval "$(op signin)"` first if it's locked, e.g. over SSH):

   ```sh
   ( umask 077; cat > ~/project/acme/project.env <<EOF
   JIRA_CONFIG_FILE=/Users/me/project/acme/.jira-config.yml
   JIRA_AUTH_TYPE=bearer
   JIRA_API_TOKEN=$(op read "op://Vault/Item/field")
   EOF
   )
   ```

   The token is long-lived (until the PAT rotates), so daily use never touches
   op — only refreshing it does. The file lives in the workspace dir (keep that
   dir out of any git repo), so it is never committed; `0600` means only your
   user (and root) can read it, which also works over SSH.

2. **`jira init`** to write the server/board/project config (at
   `<workspace>/.jira-config.yml`), with
   `--installation/--server/--login/--auth-type/--project/--board` filled from
   the `jira` block.

## Updating upstream subtrees

Run `bash config/agent-skills/sync-upstream.sh` (from the dotfiles repo
root). The script:

1. Records each vendor's HEAD commit before pulling.
2. Runs `git subtree pull --prefix=config/agent-skills/<vendor>
   <upstream-url> main --squash` for each vendor — except a vendor with
   excluded paths, which gets the script's own filtered squash instead
   (see "Excluded upstream content" below).
3. For every skill in the vendored adopted-skill list, prints a stat-level
   diff between the pre-pull and post-pull state and lists touched
   files. **Always review this output before committing the pull —
   upstream changes may need customisation updates or break our
   adopted skills.**

**There is no manual-pull path any more.** `anthropics` is the only subtree
vendor left, and it carries excluded paths — a stock `git subtree pull`
squashes the whole upstream tree and would put the proprietary content back
into history even though the merge then drops it from the worktree. Always
go through `sync-upstream.sh`, which builds a filtered squash instead.

Use `--squash` always: each pull collapses to one commit, keeping the
dotfiles history readable. Last-pull SHA is in the squash commit
message (`git log --grep=git-subtree-dir`).

### Excluded upstream content

This repo is public, so publishing it is redistribution — and it must not
carry upstream content it has no right to redistribute. Two things fail
that test, and a third is excluded for a different reason:

- **A licence that forbids it.** `skills/docx`, `skills/pdf`,
  `skills/pptx` and `skills/xlsx` under `anthropics/` each ship a
  `LICENSE.txt` that is Anthropic's proprietary "all rights reserved"
  notice, explicitly barring reproduction and distribution to third
  parties. `anthropics/CUSTOMISATION.md` quotes the terms.
- **No licence at all.** `skills/doc-coauthoring` under `anthropics/`
  ships no licence file, and `anthropics/skills` has no repo-root
  `LICENSE` to fall back on. Copyright applies by default, so silence
  grants nothing — absence of a grant is not permission, and an
  unlicensed file is excluded on the same footing as a prohibited one.
- **Upstream's own marketplace manifest**, `.claude-plugin/` under
  `anthropics/`. Not a rights question. Nothing registers a vendored
  marketplace, so the file did no work here, and what it advertised —
  `document-skills`, sourced from the four excluded paths — was not on disk.
  It also declares the marketplace name `anthropic-agent-skills`, which the
  tracked `home/.claude/settings.json` binds to GitHub. Root-only
  registration already prevents that collision structurally; excluding the
  file removes the instance too.

The vendor table in `sync-upstream.sh` has a fifth field listing these
paths. Removing them from the worktree is not enough:
`git subtree pull --squash` writes a squash commit whose tree is the
*whole* upstream tree, so every pull would put them back into reachable
history and the next push would publish them again. For a vendor with
exclusions the script does what `git subtree pull --squash` does, with
one extra step: it reads the upstream commit into a scratch index, drops
the excluded paths, and squashes and merges *that* tree — same parent
chain and `git-subtree-dir`/`git-subtree-split` trailers, so the next
pull still merges three-way against the right base, and the squash
commit message records what was excluded. Never run `git subtree pull`
by hand for a vendor that has exclusions.

The list is a guard, so it fails loudly rather than tolerating a miss.
Before building the filtered tree the script checks that every excluded
path exists in the upstream commit it is about to squash, and refuses the
pull — naming the path and listing the upstream commits that touched it —
if one does not. A path that matches nothing is most likely a rename
(`skills/docx` → `skills/word`), and skipping it would carry the content
into reachable history under the new name, where a check on the old path
never sees it. Git cannot tell that from a deliberate upstream removal,
so a human has to look either way: find where it went, update the vendor
table and the vendor's `CUSTOMISATION.md`, re-run. Every other step —
fetch, read-tree, write-tree, commit-tree, merge — is checked the same
way, and a filtered tree that comes out empty is refused too, since it
would merge cleanly as the deletion of the whole vendor. A refusal leaves
the tree clean, so the script goes on to the other vendors and exits
non-zero at the end; only a merge that actually conflicts stops the run
where it is.

Nothing has to be patched out of a vendored upstream manifest, because no
upstream manifest is vendored: `anthropics/.claude-plugin/` is on the
exclusion list itself. Keeping it and deleting the offending entries by
hand was tried and abandoned — the deletion conflicted on every upstream
edit. Excluding it outright leaves nothing to re-apply.

### Getting an excluded skill back, without vendoring it

Excluding a skill from this tree does not mean giving it up. Where the
upstream publishes its own marketplace, the skill is reached by *naming*
that marketplace in the tracked `home/.claude/settings.json` —
an `extraKnownMarketplaces` entry plus an `enabledPlugins` key — and
letting Claude Code fetch the plugin itself. Config, not a copy: nothing
is redistributed, which is exactly why this is legitimate where vendoring
was not, and it is what upstream's own README tells users to do.

That is how the four document skills come back:

```jsonc
"enabledPlugins": {
  "document-skills@anthropic-agent-skills": true
},
"extraKnownMarketplaces": {
  "anthropic-agent-skills": {
    "source": { "source": "github", "repo": "anthropics/skills" }
  }
}
```

A plugin namespaces its skills under the *plugin* name, so these arrive as
`document-skills:docx`, `:pdf`, `:pptx`, `:xlsx`.

The setting is committed but machine-local in effect: it reaches a machine
only on the next `bootstrap.sh` run, and Claude Code fetches the plugin
from GitHub at use time. And it is Claude-Code-only — OpenCode does not
read `enabledPlugins`, so a skill delivered this way is unavailable there.

Prefer this route over vendoring for any upstream content whose licence
does not clearly permit redistribution.

### Sparse vendors

When only a single skill is wanted out of a large upstream collection
(e.g. `softaworks/jira` from the 40+ skill `softaworks/agent-toolkit`),
the skill is vendored as a **sparse copy**, not a full subtree. These are
listed in the `sparse_vendors` table in `sync-upstream.sh`; the same
script refreshes them via a shallow sparse checkout + `rsync` and prints
a diff. Bump the `Last synced commit` in the vendor's `CUSTOMISATION.md`
after a sparse update.

**A sparse vendor needs its licence placed by hand, one level up.** A
subtree carries the upstream repo root with it, so the licence comes for
free; a sparse copy takes only the skill subdirectory, and upstream
licences almost always live at the repo root. The copy then travels
without the notice — which for a permissive licence like MIT is the one
condition it imposes ("shall be included in all copies or substantial
portions of the Software"). So fetch the upstream licence and commit it
at **vendor level**, next to `CUSTOMISATION.md` — `softaworks/LICENSE` —
and record its provenance there.

Not inside the skill directory: the refresh is
`rsync -a --delete … "${dest}/"`, so anything in `softaworks/jira/` with
no upstream counterpart is deleted on the next sync. A licence placed
there would disappear the first time the skill was refreshed, silently
putting the repo back out of compliance. One level up is outside the
mirror.

The corollary is that a vendor directory covers exactly one upstream
licence. A skill sparse-vendored from a different repo needs its own
vendor directory with its own `LICENSE`.

## Customisation workflow

Local patches are normal commits in `dotfiles`. When you patch an
upstream skill, also add a one-liner to the relevant
`<vendor>/CUSTOMISATION.md` so the patch is discoverable on the next
upstream pull (the next `sync-upstream.sh` run will then know to
re-check the patched files for conflicts/drift).

Conflict resolution on `git subtree pull` uses standard `git
mergetool` — no special tooling.

## Adding a new vendor

```sh
git subtree add --prefix=config/agent-skills/<vendor> \
    <upstream-url> main --squash
```

Then add a `CUSTOMISATION.md` inside the new vendor dir, append the
vendor entry to `sync-upstream.sh`, and update this README.

Check the licence before the first commit, not after. A subtree brings
the upstream repo root along, so its `LICENSE` arrives on its own; a
sparse vendor does not, and needs the licence placed by hand at vendor
level (see "Sparse vendors"). Record the licence and its upstream
provenance in the new `CUSTOMISATION.md`, and put any path this public
repo may not redistribute — a licence that forbids it, or no licence at
all — on the vendor's excluded-paths list straight away.

## Why this lives in `config/`

`bootstrap.sh` rsyncs `config/` → `~/.config/`, so the canonical tree
lands at `~/.config/agent-skills/` automatically. Claude Code reaches it
as the `tapppi-skills` marketplace (registered by directory path) and
OpenCode through the symlinks under `config/opencode/skills/` — one tree
on disk, two agent-facing views.
