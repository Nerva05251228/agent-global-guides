#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: install-global-guides.sh [options]

Installs sanitized global agent guides and, from a repository clone, the
complete modular skill package into isolated Codex and Claude homes.

Options:
  --source <dir>          Directory containing AGENTS.md and CLAUDE.md.
  --codex-home <dir>      Override Codex home directory.
  --claude-home <dir>     Override Claude home directory.
  --github-owner <value>  Render this local GitHub owner into both guides.
  --git-email <value>     Render this local Git commit email into both guides.
  --backup                Back up changed targets before replacement.
  --no-backup             Replace targets without installer recovery backups.
  --dry-run               Print validated actions without writing target files.
  --skip-skills           Install only AGENTS.md and CLAUDE.md.
  -h, --help              Show this help.
USAGE
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(cd "$script_dir/.." && pwd)"
repo_root="$(cd "$skill_dir/../.." 2>/dev/null && pwd || true)"

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
github_owner=""
git_email=""
backup_policy=""
dry_run=0
skip_skills=0
repo_mode=0

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
    --github-owner)
      github_owner="${2:?missing value for --github-owner}"
      shift 2
      ;;
    --git-email)
      git_email="${2:?missing value for --git-email}"
      shift 2
      ;;
    --backup)
      [[ "$backup_policy" != "disabled" ]] || { echo "--backup conflicts with --no-backup" >&2; exit 2; }
      backup_policy="enabled"
      shift
      ;;
    --no-backup)
      [[ "$backup_policy" != "enabled" ]] || { echo "--no-backup conflicts with --backup" >&2; exit 2; }
      backup_policy="disabled"
      shift
      ;;
    --dry-run)
      dry_run=1
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
if [[ "$repo_mode" -eq 0 && -n "$repo_root" && "$source_dir" == "$repo_root/docs" ]] && is_repo_layout "$repo_root"; then
  repo_mode=1
fi

agents_src="$source_dir/AGENTS.md"
claude_src="$source_dir/CLAUDE.md"
if [[ ! -f "$agents_src" || ! -f "$claude_src" ]]; then
  echo "Source must contain AGENTS.md and CLAUDE.md: $source_dir" >&2
  exit 2
fi

# Mandatory source validation is deliberately completed before any target write.
if [[ "$repo_mode" -eq 1 ]]; then
  "$script_dir/scan-guides.sh" --source "$repo_root"
else
  "$script_dir/scan-guides.sh" --source "$source_dir"
fi

if [[ -z "$backup_policy" ]]; then
  if [[ -t 0 && -t 1 ]]; then
    printf 'Create backups before replacing files? [Y/n] '
    IFS= read -r backup_answer || backup_answer=""
    case "$backup_answer" in
      n|N|no|NO|No) backup_policy="disabled" ;;
      *) backup_policy="enabled" ;;
    esac
  else
    backup_policy="enabled"
  fi
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
codex_backup_root="$codex_home/backups/agent-global-guides/$timestamp"
claude_backup_root="$claude_home/backups/agent-global-guides/$timestamp"

if [[ "$backup_policy" == "enabled" ]]; then
  echo "Backup policy: enabled"
  echo "Codex backup snapshot: $codex_backup_root"
  echo "Claude backup snapshot: $claude_backup_root"
else
  echo "Backup policy: disabled; installer recovery unavailable."
fi

extract_identity() {
  local file="$1"
  local label="$2"
  [[ -f "$file" ]] || return 0
  awk -v prefix="- $label:" '
    index($0, prefix) == 1 {
      value = substr($0, length(prefix) + 1)
      sub(/^[[:space:]]*`/, "", value)
      sub(/`.*/, "", value)
      print value
      exit
    }
  ' "$file"
}

resolve_identity() {
  local explicit_value="$1"
  local existing_file="$2"
  local label="$3"
  local placeholder="$4"
  local existing_value=""
  if [[ -n "$explicit_value" ]]; then
    printf '%s' "$explicit_value"
    return
  fi
  existing_value="$(extract_identity "$existing_file" "$label")"
  if [[ -n "$existing_value" && "$existing_value" != "$placeholder" ]]; then
    printf '%s' "$existing_value"
  else
    printf '%s' "$placeholder"
  fi
}

escape_sed_replacement() {
  printf '%s' "$1" | sed 's/[\\&|]/\\\\&/g'
}

render_guide() {
  local src="$1"
  local existing="$2"
  local dest="$3"
  local owner email owner_escaped email_escaped
  owner="$(resolve_identity "$github_owner" "$existing" 'GitHub owner / username' '<your-github-username>')"
  email="$(resolve_identity "$git_email" "$existing" 'Commit email, when a local Git identity is needed' '<your-git-email@example.com>')"
  owner_escaped="$(escape_sed_replacement "$owner")"
  email_escaped="$(escape_sed_replacement "$email")"
  sed \
    -e "s|<your-github-username>|$owner_escaped|g" \
    -e "s|<your-git-email@example.com>|$email_escaped|g" \
    "$src" > "$dest"
}

temp_root="$(mktemp -d "${TMPDIR:-/tmp}/agent-guides-install.XXXXXX")"
trap 'rm -rf "$temp_root"' EXIT
rendered_agents="$temp_root/AGENTS.md"
rendered_claude="$temp_root/CLAUDE.md"
render_guide "$agents_src" "$codex_home/AGENTS.md" "$rendered_agents"
render_guide "$claude_src" "$claude_home/CLAUDE.md" "$rendered_claude"

backup_path() {
  local path="$1"
  local home="$2"
  local backup_root="$3"
  local relative="${path#"$home"/}"
  printf '%s/%s' "$backup_root" "$relative"
}

backup_existing() {
  local path="$1"
  local home="$2"
  local backup_root="$3"
  local destination
  [[ -e "$path" ]] || return 0
  destination="$(backup_path "$path" "$home" "$backup_root")"
  if [[ "$dry_run" -eq 1 ]]; then
    echo "[dry-run] would back up $path -> $destination"
    return
  fi
  mkdir -p "$(dirname "$destination")"
  cp -a "$path" "$destination"
  echo "Backed up $path -> $destination"
}

install_file() {
  local src="$1"
  local dest="$2"
  local label="$3"
  local home="$4"
  local backup_root="$5"
  if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
    echo "$label already up to date: $dest"
    return
  fi
  if [[ "$dry_run" -eq 1 ]]; then
    if [[ "$backup_policy" == "enabled" && -e "$dest" ]]; then
      backup_existing "$dest" "$home" "$backup_root"
    fi
    echo "[dry-run] install $label: $src -> $dest"
    return
  fi
  if [[ "$backup_policy" == "enabled" && -e "$dest" ]]; then
    backup_existing "$dest" "$home" "$backup_root"
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  chmod 0644 "$dest"
  cmp -s "$src" "$dest" || { echo "Verification failed after installing $label: $dest" >&2; exit 1; }
  echo "Installed $label: $dest"
}

install_file "$rendered_agents" "$codex_home/AGENTS.md" "Codex AGENTS.md" "$codex_home" "$codex_backup_root"
install_file "$rendered_claude" "$claude_home/CLAUDE.md" "Claude CLAUDE.md" "$claude_home" "$claude_backup_root"

skills_src=""
if [[ "$repo_mode" -eq 1 && -d "$repo_root/skills" ]]; then
  skills_src="$repo_root/skills"
fi

install_skills() {
  local home="$1"
  local label="$2"
  local backup_root="$3"
  local target_dir="$home/skills"
  local skill name dest

  if [[ -z "$skills_src" ]]; then
    echo "No skills source directory found; skipping $label skills." >&2
    return
  fi
  if [[ -e "$target_dir" && "$skills_src" -ef "$target_dir" ]]; then
    echo "Refusing to install $label skills because source and target are the same: $skills_src" >&2
    exit 1
  fi

  for skill in "$skills_src"/*; do
    [[ -d "$skill" && -f "$skill/SKILL.md" ]] || continue
    name="$(basename "$skill")"
    dest="$target_dir/$name"
    if [[ -d "$dest" ]] && diff -qr "$skill" "$dest" >/dev/null 2>&1; then
      echo "$label skill already up to date: $dest"
      continue
    fi
    if [[ "$dry_run" -eq 1 ]]; then
      if [[ "$backup_policy" == "enabled" && -e "$dest" ]]; then
        backup_existing "$dest" "$home" "$backup_root"
      fi
      echo "[dry-run] install $label skill: $skill -> $dest"
      continue
    fi
    if [[ "$backup_policy" == "enabled" && -e "$dest" ]]; then
      backup_existing "$dest" "$home" "$backup_root"
    fi
    if [[ -e "$dest" ]]; then
      rm -rf "$dest"
    fi
    mkdir -p "$target_dir"
    cp -a "$skill" "$dest"
    diff -qr "$skill" "$dest" >/dev/null 2>&1 \
      || { echo "Verification failed after installing $label skill: $dest" >&2; exit 1; }
    echo "Installed $label skill: $dest"
  done
}

frontmatter_name() {
  sed -n '/^---[[:space:]]*$/,/^---[[:space:]]*$/s/^name:[[:space:]]*//p' "$1" | head -n 1
}

replacement_valid() {
  local home="$1"
  local replacement="$2"
  local source="$skills_src/$replacement"
  local installed="$home/skills/$replacement"
  [[ -d "$source" && -f "$source/SKILL.md" ]] || return 1
  [[ -d "$installed" && -f "$installed/SKILL.md" ]] || return 1
  [[ "$(frontmatter_name "$installed/SKILL.md")" == "$replacement" ]] || return 1
  diff -qr "$source" "$installed" >/dev/null 2>&1
}

cleanup_legacy() {
  local home="$1"
  local label="$2"
  local backup_root="$3"
  local legacy="$home/skills/subagent-orchestration"
  local recovery
  [[ -e "$legacy" ]] || return 0

  if [[ "$dry_run" -eq 1 ]]; then
    if [[ "$backup_policy" == "enabled" ]]; then
      recovery="$(backup_path "$legacy" "$home" "$backup_root")"
      echo "[dry-run] would remove $legacy after replacement validation; recovery: $recovery"
    else
      echo "[dry-run] would remove $legacy after replacement validation; recovery unavailable"
    fi
    return
  fi

  if ! replacement_valid "$home" codex-subagent-orchestration \
    || ! replacement_valid "$home" claude-subagent-orchestration; then
    echo "$label legacy skill kept: replacement validation failed for $legacy" >&2
    return 1
  fi

  if [[ "$backup_policy" == "enabled" ]]; then
    recovery="$(backup_path "$legacy" "$home" "$backup_root")"
    backup_existing "$legacy" "$home" "$backup_root"
    rm -rf "$legacy"
    echo "Removed $legacy; recovery: $recovery"
  else
    rm -rf "$legacy"
    echo "Removed $legacy; recovery unavailable"
  fi
}

cleanup_failed=0
if [[ "$skip_skills" -eq 0 ]]; then
  if [[ "$repo_mode" -eq 1 ]]; then
    install_skills "$codex_home" "Codex" "$codex_backup_root"
    install_skills "$claude_home" "Claude" "$claude_backup_root"
    cleanup_legacy "$codex_home" "Codex" "$codex_backup_root" || cleanup_failed=1
    cleanup_legacy "$claude_home" "Claude" "$claude_backup_root" || cleanup_failed=1
  else
    echo "Installed-skill mode detected; skipping modular skills. Clone the full repository to install skills/*."
  fi
fi

if [[ "$dry_run" -eq 1 ]]; then
  echo "Dry run complete. No files were changed."
else
  echo "Install complete. Restart Codex and Claude Code sessions to load the new global guides."
fi

[[ "$cleanup_failed" -eq 0 ]]
