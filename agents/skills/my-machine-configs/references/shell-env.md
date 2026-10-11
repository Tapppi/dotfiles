# Shell environment, PATH and credentials

## PATH layering

A login shell resolves commands in this order:

```text
mise shims  ->  Homebrew (GNU tools' gnubin, explicit keg-only)  ->  Nix (/run/current-system/sw/bin)  ->  macOS
```

- Homebrew wins over Nix for anything both provide, so a tool moves to Nix by leaving Homebrew,
  never by reordering PATH. That is how `nvim` resolves to the Nix build.
- The PATH order is set in macos-setup and dotfiles; macos-setup `docs/conventions.md` has the
  details, keg-only formulae included.

## Credentials

- `~/.config/bash/.credentials` is untracked, mode `0600`, and maintained by the owner.
  Interactive shells source it, so they export the tool API keys it holds, such as
  `CONTEXT7_API_KEY`. Non-interactive shells (`bash -lc`, cron) and apps started from the Dock or
  Finder do not see them.
- Harness configs reference these variables by name (context7 in each harness); they never hold
  the values.

## Per-workspace env (`mise.local.toml`)

A workspace directory can hold a `mise.local.toml` whose `[env]` loads a local `0600` dotenv file;
mise walks up across git boundaries, so every repo under the workspace inherits it. macos-setup's
`./setup.sh projects` renders it from the workspace's manifest; its `README.md` says how.

## XDG

dotfiles `config/bash/.exports` sets `XDG_CONFIG_HOME=~/.config`, plus explicit overrides for
tools that need a path (`INPUTRC`, `WGETRC`, `KUBECONFIG`, `PGPASSFILE` and others).
