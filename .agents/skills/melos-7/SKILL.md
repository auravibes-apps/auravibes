---
name: melos-7
description: Use for Melos configuration, package membership, bootstrap, or version troubleshooting. Skip ordinary runs of documented scripts.
license: MIT
metadata:
  author: AuraVibes
  version: "1.0.0"
  domain: tooling
  triggers: melos configuration, package membership, bootstrap, melos version, pub workspace setup
  role: specialist
  scope: implementation
---

# Melos 7+ Specialist

Use this skill for Melos configuration, workspace membership, bootstrap, or version migration.

## AuraVibes facts

- Root `pubspec.yaml` holds workspace members, Melos settings, and scripts.
- The current lockfile selects Melos 8.7.0. Check `pubspec.lock` before each version change.
- Keep Melos configuration in root `pubspec.yaml`. This repository has no `melos.yaml`.
- For a fresh checkout, run `fvm use`, then `fvm dart run melos bootstrap`.
- FVM runs `flutter pub get` by default when it changes SDK. Use `--skip-pub-get` to skip resolution.
- CI runs Melos bootstrap. Pub workspace membership does not replace that step.
- Use `fvm dart run melos run analyze:workspace` for workspace analysis in this repository.

## Task steps

1. Read root `pubspec.yaml`, `pubspec.lock`, and `.fvmrc` before each Melos change.
2. Read CI setup when the change affects workspace membership or bootstrap.
3. Choose a direct reference below for the task branch.
4. Make the smallest change in the root or member `pubspec.yaml` files.
5. Run the focused bootstrap or script command. Use the resolved Melos version and its `--help` output for CLI options.

## Completion checks

- Root workspace paths and member `resolution: workspace` values agree after membership changes.
- Script syntax matches the locked Melos version.
- The focused bootstrap or script command passes when the change affects its behavior.
- Review the diff. Do not run unrelated workspace checks.

## Reference branches

- For workspace configuration, SDK paths, or package discovery, read [workspace configuration](references/workspace-configuration.md).
- For script syntax, filters, CLI commands, or environment variables, read [scripts and CLI](references/scripts-and-cli.md).
- For a Melos 6 to 7 migration, read [migration steps](references/migration-6-to-7.md).
- For optional IDE or release tasks, read [IDE and releases](references/ide-and-releases.md).
