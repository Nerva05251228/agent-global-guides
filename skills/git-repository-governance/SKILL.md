---
name: git-repository-governance
description: Establish and maintain clean, secure, reviewable, and release-ready Git repositories, including tracked-file hygiene, .gitignore policy, secrets, generated artifacts, repository documentation, commits, branches, pull requests, protected branches, changelogs, versioning, tags, and releases. Use when creating or auditing a repository, preparing commits or pull requests, deciding what belongs in CHANGELOG.md, cleaning repository artifacts, defining Git workflow rules, or preparing a release.
---

# Git Repository Governance

## Precedence And Initial Audit

Follow the repository's documented conventions before applying these defaults. Read the relevant local `AGENTS.md` or `CLAUDE.md`, `CONTEXT.md`, `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, `.gitignore`, CI configuration, release configuration, and existing changelog.

Before changing repository state, inspect:

```bash
git status --short --branch
git diff
git diff --cached
git log -n 10 --oneline
```

Do not rewrite, discard, stage, or commit unrelated user changes. Keep the requested change scoped and reviewable.

## Tracked Content And Ignore Policy

Track files required to understand, build, test, operate, reproduce, or intentionally distribute the project. Typical tracked content includes source code, safe configuration, tests, migrations, documentation, project-owned scripts, dependency manifests, ecosystem-appropriate lockfiles, and intentional fixtures or assets.

Keep these out of Git unless the repository explicitly owns them:

- Local debug output, `.debug/`, traces, screenshots, agent logs, task prompts, and command transcripts.
- Build output, caches, coverage output, temporary files, package-manager caches, and generated intermediate files.
- Local environment files, machine-specific configuration, editor state, OS metadata, and personal workflow artifacts.
- Runtime logs, database dumps, user uploads, local media, and production snapshots.
- Secrets, credentials, private keys, tokens, passwords, and production environment values.

Place ignore rules according to scope:

- Shared project-generated files belong in tracked `.gitignore` files.
- Repository-local private exclusions belong in `.git/info/exclude`.
- User-wide editor, backup, or OS patterns belong in the user's global Git excludes file.

Git ignore rules do not stop tracking files that are already tracked. Do not remove an already tracked path from the index unless that cleanup is in scope and its downstream impact is understood.

Generated files may be committed when they are required distribution artifacts, reproducibility inputs, or an established repository convention. Document how they are regenerated and avoid mixing unrelated generated churn into a change.

Do not commit large binary objects casually. Prefer Git LFS, release assets, package registries, or object storage when the repository and hosting platform support them.

## Secrets And Sensitive Data

Never commit real secrets or sensitive production data. Use placeholders and safe examples such as `.env.example` without usable credentials.

Before commit or push, inspect the diff for:

- API keys, tokens, passwords, connection strings, private keys, and certificates.
- Sensitive values embedded in logs, screenshots, fixtures, notebooks, or generated files.
- Personal information or machine-specific absolute paths that should not be published.

Use repository or platform secret scanning when available. For important repositories, consider pre-commit or CI secret checks.

If a secret is committed or pushed:

1. Stop further propagation.
2. Revoke or rotate the credential first.
3. Assess branches, tags, pull requests, forks, caches, and clones.
4. Rewrite history only with explicit authorization and coordinated handling of collaborators, branch protection, tags, and downstream clones.

History rewriting is disruptive and is not a routine cleanup step.

## Repository Documentation

Add documentation according to the repository's audience and lifecycle. Do not add empty boilerplate merely to satisfy a checklist.

Common repository-level documents include:

- `README.md`: purpose, prerequisites, setup, common workflows, and links to deeper documentation.
- `LICENSE`: distribution and usage terms when the project is shared or published.
- `CONTRIBUTING.md`: contribution workflow, development setup, tests, review expectations, and commit or PR conventions.
- `SECURITY.md`: supported versions and a private vulnerability-reporting path.
- `CODE_OF_CONDUCT.md`, `SUPPORT.md`, issue templates, and pull-request templates when the contributor community benefits from them.
- `CODEOWNERS` when ownership-based review is meaningful and supported.

Keep repository-specific operational details in repository docs rather than global agent guides.

## Change Scope And Reviewability

Each change should have one coherent purpose. Avoid unrelated refactors, formatting churn, metadata changes, generated output, or dependency updates unless they are required for the objective.

Before accepting a change:

- Review the complete diff, including generated and lock files.
- Confirm new files are intentional and ignored files remain untracked.
- Run tests, lint, builds, migrations, or manual checks in proportion to risk.
- Update owning documentation when behavior, interfaces, configuration, deployment, or operations change.
- Record validation evidence in plans, pull requests, CI, or `.debug/`; do not turn the changelog into a test log.

## Commits

Follow the repository's commit convention. If none exists:

- Prefer small, coherent commits that can be reviewed and reverted independently.
- Write a concise subject that describes the repository outcome.
- Add a body when motivation, tradeoffs, migration steps, or non-obvious constraints matter.
- Separate unrelated changes into separate commits.
- Do not use commit messages as debugging diaries or command transcripts.

Conventional Commits is an optional default when structured automation is useful:

```text
<type>[optional scope]: <description>
```

Common types include `feat`, `fix`, `docs`, `refactor`, `test`, `build`, `ci`, and `chore`. Mark breaking changes with `!` or a `BREAKING CHANGE:` footer. Do not impose Conventional Commits over an existing repository convention.

## Branches, Pull Requests, And Main Protection

Follow the repository's branch and merge model. Do not impose Git Flow, trunk-based development, squash merging, rebase merging, or merge commits universally.

Project-agnostic defaults:

- Work from the correct and current base branch.
- Use a dedicated branch for non-trivial collaborative changes unless the repository explicitly works directly on the default branch.
- Do not force-push shared branches or rewrite published history without explicit authorization.
- Keep pull requests focused and include the purpose, behavior change, risk, validation, migration, rollout, and rollback information that reviewers need.
- Resolve review comments and rerun required checks after material changes.

For important collaborative or production repositories, prefer protecting the default and release branches with appropriate combinations of:

- Pull-request review requirements.
- Required status checks.
- Conversation resolution.
- Restricted direct pushes.
- Disabled force pushes and branch deletion.
- Signed commits, linear history, merge queues, or deployment gates when the repository's threat model and workflow justify them.

## Changelog Policy

A changelog is a curated, chronological list of notable resulting changes for users and contributors. It is not a raw Git log, task journal, incident log, test report, or agent transcript.

Include entries when they are notable to the repository's consumers or contributors, such as:

- Added features or supported workflows.
- Changed behavior, APIs, schemas, configuration, deployment, or compatibility.
- Deprecations and removals.
- User-visible or operationally meaningful fixes.
- Security fixes with appropriately limited detail.
- Meaningful repository tooling or documentation changes that affect contributors or releases.

Do not put these in `CHANGELOG.md`:

- Local debugging failures, retries, temporary workarounds, or abandoned attempts.
- Agent or subagent activity, timeouts, model/API errors, or orchestration history.
- Commands executed, test output, screenshots, validation logs, or "tests passed" diary entries.
- Machine-specific paths, local environment state, personal information, or secrets.
- Internal plan/checklist progress that does not describe a resulting repository change.
- A dump of commit subjects or every minor implementation detail.

Put operational evidence in `.debug/`, authoritative plans, issues, pull requests, CI logs, or incident records as appropriate.

If the repository has no stronger convention, use `CHANGELOG.md` with Keep a Changelog structure:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [1.2.3] - YYYY-MM-DD
```

Keep the newest release first. Write one concise bullet per notable outcome. Preserve only relevant categories. At release time, move applicable `Unreleased` entries into the new version section instead of duplicating them.

Update a changelog only when the repository maintains one or the change is notable under its documented policy. Do not create a changelog for a repository that deliberately uses another release-note system unless the user requests it.

## Versioning, Tags, And Releases

Follow the repository's existing version and release policy.

Use Semantic Versioning only when the project declares a public API and intends SemVer compatibility guarantees:

- Major: incompatible public API changes.
- Minor: backward-compatible functionality or deprecations.
- Patch: backward-compatible bug fixes.

Do not modify the contents of an already released version. Publish corrections as a new version.

Release tags must identify the reviewed release commit and match the repository's naming convention. Use annotated or signed tags when the project's release policy requires them. Release notes may be generated from commits or pull requests, but a raw generated list should be curated before publication.

## Pre-Commit And Pre-Push Acceptance

Before commit or push:

1. Inspect `git status`, unstaged diff, and staged diff.
2. Confirm the change contains no unrelated user work.
3. Confirm no secrets, private data, local paths, debug artifacts, logs, caches, or accidental binaries are included.
4. Confirm generated files and lockfiles are intentional and reproducible.
5. Run the required validation and record evidence outside the changelog.
6. Update repository docs and changelog only when their policies require it.
7. Confirm commit messages, branch, tags, and release metadata follow local conventions.
8. Obtain the required user confirmation before committing or pushing when the active agent guide requires it.

## Standards Basis

- Git ignore documentation: https://git-scm.com/docs/gitignore
- GitHub community profiles: https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/about-community-profiles-for-public-repositories
- GitHub protected branches: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
- GitHub sensitive-data removal: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository
- GitHub secret scanning: https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning
- GitHub Git LFS: https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-git-large-file-storage
- Keep a Changelog: https://keepachangelog.com/en/1.1.0/
- Semantic Versioning: https://semver.org/
- Conventional Commits: https://www.conventionalcommits.org/en/v1.0.0/
