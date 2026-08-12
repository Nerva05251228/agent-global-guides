#!/usr/bin/env bash

set -u
set -o pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/agent-guides-installers.XXXXXX")"
trap 'rm -rf "$test_root"' EXIT

tests_run=0
tests_passed=0
tests_failed=0
tests_skipped=0
test_was_skipped=0
last_status=0
last_output=""
case_dir=""
fixture_repo=""

pass() {
  printf 'PASS: %s\n' "$1"
  tests_passed=$((tests_passed + 1))
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  return 1
}

skip() {
  printf 'SKIP: %s\n' "$1"
  tests_skipped=$((tests_skipped + 1))
  test_was_skipped=1
}

run_test() {
  local name="$1"
  local fn="$2"
  tests_run=$((tests_run + 1))
  test_was_skipped=0
  if "$fn"; then
    if [[ "$test_was_skipped" -eq 0 ]]; then
      pass "$name"
    fi
  else
    printf 'FAILED TEST: %s\n' "$name" >&2
    tests_failed=$((tests_failed + 1))
  fi
}

assert_success() {
  [[ "$last_status" -eq 0 ]] || fail "expected success, got exit $last_status; output: $last_output"
}

assert_failure() {
  [[ "$last_status" -ne 0 ]] || fail "expected a non-zero exit; output: $last_output"
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain: $needle; output: $haystack"
}

assert_matches() {
  local haystack="$1"
  local pattern="$2"
  printf '%s\n' "$haystack" | grep -Eiq -- "$pattern" \
    || fail "expected output to match /$pattern/; output: $haystack"
}

assert_line_contains_matches() {
  local haystack="$1"
  local needle="$2"
  local pattern="$3"
  local matching_lines
  matching_lines="$(printf '%s\n' "$haystack" | grep -F -- "$needle" || true)"
  [[ -n "$matching_lines" ]] \
    || fail "expected an output line containing: $needle" || return 1
  printf '%s\n' "$matching_lines" | grep -Eiq -- "$pattern" \
    || fail "expected the line containing '$needle' to match /$pattern/; lines: $matching_lines"
}

make_fixture() {
  local name="$1"
  case_dir="$test_root/$name"
  fixture_repo="$case_dir/repo"
  mkdir -p "$fixture_repo"
  cp -R "$repo_root/docs" "$fixture_repo/docs"
  cp -R "$repo_root/scripts" "$fixture_repo/scripts"
  cp -R "$repo_root/skills" "$fixture_repo/skills"
  cp "$repo_root/README.md" "$repo_root/CHANGELOG.md" "$repo_root/.gitignore" "$fixture_repo/"
}

run_installer() {
  local output_file="$case_dir/installer-output.txt"
  local installer="$fixture_repo/skills/agent-guides-installer/scripts/install-global-guides.sh"
  "$installer" "$@" </dev/null >"$output_file" 2>&1
  last_status=$?
  last_output="$(tr -d '\r' < "$output_file")"
}

tree_fingerprint() {
  local root="$1"
  if [[ ! -e "$root" ]]; then
    printf 'ABSENT\n'
    return
  fi
  (
    cd "$root" || exit 1
    find . -mindepth 1 -print | LC_ALL=C sort | while IFS= read -r path; do
      if [[ -d "$path" ]]; then
        printf 'D %s\n' "$path"
      elif [[ -L "$path" ]]; then
        printf 'L %s %s\n' "$path" "$(readlink "$path")"
      elif [[ -f "$path" ]]; then
        printf 'F %s ' "$path"
        cksum < "$path"
      fi
    done
  )
}

seed_changed_targets() {
  local codex_home="$1"
  local claude_home="$2"
  mkdir -p "$codex_home/skills/codex-subagent-orchestration"
  mkdir -p "$claude_home/skills/claude-subagent-orchestration"
  printf 'old-codex-guide\n' > "$codex_home/AGENTS.md"
  printf 'old-claude-guide\n' > "$claude_home/CLAUDE.md"
  printf 'old-codex-skill\n' > "$codex_home/skills/codex-subagent-orchestration/SKILL.md"
  printf 'old-claude-skill\n' > "$claude_home/skills/claude-subagent-orchestration/SKILL.md"
}

seed_legacy_skills() {
  local codex_home="$1"
  local claude_home="$2"
  mkdir -p "$codex_home/skills/subagent-orchestration"
  mkdir -p "$claude_home/skills/subagent-orchestration"
  printf '%s\n' 'legacy-codex-skill' > "$codex_home/skills/subagent-orchestration/SKILL.md"
  printf '%s\n' 'legacy-claude-skill' > "$claude_home/skills/subagent-orchestration/SKILL.md"
}

frontmatter_name() {
  sed -n '/^---[[:space:]]*$/,/^---[[:space:]]*$/s/^name:[[:space:]]*//p' "$1" | head -n 1
}

test_critical_guide_policies() {
  local file pattern content
  for file in \
    "$repo_root/docs/AGENTS.md" \
    "$repo_root/docs/CLAUDE.md" \
    "$repo_root/skills/agent-guides-installer/assets/guides/AGENTS.md" \
    "$repo_root/skills/agent-guides-installer/assets/guides/CLAUDE.md"; do
    content="$(<"$file")"
    for pattern in \
      'ask whether to run `setup-matt-pocock-skills`' \
      '.debug/YYYY-MM-DD/' \
      'Never clean it automatically' \
      'ISO-8601' \
      'reopen' \
      'gpt-5.5' \
      'xhigh' \
      'Never silently substitute' \
      'failed with reason' \
      'residual risk' \
      'rollback or recovery'; do
      [[ "$content" == *"$pattern"* ]] \
        || fail "missing critical policy '$pattern' in $file" || return 1
    done
  done
}

test_macos_bash_compatibility() {
  local scanner_content test_content sed_in_place
  scanner_content="$(<"$repo_root/skills/agent-guides-installer/scripts/scan-guides.sh")"
  test_content="$(<"$repo_root/tests/test-installers.sh")"
  sed_in_place="sed -""i "

  [[ "$scanner_content" != *'mapfile '* ]] \
    || fail "Bash scanner requires mapfile, which is unavailable in macOS Bash 3.2" || return 1
  [[ "$scanner_content" != *'sort -z'* ]] \
    || fail "Bash scanner requires GNU sort -z, which is unavailable in macOS BSD sort" || return 1
  [[ "$test_content" != *"$sed_in_place"* ]] \
    || fail "Bash tests use non-portable in-place sed syntax" || return 1
}

test_dry_run_writes_nothing() {
  make_fixture dry-run
  local codex_home="$case_dir/codex-home"
  local claude_home="$case_dir/claude-home"
  local before_codex before_claude
  seed_changed_targets "$codex_home" "$claude_home"
  seed_legacy_skills "$codex_home" "$claude_home"
  before_codex="$(tree_fingerprint "$codex_home")"
  before_claude="$(tree_fingerprint "$claude_home")"

  run_installer --codex-home "$codex_home" --claude-home "$claude_home" --dry-run --backup
  assert_success || return 1
  [[ "$(tree_fingerprint "$codex_home")" == "$before_codex" ]] \
    || fail "dry-run changed the Codex home" || return 1
  [[ "$(tree_fingerprint "$claude_home")" == "$before_claude" ]] \
    || fail "dry-run changed the Claude home" || return 1
  assert_matches "$last_output" 'dry.run.*no files (were )?changed' || return 1
}

test_identity_rendering_keeps_source_sanitized() {
  make_fixture identity-render
  local codex_home="$case_dir/codex-home"
  local claude_home="$case_dir/claude-home"
  local agents_before claude_before
  agents_before="$(cksum < "$fixture_repo/docs/AGENTS.md")"
  claude_before="$(cksum < "$fixture_repo/docs/CLAUDE.md")"

  run_installer \
    --codex-home "$codex_home" \
    --claude-home "$claude_home" \
    --github-owner rendered-owner \
    --git-email rendered.user@example.com \
    --no-backup
  assert_success || return 1
  grep -Fq 'rendered-owner' "$codex_home/AGENTS.md" \
    || fail "Codex guide did not render the GitHub owner" || return 1
  grep -Fq 'rendered.user@example.com' "$codex_home/AGENTS.md" \
    || fail "Codex guide did not render the Git email" || return 1
  grep -Fq 'rendered-owner' "$claude_home/CLAUDE.md" \
    || fail "Claude guide did not render the GitHub owner" || return 1
  grep -Fq 'rendered.user@example.com' "$claude_home/CLAUDE.md" \
    || fail "Claude guide did not render the Git email" || return 1
  grep -Fq '<your-github-username>' "$fixture_repo/docs/AGENTS.md" \
    || fail "AGENTS.md source placeholder was modified" || return 1
  grep -Fq '<your-git-email@example.com>' "$fixture_repo/docs/CLAUDE.md" \
    || fail "CLAUDE.md source placeholder was modified" || return 1
  [[ "$(cksum < "$fixture_repo/docs/AGENTS.md")" == "$agents_before" ]] \
    || fail "AGENTS.md source changed during rendering" || return 1
  [[ "$(cksum < "$fixture_repo/docs/CLAUDE.md")" == "$claude_before" ]] \
    || fail "CLAUDE.md source changed during rendering" || return 1
}

test_existing_identity_is_preserved_without_flags() {
  make_fixture identity-preserve
  local codex_home="$case_dir/codex-home"
  local claude_home="$case_dir/claude-home"
  mkdir -p "$codex_home" "$claude_home"
  sed \
    -e 's/<your-github-username>/preserved-codex-owner/g' \
    -e 's/<your-git-email@example.com>/preserved.codex@example.com/g' \
    "$fixture_repo/docs/AGENTS.md" > "$codex_home/AGENTS.md"
  sed \
    -e 's/<your-github-username>/preserved-claude-owner/g' \
    -e 's/<your-git-email@example.com>/preserved.claude@example.com/g' \
    "$fixture_repo/docs/CLAUDE.md" > "$claude_home/CLAUDE.md"

  run_installer --codex-home "$codex_home" --claude-home "$claude_home" --no-backup
  assert_success || return 1
  grep -Fq 'preserved-codex-owner' "$codex_home/AGENTS.md" \
    || fail "existing Codex owner was not preserved" || return 1
  grep -Fq 'preserved.codex@example.com' "$codex_home/AGENTS.md" \
    || fail "existing Codex email was not preserved" || return 1
  grep -Fq 'preserved-claude-owner' "$claude_home/CLAUDE.md" \
    || fail "existing Claude owner was not preserved" || return 1
  grep -Fq 'preserved.claude@example.com' "$claude_home/CLAUDE.md" \
    || fail "existing Claude email was not preserved" || return 1
}

test_backup_is_external_to_active_skills() {
  make_fixture external-backup
  local codex_home="$case_dir/codex-home"
  local claude_home="$case_dir/claude-home"
  seed_changed_targets "$codex_home" "$claude_home"

  run_installer --codex-home "$codex_home" --claude-home "$claude_home" --backup
  assert_success || return 1
  [[ -d "$codex_home/backups/agent-global-guides" ]] \
    || fail "Codex external backup root was not created" || return 1
  [[ -d "$claude_home/backups/agent-global-guides" ]] \
    || fail "Claude external backup root was not created" || return 1
  local codex_snapshot claude_snapshot
  codex_snapshot="$(find "$codex_home/backups/agent-global-guides" -mindepth 1 -maxdepth 1 -type d -print)"
  claude_snapshot="$(find "$claude_home/backups/agent-global-guides" -mindepth 1 -maxdepth 1 -type d -print)"
  [[ "$(printf '%s\n' "$codex_snapshot" | sed '/^$/d' | wc -l | tr -d ' ')" -eq 1 ]] \
    || fail "Codex backup root does not contain exactly one timestamp snapshot" || return 1
  [[ "$(printf '%s\n' "$claude_snapshot" | sed '/^$/d' | wc -l | tr -d ' ')" -eq 1 ]] \
    || fail "Claude backup root does not contain exactly one timestamp snapshot" || return 1
  [[ "$(basename "$codex_snapshot")" =~ ^[0-9]{8}-[0-9]{6}([-.][0-9]+)?$ ]] \
    || fail "Codex backup snapshot is not timestamp-named: $codex_snapshot" || return 1
  [[ "$(basename "$claude_snapshot")" =~ ^[0-9]{8}-[0-9]{6}([-.][0-9]+)?$ ]] \
    || fail "Claude backup snapshot is not timestamp-named: $claude_snapshot" || return 1
  grep -RFlq 'old-codex-guide' "$codex_home/backups/agent-global-guides" \
    || fail "old Codex guide was not stored in the external backup" || return 1
  grep -RFlq 'old-claude-skill' "$claude_home/backups/agent-global-guides" \
    || fail "old Claude skill was not stored in the external backup" || return 1
  [[ -z "$(find "$codex_home/skills" "$claude_home/skills" -name '*.bak.*' -print -quit)" ]] \
    || fail "a backup was left inside an active skills directory" || return 1
  assert_matches "$last_output" 'backup.*agent-global-guides' || return 1
}

test_no_backup_reports_recovery_unavailable() {
  make_fixture no-backup
  local codex_home="$case_dir/codex-home"
  local claude_home="$case_dir/claude-home"
  seed_changed_targets "$codex_home" "$claude_home"
  seed_legacy_skills "$codex_home" "$claude_home"

  run_installer --codex-home "$codex_home" --claude-home "$claude_home" --no-backup
  assert_success || return 1
  [[ ! -e "$codex_home/backups/agent-global-guides" ]] \
    || fail "Codex backup was created despite --no-backup" || return 1
  [[ ! -e "$claude_home/backups/agent-global-guides" ]] \
    || fail "Claude backup was created despite --no-backup" || return 1
  [[ -z "$(find "$codex_home" "$claude_home" -name '*.bak.*' -print -quit)" ]] \
    || fail "an adjacent backup was created despite --no-backup" || return 1
  assert_matches "$last_output" 'recovery unavailable' || return 1
  assert_line_contains_matches "$last_output" "$codex_home/skills/subagent-orchestration" 'removed' || return 1
  assert_line_contains_matches "$last_output" "$claude_home/skills/subagent-orchestration" 'removed' || return 1
}

test_noninteractive_defaults_to_backup_without_prompting() {
  make_fixture noninteractive-default
  local codex_home="$case_dir/codex-home"
  local claude_home="$case_dir/claude-home"
  seed_changed_targets "$codex_home" "$claude_home"

  run_installer --codex-home "$codex_home" --claude-home "$claude_home"
  assert_success || return 1
  [[ -d "$codex_home/backups/agent-global-guides" ]] \
    || fail "non-interactive install did not default to backup" || return 1
  local prompt_count
  prompt_count="$(printf '%s\n' "$last_output" | grep -Eic 'back[ -]?up.*\[[Yy]/[Nn]\]' || true)"
  [[ "$prompt_count" -eq 0 ]] \
    || fail "non-interactive install emitted an interactive prompt" || return 1
}

test_interactive_prompts_exactly_once() {
  if ! command -v script >/dev/null 2>&1; then
    skip "interactive Bash prompt assertion requires a PTY-capable 'script' command"
    return 0
  fi

  make_fixture interactive-default
  local codex_home="$case_dir/codex-home"
  local claude_home="$case_dir/claude-home"
  local installer="$fixture_repo/skills/agent-guides-installer/scripts/install-global-guides.sh"
  local output_file="$case_dir/interactive-output.txt"
  local status command_text prompt_count
  seed_changed_targets "$codex_home" "$claude_home"
  printf -v command_text '%q ' "$installer" --codex-home "$codex_home" --claude-home "$claude_home" --dry-run

  if script --version 2>/dev/null | grep -qi 'util-linux'; then
    printf 'y\n' | script -q -e -c "$command_text" /dev/null >"$output_file" 2>&1
    status=$?
  else
    printf 'y\n' | script -q /dev/null "$installer" \
      --codex-home "$codex_home" --claude-home "$claude_home" --dry-run \
      >"$output_file" 2>&1
    status=$?
  fi
  last_output="$(tr -d '\r' < "$output_file")"
  [[ "$status" -eq 0 ]] || fail "interactive dry-run failed: $last_output" || return 1
  prompt_count="$(printf '%s\n' "$last_output" | grep -Eic 'back[ -]?up.*\[[Yy]/[Nn]\]' || true)"
  [[ "$prompt_count" -eq 1 ]] \
    || fail "expected exactly one backup prompt, observed $prompt_count; output: $last_output" || return 1
}

test_legacy_cleanup_requires_valid_replacements() {
  make_fixture legacy-cleanup
  local codex_home="$case_dir/codex-home"
  local claude_home="$case_dir/claude-home"
  seed_legacy_skills "$codex_home" "$claude_home"

  run_installer --codex-home "$codex_home" --claude-home "$claude_home" --backup
  assert_success || return 1
  local home replacement
  for home in "$codex_home" "$claude_home"; do
    for replacement in codex-subagent-orchestration claude-subagent-orchestration; do
      diff -qr "$fixture_repo/skills/$replacement" "$home/skills/$replacement" >/dev/null \
        || fail "$replacement in $home is not recursively identical to source" || return 1
      [[ "$(frontmatter_name "$home/skills/$replacement/SKILL.md")" == "$replacement" ]] \
        || fail "$replacement frontmatter name is invalid in $home" || return 1
    done
  done
  [[ ! -e "$codex_home/skills/subagent-orchestration" ]] \
    || fail "Codex legacy skill was not removed after replacement validation" || return 1
  [[ ! -e "$claude_home/skills/subagent-orchestration" ]] \
    || fail "Claude legacy skill was not removed after replacement validation" || return 1
  assert_line_contains_matches "$last_output" "$codex_home/skills/subagent-orchestration" 'removed' || return 1
  assert_line_contains_matches "$last_output" "$claude_home/skills/subagent-orchestration" 'removed' || return 1
  local codex_snapshot claude_snapshot
  codex_snapshot="$(find "$codex_home/backups/agent-global-guides" -mindepth 1 -maxdepth 1 -type d -print -quit)"
  claude_snapshot="$(find "$claude_home/backups/agent-global-guides" -mindepth 1 -maxdepth 1 -type d -print -quit)"
  assert_contains "$last_output" "$codex_snapshot/skills/subagent-orchestration" || return 1
  assert_contains "$last_output" "$claude_snapshot/skills/subagent-orchestration" || return 1
}

test_malformed_replacements_keep_legacy_skill() {
  make_fixture malformed-replacements
  local codex_home="$case_dir/codex-home"
  local claude_home="$case_dir/claude-home"
  seed_legacy_skills "$codex_home" "$claude_home"
  local codex_skill_file="$fixture_repo/skills/codex-subagent-orchestration/SKILL.md"
  sed 's/^name: codex-subagent-orchestration$/name: wrong-codex-name/' \
    "$codex_skill_file" > "$codex_skill_file.tmp"
  mv "$codex_skill_file.tmp" "$codex_skill_file"
  rm "$fixture_repo/skills/claude-subagent-orchestration/SKILL.md"

  run_installer --codex-home "$codex_home" --claude-home "$claude_home" --no-backup
  [[ -e "$codex_home/skills/subagent-orchestration/SKILL.md" ]] \
    || fail "malformed Codex replacement allowed legacy removal" || return 1
  [[ -e "$claude_home/skills/subagent-orchestration/SKILL.md" ]] \
    || fail "incomplete Claude replacement allowed legacy removal" || return 1
  assert_matches "$last_output" 'verification failed|validation failed|cannot remove|not removed|kept' || return 1
}

test_body_name_cannot_bypass_frontmatter_validation() {
  make_fixture body-name-bypass
  local codex_home="$case_dir/codex-home"
  local claude_home="$case_dir/claude-home"
  local codex_skill_file="$fixture_repo/skills/codex-subagent-orchestration/SKILL.md"
  seed_legacy_skills "$codex_home" "$claude_home"
  sed 's/^name: codex-subagent-orchestration$/title: invalid-frontmatter/' \
    "$codex_skill_file" > "$codex_skill_file.tmp"
  mv "$codex_skill_file.tmp" "$codex_skill_file"
  printf '\nname: codex-subagent-orchestration\n' >> "$codex_skill_file"

  run_installer --codex-home "$codex_home" --claude-home "$claude_home" --no-backup
  assert_failure || return 1
  [[ -e "$codex_home/skills/subagent-orchestration/SKILL.md" ]] \
    || fail "body name bypass allowed Codex legacy removal" || return 1
  [[ -e "$claude_home/skills/subagent-orchestration/SKILL.md" ]] \
    || fail "body name bypass allowed Claude legacy removal" || return 1
  assert_matches "$last_output" 'verification failed|validation failed|cannot remove|not removed|kept'
}

test_dry_run_reports_exact_cleanup_and_recovery_policy() {
  make_fixture cleanup-dry-run-backup
  local codex_home="$case_dir/codex-home"
  local claude_home="$case_dir/claude-home"
  seed_legacy_skills "$codex_home" "$claude_home"

  run_installer --codex-home "$codex_home" --claude-home "$claude_home" --dry-run --backup
  assert_success || return 1
  assert_line_contains_matches "$last_output" "$codex_home/skills/subagent-orchestration" 'would remove|planned removal' || return 1
  assert_line_contains_matches "$last_output" "$claude_home/skills/subagent-orchestration" 'would remove|planned removal' || return 1
  assert_matches "$last_output" 'backup.*agent-global-guides' || return 1
  [[ -e "$codex_home/skills/subagent-orchestration/SKILL.md" ]] \
    || fail "dry-run removed the Codex legacy skill" || return 1

  make_fixture cleanup-dry-run-no-backup
  codex_home="$case_dir/codex-home"
  claude_home="$case_dir/claude-home"
  seed_legacy_skills "$codex_home" "$claude_home"
  run_installer --codex-home "$codex_home" --claude-home "$claude_home" --dry-run --no-backup
  assert_success || return 1
  assert_line_contains_matches "$last_output" "$codex_home/skills/subagent-orchestration" 'would remove|planned removal' || return 1
  assert_line_contains_matches "$last_output" "$claude_home/skills/subagent-orchestration" 'would remove|planned removal' || return 1
  assert_matches "$last_output" 'recovery unavailable' || return 1
}

test_every_install_invokes_scanner() {
  make_fixture scanner-invocation
  local codex_home="$case_dir/codex-home"
  local claude_home="$case_dir/claude-home"
  local scanner="$fixture_repo/skills/agent-guides-installer/scripts/scan-guides.sh"
  local real_scanner="$case_dir/real-scan-guides.sh"
  local scan_log="$case_dir/scan.log"
  cp "$scanner" "$real_scanner"
  cat > "$scanner" <<'SHIM'
#!/usr/bin/env bash
printf 'scan\n' >> "${AGENT_GUIDES_TEST_SCAN_LOG:?}"
exec "${AGENT_GUIDES_REAL_SCANNER:?}" "$@"
SHIM
  chmod +x "$scanner" "$real_scanner"
  export AGENT_GUIDES_TEST_SCAN_LOG="$scan_log"
  export AGENT_GUIDES_REAL_SCANNER="$real_scanner"

  run_installer --codex-home "$codex_home" --claude-home "$claude_home" --dry-run --backup
  assert_success || return 1
  run_installer --codex-home "$codex_home" --claude-home "$claude_home" --dry-run --no-backup
  assert_success || return 1
  run_installer --codex-home "$codex_home" --claude-home "$claude_home" --dry-run
  assert_success || return 1
  run_installer --codex-home "$codex_home" --claude-home "$claude_home" --backup
  assert_success || return 1
  run_installer --codex-home "$codex_home" --claude-home "$claude_home" --no-backup
  assert_success || return 1
  run_installer --codex-home "$codex_home" --claude-home "$claude_home"
  assert_success || return 1
  unset AGENT_GUIDES_TEST_SCAN_LOG AGENT_GUIDES_REAL_SCANNER
  [[ "$(wc -l < "$scan_log" | tr -d ' ')" -eq 6 ]] \
    || fail "expected one scanner invocation per install" || return 1
}

test_scanner_failure_precedes_all_target_writes() {
  make_fixture scanner-failure
  local codex_home="$case_dir/codex-home"
  local claude_home="$case_dir/claude-home"
  mkdir -p "$codex_home/skills/sentinel" "$claude_home/skills/sentinel"
  printf 'codex-sentinel\n' > "$codex_home/skills/sentinel/value.txt"
  printf 'claude-sentinel\n' > "$claude_home/skills/sentinel/value.txt"
  printf 'leak.user@%s\n' 'invalid.test' > "$fixture_repo/docs/scan-contract-leak.ps1"
  local before_codex before_claude
  before_codex="$(tree_fingerprint "$codex_home")"
  before_claude="$(tree_fingerprint "$claude_home")"

  run_installer --codex-home "$codex_home" --claude-home "$claude_home" --backup
  assert_failure || return 1
  assert_matches "$last_output" 'scan failed|potential leak|real email address' || return 1
  [[ "$(tree_fingerprint "$codex_home")" == "$before_codex" ]] \
    || fail "Codex home changed after scanner failure" || return 1
  [[ "$(tree_fingerprint "$claude_home")" == "$before_claude" ]] \
    || fail "Claude home changed after scanner failure" || return 1
}

test_skip_scan_bypass_is_not_exposed() {
  make_fixture no-skip-scan
  local codex_home="$case_dir/codex-home"
  local claude_home="$case_dir/claude-home"
  local installer="$fixture_repo/skills/agent-guides-installer/scripts/install-global-guides.sh"
  local help_output
  help_output="$($installer --help 2>&1)"
  [[ "$help_output" != *'--skip-scan'* ]] \
    || fail "installer help still exposes --skip-scan" || return 1

  run_installer --codex-home "$codex_home" --claude-home "$claude_home" --dry-run --skip-scan
  assert_failure || return 1
  assert_matches "$last_output" 'unknown argument|unrecognized option' || return 1
  [[ ! -e "$codex_home" && ! -e "$claude_home" ]] \
    || fail "rejected --skip-scan invocation changed a target home" || return 1
}

run_test 'critical policies are present in both English guides and installer assets' test_critical_guide_policies
run_test 'Bash scanner and tests avoid macOS-incompatible shell constructs' test_macos_bash_compatibility
run_test 'dry-run writes nothing' test_dry_run_writes_nothing
run_test 'identity flags render local values without modifying sanitized sources' test_identity_rendering_keeps_source_sanitized
run_test 'existing non-placeholder identities are preserved without flags' test_existing_identity_is_preserved_without_flags
run_test 'backup stores changed guides and skills outside active skills directories' test_backup_is_external_to_active_skills
run_test '--no-backup creates no backup and reports unavailable recovery' test_no_backup_reports_recovery_unavailable
run_test 'non-interactive install defaults to backup without prompting' test_noninteractive_defaults_to_backup_without_prompting
run_test 'interactive install asks exactly one backup question' test_interactive_prompts_exactly_once
run_test 'legacy cleanup follows recursive and frontmatter replacement validation' test_legacy_cleanup_requires_valid_replacements
run_test 'malformed or incomplete replacements keep legacy skills' test_malformed_replacements_keep_legacy_skill
run_test 'body name cannot bypass frontmatter validation' test_body_name_cannot_bypass_frontmatter_validation
run_test 'dry-run reports exact legacy removals and recovery policy' test_dry_run_reports_exact_cleanup_and_recovery_policy
run_test 'every dry-run and real install invokes the scanner' test_every_install_invokes_scanner
run_test 'scanner failure exits before any target write' test_scanner_failure_precedes_all_target_writes
run_test 'installer exposes no --skip-scan bypass' test_skip_scan_bypass_is_not_exposed

printf '\nBash installer contract: %d run, %d passed, %d failed, %d skipped\n' \
  "$tests_run" "$tests_passed" "$tests_failed" "$tests_skipped"

[[ "$tests_failed" -eq 0 ]]
