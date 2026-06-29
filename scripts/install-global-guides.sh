#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$repo_root/skills/agent-guides-installer/scripts/install-global-guides.sh" --source "$repo_root/docs" "$@"
