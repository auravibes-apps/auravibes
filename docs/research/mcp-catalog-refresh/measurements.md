# MCP catalog refresh measurements

Issue: https://github.com/auravibes-apps/auravibes/issues/1450

## Status

No measurements are available yet. The repository validation lease rejected the baseline test command before Flutter executed. Production metadata persistence remains unchanged. The evidence rule for batching has not been met.

The isolated worktree starts at `f00fc7b9159cc35713db498ad319200a5ed4052e` and uses the installed pinned Flutter 3.47.9 SDK. No bootstrap, SDK install, or lease bypass is authorized. This worktree does not yet have its own `.dart_tool/package_config.json`; existing dependency resolution is present in the main checkout. Reusing it must preserve workspace-relative package paths and avoid accidentally measuring the main checkout's source.

## Reproduction

The opt-in benchmark measures 10, 100, and 1000 existing tools with 0%, 10%, and 100% changed metadata. It runs SQLite in memory and through a background isolate using a temporary file. Each case excludes database creation, seeding, input construction, and verification from timing. It performs one warm-up followed by seven reported samples and alternates metadata versions so changed tools require updates in every sample.

Run from `apps/auravibes_app` after the validation environment is ready. Capture expanded test output, which contains one JSON record per workload. Run five independent test processes for each implementation and record a distinct run label each time. Each process produces 18 workload records and 126 measured samples. The complete baseline contains 90 records and 630 measured samples.

```sh
AURAVIBES_MCP_CATALOG_BENCHMARK=1 \
AURAVIBES_MCP_BENCHMARK_REVISION="$(git rev-parse HEAD)" \
AURAVIBES_MCP_BENCHMARK_RUN=baseline-1 \
python3 /workspace/auravibes-agent-worktrees/issue-1450/tool/validation_lease.py \
  --label issue-1450-measurement -- fvm flutter test \
  test/data/repositories/mcp_catalog_refresh_benchmark_test.dart \
  --no-pub --reporter=expanded
```

Each JSON record contains the source revision, run label, baseline revision, OS, Dart version, backend, catalog size, changed count, sample count, total refresh median/p95, and every raw sample. Samples contain elapsed refresh microseconds, metadata executor microseconds, tool UPDATE row executions, individual UPDATE dispatches, batch dispatches, total mutation row executions, SELECT calls, and transaction commit/rollback counts. Batch row executions count parameter sets, not unique prepared statements. These counters describe attempted executions; successful workloads also verify stored metadata and identity.

Correctness assertions have no timing thresholds. They assert the requested number of metadata updates, no mutations for unchanged tools, successful transaction completion, current stored schemas/descriptions, stable IDs and permissions/enablement, and full stored-row equality for unchanged tools. Ordinary refresh tests cover full-row preservation, explicit null output schemas, mixed membership changes, metadata failure, late removal failure, and observer snapshots after rollback.

## Evidence rule

Compare baseline/candidate raw distributions across repeated complete runs at 100 and 1000 changed tools, especially for the background-isolate backend. Retain batching only if savings repeat beyond observed run-to-run variation and total-refresh medians improve at both sizes, with no no-op regression distinguishable from variation. Record absolute savings and the distributions used to reach that decision. There is no arbitrary percentage cutoff and no CI timing gate.

An executor batch still executes one SQL UPDATE per changed row. Its expected benefit is fewer awaited executor dispatches and prepared-statement reuse. Report row writes and dispatch counts separately. Do not infer speedup solely from reduced dispatch counts.

## Validation blocker

The following command exited 3 before Flutter ran:

```sh
python3 /workspace/auravibes-agent-worktrees/issue-1450/tool/validation_lease.py \
  --label issue-1450-baseline -- fvm flutter test \
  test/data/database/drift/daos/workspace_tools_dao_test.dart \
  test/data/repositories/mcp_servers_repository_impl_test.dart --no-pub
```

The lease reported 17.5 GiB available on the worktree filesystem and 3.0 GiB on `/tmp`, below its 20.0 GiB reserve. No files were deleted, and the reserve check was not bypassed. The new benchmark and preservation tests, Dart formatting, and Dart analysis remain unexecuted. `git diff --check` is the available whitespace check; its result does not establish Dart correctness.

After resolving this environment constraint, run the baseline command, then the new `test/data/repositories/mcp_catalog_refresh_test.dart` and opt-in benchmark through the lease. Save actual output here before making a production batching decision.

## Hosted collection

The initial dedicated workflow did not produce a measurement job on draft PR #1778. GitHub run `41253206092` at `eee1f9c21a20369496fc9c4362bdb44ebb359190` ended as a failed `push` event with no jobs. No PR-triggered capture or usable artifact exists from that attempt. The dedicated workflow has been removed.

The registered `.github/workflows/ci.yml` now accepts boolean dispatch input `capture_mcp_catalog_benchmark`, which defaults to false. Its existing `format` job collects measurements only when a manual dispatch explicitly enables the input. Automatic PR/push runs and ordinary manual dispatch keep their existing behavior. The workflow uses its existing checkout, permissions, and setup-workspace action. It verifies the checked-out commit against the immutable dispatched `GITHUB_SHA` before measuring.

After the reviewed commit is pushed to the draft PR branch, run:

```sh
gh workflow run ci.yml --ref issue-1450-mcp-metadata-batching -f capture_mcp_catalog_benchmark=true
```

The capture step runs focused correctness tests and five sequential fresh benchmark processes on the same hosted Ubuntu runner, with a 20-minute step timeout. The existing hosted setup action provisions the pinned SDK and bootstraps the fresh hosted checkout. It does not authorize bootstrap or SDK installation in the current local environment. Manual dispatch still schedules its normal broad CI jobs; no routing, required check, or existing format/import check has changed.

The artifact records the dispatched ref, checked-out revision, workflow SHA, event, run ID/attempt, runner OS/architecture, `uname`, and `flutter --version --machine`. Process labels are `baseline-1` through `baseline-5`. Each benchmark process sets the opt-in flag and runs only `mcp_catalog_refresh_benchmark_test.dart` with `--no-pub --reporter=expanded`.

Complete logs are `baseline-1.log` through `baseline-5.log`, with unmodified workload JSON records in corresponding `.jsonl` files and separate exit-status files. A valid artifact contains 18 records per process and 90 total records, including all 630 raw samples. Capture preserves partial output if an invocation fails, and extraction saves an explicit validity result and errors in `validation.json`. A correctness failure or incomplete process invalidates the baseline.

Capture, extraction, and upload are optional steps with `continue-on-error: true`. Upload uses `if-no-files-found: warn`, runs even after capture or format-check failures, and retains evidence for seven days as `mcp-catalog-baseline-<run-id>-<attempt>`. Optional setup errors, missing files, or upload-service failures cannot fail the existing required format check. A passing format check does not establish measurement validity. A missing/incomplete artifact or failed upload leaves the benchmark invalid. The artifact cannot certify its own upload success, so `validation.json` explicitly requires checking upload status against the workflow run.

No timing threshold determines CI success. Production batching remains excluded pending actual measurements. After the reviewed dispatch runs, download its artifact, verify upload success, source revision and all process statuses, validate all records and samples, then record the five baseline distributions here before deciding whether to evaluate a batching candidate.
