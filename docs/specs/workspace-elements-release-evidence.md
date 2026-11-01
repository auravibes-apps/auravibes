# Workspace elements release evidence

Review checkpoint: 2026-10-31, against main commit [`8b0d714`](https://github.com/auravibes-apps/auravibes/commit/8b0d7140a869730e1ea4e2cf850ef9448c8cd635).

This report consolidates evidence for #1692 after its #1691 dependency merged. It records current implementation bounds and synthetic measurements; it is not a production capacity commitment, a deployment record, legal advice, or a privacy/store compliance certification. No production data or provider was used in these measurements.

## Capacity measurements

All runs used synthetic data. Times below are observed results, not service objectives.

| Surface and environment | Workload | Observed results | Limits of the evidence |
| --- | --- | --- | --- |
| Local SQLite, in memory; Apple M1 Pro, 16 GiB, macOS 27.2, Flutter 3.47.8 / Dart 3.13.7; two runs | 100 columns, 1,000 records with one populated column, ten 100-record queries and one atomic 50-record update | Schema 285–380 ms; inserts 4.03–4.95 s; median query 1.69–1.98 ms; largest of ten query samples 6.47–9.26 ms; update 377–432 ms | One machine and small sample; not on-disk local performance, concurrency or a production recommendation. The largest of ten is not a reliable percentile estimate. |
| Authenticated Serverpod endpoint against isolated local PostgreSQL 17 | 20 text columns, 100 records in four batches of 25, and a 100-record page | Table create 204–238 ms; writes 8.27–8.35 s; raw page read 473–530 ms. A separate run of ten filtered 100-record queries had 691 ms median and 1,317 ms maximum. | Local test service, not deployed cloud. The filtered query cost is material; no concurrency or network/TLS load was measured. |
| Local asset store with temporary disk bytes and in-memory SQLite metadata | One exact 25 MiB upload and read | Upload 415 ms; read 18 ms; bytes matched; 25 MiB plus one byte rejected | Single local run. |
| In-process signed gateway handlers with LocalStack 3.8.1 and PostgreSQL 17 | One synthetic 25 MiB upload and read | Upload 360 ms; read 224 ms; bytes matched | Not authenticated Serverpod end to end, TLS, deployed R2, concurrent traffic, or production capacity. |

The opt-in harnesses are [local record capacity](../../apps/auravibes_app/test/features/workspaces/benchmarks/local_workspace_capacity_test.dart), [authenticated server capacity](../../apps/auravibes_server/test/integration/features/workspace_state/workspace_capacity_benchmark_test.dart), and [local asset capacity](../../apps/auravibes_app/test/features/workspaces/benchmarks/local_workspace_asset_capacity_test.dart). A separate LocalStack gateway run is recorded in the chronological [implementation progress log](workspace-elements-progress.md).

## Current enforceable bounds

These are existing engineering guards and reasonable candidate ceilings to keep until the product owner ratifies advertised limits. They are not demonstrated production capacities.

| Surface | Current code bound | Boundary evidence |
| --- | --- | --- |
| Columns in a table | 100 | Local and server validation reject column 101. See [app validation](../../apps/auravibes_app/lib/features/workspaces/models/workspace_column_validation.dart) and [server validation](../../apps/auravibes_server/lib/src/features/workspace_state/domain/workspace_table_validation.dart). |
| Records per query page | 100 | Local query and authenticated cloud endpoint reject page size 101. See [app query validation](../../apps/auravibes_app/lib/features/workspaces/usecases/query_workspace_records_usecase.dart) and [cloud query validation](../../apps/auravibes_server/lib/src/features/workspace_state/workspace_record_query.dart). |
| Operations in one record batch | 50 | Client and server reject batch size 51; the bulk editor also stops selection at 50. See [record change validation](../../apps/auravibes_app/lib/features/workspaces/models/workspace_record_change.dart). |
| Columns in an AI summary | 50 | The server validates summary column IDs before creating the summary. See [record query summary validation](../../apps/auravibes_server/lib/src/features/workspace_state/workspace_record_query.dart). |
| Workspace asset object | 25 MiB | Reuses the app's attachment byte ceiling; the local asset harness rejects 25 MiB plus one byte. See [asset input validation](../../apps/auravibes_app/lib/features/workspaces/models/workspace_asset_input.dart). |
| Cloud workspace resource JSON | 64 KiB | Server validation rejects oversized resource payloads. See [resource validation](../../apps/auravibes_server/lib/src/features/workspace_state/domain/workspace_resource_validation.dart). |

Boundary rejection is covered, but the user-facing explanation is uneven: the bulk editor and 25 MB attachment flow name their limits, while some table, query, and resource validation failures resolve to general invalid-input wording. Add cap-specific copy where users can trigger those limits before publishing them as supported product limits. No in-code bound should be increased based on these measurements alone.

## Behavior and privacy evidence

| Requirement | Evidence and current result |
| --- | --- |
| Local/cloud parity for record, asset, authorization and report behavior | Local persistence/use-case tests and authenticated Serverpod endpoint tests cover the implemented paths. The opt-in benchmarks above exercise representative local and local-server paths only. A test result does not show a deployed provider's latency or durability. |
| No persistent cloud offline content cache | This is an accepted implementation/specification constraint. Client byte requests set `Cache-Control: no-store`; signed GET requests request `response-cache-control=no-store`, with adapter tests for both. Those tests do not prove CORS behavior, response headers at deployed R2/CDN, service-worker behavior, or every device and intermediary cache. See the cache audit in the [progress log](workspace-elements-progress.md). |
| Scoped AI transfers | Workspace content is accessed through explicit authorized tool calls; View data is not automatically injected into AI context. Tests and the merged #1693 implementation cover selected local/cloud tool flows. This does not settle AI provider retention, training, subprocessors or onward processing. |
| Access isolation during erasure | Merged [PR #1749](https://github.com/auravibes-apps/auravibes/pull/1749) verifies a non-owner member can use synthetic workspace content before an owner requests erasure, then cannot read, write or execute commands while retained rows still exist and cleanup proceeds. This verifies application authorization, not provider deletion. |
| Recovery | Local file/credential cleanup queues persist after workspace removal and support retry. Cloud erasure exposes owner-scoped pending/failed/completed status and retry for retryable failures. Unknown registration provenance, legacy uploads without proof and unavailable replica provenance remain fail-closed blockers, not recoverable success. See [erasure behavior and limits](../concepts/workspace-elements-legal.md#current-erasure-behavior-in-this-implementation-slice). |
| Content review | The product owner confirmed that each workspace owner is accountable for reports, with current workspace admins as delegated reviewers. The local report screen and authenticated cloud report queue have behavior tests; there is no platform-wide moderation queue or staffed service implied. See [#1690 acceptance](https://github.com/auravibes-apps/auravibes/issues/1690#issuecomment-6415724769). |
| Deletion and retained identities | Cloud erasure revokes access immediately and queues workspace content/assets for cleanup. Shared-workspace actor IDs and invitation email addresses can remain after account deletion; no expiry or treatment policy is configured. Completed Connector actions, downloaded exports, backups and provider copies are outside what application deletion alone can recall. |

## Privacy, stores and owner decisions

The [legal requirements brief](../concepts/workspace-elements-legal.md) and [feature specification](workspace-elements.md) are planning inputs. No existing public privacy policy, app store declaration, vendor contract, or complete separate-consent flow was audited against the running implementation. The implementation/spec keeps required consent and provider authorization separate from allow-all edit approval, but that does not establish that each required notice and choice is implemented for launch.

The release decision record is:

- Cloudflare R2 was selected for the dedicated workspace asset bucket. That owner decision does not prove a production deployment, provider-level deletion, replica provenance, recovery from uncertain writes, or a safe cutover from legacy writers. Provider deletion remains fail-closed until those proofs and deployment prerequisites are complete.
- Launch countries, legal entity, minimum age/audience assessment, retention periods, payments, other hosting/AI/Connector providers and permitted scopes remain unresolved. Do not invent them or make public claims for them.
- Qualified counsel and applicable Apple, Google Play and Microsoft store review remain outstanding. Public notices, store declarations, provider terms, local/cloud location claims, retention and deletion explanations must match actual behavior before release.
- Separate consent must be implemented for any use that requires it; an edit approval mode is not that consent. Provider contracts and permissions must allow the proposed shared-workspace authorization, reads/edits, AI processing, retention and onward sharing.
- Numerical limits remain an owner decision. Treat the current bounds above as provisional hard stops until ratified; avoid claiming unbounded scale.
- Keep HTML/JS execution, bundled workflows, public publishing, automatic synchronization, and other excluded features disabled.

## Validation record

The benchmark and focused behavior tests named above were run during the earlier implementation work and their results are preserved in the progress log. This evidence-document change has no Dart/runtime changes; no fresh pinned-FVM or Flutter test command was run for it. The GitHub checks for the documentation PR should provide the current repository-level validation record. No production deployment, live provider write, or legal/store review was performed.
