#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scan-guides.sh [--source <dir>]...

Scans agent guide markdown files and bundled skill files for known personal
values and common secret patterns before installing or publishing them.
USAGE
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(cd "$script_dir/.." && pwd)"
repo_root="$(cd "$skill_dir/../.." 2>/dev/null && pwd || true)"
sources=()

is_repo_layout() {
  local root="$1"
  [[ -n "$root" \
    && -f "$root/docs/AGENTS.md" \
    && -f "$root/docs/CLAUDE.md" \
    && -f "$root/scripts/install-global-guides.sh" \
    && -f "$root/skills/agent-guides-installer/SKILL.md" ]]
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      sources+=("${2:?missing value for --source}")
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ ${#sources[@]} -eq 0 ]]; then
  if is_repo_layout "$repo_root"; then
    sources+=("$repo_root/docs")
    if [[ -d "$repo_root/skills" ]]; then
      sources+=("$repo_root/skills")
    fi
  elif [[ -f "$skill_dir/assets/guides/AGENTS.md" && -f "$skill_dir/assets/guides/CLAUDE.md" ]]; then
    sources+=("$skill_dir/assets/guides")
  else
    echo "Could not find guide source directory. Pass --source <dir>." >&2
    exit 2
  fi
fi

resolved_sources=()
for source_dir in "${sources[@]}"; do
  if [[ ! -d "$source_dir" ]]; then
    echo "Source directory does not exist: $source_dir" >&2
    exit 2
  fi
  resolved_sources+=("$(cd "$source_dir" && pwd)")
done

mapfile -d '' files < <(
  find "${resolved_sources[@]}" -type f \( -name '*.md' -o -name '*.sh' -o -name '*.yaml' -o -name '*.yml' \) -print0 \
    | while IFS= read -r -d '' file; do
        [[ "$(basename "$file")" == "scan-guides.sh" ]] && continue
        printf '%s\0' "$file"
      done \
    | sort -z
)
if [[ ${#files[@]} -eq 0 ]]; then
  echo "No scan target files found under: ${resolved_sources[*]}" >&2
  exit 2
fi

failed=0

check_fixed() {
  local label="$1"
  local value="$2"
  local output
  if output="$(grep -RFn -- "$value" "${files[@]}" 2>/dev/null)"; then
    echo "Potential leak: $label" >&2
    echo "$output" >&2
    failed=1
  fi
}

check_regex() {
  local label="$1"
  local pattern="$2"
  local output
  if output="$(grep -REn -- "$pattern" "${files[@]}" 2>/dev/null)"; then
    echo "Potential secret: $label" >&2
    echo "$output" >&2
    failed=1
  fi
}

check_regex_except() {
  local label="$1"
  local pattern="$2"
  local exclude="$3"
  local output
  output="$(grep -REn -- "$pattern" "${files[@]}" 2>/dev/null || true)"
  output="$(printf '%s\n' "$output" | grep -Ev -- "$exclude" || true)"
  if [[ -n "$output" ]]; then
    echo "Potential leak: $label" >&2
    echo "$output" >&2
    failed=1
  fi
}

check_regex_except "real email address" '[A-Za-z0-9._%+-]+@([A-Za-z0-9-]+\.)+[A-Za-z]{2,}' 'example\.com'
check_regex "local Windows workspace path" '[A-Za-z]:/(Users|Workspace|Work|Projects)/[^[:space:]`"'\''<>]+'
check_regex "private key block" 'BEGIN (RSA |OPENSSH |EC |DSA )?PRIVATE KEY'
check_regex "AWS access key" 'AKIA[0-9A-Z]{16}'
check_regex "OpenAI-style API key" 'sk-[A-Za-z0-9_-]{20,}'
check_regex "GitHub token" 'gh[pousr]_[A-Za-z0-9_]{20,}'
check_regex "Slack token" 'xox[baprs]-[A-Za-z0-9-]{20,}'
check_regex "Google API key" 'AIza[0-9A-Za-z_-]{20,}'
check_regex "Authorization header" 'Authorization:[[:space:]]*[^[:space:]]+'
check_regex "Bearer token" 'Bearer[[:space:]]+[A-Za-z0-9._-]{20,}'
check_regex "database URL" '(postgresql|postgres|mysql|redis)://[^[:space:]]+'
check_regex "credential assignment" '^[[:space:]]*(export[[:space:]]+)?[A-Z0-9_]*(KEY|TOKEN|SECRET|PASSWORD|PASS|PWD)[A-Z0-9_]*[[:space:]]*=[[:space:]]*[^[:space:]]+'

if [[ "$failed" -ne 0 ]]; then
  echo "Guide scan failed." >&2
  exit 1
fi

echo "Guide scan passed: ${resolved_sources[*]}"
