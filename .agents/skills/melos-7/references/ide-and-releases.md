# Melos IDE and Release References

Read this file only when you change editor integration or release settings. Check the resolved Melos version and current extension docs before you use these options.

## IDE support

The Melos VS Code extension can provide `pubspec.yaml` completion, script actions, and tasks. Confirm its current task format before you add `.vscode/tasks.json` entries.

Melos can generate IntelliJ module files and run configurations during bootstrap. Check current Melos docs before you change `melos.ide.intellij` settings.

## Versioning and publishing

Melos versioning can update package versions and changelogs from conventional commits. It can also create commits and tags. Review branch and release policy before you run it.

Use `fvm dart run melos version --help` and `fvm dart run melos publish --help` for current options. Use a dry run to inspect publish output. Do not use a real publish command unless the user authorized it.

Release settings can include a repository URL, version branch, changelog options, commit message, changelog groups, and command hooks. Confirm each setting against current Melos docs before you add it.

Conventional commit prefixes often map to version changes as follows. Confirm the workspace release policy before a version run.

| Prefix | Common version change |
|---|---|
| `feat:` | Minor |
| `fix:` | Patch |
| `feat!:` or `BREAKING CHANGE` | Major |
| `docs:`, `chore:`, `refactor:`, `test:` | No version change by default |
