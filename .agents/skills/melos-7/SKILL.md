---
name: melos-7
description: Use when working with Melos 7+ in Dart/Flutter monorepos. Covers pub workspace configuration, scripts, commands, filtering, and common patterns. Essential for any task involving melos commands, monorepo scripts, workspace config, or package management in a Melos workspace.
license: MIT
metadata:
  author: AuraVibes
  version: "1.0.0"
  domain: tooling
  triggers: melos, monorepo, workspace, bootstrap, melos run, melos exec, melos bs, pub workspace
  role: specialist
  scope: implementation
---

# Melos 7 Specialist

Authoritative guide for Melos 7+ (pub workspace-based). Prevents common AI mistakes from Melos 6 era assumptions.

## Critical Breaking Changes (Melos 6 -> 7)

These are the most common mistakes AI agents make. MEMORIZE THESE:

| Mistake (Melos 6 era) | Correct (Melos 7+) |
|---|---|
| Creating/editing `melos.yaml` | Config goes in root `pubspec.yaml` under `melos:` key |
| Expecting `pubspec_overrides.yaml` | Uses Dart pub workspaces (`workspace:` key) instead |
| Running `melos analyze` | **Command removed.** Use `dart analyze` directly or via a script |
| Using `packages:` key for package discovery | Use `workspace:` key (Dart pub workspace standard) |
| Using `name:` in `melos:` section | Removed. Workspace name comes from root `name:` in pubspec.yaml |
| Omitting `resolution: workspace` in packages | **Required** in every workspace package's pubspec.yaml |
| Using `select-package:` in scripts | Renamed to `packageFilters:` with camelCase filter names |
| Using `--since` flag | Removed. Use `--diff` instead |
| Using `usePubspecOverrides` config | Removed. Pub workspaces handle linking automatically |
| Dart SDK < 3.9.0 | **Requires Dart SDK >= 3.9.0** for pub workspaces |

## Configuration

### Root pubspec.yaml (Workspace Root)

```yaml
name: my_workspace
publish_to: none
environment:
  sdk: ^3.9.0

workspace:
  # Explicit paths (works on all supported SDKs):
  - apps/my_app
  - packages/core
  - packages/ui
  # Dart 3.11+ supports globs — use instead of listing every path:
  # - apps/*
  # - packages/*

dev_dependencies:
  melos: ^7.0.0

melos:
  sdkPath: auto  # or ".fvm/flutter_sdk" for FVM projects

  repository: https://github.com/org/repo

  useRootAsPackage: false  # set true if root is also a package
  discoverNestedWorkspaces: false  # set true for nested workspaces

  categories:
    app:
      - "apps/**"
    packages:
      - "packages/**"

  ignore:
    - 'packages/**/example'

  command:
    bootstrap:
      runPubGetInParallel: false
      runPubGetOffline: false
      enforceLockfile: false
      environment:
        sdk: ^3.9.0
      dependencies:
        collection: ^1.18.0
      dev_dependencies:
        test: ^1.24.0
      dependencyOverridePaths:
        - '../external_project/packages/**'
      hooks:
        pre: echo "Bootstrapping..."
        post: echo "Done!"

    version:
      branch: main
      message: |
        chore(release): publish packages

        {new_package_versions}
      linkToCommits: true
      workspaceChangelog: true
      includeScopes: true
      fetchTags: true
      releaseUrl: false
      changelogFormat:
        includeDate: false
      changelogCommitBodies:
        include: false
        onlyBreaking: true
      changelogs:
        - path: FOO_CHANGELOG.md
          description: Changes to foo packages
          packageFilters:
            scope: foo_*
      hooks:
        pre: echo "Versioning..."
        preCommit: echo "Before commit..."
        post: echo "Versioning done!"

    clean:
      hooks:
        post: melos exec --flutter --concurrency=3 -- "flutter clean"

    publish:
      hooks:
        pre: echo "Publishing..."
        post: echo "Published!"

  scripts:
    analyze:
      run: dart analyze
      description: Run static analysis

    format:check:
      run: dart format --line-length 80 -o none --set-exit-if-changed .
      description: Check formatting

    test:
      exec: flutter test --coverage
      description: Run tests
      packageFilters:
        dirExists: test

    generate:
      exec: dart run build_runner build --delete-conflicting-outputs
      packageFilters:
        dependsOn: build_runner

  ide:
    intellij:
      enabled: true
      moduleNamePrefix: melos_
      executeInTerminal: true
      generateAppRunConfigs: true
```

### Package pubspec.yaml (Workspace Member)

Every package in the workspace MUST have:

```yaml
name: my_package
environment:
  sdk: ^3.9.0
resolution: workspace  # REQUIRED for pub workspaces
```

### Configuration Options Reference

| Option | Type | Default | Description |
|---|---|---|---|
| `repository` | string or object | - | Git repo URL for changelog commit links |
| `sdkPath` | string | - | Path to SDK. Use `auto` for system SDK, `.fvm/flutter_sdk` for FVM |
| `useRootAsPackage` | bool | `false` | Include repo root as a workspace package |
| `discoverNestedWorkspaces` | bool | `false` | Recursively discover nested pub workspaces |
| `categories` | map | - | Group packages by glob patterns |
| `ignore` | list | - | Paths/globs excluded from Melos (not from Dart tooling) |
| `pub/timeoutSeconds` | int | 0 | Per-request pub registry timeout (0 = no timeout) |
| `pub/retry/maxAttempts` | int | 8 | Max retry attempts for pub requests |

### SDK Path Precedence (highest to lowest)

1. `--sdk-path` CLI option
2. `MELOS_SDK_PATH` environment variable
3. `sdkPath` in root `pubspec.yaml` melos section

### Workspace Globs (Dart 3.11+)

Starting from Dart 3.11.0, the `workspace:` key supports glob patterns:

```yaml
# Dart 3.11+ (globs) — simpler, auto-discovers new packages
workspace:
  - apps/*
  - packages/*

# Dart 3.9–3.10 (explicit paths only)
workspace:
  - apps/my_app
  - packages/core
  - packages/ui
```

For projects using SDK `^3.11.0` or higher, prefer globs to avoid manually adding every new package.

## Scripts System

Scripts are defined under `melos:` -> `scripts:` in root `pubspec.yaml`.

### Script Types

**Simple syntax** (name + command):
```yaml
scripts:
  hello: echo 'Hello World'
```

**Extended syntax** (with options):
```yaml
scripts:
  test:
    description: Run tests with coverage
    run: flutter test --coverage
    exec:
      concurrency: 1
      failFast: true
      orderDependents: true
    packageFilters:
      dirExists: test
    env:
      TEST_VAR: value
    private: false
    groups:
      - ci
```

**Steps syntax** (sequential multi-script):
```yaml
scripts:
  validate:
    description: Full validation
    steps:
      - melos run analyze
      - melos run format:check
      - melos run test
```

### run vs exec vs steps

| Mode | Keyword | Scope | Use Case |
|---|---|---|---|
| **Single command** | `run:` | Workspace root only | `dart analyze`, `flutter pub outdated` |
| **Per-package** | `exec:` | Runs in each package | `flutter test`, `dart run build_runner` |
| **Multi-step** | `steps:` | Sequential pipeline | CI pipelines, composite workflows |

For `exec`, use shorthand `exec: command` for defaults, or `run:` + `exec:` block for options:
```yaml
scripts:
  # Shorthand exec
  hello:
    exec: echo 'Hello from $MELOS_PACKAGE_NAME'

  # Exec with options
  build:
    run: flutter build apk
    exec:
      concurrency: 1
      failFast: true
      orderDependents: true
```

### Exec Options

| Option | Type | Default | Description |
|---|---|---|---|
| `concurrency` | int | CPU count | Max parallel package executions |
| `failFast` | bool | `false` | Stop on first package failure |
| `orderDependents` | bool | `false` | Execute in dependency order (leaves first) |

### packageFilters

Filter names are **camelCase** (not kebab-case):

```yaml
scripts:
  test:
    exec: flutter test
    packageFilters:
      dirExists: test         # --dir-exists
      fileExists: pubspec.yaml  # --file-exists
      flutter: true            # --flutter
      scope: "*_test"          # --scope (glob)
      ignore: "*_example"      # --ignore (glob)
      dependsOn: build_runner  # --depends-on
      noDependsOn: legacy      # --no-depends-on
      diff: main               # --diff (git ref or range)
      includeDependencies: true  # --include-dependencies
      includeDependents: true    # --include-dependents
      published: true            # --published
      noPrivate: false           # --no-private
      category: app              # --category
```

### Script Visibility

```yaml
scripts:
  internal-task:
    run: echo "internal"
    private: true  # Hidden from `melos run` prompt, only usable as a step
```

Use `--include-private` to see/run private scripts.

### Hooks

Available on: `bootstrap`, `clean`, `version`, `publish`

```yaml
command:
  bootstrap:
    hooks:
      pre: echo "before bootstrap"
      post: echo "after bootstrap"
  version:
    hooks:
      pre: echo "before versioning"
      preCommit: echo "before version commit"  # unique to version
      post: echo "after versioning"
```

### Overriding Built-in Commands

Custom scripts can override built-in commands (`format`, `clean`, etc.):
```yaml
scripts:
  format: dart run custom_formatter
```

Both `melos format` and `melos run format` will use the custom script.

### Groups

Scripts can be organized into groups for filtered execution:
```yaml
scripts:
  test:unit:
    run: flutter test
    groups:
      - ci
      - testing

  test:integration:
    run: flutter test integration_test
    groups:
      - ci
      - testing

  lint:
    run: dart analyze
    groups:
      - ci
```

Run scripts by group:
```bash
melos run --group=ci          # Run all scripts in the "ci" group
melos run --group=testing     # Run all scripts in the "testing" group
```

## CLI Commands Reference

### bootstrap (alias: bs)
```bash
melos bootstrap          # Install deps & link all packages
melos bs                 # Shorthand
melos bs --diff=main     # Only changed packages
melos bs --enforce-lockfile  # Strict lockfile adherence
melos bs --offline       # No network
melos bs --scope="pkg_*" # Specific packages
```

### clean
```bash
melos clean              # Remove .dart_tool, IDE files, generated config
melos clean --flutter    # Only Flutter packages
```

### format
```bash
melos format             # Format all packages
melos format --set-exit-if-changed  # CI mode: fail if not formatted
melos format -o none     # List files without formatting
melos format -c 5        # Concurrency of 5
```

### exec
```bash
melos exec -- dart analyze              # Run in all packages
melos exec -c 1 -- "dart test"          # Serial execution
melos exec --fail-fast -- dart test     # Stop on first failure
melos exec --order-dependents -- dart pub publish --dry-run
melos exec --scope="core_*" -- dart analyze
melos exec --flutter -- flutter build
melos exec --depends-on="core" -- dart analyze
melos exec --diff="main" -- dart test
melos exec --dir-exists="test" -- dart test
```

### list (alias: ls)
```bash
melos list               # Column format (default)
melos ls -p              # Parsable format
melos list --json        # JSON output
melos list --graph       # Dependency graph
melos list --gviz        # GraphViz format
melos list --mermaid     # Mermaid diagram
melos list --cycles      # Show circular deps
```

### run
```bash
melos run                # Interactive script picker
melos run test           # Run specific script
melos run test --no-select  # Skip package selection prompt
melos run --group=ci     # Run all scripts in a group
melos run --include-private  # Include private scripts in picker
```

### version
```bash
melos version            # Interactive version bumps
melos version --all      # Version all packages
melos version --no-git-tag-version  # No git tags
```

### publish
```bash
melos publish            # Dry run by default
melos publish --no-dry-run  # Actually publish
```

## Environment Variables

### Available in melos exec scripts

| Variable | Description |
|---|---|
| `MELOS_ROOT_PATH` | Absolute path to workspace root |
| `MELOS_PACKAGE_NAME` | Name of current package |
| `MELOS_PACKAGE_VERSION` | Version of current package |
| `MELOS_PACKAGE_PATH` | Path of current package |
| `MELOS_PARENT_PACKAGE_NAME` | Parent package name (for example packages) |
| `MELOS_PARENT_PACKAGE_VERSION` | Parent package version |
| `MELOS_PARENT_PACKAGE_PATH` | Parent package path |
| `MELOS_PUBLISH_DRY_RUN` | `true` on dry-run publish |

### User-configurable

| Variable | Description |
|---|---|
| `MELOS_SDK_PATH` | Override SDK path (precedence over config) |
| `MELOS_PACKAGES` | Comma-delimited package names to scope |

## Common Patterns

### FVM Projects

```yaml
melos:
  sdkPath: .fvm/flutter_sdk
```

Run melos with FVM:
```bash
fvm dart run melos bootstrap
fvm dart run melos run test
```

### CI Validation Pipeline

```yaml
scripts:
  validate:
    description: Full CI validation
    steps:
      - melos run analyze
      - melos run format:check
      - melos run test

  validate:quick:
    description: Quick dev check
    steps:
      - melos run analyze
      - melos run format:check
```

### Code Generation

```yaml
scripts:
  generate:
    exec: dart run build_runner build --delete-conflicting-outputs
    description: Run code generation
    packageFilters:
      dependsOn: build_runner

  generate:watch:
    run: dart run build_runner watch --delete-conflicting-outputs
    description: Watch mode code generation
    exec:
      concurrency: 10
    packageFilters:
      dependsOn: build_runner
    packageFilters:
      dependsOn: build_runner
```

### Testing with Coverage

```yaml
scripts:
  test:
    exec: flutter test --coverage --reporter=expanded
    description: Run tests with coverage
    packageFilters:
      dirExists: test

  test:specific:
    run: flutter test --no-pub
    description: Run specific test files (run from package dir)
```

### Reset Workspace

```yaml
scripts:
  reset:
    description: Full workspace reset
    steps:
      - melos clean
      - melos bootstrap
      - melos run generate
```

### Per-Category Scripts

```yaml
melos:
  categories:
    app:
      - "apps/**"
    packages:
      - "packages/**"

scripts:
  test:apps:
    exec: flutter test
    packageFilters:
      category: app
      dirExists: test

  test:packages:
    exec: flutter test
    packageFilters:
      category: packages
      dirExists: test
```

## IDE Support

### VS Code

Install the [Melos extension](https://marketplace.visualstudio.com/items?itemName=blaugold.melos-code) for:
- Script validation and autocompletion in `pubspec.yaml`
- CodeLenses to run scripts inline
- Melos scripts as VS Code tasks

Configure tasks:
```json
// .vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "type": "melos",
      "script": "test",
      "label": "melos: test"
    }
  ]
}
```

Commands available in palette: `Melos: Bootstrap`, `Melos: Clean`, `Melos: Run script`, `Melos: Show package graph`.

### IntelliJ / Android Studio

Melos generates `.iml` module files during `melos bootstrap` for each package, plus run configurations for `main.dart` and test suites. Configure in:
```yaml
melos:
  ide:
    intellij:
      enabled: true
      moduleNamePrefix: melos_
      executeInTerminal: true
      generateAppRunConfigs: true
```

## Automated Releases

Melos supports conventional-commit-based versioning and publishing.

### Workflow

```bash
# 1. Version packages (interactive — prompts for version bumps per package)
melos version

# 2. Publish (dry-run by default)
melos publish

# 3. Actually publish
melos publish --no-dry-run
```

### Version Command Details

`melos version` reads conventional commits (`feat:`, `fix:`, `feat!:` / `BREAKING CHANGE`) since last tag and:
- Prompts for version bump per changed package (patch/minor/major)
- Updates each package's `pubspec.yaml` version
- Generates/updates `CHANGELOG.md` per package
- Creates a workspace changelog (if `workspaceChangelog: true`)
- Commits and tags

Key flags:
```bash
melos version              # Interactive per-package bumps
melos version --all        # Bump all packages regardless of changes
melos version --no-git-tag-version    # Skip git tags
melos version --no-git-commit-version # Skip git commit
```

### Configuration for Releases

```yaml
melos:
  repository: https://github.com/org/repo  # Required for changelog links

  command:
    version:
      branch: main              # Restrict versioning to this branch
      linkToCommits: true       # Add commit links in CHANGELOG.md
      workspaceChangelog: true  # Root CHANGELOG.md aggregating all packages
      includeScopes: true       # Include scopes in changelog
      fetchTags: true           # Fetch tags before versioning
      releaseUrl: false         # Generate GitHub release URLs
      message: |
        chore(release): publish packages

        {new_package_versions}
      changelogFormat:
        includeDate: true       # Add date to changelog entries
      changelogCommitBodies:
        include: true           # Include commit bodies
        onlyBreaking: false     # All commits, not just breaking

      # Aggregate changelogs for package subsets
      changelogs:
        - path: PACKAGES_CHANGELOG.md
          description: All notable changes to packages
          packageFilters:
            category: packages
```

### Publish Configuration

```yaml
melos:
  command:
    publish:
      hooks:
        pre: echo "Publishing..."
        post: echo "Published!"
```

### Conventional Commit Reference

| Prefix | Version Bump | Changelog Section |
|---|---|---|
| `feat:` | minor | Features |
| `fix:` | patch | Bug Fixes |
| `feat!:` or `BREAKING CHANGE` | major | Breaking Changes |
| `docs:` | — | Documentation |
| `chore:`, `refactor:`, `test:` | — | (not versioned by default) |

## Migration Checklist (Melos 6 -> 7)

1. [ ] Update melos dependency to `^7.0.0` in root pubspec.yaml
2. [ ] Move all `melos.yaml` content into root `pubspec.yaml` under `melos:` key
3. [ ] Remove `packages:` and `name:` from the melos section (packages go in `workspace:` key)
4. [ ] Add `workspace:` key listing all package paths
5. [ ] Add `resolution: workspace` to every package's pubspec.yaml
6. [ ] Ensure Dart SDK >= 3.9.0
7. [ ] Remove `pubspec_overrides.yaml` from `.gitignore` (no longer generated)
8. [ ] Rename `select-package:` to `packageFilters:` with camelCase names
9. [ ] Replace `melos analyze` with `dart analyze` (custom script)
10. [ ] Move lifecycle hooks from scripts to `command/<name>/hooks/`
11. [ ] Replace `--since` with `--diff` in any scripts/commands
12. [ ] Delete old `melos.yaml` file
