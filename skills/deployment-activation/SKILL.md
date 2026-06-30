---
name: deployment-activation
description: Activate existing project changes in the deployed environment by discovering actual frontend build commands, dist output, nginx roots, API proxying, FastAPI process management, rebuilding, deploying static assets, testing nginx, reloading, restarting backend safely, and verifying health/API/frontend behavior. Use when the user asks to make current project changes take effect, redeploy, rebuild frontend, reload nginx, restart FastAPI, or verify deployed frontend/API behavior.
---

# Deployment Activation

## Deployment activation workflow

Use this workflow when the user asks to make the current project's changes take effect in a deployed web app, redeploy frontend assets, reload nginx, restart a FastAPI backend, or otherwise activate local changes on the running service.

First inspect the actual deployment. Do not assume:

- Frontend package manager and build command. Identify them from lockfiles, `package.json` scripts, project docs, or existing deployment scripts.
- Frontend build output directory. Identify it from the framework config, build script, or observed build output.
- The currently effective nginx `root`, active `server` block, and active `location` blocks from `nginx -T`.
- Whether `/api` is reverse-proxied to FastAPI, and to which host, port, and path.
- How the FastAPI backend is managed: PM2, systemd, supervisor, docker, or a manual `uvicorn` process. Check the real process manager and running processes before restarting anything.

Safe activation sequence:

1. Rebuild the frontend with the actual package manager and build command.
2. Deploy the latest frontend build artifacts to the directory currently served by nginx.
3. Run `nginx -t`.
4. Reload nginx only after `nginx -t` succeeds.
5. Restart the FastAPI backend using its current real management method.
6. Check the backend listener port, health endpoint, and `/api` endpoint.
7. Open or request the frontend page and confirm static assets and API requests are working.

Safety constraints:

- Do not delete databases.
- Do not clear user-uploaded files.
- Do not modify production secrets or keys.
- Do not start duplicate `uvicorn` processes. If the backend is manually managed, identify and handle the existing process deliberately before starting another one.
- If a command fails, inspect relevant logs before attempting a fix. Use the current manager's logs, such as PM2 logs, `journalctl`, supervisor logs, docker logs, nginx error logs, or application logs.
- Be careful with copy or sync commands into nginx roots. Confirm source and destination paths first, and preserve non-build directories such as uploads, media, and user data.

Final response for activation work must include:

- Key commands executed.
- Frontend build result.
- Deployment target directory and copy/sync result.
- `nginx -t` and reload result.
- Backend restart method and result.
- Verified backend port, health URL, `/api` URL, and frontend URL.
- Remaining issues, if any.
