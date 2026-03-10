# Platform Build Matrix CI Implementation Plan

> **for Claude:** REQUIRED BEFORE IMPLEMENTATION: Load the design document at `docs/plans/2026-03-10-platform-build-matrix-design.md` for full context.

**goal:** Implement a multi-platform build matrix CI workflow that catches platform-specific build failures (like CocoaPods minimum version conflicts) on pull requests before they reach main.

**architecture:** GitHub Actions workflow with change detection, 6 platform-specific build jobs (macOS, iOS, Android, Windows, Linux, Web), path filters for efficiency, and artifact upload for debugging.

**tech stack:** GitHub Actions, Flutter, Melos, CocoaPods, Gradle

---

## Task 1: Verify Podfile Platform Versions

**Files:**
- Verify: `apps/auravibes_app/macos/Podfile`
- Verify: `apps/auravibes_app/ios/Podfile`

**Step 1: Check macOS Podfile minimum version**

Read `apps/auravibes_app/macos/Podfile` and verify:
- Platform line exists: `platform :osx, 'X.Y'`
- Minimum version should be at least `10.14` (required by sqlite3_flutter_libs)

If version is too low (e.g., `10.13`), update to `10.15`:
```ruby
platform :osx, '10.15'
```

**Step 2: Check iOS Podfile minimum version**

Read `apps/auravibes_app/ios/Podfile` and verify:
- Platform line is UNCOMMENTED: `platform :ios, '13.0'` (or higher)
- Minimum version should be at least `12.0` (required by sqlite3 pod)

If commented out, uncomment and set to `13.0`:
```ruby
platform :ios, '13.0'
```

**Step 3: Test pod install locally**

```bash
cd apps/auravibes_app/macos && rm -rf Pods Podfile.lock && pod install
cd ../ios && rm -rf Pods Podfile.lock && pod install
```
Expected: Both succeed without errors

**Step 4: Commit**

```bash
git add apps/auravibes_app/macos/Podfile apps/auravibes_app/ios/Podfile
git commit -m "fix(ci): ensure Podfile minimum deployment versions are compatible"
```

---

## Task 2: Create Build Matrix Workflow File

**Files:**
- Create: `.github/workflows/build-matrix.yml`

**Step 1: Write the workflow file**

Create `.github/workflows/build-matrix.yml` with the following structure:

```yaml
name: Platform Build Matrix

on:
  pull_request:
    branches: [main, dev, stage]
    paths:
      # Common paths - trigger all platform builds
      - 'apps/auravibes_app/lib/**'
      - 'apps/auravibes_app/pubspec.yaml'
      - 'apps/auravibes_app/pubspec.lock'
      - 'packages/**'
      - 'melos.yaml'
      - '.fvm/**'
      - '.github/workflows/build-matrix.yml'
      # Platform-specific paths
      - 'apps/auravibes_app/macos/**'
      - 'apps/auravibes_app/ios/**'
      - 'apps/auravibes_app/android/**'
      - 'apps/auravibes_app/windows/**'
      - 'apps/auravibes_app/linux/**'
      - 'apps/auravibes_app/web/**'
  push:
    branches: [main]
    paths:
      - 'apps/auravibes_app/lib/**'
      - 'apps/auravibes_app/pubspec.yaml'
      - 'apps/auravibes_app/pubspec.lock'
      - 'packages/**'
      - 'melos.yaml'
      - '.fvm/**'
      - '.github/workflows/build-matrix.yml'
      - 'apps/auravibes_app/macos/**'
      - 'apps/auravibes_app/ios/**'
      - 'apps/auravibes_app/android/**'
      - 'apps/auravibes_app/windows/**'
      - 'apps/auravibes_app/linux/**'
      - 'apps/auravibes_app/web/**'

env:
  FLUTTER_WORKING_DIRECTORY: apps/auravibes_app

jobs:
  # Detect which platforms need building based on changed files
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      common: ${{ steps.filter.outputs.common }}
      macos: ${{ steps.filter.outputs.macos }}
      ios: ${{ steps.filter.outputs.ios }}
      android: ${{ steps.filter.outputs.android }}
      windows: ${{ steps.filter.outputs.windows }}
      linux: ${{ steps.filter.outputs.linux }}
      web: ${{ steps.filter.outputs.web }}
    steps:
      - name: 📚 Git Checkout
        uses: actions/checkout@v4

      - name: 🔍 Detect changed paths
        uses: dorny/paths-filter@v3
        id: filter
        with:
          filters: |
            common:
              - 'apps/auravibes_app/lib/**'
              - 'apps/auravibes_app/pubspec.yaml'
              - 'apps/auravibes_app/pubspec.lock'
              - 'packages/**'
              - 'melos.yaml'
              - '.fvm/**'
              - '.github/workflows/build-matrix.yml'
            macos:
              - 'apps/auravibes_app/macos/**'
            ios:
              - 'apps/auravibes_app/ios/**'
            android:
              - 'apps/auravibes_app/android/**'
            windows:
              - 'apps/auravibes_app/windows/**'
            linux:
              - 'apps/auravibes_app/linux/**'
            web:
              - 'apps/auravibes_app/web/**'

  # macOS Build
  build-macos:
    needs: detect-changes
    if: ${{ needs.detect-changes.outputs.common == 'true' || needs.detect-changes.outputs.macos == 'true' }}
    runs-on: macos-latest
    steps:
      - name: 📚 Git Checkout
        uses: actions/checkout@v4

      - name: 🔧 Setup FVM
        uses: kuhnroyal/flutter-fvm-config-action/config@v3
        id: fvm-config-action

      - name: 🐦 Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ steps.fvm-config-action.outputs.FLUTTER_VERSION }}
          channel: ${{ steps.fvm-config-action.outputs.FLUTTER_CHANNEL }}
          cache: true
          cache-key: "flutter-:os:-:channel:-:version:-:arch:"
          pub-cache-key: "flutter-pub-:os:-:channel:-:version:-:arch:-${{ hashFiles('pubspec.lock') }}"

      - name: 📦 Melos Bootstrap
        uses: bluefireteam/melos-action@main
        with:
          run-bootstrap: true

      - name: 🔧 Setup CocoaPods
        run: |
          cd ${{ env.FLUTTER_WORKING_DIRECTORY }}/macos
          rm -rf Pods Podfile.lock
          pod install --repo-update

      - name: 🏗️ Build macOS
        run: flutter build macos --debug
        working-directory: ${{ env.FLUTTER_WORKING_DIRECTORY }}

      - name: 📤 Upload macOS Artifact
        uses: actions/upload-artifact@v4
        with:
          name: macos-build
          path: ${{ env.FLUTTER_WORKING_DIRECTORY }}/build/macos/Build/Products/Debug/auravibes.app
          retention-days: 7

  # iOS Build
  build-ios:
    needs: detect-changes
    if: ${{ needs.detect-changes.outputs.common == 'true' || needs.detect-changes.outputs.ios == 'true' }}
    runs-on: macos-latest
    steps:
      - name: 📚 Git Checkout
        uses: actions/checkout@v4

      - name: 🔧 Setup FVM
        uses: kuhnroyal/flutter-fvm-config-action/config@v3
        id: fvm-config-action

      - name: 🐦 Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ steps.fvm-config-action.outputs.FLUTTER_VERSION }}
          channel: ${{ steps.fvm-config-action.outputs.FLUTTER_CHANNEL }}
          cache: true
          cache-key: "flutter-:os:-:channel:-:version:-:arch:"
          pub-cache-key: "flutter-pub-:os:-:channel:-:version:-:arch:-${{ hashFiles('pubspec.lock') }}"

      - name: 📦 Melos Bootstrap
        uses: bluefireteam/melos-action@main
        with:
          run-bootstrap: true

      - name: 🔧 Setup CocoaPods
        run: |
          cd ${{ env.FLUTTER_WORKING_DIRECTORY }}/ios
          rm -rf Pods Podfile.lock
          pod install --repo-update

      - name: 🏗️ Build iOS (No Codesign)
        run: flutter build ios --debug --no-codesign
        working-directory: ${{ env.FLUTTER_WORKING_DIRECTORY }}

      - name: 📤 Upload iOS Artifact
        uses: actions/upload-artifact@v4
        with:
          name: ios-build
          path: ${{ env.FLUTTER_WORKING_DIRECTORY }}/build/ios/iphoneos/Runner.app
          retention-days: 7

  # Android Build
  build-android:
    needs: detect-changes
    if: ${{ needs.detect-changes.outputs.common == 'true' || needs.detect-changes.outputs.android == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - name: 📚 Git Checkout
        uses: actions/checkout@v4

      - name: 🔧 Setup FVM
        uses: kuhnroyal/flutter-fvm-config-action/config@v3
        id: fvm-config-action

      - name: 🐦 Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ steps.fvm-config-action.outputs.FLUTTER_VERSION }}
          channel: ${{ steps.fvm-config-action.outputs.FLUTTER_CHANNEL }}
          cache: true
          cache-key: "flutter-:os:-:channel:-:version:-:arch:"
          pub-cache-key: "flutter-pub-:os:-:channel:-:version:-:arch:-${{ hashFiles('pubspec.lock') }}"

      - name: ☕ Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: 📦 Melos Bootstrap
        uses: bluefireteam/melos-action@main
        with:
          run-bootstrap: true

      - name: 🏗️ Build Android APK
        run: flutter build apk --debug
        working-directory: ${{ env.FLUTTER_WORKING_DIRECTORY }}

      - name: 📤 Upload Android Artifact
        uses: actions/upload-artifact@v4
        with:
          name: android-build
          path: ${{ env.FLUTTER_WORKING_DIRECTORY }}/build/app/outputs/flutter-apk/app-debug.apk
          retention-days: 7

  # Windows Build
  build-windows:
    needs: detect-changes
    if: ${{ needs.detect-changes.outputs.common == 'true' || needs.detect-changes.outputs.windows == 'true' }}
    runs-on: windows-latest
    steps:
      - name: 📚 Git Checkout
        uses: actions/checkout@v4

      - name: 🔧 Setup FVM
        uses: kuhnroyal/flutter-fvm-config-action/config@v3
        id: fvm-config-action

      - name: 🐦 Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ steps.fvm-config-action.outputs.FLUTTER_VERSION }}
          channel: ${{ steps.fvm-config-action.outputs.FLUTTER_CHANNEL }}
          cache: true
          cache-key: "flutter-:os:-:channel:-:version:-:arch:"
          pub-cache-key: "flutter-pub-:os:-:channel:-:version:-:arch:-${{ hashFiles('pubspec.lock') }}"

      - name: 📦 Melos Bootstrap
        uses: bluefireteam/melos-action@main
        with:
          run-bootstrap: true

      - name: 🏗️ Build Windows
        run: flutter build windows --debug
        working-directory: ${{ env.FLUTTER_WORKING_DIRECTORY }}

      - name: 📤 Upload Windows Artifact
        uses: actions/upload-artifact@v4
        with:
          name: windows-build
          path: ${{ env.FLUTTER_WORKING_DIRECTORY }}/build/windows/x64/runner/Debug/
          retention-days: 7

  # Linux Build
  build-linux:
    needs: detect-changes
    if: ${{ needs.detect-changes.outputs.common == 'true' || needs.detect-changes.outputs.linux == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - name: 📚 Git Checkout
        uses: actions/checkout@v4

      - name: 🔧 Setup FVM
        uses: kuhnroyal/flutter-fvm-config-action/config@v3
        id: fvm-config-action

      - name: 🐦 Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ steps.fvm-config-action.outputs.FLUTTER_VERSION }}
          channel: ${{ steps.fvm-config-action.outputs.FLUTTER_CHANNEL }}
          cache: true
          cache-key: "flutter-:os:-:channel:-:version:-:arch:"
          pub-cache-key: "flutter-pub-:os:-:channel:-:version:-:arch:-${{ hashFiles('pubspec.lock') }}"

      - name: 📦 Install Linux Dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev libsqlite3-dev

      - name: 📦 Melos Bootstrap
        uses: bluefireteam/melos-action@main
        with:
          run-bootstrap: true

      - name: 🏗️ Build Linux
        run: flutter build linux --debug
        working-directory: ${{ env.FLUTTER_WORKING_DIRECTORY }}

      - name: 📤 Upload Linux Artifact
        uses: actions/upload-artifact@v4
        with:
          name: linux-build
          path: ${{ env.FLUTTER_WORKING_DIRECTORY }}/build/linux/x64/debug/bundle/
          retention-days: 7

  # Web Build
  build-web:
    needs: detect-changes
    if: ${{ needs.detect-changes.outputs.common == 'true' || needs.detect-changes.outputs.web == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - name: 📚 Git Checkout
        uses: actions/checkout@v4

      - name: 🔧 Setup FVM
        uses: kuhnroyal/flutter-fvm-config-action/config@v3
        id: fvm-config-action

      - name: 🐦 Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ steps.fvm-config-action.outputs.FLUTTER_VERSION }}
          channel: ${{ steps.fvm-config-action.outputs.FLUTTER_CHANNEL }}
          cache: true
          cache-key: "flutter-:os:-:channel:-:version:-:arch:"
          pub-cache-key: "flutter-pub-:os:-:channel:-:version:-:arch:-${{ hashFiles('pubspec.lock') }}"

      - name: 📦 Melos Bootstrap
        uses: bluefireteam/melos-action@main
        with:
          run-bootstrap: true

      - name: 🏗️ Build Web
        run: flutter build web --release
        working-directory: ${{ env.FLUTTER_WORKING_DIRECTORY }}

      - name: 📤 Upload Web Artifact
        uses: actions/upload-artifact@v4
        with:
          name: web-build
          path: ${{ env.FLUTTER_WORKING_DIRECTORY }}/build/web/
          retention-days: 7
```

**Step 2: Validate YAML syntax**

```bash
cat .github/workflows/build-matrix.yml | head -50
```
Expected: Valid YAML with no syntax errors

**Step 3: Commit**

```bash
git add .github/workflows/build-matrix.yml
git commit -m "feat(ci): add platform build matrix workflow for all platforms"
```

---

## Task 3: Test Workflow on a Branch

**Files:**
- None (testing only)

**Step 1: Create a test branch**

```bash
git checkout -b test/build-matrix-ci
git push -u origin test/build-matrix-ci
```

**Step 2: Make a small change to trigger CI**

```bash
echo "// Test build matrix" >> apps/auravibes_app/lib/main.dart
git add apps/auravibes_app/lib/main.dart
git commit -m "test: trigger build matrix ci"
git push
```

**Step 3: Open a Pull Request**

Create PR from `test/build-matrix-ci` to `main`

**Step 4: Verify CI behavior**

Expected:
- `detect-changes` job runs and detects "common" change
- All 6 platform build jobs are triggered
- Each job builds successfully (or fails with clear error if there are issues)
- Artifacts are uploaded

**Step 5: If builds fail, debug and fix**

- Check the failed job logs
- Fix any issues (e.g., missing dependencies, wrong paths)
- Push fixes to the branch
- Verify builds pass

**Step 6: Cleanup test branch**

After successful validation:
```bash
gh pr close --delete-branch
```

---

## Task 4: Update Documentation

**Files:**
- Create: `docs/ci-cd.md`

**Step 1: Create CI/CD documentation**

Create `docs/ci-cd.md`:

```markdown
# CI/CD Pipeline

## Overview

This project uses GitHub Actions for continuous integration and deployment.

## Workflows

### CI Workflow (`ci.yml`)

Runs on every push and pull request to main/dev/stage branches:
- Code formatting check
- Static analysis
- Unit tests
- Dependency validation
- Import sorting

### Platform Build Matrix (`build-matrix.yml`)

Runs on pull requests and pushes to main:
- Detects which platforms need building based on changed files
- Builds all affected platforms in parallel
- Uploads build artifacts for debugging

**Supported Platforms:**
- macOS (macos-latest)
- iOS (macos-latest)
- Android (ubuntu-latest)
- Windows (windows-latest)
- Linux (ubuntu-latest)
- Web (ubuntu-latest)

## Branch Protection

The main branch requires:
- All CI checks to pass
- Platform builds to succeed (for relevant platforms)
- Pull request review approval

## Adding New Platforms

To add a new platform to the build matrix:
1. Add the platform directory to the path filters
2. Add a new build job with appropriate runner
3. Add any platform-specific setup steps
4. Upload artifacts for debugging
```

**Step 2: Commit**

```bash
git add docs/ci-cd.md
git commit -m "docs: add CI/CD pipeline documentation"
```

---

## Task 5: Configure Branch Protection Rules

**Files:**
- None (GitHub Settings)

**Step 1: Navigate to Branch Protection Settings**

Go to: `Settings` → `Branches` → `Branch protection rules` → `Add rule` or edit existing `main` rule

**Step 2: Configure Required Status Checks**

Enable:
- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging

Select these required checks:
- `build-macos`
- `build-ios`
- `build-android`
- `build-windows`
- `build-linux`
- `build-web`
- `detect-changes` (optional - the individual build jobs are the real gates)

**Step 3: Save Changes**

Click "Create" or "Save changes"

---

## Summary

| Task | Files | Commit Message |
|------|-------|----------------|
| 1 | `macos/Podfile`, `ios/Podfile` | `fix(ci): ensure Podfile minimum deployment versions are compatible` |
| 2 | `.github/workflows/build-matrix.yml` | `feat(ci): add platform build matrix workflow for all platforms` |
| 3 | None (testing) | N/A |
| 4 | `docs/ci-cd.md` | `docs: add CI/CD pipeline documentation` |
| 5 | GitHub Settings | N/A |

## Testing Commands

```bash
# Test macOS build locally
cd apps/auravibes_app && fvm flutter build macos --debug

# Test iOS build locally (requires macOS)
cd apps/auravibes_app && fvm flutter build ios --debug --no-codesign

# Test Android build locally
cd apps/auravibes_app && fvm flutter build apk --debug

# Test web build locally
cd apps/auravibes_app && fvm flutter build web --release
```
