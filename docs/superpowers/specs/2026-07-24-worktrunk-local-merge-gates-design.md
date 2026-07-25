# Worktrunk Local Merge Gates Design

## Goal

Make `wt merge` provide a reliable local equivalent of the repository's essential GitHub CI checks before it fast-forwards a feature branch into its target.

## Decision

Use project-scoped `pre-merge` hooks in `.config/wt.toml`. Worktrunk runs these after rebasing the feature branch onto its target and before the fast-forward merge, so a failing check leaves the target branch unchanged.

Run the default merge gate as one ordered pipeline:

1. `fvm dart run melos run validate:quick` — fatal analysis and formatting.
2. `fvm dart run melos run test:local --no-select` — hermetic unit and widget tests without coverage, Docker-backed integrations, or Melos's interactive package picker.
3. `fvm dart run dependency_validator` — declared-dependency validation.
4. `fvm dart run import_sorter:main --exit-if-changed` — import ordering validation.

Each step starts only after its predecessor succeeds. This provides actionable failure output and avoids running expensive checks when a quick gate already fails.

## Full CI parity

The repository already exposes `fvm dart run melos run validate:ci`, which includes coverage. It is intentionally not a default `wt merge` hook because it duplicates the default analysis work and adds coverage collection. Developers can run it explicitly before a high-risk merge or when they need maximum local parity with remote CI.

Docker-backed Serverpod integration tests are explicit through `fvm dart run melos run test:integration --no-select`; local and GitHub CI scripts run the server's `test/features` and `test/migrations` paths explicitly, so they never load `test/integration`. GitHub branch protection and remote CI remain the authority for checks that cannot be proven locally, including the hosted environment, pull-request policy, and platform-specific jobs.

## Non-goals

- Poll GitHub from a local merge hook or wait for remote CI status.
- Run deployments, publishing, database migrations, or destructive operations during `wt merge`.
- Change repository CI definitions or branch-protection rules.
- Add a hook that silently bypasses Worktrunk's per-project command approval.

## Failure behavior

Any `pre-merge` failure aborts the merge before the target branch changes. The feature worktree and branch remain available for correction and another `wt merge` attempt.

Worktrunk requires every developer to review and approve project hooks locally. After the configuration is merged, each developer should run `wt config approvals add` interactively; no automated approval or `--yes` bypass is used.

## Verification

- Preview the rendered commands with `wt hook pre-merge --dry-run`.
- Execute the hooks in a feature worktree with `wt hook pre-merge` after interactive approval.
- Confirm a deliberately failing command aborts `wt merge` before target-branch movement.
- Confirm the four commands independently succeed on the intended baseline.
