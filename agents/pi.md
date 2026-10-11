# Pi: user-level instructions

Generated from dotfiles `agents/`; a hand edit here is lost at the next sync.

## Pi

- MCP servers, context7 among them, are reached by default through codemode: find their tools with
  `searchTools()`. A tool is named `mcp__<server>__<tool>`, with each non-alphanumeric character
  in a name replaced by `_`.
- context7 serves current library, framework, SDK, API and CLI documentation; prefer it to web
  search for those.
- If a loaded context file only references another file as `@path`, read that file.
- For Pi's own configuration and its docs, load the `pi-config` skill. For how this machine sets
  Pi up: the `my-machine-configs` skill, `references/pi.md`.
