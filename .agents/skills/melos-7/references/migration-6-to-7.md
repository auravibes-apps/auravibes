# Migrate Melos 6 to 7

Use this checklist only for a Melos 6 to 7 migration. Check the target SDK and Melos version first. AuraVibes currently uses Dart 3.13 and Melos 8.7.0, so do not copy the target version below into this repository.

## Migration checklist

1. Set the root `melos` dependency to the target version.
2. Move `melos.yaml` settings to root `pubspec.yaml` under `melos:`.
3. Remove Melos `name:` and `packages:` settings. Put package paths under Dart Pub `workspace:`.
4. Add `resolution: workspace` to each workspace package.
5. Use Dart SDK 3.9.0 or later.
6. Replace `select-package:` with `packageFilters:` and camelCase filter names.
7. Replace removed `--since` usage with `--diff`.
8. Remove `usePubspecOverrides` configuration. Pub workspaces provide package linking.
9. Check every command against the target Melos version. Melos 7 removed `melos analyze`. AuraVibes Melos 8.7.0 uses the root `analyze:workspace` script, so follow current root scripts.
10. Run the target version's bootstrap. Confirm package discovery and affected scripts.

This list does not need changes to `.gitignore`. Check actual Pub output before you change any `pubspec_overrides.yaml` ignore rule.

Lifecycle hooks moved from scripts to command configuration in an earlier Melos migration. Do not treat that change as a Melos 6 to 7 step.

## Completion checks

- Root `workspace:` lists every intended package.
- Every member has `resolution: workspace`.
- Root `melos:` settings use names supported by the target version.
- The target bootstrap, package listing, and focused scripts pass.
- The diff contains no obsolete Melos 6 configuration.
