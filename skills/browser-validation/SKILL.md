---
name: browser-validation
description: Validate real-machine behavior, web UI behavior, screenshots, traces, browser automation, Playwright checks, and Xvfb/headless UI evidence. Use when a task needs browser validation, screenshots, visual verification, canvas or UI rendering checks, or real-machine testing evidence.
---

# Browser Validation

## Real-machine and screenshot validation

For real-machine testing, prefer `computer-use` when available and proceed without asking for extra confirmation.

If `computer-use` is unavailable, use screenshot-based validation and store screenshots under `.debug/`.

For web UI validation in environments without a visible GUI:

- Prefer Playwright or an equivalent browser automation tool in headless mode for screenshots, traces, and assertions.
- If a headed browser is required on Linux but no physical display or X server is available, use Xvfb, for example `xvfb-run <command>`.
- Store screenshots, traces, and logs in the dated `.debug/` structure.
- Treat screenshots as evidence to support validation, not as a substitute for build/test checks.
