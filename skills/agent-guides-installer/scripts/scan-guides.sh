#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scan-guides.sh [--source <dir>]...

Scans all shipped guide, skill, script, workflow, test, and plan source files
for personal values, machine-specific paths, and common secret patterns.
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
    sources+=("$repo_root")
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

files=()
while IFS= read -r -d '' file; do
  case "$(basename "$file")" in
    scan-guides.sh|scan-guides.ps1) continue ;;
  esac
  files[${#files[@]}]="$file"
done < <(
  find "${resolved_sources[@]}" \
    -type d \( -name .git -o -name .debug -o -name backups \) -prune -o \
    -type f \( \
      -name '*.md' -o -name '*.sh' -o -name '*.ps1' -o \
      -name '*.yaml' -o -name '*.yml' -o -name '*.json' \
    \) -print0
)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No scan target files found under: ${resolved_sources[*]}" >&2
  exit 2
fi

if ! awk '
  function report(label) {
    print "Potential leak: " label > "/dev/stderr"
    print FILENAME ":" FNR ":" $0 > "/dev/stderr"
    failed = 1
  }
  {
    if ($0 ~ /[A-Za-z0-9._%+-]+@([A-Za-z0-9-]+\.)+[A-Za-z][A-Za-z]+/ && $0 !~ /example\.com/) report("real email address")
    if ($0 ~ /[A-Za-z]:[\\/]+(Users|Workspace|Work|Projects)[\\/]+[^[:space:]`"\047<>]+/) report("local Windows workspace path")
    if ($0 ~ /\/(Users|home)\/[^/[:space:]`"\047<>]+\/[^[:space:]`"\047<>]+/) report("local Unix home path")
    if ($0 ~ /BEGIN (RSA |OPENSSH |EC |DSA )?PRIVATE KEY/) report("private key block")
    if ($0 ~ /AKIA[0-9A-Z]{16}/) report("AWS access key")
    if ($0 ~ /sk-[A-Za-z0-9_-]{20,}/) report("OpenAI-style API key")
    if ($0 ~ /gh[pousr]_[A-Za-z0-9_]{20,}/) report("GitHub token")
    if ($0 ~ /xox[baprs]-[A-Za-z0-9-]{20,}/) report("Slack token")
    if ($0 ~ /AIza[0-9A-Za-z_-]{20,}/) report("Google API key")
    if ($0 ~ /Authorization:[[:space:]]*[^[:space:]]+/) report("Authorization header")
    if ($0 ~ /Bearer[[:space:]]+[A-Za-z0-9._-]{20,}/) report("Bearer token")
    if ($0 ~ /(postgresql|postgres|mysql|redis):\/\/[^[:space:]]+/) report("database URL")
    if ($0 ~ /^[[:space:]]*(export[[:space:]]+)?[A-Z0-9_]*(KEY|TOKEN|SECRET|PASSWORD|PASS|PWD)[A-Z0-9_]*[[:space:]]*=[[:space:]]*[^[:space:]]+/) report("credential assignment")
  }
  END { exit failed ? 1 : 0 }
' "${files[@]}"; then
  echo "Guide scan failed." >&2
  exit 1
fi

echo "Guide scan passed: ${resolved_sources[*]}"
