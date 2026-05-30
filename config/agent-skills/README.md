# agent-skills

Source-of-truth tree for all agent skills used by Claude Code and OpenCode.
Synced to `~/.config/agent-skills/` by `bootstrap.sh`. Skills are exposed to
agents in one of two ways:

- **Globally** (active in every project) — `~/.claude/skills/<skill>` and
  `~/.config/opencode/skills/<skill>` are symlinks pointing here, so a single
  edit (or upstream pull) updates both agents everywhere.
- **Per-repo** (active only in opted-in projects) — a repo carries a gitignored
  `.local-skills.json` manifest and the parent `macos-setup` repo's
  `./setup.sh skills` task symlinks the named skills into that repo's
  `.claude/skills/`. Used for skills that should not be globally active (e.g.
  `jira`, the Google Cloud skills). See "Repo-level adoption" below.

## Layout

```
agent-skills/
  CLAUDE.md  AGENTS.md  README.md       # this file is the canonical doc
  sync-upstream.sh                      # subtree pull + per-skill diff
  tapppi/                               # my own skills
    browser/  subrepo-permissions/  ...
  anthropics/                           # git subtree of anthropics/skills (squashed)
    CUSTOMISATION.md                    # adopted skills + local patches
    skills/                             # upstream layout preserved
      skill-creator/  pdf/  pptx/  docx/  xlsx/  ...
    spec/  template/  README.md  ...    # other upstream content (not symlinked)
  google/                               # git subtree of google/skills (squashed)
    CUSTOMISATION.md
    skills/cloud/
      cloud-run-basics/  cloud-sql-basics/  gke-basics/  ...   # repo-level only
    README.md  LICENSE  ...
  softaworks/                           # sparse vendor (single skill, not a subtree)
    CUSTOMISATION.md                    # provenance + sync commit
    jira/  SKILL.md  references/         # repo-level only (drives ankitpokhrel/jira-cli)
```

The vendor directories preserve the upstream repo layout exactly so
`git subtree pull` is conflict-free for unmodified content. Adopted
skills are surfaced via symlinks in `dotfiles/home/.claude/skills/` and
`dotfiles/config/opencode/skills/`; non-adopted upstream content stays
on disk but isn't exposed to either agent.

## Adopting / dropping a skill (global)

Adopt: add a symlink in both `home/.claude/skills/<name>` and
`config/opencode/skills/<name>` pointing into the relevant
`agent-skills/<vendor>/skills/[cloud/]<upstream-name>/`. Use the
upstream skill name verbatim — keeps customisations and upstream
references aligned.

Drop: remove the two symlinks. `bootstrap.sh` mirrors the skill dirs with
`rsync --delete`, so the dropped symlinks are pruned from `~/.claude/skills/`
and `~/.config/opencode/skills/` on the next sync (a plain rsync only adds).
The upstream content stays in the subtree so the skill can be re-adopted later
without re-fetching.

## Repo-level adoption (`.local-skills`)

Some skills should be active only in specific repos, not globally — e.g.
`jira` (driven by `ankitpokhrel/jira-cli`) and the Google Cloud skills. These
are vendored here but **not** symlinked into the global skill dirs. Instead, a
target repo opts in with a gitignored manifest at its root:

```json
{
  "skills": ["jira", "bigquery-basics", "gke-basics"],
  "auth": {
    "config": { "JIRA_CONFIG_FILE": "{{config_root}}/.jira-config.yml" }
  },
  "jira": {
    "installation": "cloud",
    "server": "https://acme.atlassian.net",
    "login": "me@acme.com",
    "auth_type": "basic",
    "project": "PROJ",
    "board": "",
    "token_op_ref": "op://Private/Jira PROJ/credential"
  }
}
```

Running `./setup.sh skills` (in the parent `macos-setup` repo) scans
`~/project` for these manifests and, per repo:

1. Symlinks each named skill into the repo's `.claude/skills/<name>` (resolved
   from anywhere under `~/.config/agent-skills/` by matching a dir with a
   `SKILL.md`).
2. If `auth.config` is present, renders a gitignored `mise.local.toml` `[env]`
   block from it — **non-secret env only** (e.g. `JIRA_CONFIG_FILE`,
   `JIRA_AUTH_TYPE`), values verbatim so mise template vars like
   `{{config_root}}` work.
3. Adds `/.claude/skills/` and `/mise.local.toml` to the repo's
   `.git/info/exclude`.
4. If a `jira` block is present, prints the one-time setup commands (it does
   not run them — they need an interactive 1Password unlock).

The execution context is plain shell env: mise's directory hook
(`mise activate bash`) exports the repo's `[env]` when you're in the repo, so
any agent (Claude Code / Codex / OpenCode) launched there inherits
`JIRA_CONFIG_FILE` etc. The manifest filename is in the global gitignore
(`config/git/ignore`), so it is never committed to the target repo.

### Why the token is not in mise

mise evaluates `[env]` **synchronously on every `cd`/prompt**, so a blocking
command there (e.g. `op read` when 1Password is not unlocked non-interactively)
freezes the shell. So the API token is **never** put in `mise.local.toml`.
Instead it lives in the **macOS Keychain**, which is exactly where `jira-cli`
looks it up at runtime (`keyring` service `jira-cli`, account = your login;
the lookup order is env → config → `.netrc` → Keychain). `./setup.sh skills`
prints two ready-to-run commands (skipped once each is done):

1. **Load the token into the Keychain from 1Password** (one `op read`, run
   interactively when you can unlock 1Password — no eager/repeated calls):

   ```sh
   security add-generic-password -U -s jira-cli -a "me@acme.com" \
       -w "$(op read 'op://Private/Jira PROJ/credential')"
   ```

2. **`jira init`** to write the server/board/project config (it reads the
   token from the Keychain), with `--installation/--server/--login/--auth-type/--project/--board`
   filled from the `jira` block, pointed at `auth.config.JIRA_CONFIG_FILE`.

## Updating upstream subtrees

Run `bash config/agent-skills/sync-upstream.sh` (from the dotfiles repo
root). The script:

1. Records each vendor's HEAD commit before pulling.
2. Runs `git subtree pull --prefix=config/agent-skills/<vendor>
   <upstream-url> main --squash` for each vendor.
3. For every adopted skill (the symlink targets), prints a stat-level
   diff between the pre-pull and post-pull state and lists touched
   files. **Always review this output before committing the pull —
   upstream changes may need customisation updates or break our
   symlinked skills.**

Manual subtree commands (if needed):

```sh
# From dotfiles repo root:
git subtree pull --prefix=config/agent-skills/anthropics \
    https://github.com/anthropics/skills main --squash
git subtree pull --prefix=config/agent-skills/google \
    https://github.com/google/skills main --squash
```

Use `--squash` always: each pull collapses to one commit, keeping the
dotfiles history readable. Last-pull SHA is in the squash commit
message (`git log --grep=git-subtree-dir`).

### Sparse vendors

When only a single skill is wanted out of a large upstream collection
(e.g. `softaworks/jira` from the 40+ skill `softaworks/agent-toolkit`),
the skill is vendored as a **sparse copy**, not a full subtree. These are
listed in the `sparse_vendors` table in `sync-upstream.sh`; the same
script refreshes them via a shallow sparse checkout + `rsync` and prints
a diff. Bump the `Last synced commit` in the vendor's `CUSTOMISATION.md`
after a sparse update.

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

## Why this lives in `config/`

`bootstrap.sh` rsyncs `config/` → `~/.config/`, so the canonical tree
lands at `~/.config/agent-skills/` automatically. Symlinks under
`home/.claude/skills/` and `config/opencode/skills/` resolve there at
agent runtime — one tree on disk, two agent-facing views.
