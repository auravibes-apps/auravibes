[PLANS]
- 2026-04-08T00:00Z [USER] Keep Melos aligned to the FVM SDK and make CI workflows resolve the SDK path correctly.

[DECISIONS]
- 2026-04-08T00:00Z [CODE] `melos.sdkPath` is set to `.fvm/flutter_sdk` instead of `auto`.
- 2026-04-08T00:00Z [CODE] GitHub Actions create `.fvm/flutter_sdk` from `FLUTTER_ROOT`; Windows uses a PowerShell junction instead of `ln -sfn`.
- 2026-04-08T00:00Z [CODE] The duplicate symlink logic remains in workflows for now; not extracted to a composite action because Windows requires different setup and the current scope is small.

[PROGRESS]
- 2026-04-08T00:00Z [CODE] Removed the unused `id: flutter-action` from `.github/workflows/ci.yml` after switching the workflow to use `$FLUTTER_ROOT` directly.
- 2026-04-08T00:00Z [CODE] Removed the same unused `id: flutter-action` from `.github/workflows/lockfiles.yml`; `steps.flutter-action.*` is not referenced there either.

[DISCOVERIES]
- 2026-04-08T00:00Z [TOOL] Bare `melos` can fail with `Invalid SDK hash` when global/system Dart differs from FVM Dart; `fvm dart run melos` works after clearing stale pub cache snapshots.
- 2026-04-08T00:00Z [TOOL] CI failed when `sdkPath` pointed at `.fvm/flutter_sdk` without the path existing on runners; symlink/junction creation before `melos-action` fixes that class of failure.

[OUTCOMES]
- 2026-04-08T00:00Z [CODE] PR branch contains the Melos SDK path fix, CI workflow updates, Windows junction handling, and the small cleanup removing the unused Flutter action step id.
