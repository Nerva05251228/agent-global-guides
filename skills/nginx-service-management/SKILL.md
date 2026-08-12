---
name: nginx-service-management
description: Use when work may inspect, modify, validate, reload, remove, or troubleshoot nginx, reverse proxies, web-server routes, listeners, certificates, or upstream ports.
---

# Nginx Service Management

## Establish whether nginx is actually in use

Before changing nginx, discover the operating system, active web server, nginx executable and configuration prefix, effective configuration, service manager, running processes, public listeners, and proxy targets.

- Windows: inspect Windows Services, IIS, nginx processes and command lines, configuration near the discovered executable, and `Get-NetTCPConnection`.
- Linux: inspect `nginx -T`, systemd, supervisor, PM2, Docker, process command lines, `ss`, and `lsof`.
- macOS: inspect `nginx -T`, launchd, Homebrew Services, Docker, process command lines, and `lsof`.
- Shared cases: containerized nginx, PM2-managed wrappers, and manually started processes.

Do not assume `/etc/nginx`, `sites-available`, systemd, or ports 80/443. If nginx is absent or inactive, do not install it, enable it, or replace IIS, Apache, Caddy, a managed proxy, or another active server without explicit authorization. Stop the nginx-specific action and report `not verified` when the required environment is unavailable.

## Modification workflow

1. Inspect the effective configuration, preferably with the discovered nginx executable's `-T` option.
2. State the exact file, server block, route, listener, and upstream that would change.
3. Treat backup files as historical, not active configuration.
4. Preserve websocket and long-running proxy requirements such as `Upgrade`, `Connection`, longer timeouts, and `proxy_buffering off` unless removal is explicitly safe.
5. Run the discovered nginx executable's configuration test after edits.
6. Reload only after validation succeeds, using the current service manager or established process method.
7. Verify effective configuration, public listeners, backend proxy ports, route behavior, and relevant logs.

## Adding or removing routes and services

- Confirm a backend listener is free and identify its process owner before assignment.
- Prefer loopback binding for backends exposed only through a proxy; explain any `0.0.0.0` binding.
- Before removal, disclose exact process, route, configuration, and filesystem targets.
- Remove only user-authorized service data and project directories.
- After removal, verify the process, route, listener references, and requested directories are absent or intentionally retained.

## Port reporting

Always separate:

- Public nginx listener ports from `listen` directives.
- Backend proxy ports from `proxy_pass` or equivalent upstream configuration.

Do not describe backend ports as nginx listener ports.

## Security and reporting

- Never print private key contents; certificate and key paths may be referenced.
- Treat SSL, authentication callbacks, OAuth routes, streaming routes, and production changes as high risk.
- Inspect state and logs before retrying a failed change.
- Final reporting must state executed and not-executed actions, verification status, rollback/recovery, and residual risk.
