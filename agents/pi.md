# Pi: user-level instructions

Generated from dotfiles `agents/`: edit there, run `agents/render.sh`, then sync. Pi reads this
file as `~/.pi/agent/AGENTS.md` and does not read `~/.claude/CLAUDE.md`.

## Pi configuration

- `settings.json`, `auth.json`, `models-store.json` and `sessions/` in `~/.pi/agent/` are
  Pi-owned and untracked; change settings and packages through Pi (`pi install`). Never copy
  credentials into a repository. Skills come from Pi's skill directories and installed packages;
  macos-setup's `docs/skills.md` lists where.
- Pi loads one context file per directory, preferring `AGENTS.md` to `CLAUDE.md`, and follows no
  `@` imports. Repos here keep their rules in `AGENTS.md`; a `CLAUDE.md` that only imports it
  carries nothing to Pi.
