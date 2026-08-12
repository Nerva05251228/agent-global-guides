---
name: deployment-activation
description: Use when a user asks to rebuild, redeploy, restart, reload, activate, or verify project changes in a deployed environment.
---

# Deployment Activation

## Discover before acting

Do not assume the project uses nginx, FastAPI, PM2, systemd, a static frontend, or any particular operating system. Inspect repository docs, manifests, lockfiles, deployment scripts, running processes, containers, service managers, listeners, proxy configuration, and health endpoints to identify:

- Frontend package manager, build command, output directory, and served destination.
- Backend runtime, start command, listener, health endpoint, and current management method.
- Reverse proxy or web server, effective configuration, public listeners, and backend routes.
- Deployment mechanism: local copy, container image, orchestrator, managed platform, remote host, or another established workflow.
- Which changed files actually require frontend rebuild, backend restart, proxy reload, migration, or no activation step.

Platform discovery examples:

- Windows: Windows Services, IIS, Task Scheduler, PM2, Docker, manual processes, `Get-NetTCPConnection`, and process command lines.
- Linux: systemd, supervisor, PM2, Docker, manual processes, `ss`, and `lsof`.
- macOS: launchd, Homebrew Services, PM2, Docker, manual processes, and `lsof`.

Nginx, FastAPI, PM2, and systemd are supported scenarios, not universal prerequisites. If an expected component is absent or inactive, do not install, replace, or enable it without explicit user authorization.

## Activation sequence

1. State the discovered architecture and exact affected components.
2. Confirm source and destination paths before copying or synchronizing artifacts.
3. Build only required components with the project's actual commands.
4. Apply the project's established deployment method.
5. Validate configuration before reload or restart when the component provides a validator.
6. Inspect current process ownership and logs before any restart; do not start duplicate processes.
7. Verify listeners, health endpoints, API behavior, frontend assets, and browser behavior relevant to the change.
8. Explicitly report skipped components and why they were unaffected or unavailable.

## Safety

- Never delete databases, user uploads, or production secrets without exact authorization.
- Preserve non-build directories when deploying static assets.
- For failed high-risk steps, inspect state and logs before retrying; do not use blind retry loops.
- Before production deployment or an irreversible external action, disclose the exact target and scope and obtain required authorization.
- Keep rollback or recovery information available and report whether each action was executed or not executed.

## Final report

Include:

- Discovered frontend, backend, proxy, process manager, listeners, and deployment target.
- Components changed, commands executed, and components skipped.
- Build, config validation, reload/restart, health/API/frontend/browser verification results.
- Explicit status for each check: `verified`, `failed with reason`, or `not verified`.
- Rollback or recovery path and residual risk.
