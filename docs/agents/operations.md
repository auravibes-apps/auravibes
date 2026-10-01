# Agent operations

Read only the section relevant to CI failure diagnosis, database queries, or native Flutter driver control.

## CI failure triage

- `ci success` only summarizes fan-out; inspect first failed job. A cancelled PR run may be superseded by newer push.
- `integrity` generated drift: run `generate` and `generate:serverpod`; review and commit generated diff. Never hand-edit output.
- `integrity` FVM drift: run `fvm use` after `.fvmrc` changes; it selects the SDK and runs `flutter pub get` by default when switching SDKs (`--skip-pub-get` skips it). CI's setup action runs Melos bootstrap before checking dependency artifact drift; do not infer bootstrap is redundant from the Pub workspace declaration. Commit `.vscode/settings.json` sync.
- Workspace setup failures are dependency/version issues; inspect pub solver output before changing Dart code.
- DCL unused-code scans production `lib`, not tests. Remove true dead code; test-only contracts or generated/route reachability need narrow, reasoned excludes only after reference review.

### Scoped database queries

- From repo root, run `fvm dart run tool/db_query.dart "SELECT ..."` to query the dev database scoped by VS Code's `DB_HASH_SOURCE`, which defaults to the current repo path. Use `--hash-source PATH` for another workspace.
- Use `--database-directory PATH` when the platform documents directory needs an override. Results print as JSON lines; a missing scoped database fails without creating a file.

## Flutter MCP Control

- Use `dev Debug` for manual testing with the native keyboard. Use the `dev Driver` VS Code launch profile, or run from `apps/auravibes_app`: `fvm flutter run --flavor dev --dart-define=AURAVIBES_SERVER_URL=http://localhost:8080/ --dart-define=ENABLE_FLUTTER_DRIVER=true`.
- Driver mode emulates text entry; the native keyboard is unavailable. Through `mcp__dart_mcp_server__flutter_driver_command`, call `get_health`, focus and `tap` a finder, `enter_text`, then verify with `get_text` or `screenshot`. Set `appUri` when multiple apps are connected.
- Do not use driver mode to verify real iOS keyboard behavior.
