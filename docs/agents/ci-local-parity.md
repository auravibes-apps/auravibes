# Local GitHub CI parity

`fvm dart run melos run validate:ci --no-select` covers the Melos validation
subset: workspace analysis, code-health checks, formatting, and package tests
with coverage. It is not the complete `.github/workflows/ci.yml` workflow.

## Reproducible local gates

Run from the repository root after `fvm dart run melos bootstrap`:

```sh
fvm dart run melos run validate:ci --no-select
fvm dart run melos run dcl:analyze
fvm dart run import_sorter:main --exit-if-changed
fvm dart test tool/changed_test_selector_test.dart tool/merge_lcov_test.dart
python3 tool/classify_ci_changes_test.py
python3 tool/ci_summary_test.py
fvm dart run dependency_validator
fvm dart run melos run generate --no-select
```

Run app-specific gates from `apps/auravibes_app`:

```sh
fvm flutter test test/first_party_tool_schema_audit_test.dart --no-pub
fvm dart run tool/localization_audit.dart
fvm flutter test test/widgets/responsive_shell_test.dart --no-pub --tags=golden
```

For Serverpod artifact parity, install the CLI version from `pubspec.lock`
before running `fvm dart run melos run generate:serverpod`. Inspect
`git status --short` afterward; generated drift fails the GitHub integrity job.

## Report separately

Do not report `validate:ci` as full GitHub CI. Mark these gates separately:

- platform builds from `.github/workflows/build-matrix.yml`;
- Docker-backed `server-compose` and `server-integration` jobs;
- GitHub test-plan selection, sharding, coverage/Sonar, and hosted runner-only
  behavior.

The final report must name each skipped gate and why it was not run.
