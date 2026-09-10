# agent-skills

Source-of-truth tree for all agent skills used by Claude Code and OpenCode.
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
    the Google Cloud skills. See "Per-project setup" below.

  Claude Code has no `enabledSkills` toggle for a raw (unpackaged) skill, so
  packaging as a plugin is what makes per-project scoping — or even a clean
  global on/off switch — possible in the first place.

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
  google/                               # git subtree of google/skills (squashed)
    CUSTOMISATION.md
    skills/cloud/
      cloud-run-basics/  cloud-sql-basics/  gke-basics/  ...   # project-scoped
    README.md  LICENSE  ...
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
agent. There is no `home/.claude/skills/` route — that directory was
emptied when the global skill symlinks became plugins, and `bootstrap.sh`
no longer mirrors it.

## Adopting / dropping a skill (global)

Adopt, for Claude Code: add an entry to `.claude-plugin/marketplace.json`
whose `source` points at the relevant
`./<vendor>/skills/[cloud/]<upstream-name>` (`"strict": false` supplies
name and description inline, so the vendored tree is left untouched), then
`claude plugin install <name>@tapppi-skills --scope user`.

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
`jira` (driven by `ankitpokhrel/jira-cli`) and the Google Cloud skills. These
are vendored here but **not** symlinked into the global skill dirs. Instead, a
*workspace* directory (a folder containing one or more related repos, e.g.
`~/project/acme/`) carries a gitignored manifest:

```json
{
  "skills": {
    "service-a": ["jira", "gke-basics"],
    "service-b": ["jira"]
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

1. **Skills (per repo).** For each `repo -> [skills]` entry, symlinks the named
   skills into `<workspace>/<repo>/.claude/skills/<name>` (resolved from
   anywhere under `~/.config/agent-skills/` by matching a dir with a `SKILL.md`)
   and adds `/.claude/skills/` to that repo's `.git/info/exclude`. Skills are
   **per repo** because Claude Code only discovers project skills up to a repo's
   git root — a `.claude/skills/` in the workspace dir is invisible from inside
   a child repo.
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
3. For every adopted skill (the symlink targets), prints a stat-level
   diff between the pre-pull and post-pull state and lists touched
   files. **Always review this output before committing the pull —
   upstream changes may need customisation updates or break our
   symlinked skills.**

Manual subtree commands (if needed):

```sh
# From dotfiles repo root. Only for a vendor with no excluded paths —
# a stock pull of anthropics would put the excluded content back.
git subtree pull --prefix=config/agent-skills/google \
    https://github.com/google/skills main --squash
```

Use `--squash` always: each pull collapses to one commit, keeping the
dotfiles history readable. Last-pull SHA is in the squash commit
message (`git log --grep=git-subtree-dir`).

### Excluded upstream content

This repo is public, so publishing it is redistribution — and it must not
carry upstream content it has no right to redistribute. Two things fail
that test, and both are excluded:

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

An excluded path must also leave the vendored
`<vendor>/.claude-plugin/marketplace.json`, or that marketplace advertises
a plugin whose source is not on disk. Both edits are recorded as local
patches in the vendor's `CUSTOMISATION.md`, because upstream will keep
re-adding them.

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
`document-skills:docx`, `:pdf`, `:pptx`, `:xlsx`. The retired
`tapppi-skills` entries were one plugin per skill, so the same four used
to appear as `docx:docx`, `pdf:pdf`, `pptx:pptx`, `xlsx:xlsx` — anything
referring to them by those old names needs updating.

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
