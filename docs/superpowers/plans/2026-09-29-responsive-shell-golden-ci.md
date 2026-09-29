# Responsive-Shell Golden CI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` to implement this plan task-by-task.

**Goal:** Make responsive-shell golden updates repeatable on Linux x64 and retain actionable mismatch images from failed CI runs.

**Architecture:** Keep CI's existing `.fvmrc`-driven Flutter setup and Ubuntu runner. Add one guide for update/verify commands and one failure-only artifact/summary path in the existing golden job.

**Tech Stack:** Flutter 3.47.5 via FVM, GitHub Actions, `actions/upload-artifact` v7.

**Spec:** `docs/superpowers/specs/2026-09-29-responsive-shell-golden-ci-design.md`

## Global Constraints

- Keep scope limited to #1092 and #1093 and their shared golden CI job.
- Keep `ubuntu-26.04` and Flutter version sourced from `.fvmrc`.
- Preserve the tagged test command: `flutter test test/widgets/responsive_shell_test.dart --no-pub --tags=golden`.
- Upload only `apps/auravibes_app/test/widgets/failures/*.png` after the golden step fails; ignore missing files; retain for seven days.
- Do not change app behavior or regenerate golden images.

## Review Focus

- A non-Linux or differently pinned local environment must not be presented as a valid golden-update environment; verify guide specifies Linux x64 and FVM.
- The update command must target the same tagged test and differ only by `--update-goldens`; verify both commands in the guide.
- Diagnostics may be absent when failure happens before a golden comparison; verify upload ignores missing files and summary reports no artifact URL.
- CI may fail in an earlier step; verify upload and summary require the golden test step's failed outcome.
- Workflow reruns must not reuse artifact names; verify run ID and attempt appear in the name and retention is bounded.

---

### Task 1: Document Linux Golden Updates

**Files:**
- Create: `docs/testing/responsive-shell-goldens.md`

**Interfaces:**
- Consumes: `.fvmrc` Flutter version and `.github/workflows/ci.yml` runner/test command.
- Produces: a concise update and verification runbook for contributors.

- [ ] Create `docs/testing/responsive-shell-goldens.md`. State Linux x64 is required, `ubuntu-26.04` matches CI, and FVM reads the repository's Flutter version from `.fvmrc` (currently 3.47.5). From `apps/auravibes_app`, give these commands:

  ```sh
  fvm flutter test test/widgets/responsive_shell_test.dart --no-pub --tags=golden --update-goldens
  fvm flutter test test/widgets/responsive_shell_test.dart --no-pub --tags=golden
  ```

- [ ] Verify the Markdown names both commands and that the second command matches the existing CI invocation.

### Task 2: Upload Golden Failure Diagnostics

**Files:**
- Modify: `.github/workflows/ci.yml` in `responsive-shell-goldens`.

**Interfaces:**
- Consumes: Flutter's `apps/auravibes_app/test/widgets/failures/*.png` output and the existing pinned upload-artifact action.
- Produces: a failure-only artifact with a job-summary download link.

- [ ] First add and run a temporary workflow-contract check at `.superpowers/sdd/2026-09-29-responsive-shell-golden-ci/workflow_contract.py`. It must assert the existing runner/test command, `responsive-shell-test` ID, failure-gated upload step, exact path/name/retention settings, and summary URL reference; expect it to fail because the diagnostic steps do not exist yet.
- [ ] Give the golden test step ID `responsive-shell-test`. Add upload step ID `upload-golden-failures` using the existing pinned `actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a` (v7) with condition `${{ failure() && steps.responsive-shell-test.outcome == 'failure' }}`, path `apps/auravibes_app/test/widgets/failures/*.png`, name `responsive-shell-golden-failures-${{ github.run_id }}-${{ github.run_attempt }}`, `if-no-files-found: ignore`, and `retention-days: 7`.
- [ ] Add a summary step with ID `summarize-golden-failures` and condition `${{ always() && steps.responsive-shell-test.outcome == 'failure' }}`. Set `ARTIFACT_URL` from `${{ steps.upload-golden-failures.outputs.artifact-url }}` and `ARTIFACT_NAME` to the upload name. Link the URL when present; otherwise state no artifact was produced. Include the name in either message.
- [ ] Run `python3 .superpowers/sdd/2026-09-29-responsive-shell-golden-ci/workflow_contract.py` and `python3 -c 'import yaml; yaml.safe_load(open(".github/workflows/ci.yml"))'`; expect both to exit 0. Verify the tagged golden test and that success skips artifact/summary steps through the matching Linux CI job.
