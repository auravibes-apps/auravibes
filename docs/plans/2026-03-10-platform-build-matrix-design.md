# Platform Build Matrix CI Design

**Date**: 2026-03-10
**Status**: Approved
**Author**: David Londono

## Problem Statement

Dependabot updates can introduce platform-specific build failures (e.g., minimum deployment version conflicts in CocoaPods) that aren't caught by the current CI which only runs tests on Ubuntu. This resulted in a broken `main` branch when `sqlite3_flutter_libs` was updated and the `sqlite3` pod required a higher minimum macOS version.

## Solution

Implement a **Platform Build Matrix** workflow that:
1. Builds all supported platforms on **Pull Requests** (blocks merging if any fail)
2. Generates release artifacts on **push to main** (after validation in PR)

## Architecture

### Workflow Triggers

```yaml
on:
  pull_request:
    branches: [main, dev, stage]
    paths: [...]  # Path filters for efficiency
  push:
    branches: [main]
    paths: [...]  # For release artifacts
```

### Platform Support

| Platform | Runner | Build Command | Notes |
|----------|--------|---------------|-------|
| macOS | `macos-latest` | `flutter build macos` | Catches CocoaPods issues |
| iOS | `macos-latest` | `flutter build ios --no-codesign` | No signing for CI |
| Android | `ubuntu-latest` | `flutter build apk` | Debug APK |
| Windows | `windows-latest` | `flutter build windows` | Requires Windows runner |
| Linux | `ubuntu-latest` | `flutter build linux` | Requires SQLite dev libs |
| Web | `ubuntu-latest` | `flutter build web` | Static files |

### Job Structure

```
detect-changes (ubuntu-latest)
         │
         ├──► build-macos (macos-latest) [if: common || macos]
         ├──► build-ios (macos-latest) [if: common || ios]
         ├──► build-android (ubuntu-latest) [if: common || android]
         ├──► build-windows (windows-latest) [if: common || windows]
         ├──► build-linux (ubuntu-latest) [if: common || linux]
         └──► build-web (ubuntu-latest) [if: common || web]
```

### Path Filters

**Common paths** (trigger ALL platforms):
- `apps/auravibes_app/lib/**`
- `apps/auravibes_app/pubspec.yaml`
- `apps/auravibes_app/pubspec.lock`
- `packages/**`
- `melos.yaml`
- `.fvm/**`
- `.github/workflows/build-matrix.yml`

**Platform-specific paths**:
- macOS: `apps/auravibes_app/macos/**`
- iOS: `apps/auravibes_app/ios/**`
- Android: `apps/auravibes_app/android/**`
- Windows: `apps/auravibes_app/windows/**`
- Linux: `apps/auravibes_app/linux/**`
- Web: `apps/auravibes_app/web/**`

## Implementation Details

### 1. Change Detection Job

Uses `dorny/paths-filter@v3` to detect which platforms need building based on changed files.

### 2. FVM Integration

Uses existing `flutter-fvm-config-action` to ensure consistent Flutter version across all platforms.

### 3. Melos Bootstrap

Each job runs `melos bs` to link workspace packages before building.

### 4. Platform-Specific Setup

- **macOS/iOS**: `pod install` in respective directories
- **Linux**: Install `libsqlite3-dev`, `libgtk-3-dev`, `ninja-build`, etc.
- **Android**: Uses default SDK from `subosito/flutter-action`
- **Windows**: Uses MSVC from `windows-latest` runner

### 5. Fail-Fast Disabled

All platforms build independently - one failure doesn't stop others. This provides complete visibility into all platform issues.

### 6. Artifact Upload

Each job uploads its build artifact with 7-day retention for debugging failed builds.

## Branch Protection Requirements

After implementing this workflow, enable these GitHub branch protection rules:

1. **Require status checks to pass before merging**
   - Select all platform build jobs as required
2. **Require branches to be up to date before merging**
3. **Require a pull request review before merging** (optional, team-dependent)

## Expected CI Time

| Platform | Estimated Time |
|----------|----------------|
| detect-changes | ~30 sec |
| macOS | ~8 min |
| iOS | ~10 min |
| Android | ~7 min |
| Windows | ~10 min |
| Linux | ~6 min |
| Web | ~3 min |

**Total parallel time**: ~10-12 min (limited by slowest job - typically iOS)

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `.github/workflows/build-matrix.yml` | Create | New platform build workflow |
| `apps/auravibes_app/macos/Podfile` | Verify | Ensure minimum version is compatible |
| `apps/auravibes_app/ios/Podfile` | Verify | Ensure platform line is uncommented |

## Success Criteria

- [ ] All 6 platforms build successfully in CI
- [ ] Path filters correctly skip irrelevant platform builds
- [ ] Failed builds block PR merging
- [ ] Artifacts are uploaded for debugging
- [ ] Branch protection rules are configured

## References

- [GitHub Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/managing-a-branch-protection-rule)
- [GitHub Actions Matrix Strategy](https://codefresh.io/learn/github-actions/github-actions-matrix/)
- [Drift Database Setup](https://drift.simonbinder.eu/)
