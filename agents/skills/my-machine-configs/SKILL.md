---
name: my-machine-configs
description: >-
  Where this Mac's configuration lives and how a change to it deploys: the systems, macos-setup
  and dotfiles repos, the tapppi-skills and ikeh marketplaces, each agent harness's config
  (Claude Code, Codex, OpenCode, Cursor, Pi), user-level skills, plugins and MCP servers, the
  shell environment, PATH and credentials. Use it before changing any of these, and whenever a
  task touches them without saying so: installing a CLI tool, package or runtime; enabling a
  plugin, skill or MCP server for a repo; setting a harness option or env var; editing the
  user-level agent instructions; changing anything under ~/.config, ~/.claude, ~/.codex,
  ~/.cursor or ~/.pi; or answering where some setting is managed.
---

# My machine configs

What configures this Mac, where each piece is managed, and how a change reaches the live machine.
It covers this machine only. For a harness's generic configuration and its docs, use the
harness's own documentation or configuration skill (for Pi, `pi-config`).

## The repos

All checkouts live under `~/project/github/`.

| Repo | Checkout | Role |
| --- | --- | --- |
| [systems](https://github.com/Tapppi/systems) | `tapppi/systems` | Nix flakes: nix-darwin for this Mac, the Neovim flake, later NixOS hosts. Public |
| [macos-setup](https://github.com/Tapppi/macos-setup) | `tapppi/macos-setup` | Brewfile, `setup.sh` and `tasks/*.sh`: installs, harness setup, app config, macOS defaults, per-project env. Public |
| [dotfiles](https://github.com/Tapppi/dotfiles) | `tapppi/macos-setup/dotfiles` (submodule) | Shell and harness config synced into `~`; the user-level agent instructions and this skill, under `agents/`. Public |
| Tapppi/skills | `tapppi/skills` | The `tapppi-skills` marketplace: shared plugins and skill bundles. Private |
| mantadevoy/ikeh | `mantadevoy/ikeh` | The `ikeh` marketplace: `ikeh-git`, `ikeh-development`. Private |
| Tapppi/tieto | `tapppi/tieto` | The owner's personal knowledge base (Obsidian); migration notes in `konehuone/sysmi/`. Private |
| workspace | `tapppi` (local only) | Coordinates the migration; its `AGENTS.md` holds the live state |

The idea behind the split:

- **systems is the declarative future.** It already owns a deliberately narrow set on this Mac:
  Nix-built `nvim`, `codex`, `opencode`, `pi` and `herdr`, Hammerspoon, Codex's system config. Its
  `AGENTS.md` lists what it owns; everything else is still macos-setup's.
- **macos-setup with dotfiles is the imperative legacy** that still owns most of the machine, and
  is migrating into systems. dotfiles is public: it is due to split into a public example and
  private config in systems, and systems itself awaits a private counterpart. Keep private values
  out of all three public repos.
- **The marketplaces hold capability** that user-level config or a repo enables; they configure
  nothing on their own.
- **tieto holds notes and decisions**, never config.

## How a change deploys

1. **Edit the source** in the owning repo, in a worktree, following that repo's `AGENTS.md`. The
   deployed copy under `~` is a target, not a source.
2. **Render generated files.** The user-level instruction files come from `dotfiles/agents/`:
   edit there, run `agents/render.sh`, and commit sources and outputs together.
3. **Sync** with `./setup.sh dotfiles`: `bootstrap.sh` rsyncs dotfiles `home/` to `~` and
   `config/` to `~/.config/`, then the dispatch re-asserts tool-written config and the
   `my-machine-configs` link. The rsync never deletes, so a file removed from dotfiles stays live
   until someone deletes it.
4. **Install or re-assert** with a `./setup.sh` dispatch (`install`, or one harness such as
   `codex`, `pi`, `opencode`, `context7`, `herdr`): brew packages, mise runtimes, plugins, skill
   links and MCP servers. `./setup.sh` with no argument lists the dispatches, and the macos-setup
   `README.md` describes them.
5. **Activate systems** with `nix run .#build-switch` in the systems checkout.

Steps 3 to 5 are owner steps: give the owner the command. Most dispatches ask for `sudo`, and some
refuse while the harness they change is running. A repo or skill may allow a narrow exception;
macos-setup allows `./setup.sh projects` for its `tool-update-review` skill only.

Untracked files that a tool owns (`~/.claude.json`, `~/.codex/config.toml`, Pi's
`~/.pi/agent/settings.json` and `mcp.json`) change through that tool's CLI. When a tool's own
entries go missing, re-run the dispatch that writes them rather than copying them into dotfiles.

## Where to change what

| To change | Go to |
| --- | --- |
| A CLI tool or app | systems if it already owns that kind of tool, else macos-setup `Brewfile` then `intel.Brewfile` (a keg-only formula also needs `.path`). Ask before any install |
| A language runtime | dotfiles `config/mise/config.toml` |
| Shell env, aliases, functions | dotfiles `config/bash/` (`.exports`, `.aliases`, `.functions`); macos-setup `.path`, `.extra` |
| A secret or API key | The owner's `~/.config/bash/.credentials`, or a workspace dotenv: [shell-env.md](references/shell-env.md) |
| Git config | dotfiles `config/git/config`; identity and signing key in macos-setup `.extra` |
| A harness setting, env var, permission or hook | That harness's reference below |
| A plugin, skill or MCP server for one repo | macos-setup `docs/skills.md`: the committed per-repo files and the per-machine steps |
| A user-level skill or the user-level instructions | dotfiles `agents/` and its `README.md` |
| App configuration, login items, macOS defaults | macos-setup `tasks/config.sh`, `tasks/macos.sh` |
| Hotkeys and Hammerspoon | systems |

## References

Read the one the task needs:

- [claude-code.md](references/claude-code.md), [codex.md](references/codex.md),
  [opencode.md](references/opencode.md), [cursor.md](references/cursor.md),
  [pi.md](references/pi.md): per harness, its config files and who owns them, what dotfiles
  tracks, where its skills, plugins and MCP servers come from, and how to restore tool-owned parts.
- [shell-env.md](references/shell-env.md): PATH layering, Homebrew versus Nix, credentials,
  `mise.local.toml`, XDG.

For deeper detail, read the repos' own docs, under `~/project/github/tapppi/`:

- `macos-setup/README.md` (tasks and dispatches), `macos-setup/docs/harnesses.md` (how setup
  configures each harness), `macos-setup/docs/skills.md` (skill and plugin routing),
  `macos-setup/docs/conventions.md` (script, Brewfile and PATH conventions);
- `macos-setup/dotfiles/README.md`, `macos-setup/dotfiles/docs/harnesses.md` (config locations and
  tool-owned files), `macos-setup/dotfiles/agents/README.md` (the instruction sources);
- `systems/AGENTS.md` (what systems owns, and its build and deploy rules).
