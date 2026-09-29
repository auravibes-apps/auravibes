# Responsive-Shell Golden CI Design

**Date:** 2026-09-29

**Status:** Approved scope

**Scope:** Issues #1092 and #1093 only

## Intent

Make responsive-shell golden updates reproducible in the same environment as CI and retain Flutter's golden mismatch images from failed CI runs.

## Evidence and constraints

- `.fvmrc` pins Flutter 3.47.5; `.github/actions/setup-workspace` installs that version for CI.
- The `responsive-shell-goldens` job runs on `ubuntu-26.04` and executes the tagged test from `apps/auravibes_app`.
- Flutter 3.47.5 writes master, test, isolated-diff, and masked-diff PNGs under the test file's `failures/` directory. For this test that path is `apps/auravibes_app/test/widgets/failures/`.
- macOS x64/arm64 rendering has differed from the committed Linux x64 images; regenerating on macOS is not a supported update path.

## Design

Add a concise guide with the Linux x64/FVM update command (`--update-goldens`) and the matching verification command. Keep the guide tied to `.fvmrc` and CI's existing `ubuntu-26.04` job so version changes remain sourced from the repository.

Give the golden test step an ID. When that step fails, upload any PNGs in its `failures/` directory using the existing pinned `actions/upload-artifact` version, seven-day retention, and `if-no-files-found: ignore`. Name artifacts with workflow run ID and attempt so reruns remain distinct. Follow with a failed-test-only job-summary step that links the artifact using the upload action's `artifact-url`, or states that Flutter produced no PNGs.

## Acceptance criteria

1. The guide provides exact Linux x64 update and verification commands from `apps/auravibes_app` and identifies `.fvmrc` as the Flutter version source.
2. CI still runs the tagged responsive-shell golden test on `ubuntu-26.04` using the version from `.fvmrc`.
3. A failed golden step uploads the available Flutter diagnostic PNGs and exposes their artifact URL in the job summary; success skips both steps.
4. Upload ignores absent diagnostics and expires after seven days.
5. No unrelated issue, app behavior, or golden image changes.
