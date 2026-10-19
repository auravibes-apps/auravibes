# Melos Scripts and CLI

Read this file when you change script definitions, filters, CLI use, or script environment.

## Script modes

- `run` executes one command from the workspace root.
- `exec` executes a command in matching packages.
- `steps` runs commands in order.

Melos 8 does not allow `run` and `exec` in one script. Put a per-package command in `exec.command` when the script needs `exec` options.

This generic Melos 8 fragment shows valid syntax. Replace commands and filters with project needs.

```yaml
melos:
  scripts:
    analyze:
      run: dart analyze
    test:
      exec:
        command: flutter test --coverage
        concurrency: 1
        failFast: true
      packageFilters:
        dirExists: test
    validate:
      steps:
        - melos run analyze
        - melos run test
```

## Package filters

Filter names use camelCase. Melos maps them to kebab-case CLI options.

| Filter | Example |
|---|---|
| `dirExists` | `dirExists: test` |
| `fileExists` | `fileExists: pubspec.yaml` |
| `dependsOn` | `dependsOn: build_runner` |
| `noDependsOn` | `noDependsOn: legacy` |
| `scope` | `scope: "core_*"` |
| `ignore` | `ignore: "*_example"` |
| `diff` | `diff: main` |
| `category` | `category: app` |
| `includeDependencies` | `includeDependencies: true` |
| `includeDependents` | `includeDependents: true` |

Use `private: true` to hide an internal script from the normal script picker. Use `groups` to group scripts for filtered runs. Check the resolved CLI before you use `--include-private`, `--group`, or package-selection flags.

## Hooks and command overrides

Put lifecycle hooks under `melos.command.<name>.hooks` for commands that support hooks. Check current Melos docs for supported commands and hook names.

A custom script can override a built-in command name. Confirm the effect before you use names such as `format` or `clean`.

## CLI commands

Run Melos through FVM in this repository:

```bash
fvm dart run melos bootstrap
fvm dart run melos run <script>
fvm dart run melos list --json
fvm dart run melos exec --diff=main -- dart test
```

These are command patterns, not a full option list. Check `fvm dart run melos <command> --help` before you use other flags.

## Script environment

Melos makes these variables available to package scripts:

| Variable | Meaning |
|---|---|
| `MELOS_ROOT_PATH` | Workspace root path. |
| `MELOS_PACKAGE_NAME` | Current package name. |
| `MELOS_PACKAGE_PATH` | Current package path. |
| `MELOS_PACKAGE_VERSION` | Current package version. |
| `MELOS_PUBLISH_DRY_RUN` | Whether publish runs in dry-run mode. |

`MELOS_SDK_PATH` selects the SDK. `MELOS_PACKAGES` can scope packages. Check the resolved version before you depend on other variables.

## Common patterns

For sequential validation, use `steps`. For per-package tests, use `exec` with `packageFilters.dirExists: test`.

For code generation, select packages that depend on the generator. This Melos 8 fragment uses one `packageFilters` key and valid `exec` options:

```yaml
melos:
  scripts:
    generate:
      exec: dart run build_runner build --delete-conflicting-outputs
      packageFilters:
        dependsOn: build_runner
    generate:watch:
      exec:
        command: dart run build_runner watch --delete-conflicting-outputs
        concurrency: 10
      packageFilters:
        dependsOn: build_runner
```

For category runs, define categories under `melos.categories`, then filter scripts with `packageFilters.category`. Check the root workspace configuration before you add categories.
