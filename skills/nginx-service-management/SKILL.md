---
name: nginx-service-management
description: Inspect, modify, reload, remove, and report nginx service configuration safely, including effective nginx -T inspection, listener/proxy port reporting, static directories, service removal, SSL caution, and production config guardrails. Use when work touches nginx, reverse proxy routes, ports, static hosting, certificates, service removal, or production web server configuration.
---

# Nginx Service Management

## Nginx configuration management

Before changing nginx, inspect the currently effective configuration instead of only reading `sites-available`.

Use:

```bash
nginx -T
ls -la /etc/nginx/sites-enabled /etc/nginx/sites-available /etc/nginx/conf.d
ss -ltnp | rg 'nginx|:<port>'
```

Distinguish these scopes:

- `sites-enabled/*` is the effective entrypoint set.
- `sites-available/*` is only available configuration; it is effective only when symlinked from `sites-enabled`.
- `*.bak` files are historical backups and must not be treated as active configuration unless the user explicitly asks to inspect or clean historical config.

When modifying nginx:

1. State which file, server block, and locations will be changed.
2. Prefer editing `/etc/nginx/sites-available/<site>.conf`; never edit `nginx -T` output directly.
3. Record a short summary of the current relevant config before changing it.
4. Run `nginx -t` after edits.
5. Reload nginx only after `nginx -t` succeeds.
6. Prefer `systemctl reload nginx` over restart unless reload is insufficient.
7. After reload, verify listeners and route mappings with `nginx -T`, `ss -ltnp`, or both.

When adding a service:

- Confirm the backend port is free before assigning it.
- Record the URL path, static directory, backend port, and process manager in the response or owning docs.
- Prefer path-mounted apps by default:
  - Static UI: `/<app>/`
  - API: `/api/<app>/`
- Prefer static files under `/var/www/<app>/`.
- If a backend is meant to be exposed only through nginx, prefer binding it to `127.0.0.1`.
- If a backend must bind to `0.0.0.0`, state why.

When removing a service:

1. Stop and remove the corresponding process from its process manager, such as PM2 or systemd.
2. Remove the matching `location` blocks from the effective nginx site config.
3. Remove the matching static directory, such as `/var/www/<app>/`, when requested.
4. Before deleting project directories, confirm the exact path matches the user's request.
5. If PM2 is used, run `pm2 save` after deleting the process.
6. Run `nginx -t`.
7. Reload nginx.
8. Verify that:
   - The removed route no longer appears in effective `nginx -T` output.
   - The removed backend port is no longer referenced by nginx.
   - The removed process is no longer running.
   - The removed directories are gone or intentionally retained.

Port reporting rules:

- Separate nginx public listener ports from backend proxy ports.
- "Nginx listener ports" means `listen` directives, such as `80` and `443`.
- "Nginx backend proxy ports" means ports in `proxy_pass`, such as `20001` or `8317`.
- When reporting ports to the user, explicitly label these two categories and do not describe backend ports as nginx listener ports.

Security rules:

- Never print private key file contents.
- It is acceptable to reference certificate and key paths, but not private key contents.
- Be extra cautious when changing SSL, certificate, reverse proxy headers, callback routes, OAuth routes, or `/callback/` routes, because these commonly affect login, callbacks, or streaming connections.
- For websocket or long-running proxy routes, preserve `Upgrade`, `Connection`, longer timeouts, and `proxy_buffering off` unless it is explicitly safe to remove them.
