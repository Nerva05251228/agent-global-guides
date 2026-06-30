#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: install-global-guides.sh [options]

Installs sanitized global agent guide templates:
  AGENTS.md  -> ${CODEX_HOME:-$HOME/.codex}/AGENTS.md
  CLAUDE.md  -> ${CLAUDE_HOME:-$HOME/.claude}/CLAUDE.md
  skills/*   -> both Codex and Claude skills directories, repository mode only

Options:
  --source <dir>       Directory containing AGENTS.md and CLAUDE.md.
  --codex-home <dir>   Override Codex home directory.
  --claude-home <dir>  Override Claude home directory.
  --dry-run            Print actions without writing files.
  --skip-scan          Skip pre-install secret/personal-info scan.
  --skip-skills        Install only AGENTS.md and CLAUDE.md, not skills.
  -h, --help           Show this help.
USAGE
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(cd "$script_dir/.." && pwd)"
repo_root="$(cd "$skill_dir/../.." 2>/dev/null && pwd || true)"
repo_mode=0

is_repo_layout() {
  local root="$1"
  [[ -n "$root" \
    && -f "$root/docs/AGENTS.md" \
    && -f "$root/docs/CLAUDE.md" \
    && -f "$root/scripts/install-global-guides.sh" \
    && -f "$root/skills/agent-guides-installer/SKILL.md" ]]
}

source_dir=""
codex_home="${CODEX_HOME:-$HOME/.codex}"
claude_home="${CLAUDE_HOME:-$HOME/.claude}"
dry_run=0
skip_scan=0
skip_skills=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      source_dir="${2:?missing value for --source}"
      shift 2
      ;;
    --codex-home)
      codex_home="${2:?missing value for --codex-home}"
      shift 2
      ;;
    --claude-home)
      claude_home="${2:?missing value for --claude-home}"
      shift 2
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --skip-scan)
      skip_scan=1
      shift
      ;;
    --skip-skills)
      skip_skills=1
      shift
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

if [[ -z "$source_dir" ]]; then
  if is_repo_layout "$repo_root"; then
    source_dir="$repo_root/docs"
    repo_mode=1
  elif [[ -f "$skill_dir/assets/guides/AGENTS.md" && -f "$skill_dir/assets/guides/CLAUDE.md" ]]; then
    source_dir="$skill_dir/assets/guides"
  else
    echo "Could not find guide source directory. Pass --source <dir>." >&2
    exit 2
  fi
fi

source_dir="$(cd "$source_dir" && pwd)"
if [[ "$repo_mode" -eq 0 && "$source_dir" == "$repo_root/docs" ]]; then
  if is_repo_layout "$repo_root"; then
    repo_mode=1
  fi
fi
agents_src="$source_dir/AGENTS.md"
claude_src="$source_dir/CLAUDE.md"

if [[ ! -f "$agents_src" || ! -f "$claude_src" ]]; then
  echo "Source must contain AGENTS.md and CLAUDE.md: $source_dir" >&2
  exit 2
fi

if [[ "$skip_scan" -eq 0 ]]; then
  if [[ "$repo_mode" -eq 1 ]]; then
    "$script_dir/scan-guides.sh" --source "$source_dir" --source "$repo_root/skills"
  else
    "$script_dir/scan-guides.sh" --source "$source_dir"
  fi
fi

timestamp="$(date +%Y%m%d-%H%M%S)"

install_one() {
  local src="$1"
  local dest="$2"
  local label="$3"
  local dest_dir
  dest_dir="$(dirname "$dest")"

  if [[ "$dry_run" -eq 1 ]]; then
    echo "[dry-run] install $label: $src -> $dest"
    if [[ -f "$dest" ]]; then
      if cmp -s "$src" "$dest"; then
        echo "[dry-run] existing $label is already identical"
      else
        echo "[dry-run] would back up existing $dest to $dest.bak.$timestamp"
      fi
    fi
    return
  fi

  mkdir -p "$dest_dir"

  if [[ -f "$dest" ]]; then
    if cmp -s "$src" "$dest"; then
      echo "$label already up to date: $dest"
      return
    fi
    cp "$dest" "$dest.bak.$timestamp"
    echo "Backed up existing $label to $dest.bak.$timestamp"
  fi

  cp "$src" "$dest"
  chmod 0644 "$dest"

  if ! cmp -s "$src" "$dest"; then
    echo "Verification failed after installing $label: $dest" >&2
    exit 1
  fi

  echo "Installed $label: $dest"
}

install_one "$agents_src" "$codex_home/AGENTS.md" "Codex AGENTS.md"
install_one "$claude_src" "$claude_home/CLAUDE.md" "Claude CLAUDE.md"

skills_src=""
if [[ "$repo_mode" -eq 1 && -n "$repo_root" && -d "$repo_root/skills" ]]; then
  skills_src="$repo_root/skills"
fi

install_skills() {
  local target_root="$1"
  local label="$2"
  local target_dir="$target_root/skills"
  local resolved_src
  local resolved_target

  if [[ -z "$skills_src" || ! -d "$skills_src" ]]; then
    echo "No skills source directory found; skipping $label skills." >&2
    return
  fi

  resolved_src="$(cd "$skills_src" && pwd)"
  if [[ -d "$target_dir" ]]; then
    resolved_target="$(cd "$target_dir" && pwd)"
  else
    resolved_target="$target_dir"
  fi

  if [[ "$resolved_src" == "$resolved_target" || ( -e "$target_dir" && "$skills_src" -ef "$target_dir" ) ]]; then
    echo "Refusing to install $label skills because source and target are the same: $resolved_src" >&2
    return
  fi

  if [[ "$dry_run" -eq 1 ]]; then
    echo "[dry-run] install $label skills: $resolved_src -> $resolved_target"
    return
  fi

  mkdir -p "$target_dir"
  resolved_target="$(cd "$target_dir" && pwd)"
  if [[ "$resolved_src" == "$resolved_target" || "$skills_src" -ef "$target_dir" ]]; then
    echo "Refusing to install $label skills because source and target are the same: $resolved_src" >&2
    return
  fi

  local skill
  for skill in "$skills_src"/*; do
    [[ -d "$skill" && -f "$skill/SKILL.md" ]] || continue
    local name
    name="$(basename "$skill")"
    local dest="$target_dir/$name"
    if [[ -e "$dest" && "$skill" -ef "$dest" ]]; then
      echo "Skipping $label skill with identical source and target: $dest" >&2
      continue
    fi
    if [[ -d "$dest" ]]; then
      if diff -qr "$skill" "$dest" >/dev/null 2>&1; then
        echo "$label skill already up to date: $dest"
        continue
      fi
      cp -a "$dest" "$dest.bak.$timestamp"
      rm -rf "$dest"
      echo "Backed up existing $label skill to $dest.bak.$timestamp"
    fi
    cp -a "$skill" "$dest"
    echo "Installed $label skill: $dest"
  done
}

if [[ "$skip_skills" -eq 0 ]]; then
  if [[ "$repo_mode" -eq 1 ]]; then
    install_skills "$codex_home" "Codex"
    install_skills "$claude_home" "Claude"
  else
    echo "Installed-skill mode detected; skipping modular skills. Clone the full repository to install skills/*."
  fi
fi

if [[ "$dry_run" -eq 1 ]]; then
  echo "Dry run complete. No files were changed."
else
  echo "Install complete. Restart Codex and Claude Code sessions to guarantee the new global guides are loaded."
fi
