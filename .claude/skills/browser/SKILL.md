---
name: browser
description: Browser testing and debugging with Playwright and Chrome DevTools
allowed-tools:
  - mcp__playwright__browser_navigate
  - mcp__playwright__browser_click
  - mcp__playwright__browser_type
  - mcp__playwright__browser_snapshot
  - mcp__playwright__browser_screenshot
  - mcp__playwright__browser_fill
  - mcp__playwright__browser_tabs
  - mcp__playwright__browser_run_code
  - mcp__playwright__browser_console_messages
  - mcp__playwright__browser_network_requests
  - mcp__chrome_devtools__navigate
  - mcp__chrome_devtools__click
  - mcp__chrome_devtools__type_text
  - mcp__chrome_devtools__screenshot
  - mcp__chrome_devtools__evaluate
  - mcp__chrome_devtools__console_messages
  - mcp__chrome_devtools__network_requests
  - mcp__chrome_devtools__lighthouse_audit
  - mcp__chrome_devtools__start_tracing
  - mcp__chrome_devtools__stop_tracing
  - Bash(npx playwright *)
---

# Browser Testing and Debugging

Two browser tools are available. Choose based on the task:

## Playwright MCP — UX testing and automation

Use for: verifying user flows, filling forms, clicking through pages,
taking screenshots, asserting page state.

- Works on accessibility snapshots (structured data, no vision needed).
- Fast and token-efficient.
- Supports Chromium, Firefox, WebKit via `--browser` flag.
- `browser_snapshot` gives a structured DOM view — prefer it over screenshots
  for element inspection.
- `browser_run_code` can execute arbitrary Playwright scripts for complex
  multi-step interactions.
- `browser_network_requests` and `browser_console_messages` available for
  basic request/error checking.

## Chrome DevTools MCP — debugging and performance

Use for: performance profiling, Lighthouse audits, network waterfall
analysis, memory snapshots, JavaScript debugging.

- Full Chrome DevTools Protocol access.
- `lighthouse_audit` for accessibility, performance, SEO, best-practices
  scores.
- `start_tracing`/`stop_tracing` for performance traces.
- `network_requests` with detailed timing, headers, response bodies.
- `evaluate` for running JS in page context with DevTools access.
- `console_messages` for runtime errors and warnings.

## Overlap and when to pick which

Both can navigate, click, type, screenshot, and read console/network.
- **Testing a user flow or form?** Use Playwright — snapshot-based interaction
  is more reliable and faster.
- **Debugging why something is slow or broken?** Use Chrome DevTools —
  Lighthouse, tracing, and detailed network inspection.
- **Need both?** Start with Playwright for the interaction, switch to DevTools
  for profiling or deeper inspection.

$ARGUMENTS
