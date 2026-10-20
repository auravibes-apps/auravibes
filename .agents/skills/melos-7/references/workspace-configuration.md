# Melos Workspace Configuration

Read this file when you change workspace membership, SDK selection, or package discovery. Root `pubspec.yaml` remains source of truth for AuraVibes.

## Pub workspaces

Melos 7 and later use Dart Pub workspaces. Put member paths under root `workspace:`. Set `resolution: workspace` in each member package.

This fragment shows structure only. Use actual paths and SDK constraints from the repository.

```yaml
workspace:
  - apps/my_app
  - packages/core

melos:
  sdkPath: auto
```

```yaml
name: my_package
resolution: workspace
```

Dart Pub workspaces need Dart 3.9.0 or later. Dart 3.11.0 and later support workspace globs. Older SDKs need explicit paths. AuraVibes lists explicit paths in root `pubspec.yaml`.

## Melos options

| Option | Purpose |
|---|---|
| `sdkPath` | Select the SDK that Melos uses. |
| `useRootAsPackage` | Include the root as a workspace package. |
| `discoverNestedWorkspaces` | Find nested Pub workspaces. |
| `categories` | Group packages by path patterns. |
| `ignore` | Exclude paths from Melos discovery. |
| `repository` | Set the repository URL for release links. |

The `--sdk-path` CLI option takes precedence over `MELOS_SDK_PATH`. `MELOS_SDK_PATH` takes precedence over `sdkPath` in root `pubspec.yaml`.

Use workspace globs only when the selected Dart SDK supports them. Do not replace AuraVibes explicit paths with globs without a task need.
