# MCP catalog refresh measurements

Issue: https://github.com/auravibes-apps/auravibes/issues/1450

## Status

The hosted baseline capture is valid. Workflow run [41345333675](https://github.com/auravibes-apps/auravibes/actions/runs/41345333675) produced artifact `mcp-catalog-baseline-41345333675-1` for revision `8a90da5089cdc65a58bf6d6acf5facdd5e79a70c`. The artifact was uploaded successfully and is not expired. Its `validation.json` reports no errors; all five benchmark processes and the focused correctness run passed.

The capture contains 90 workload records (18 cases in each of five fresh processes) and 630 measured samples (seven samples per case). It ran on Linux x64 with Flutter 3.47.9 and Dart 3.13.7. The full raw logs, JSONL, environment, and validation files are retained in the artifact.

This is a baseline-only capture. Production metadata persistence remains unchanged, and no batching candidate has been measured. The baseline shows enough time in per-tool metadata executor calls to justify measuring a candidate, but it cannot establish that batching improves total refresh time. No batching decision is made until the candidate is compared against this baseline.

## Baseline results

For each case, `refresh median` is the median of the five process-level medians; the range shows the lowest and highest process-level median. `refresh p95` is the range of the five process-level p95 values, each calculated from seven measured samples. `executor median` is the median of the five per-process medians for time spent in metadata executor calls. Times are microseconds.

| Backend | Tools | Changed | Refresh median (run range) | Refresh p95 (run range) | Executor median | UPDATE dispatches/sample | Batch dispatches/sample |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| In-memory SQLite | 10 | 0 | 1,656 (1,587–1,820) | 1,829–2,520 | 0 | 0 | 0 |
| In-memory SQLite | 10 | 1 | 2,249 (2,095–2,309) | 2,997–3,239 | 107 | 1 | 0 |
| In-memory SQLite | 10 | 10 | 3,881 (3,690–4,383) | 4,272–5,313 | 915 | 10 | 0 |
| In-memory SQLite | 100 | 0 | 3,699 (3,534–3,762) | 4,015–6,585 | 0 | 0 | 0 |
| In-memory SQLite | 100 | 10 | 5,018 (4,901–5,205) | 6,057–7,177 | 704 | 10 | 0 |
| In-memory SQLite | 100 | 100 | 19,930 (19,510–20,463) | 22,376–23,230 | 6,136 | 100 | 0 |
| In-memory SQLite | 1,000 | 0 | 21,115 (20,076–21,935) | 26,950–28,518 | 0 | 0 | 0 |
| In-memory SQLite | 1,000 | 100 | 30,708 (29,886–32,241) | 31,202–34,063 | 4,745 | 100 | 0 |
| In-memory SQLite | 1,000 | 1,000 | 118,450 (110,125–119,665) | 125,530–137,061 | 41,028 | 1,000 | 0 |
| Background-file SQLite | 10 | 0 | 1,671 (1,643–1,858) | 1,738–1,987 | 0 | 0 | 0 |
| Background-file SQLite | 10 | 1 | 2,987 (2,962–3,092) | 3,114–3,600 | 342 | 1 | 0 |
| Background-file SQLite | 10 | 10 | 6,255 (6,184–6,826) | 6,478–8,650 | 2,777 | 10 | 0 |
| Background-file SQLite | 100 | 0 | 3,320 (3,219–3,401) | 3,484–4,007 | 0 | 0 | 0 |
| Background-file SQLite | 100 | 10 | 8,168 (7,816–8,645) | 8,609–9,372 | 2,788 | 10 | 0 |
| Background-file SQLite | 100 | 100 | 41,044 (40,223–42,734) | 41,194–49,615 | 26,915 | 100 | 0 |
| Background-file SQLite | 1,000 | 0 | 20,441 (19,256–20,606) | 21,061–21,456 | 0 | 0 | 0 |
| Background-file SQLite | 1,000 | 100 | 59,765 (56,659–60,777) | 60,455–68,012 | 29,259 | 100 | 0 |
| Background-file SQLite | 1,000 | 1,000 | 319,727 (307,516–344,821) | 336,932–363,542 | 226,385 | 1,000 | 0 |

At 100% changed metadata, metadata executor time accounts for about 31% of the in-memory 100-tool refresh median and 66% of the background-file median. At 1,000 tools, those figures are about 35% and 71%. These measurements make executor dispatch overhead a plausible bottleneck; they do not measure a batch speedup.

## Reproduction and evidence rule

The opt-in benchmark measures 10, 100, and 1,000 existing tools with 0%, 10%, and 100% changed metadata, using in-memory SQLite and SQLite through a background isolate with a temporary file. Database creation, seeding, input construction, and verification are outside the timed interval. Each case has one warm-up followed by seven measured samples; metadata versions alternate so each changed case writes on every measured sample.

The hosted collection was dispatched from the PR branch with:

```sh
gh workflow run ci.yml \
  --ref issue-1450-mcp-metadata-batching \
  -f capture_mcp_catalog_benchmark=true
```

Capture runs five fresh benchmark processes and a focused correctness test on the same hosted Ubuntu runner. The artifact includes source and workflow SHAs, event/run provenance, OS and architecture, Flutter version, process logs and exit statuses, raw JSONL, and validation output. The optional capture does not add timing gates to required CI.

Compare baseline and candidate raw distributions at 100 and 1,000 changed tools, especially for the background-file backend. Keep batching only if savings repeat beyond the observed run-to-run variation and total-refresh medians improve at both sizes, with no no-op regression distinguishable from variation. Record absolute savings and the distributions used. There is no arbitrary percentage cutoff. A batch still executes one SQL UPDATE per changed row, so report row writes separately from executor dispatches and do not infer speedup from fewer dispatches alone.

Correctness checks have no timing thresholds. They verify that unchanged tools are not written, changed metadata is stored, IDs and permissions/enablement remain intact, full-row equality holds for unchanged tools, and failures do not expose a partially updated catalog. Ordinary refresh tests also cover schema clearing, membership changes, transaction rollback, and observer snapshots.

## Historical local validation constraint

The initial local attempt was blocked before Flutter ran because the repository validation lease found 17.5 GiB available on the worktree filesystem and 3.0 GiB on `/tmp`, below its 20 GiB reserve. The check was not bypassed and no files were deleted. The hosted capture above subsequently ran the benchmark and focused correctness checks using the repository's pinned hosted setup.
