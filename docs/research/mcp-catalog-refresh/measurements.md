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

The existing `ci.yml` supports manual dispatch but has no input to enable this opt-in benchmark. Its normal test invocation skips measurements. Reusing that dispatch would therefore run broad CI without collecting a baseline.

`.github/workflows/mcp-catalog-benchmark.yml` runs on `pull_request` events for `opened`, `synchronize`, and `reopened`, restricted to this benchmark, fixture, correctness tests, and the workflow file. Unlike manual dispatch of a newly added workflow, this trigger can execute the workflow added by an unmerged PR. It checks out the immutable `github.event.pull_request.head.sha`, with credentials persistence disabled, and records both that SHA and `git rev-parse HEAD` in the artifact. It uses neither `pull_request_target` nor repository secrets.

The workflow runs focused correctness tests and five sequential fresh benchmark processes on the same hosted Ubuntu runner. It reuses the repository's pinned checkout and artifact actions and its existing setup-workspace action. That action provisions the pinned SDK and bootstraps a fresh hosted checkout. It does not authorize bootstrap or SDK installation in the current local environment.

The workflow has read-only contents permission, a 20-minute timeout, no timing gates, no modification to existing CI, and no change to required checks. It is an independent optional workflow, outside the existing CI summary job's dependencies. It records process labels `baseline-1` through `baseline-5`, workflow run ID/attempt, and `flutter --version --machine`. Each benchmark process sets the opt-in flag and runs only `mcp_catalog_refresh_benchmark_test.dart` with `--no-pub --reporter=expanded`.

It captures complete logs in `baseline-1.log` through `baseline-5.log` and extracts unmodified workload JSON records into corresponding `.jsonl` files. A valid artifact contains 18 records per process and 90 total records, including every raw sample. The workflow preserves partial output and process exit codes if an invocation fails, and never marks a failed run as valid measurement evidence. It uploads logs, raw JSON, environment metadata, correctness output, process statuses, and `validation.json` with `if: always()` and seven-day retention. Correctness failures remain failures; elapsed times and speedup ratios do not determine success.

The parent approved this workflow design. The implementation is awaiting independent review before draft PR publication. No hosted run has happened, and production batching remains excluded pending actual measurements. After a run, download its artifact, verify source revision and all five process statuses, validate all raw samples and workload counts, and record the baseline distributions here before deciding whether to evaluate a batching candidate.
