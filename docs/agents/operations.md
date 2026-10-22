# Agent operations

Read only the section relevant to PR check monitoring, GitHub CLI merge preflight, CI failure diagnosis, Codemagic release triage, database queries, or native Flutter driver control.

## CI failure triage

### PR check monitoring

- Before polling, compare `gh pr view <number> --json headRefOid` with local `git rev-parse HEAD` to avoid watching stale runs.
- For a compact check snapshot, show only pending, failed, or cancelled checks:

```sh
gh pr checks <number> --json name,bucket \
  --jq '.[] | select(.bucket == "pending" or .bucket == "fail" or .bucket == "cancel") | "\(.bucket): \(.name)"'
```

- Repeat every 60 seconds while rows remain. Exit code 8 means checks are pending; empty output means no checks need attention. Use `--watch` only when full live output is useful.
- After a watch interruption, query current status before restarting; follow [validation policy](task-policies.md#validation).
- For job-level diagnosis, with `run_id` set to the relevant run, project unfinished jobs instead of printing full job objects:
  ```sh
  gh run view "$run_id" --json jobs --jq \
    '[.jobs[] | select(.status != "completed") | {name, status, activeStep: ([.steps[]? | select(.status == "in_progress") | .name][0])}]'
  ```

- `ci success` only summarizes fan-out; inspect first failed job. A cancelled PR run may be superseded by newer push.
- `integrity` generated drift: run `python3 tool/validation_lease.py -- fvm dart run melos run validate:generated` from a clean worktree; inspect and commit generated diff. Never hand-edit output.
- `integrity` FVM drift: run `fvm use` after `.fvmrc` changes; it selects the SDK and runs `flutter pub get` by default when switching SDKs (`--skip-pub-get` skips it). CI's setup action runs Melos bootstrap before checking dependency artifact drift; do not infer bootstrap is redundant from the Pub workspace declaration. Commit `.vscode/settings.json` sync.
- Workspace setup failures are dependency/version issues; inspect pub solver output before changing Dart code.
- DCL unused-code scans production `lib`, not tests. Remove true dead code; test-only contracts or generated/route reachability need narrow, reasoned excludes only after reference review.

## GitHub CLI merge preflight

- `gh pr merge` has no dry-run; treat it as a remote write. Before invoking it, inspect the current head and merge requirements:
  ```sh
  gh pr view <number> --json headRefOid,mergeStateStatus,reviewDecision,reviewRequests
  ```
- Compare `headRefOid` with the reviewed commit and guard the merge with that SHA:
  ```sh
  gh pr merge <number> --match-head-commit <reviewed-head-sha>
  ```
- Stop and report when `mergeStateStatus` is `BLOCKED`, `reviewDecision` is `REVIEW_REQUIRED`, required checks are pending or failing, or required approval is absent. Requested review is not approval.
- On merge-queue branches, omit strategy flags and never use `--admin`; use the normal merge command so GitHub can queue the PR. A request to merge does not authorize bypassing the queue. When requirements remain unmet, `gh pr merge` may enable auto-merge; do not use it to probe readiness.
- Outside merge queues, use `--admin` only when the user explicitly authorizes bypassing repository requirements.

## Codemagic release triage

- Merging a `chore(release)` commit starts [the GitHub release workflow](../../.github/workflows/release.yml). Its `release` job waits for all six [platform builds](../../.github/workflows/build-matrix.yml), then creates the `auravibes_app-v<version>` tag and release. Codemagic's [iOS and Android workflows](../../codemagic.yaml) listen for tags matching `auravibes_app-v*`.
- Check GitHub's release run before expecting a tag or Codemagic build:

  ```sh
  gh run list --repo auravibes-apps/auravibes --workflow release.yml --limit 5
  # Set run_id to the selected run's ID from the list.
  gh run view "$run_id" --repo auravibes-apps/auravibes --json status,conclusion,url,jobs \
    --jq '{status, conclusion, url, jobs: [.jobs[] | {name, status, conclusion}]}'
  ```

- After the release job succeeds, check the tag and uploaded assets with `gh release view "$tag" --repo auravibes-apps/auravibes --json tagName,url,assets --jq '{tagName, url, assets: [.assets[].name]}'`.
- If Codemagic skips a tag, inspect the GitHub webhook delivery record first. A `202` response means Codemagic accepted the event; compare the tag's `codemagic.yaml` trigger and tag pattern before changing webhook configuration. Do not add a duplicate webhook for an event Codemagic already accepted.
- If Codemagic builds but release assets are missing, inspect the `gh release upload` step. Verify `GH_TOKEN` exists in the `github` group as a secret and has `Contents: write` for this repository. Never print or read the token value.

### Scoped database queries

- From repo root, run `fvm dart run tool/db_query.dart "SELECT ..."` to query the dev database scoped by VS Code's `DB_HASH_SOURCE`, which defaults to the current repo path. Use `--hash-source PATH` for another workspace.
- Use `--database-directory PATH` when the platform documents directory needs an override. Results print as JSON lines; a missing scoped database fails without creating a file.

## Flutter MCP Control

- Use `dev Debug` for manual testing with the native keyboard. Use the `dev Driver` VS Code launch profile, or run from `apps/auravibes_app`: `fvm flutter run --flavor dev --dart-define=AURAVIBES_SERVER_URL=http://localhost:8080/ --dart-define=ENABLE_FLUTTER_DRIVER=true`.
- Driver mode emulates text entry; the native keyboard is unavailable. Through `mcp__dart_mcp_server__flutter_driver_command`, call `get_health`, focus and `tap` a finder, `enter_text`, then verify with `get_text` or `screenshot`. Set `appUri` when multiple apps are connected.
- Do not use driver mode to verify real iOS keyboard behavior.
