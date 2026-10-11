# Shell environment, PATH and credentials

## PATH layering

A login shell resolves commands in this order:

```text
mise shims  ->  Homebrew (GNU tools' gnubin, explicit keg-only)  ->  Nix (/run/current-system/sw/bin)  ->  macOS
```

- macos-setup `.path` is sourced last by dotfiles `config/bash/.bash_profile`, and mise activates
  after it.
- Homebrew wins over Nix for anything both provide. A tool moves to Nix by leaving the Brewfile
  and being uninstalled from Homebrew, never by reordering PATH. That is how `nvim` resolves to the
  Nix build.
- Keg-only formulae need an explicit `.path` entry to win: `curl` and `libpq` (`psql`,
  `pg_dump`) have one; `binutils` and `e2fsprogs` deliberately do not, since they would shadow the
  system toolchain.
- The GNU userland comes first once setup has run. macos-setup's bootstrap code still has to run
  on stock BSD tools; its `docs/conventions.md` says how.

## Credentials

- `~/.config/bash/.credentials` is untracked, mode `0600`, and maintained by the owner. dotfiles
  `.bash_profile` sources it first, so interactive shells export the tool API keys it holds, such
  as `CONTEXT7_API_KEY`. Non-interactive shells (`bash -lc`, cron) and apps started from the Dock
  or Finder do not see them. Its template is macos-setup `.credentials.dist`, and `backup.sh`
  includes it.
- Harness configs reference these variables by name (context7 in each harness); they never hold
  the values.

## Per-workspace env (`mise.local.toml`)

`./setup.sh projects` scans `~/project` for gitignored `.tapppi-project.{json,yml,yaml}`
manifests. For each workspace it renders a `mise.local.toml` whose `[env]` loads a local `0600`
dotenv file through mise's `_.file`; mise walks up across git boundaries, so every repo under the
workspace inherits it. For a `jira` block it prints the one-time commands that write that dotenv
from 1Password. The header of macos-setup `tasks/projects.sh` documents the manifest.

## XDG

dotfiles `config/bash/.exports` sets `XDG_CONFIG_HOME=~/.config`, plus explicit overrides for
tools that need a path (`INPUTRC`, `WGETRC`, `KUBECONFIG`, `PGPASSFILE` and others).
