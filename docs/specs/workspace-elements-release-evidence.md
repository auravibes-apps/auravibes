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
| Columns in a table | 100 | The opt-in local harness and hosted authenticated cloud tests accept 100 and reject 101. See [app validation](../../apps/auravibes_app/lib/features/workspaces/models/workspace_column_validation.dart), [server resource validation](../../apps/auravibes_server/lib/src/features/workspace_state/domain/workspace_resource_validation.dart), and the [cloud boundary test](../../apps/auravibes_server/test/integration/features/workspace_state/workspace_capacity_benchmark_test.dart). |
| Records per query page | 100 | Local query and hosted authenticated cloud endpoint tests accept 100 and reject 101. See [app query validation](../../apps/auravibes_app/lib/features/workspaces/usecases/query_workspace_records_usecase.dart) and [cloud query validation](../../apps/auravibes_server/lib/src/features/workspace_state/workspace_record_query.dart). |
| Operations in one record batch | 50 | Client and hosted server tests accept a batch of 50 and reject 51; the bulk editor also stops selection at 50. See [record change validation](../../apps/auravibes_app/lib/features/workspaces/models/workspace_record_change.dart) and the [cloud boundary test](../../apps/auravibes_server/test/integration/features/workspace_state/workspace_capacity_benchmark_test.dart). |
| Columns in an AI summary | 50 | Hosted authenticated cloud tests accept 50 summary columns and reject 51. See [record query summary validation](../../apps/auravibes_server/lib/src/features/workspace_state/workspace_record_query.dart) and the [cloud boundary test](../../apps/auravibes_server/test/integration/features/workspace_state/workspace_capacity_benchmark_test.dart). |
| Workspace asset object | 25 MiB | Reuses the app's attachment byte ceiling; the local asset harness rejects 25 MiB plus one byte. See [asset input validation](../../apps/auravibes_app/lib/features/workspaces/models/workspace_asset_input.dart). |
| Cloud workspace resource JSON | 64 KiB | The direct [UTF-8 boundary test](../../apps/auravibes_server/test/features/workspace_state/workspace_resource_validation_test.dart) accepts 65,536 bytes and rejects 65,537 bytes; it passed in hosted CI. See [resource validation](../../apps/auravibes_server/lib/src/features/workspace_state/domain/workspace_resource_validation.dart). |

Hosted CI for #1783 head `03aa98d` passed the authenticated boundary tests for table columns 100/101, query pages 100/101, record batches 50/51, summary columns 50/51, and the UTF-8 resource JSON boundary, alongside app tests, Serverpod generation/integration, code health, and platform build. The opt-in capacity benchmark remains separate from these regular boundary tests. The client now maps typed table limits to dedicated copy and the workspace File flow names its existing 25 MiB ceiling; this does not change any bound or make it a production capacity promise. Server resource-limit responses still map to generic visible copy pending approval of copy for that path. The 64 KiB resource-write path uses a source-level `WorkspaceResourceSizeLimitException`; the server preserves the legacy `validationFailed` wire code and adds optional `resourceLimitKind: "resourceSizeLimitExceeded"` metadata, which current clients recognize and older clients can ignore. Hosted generation and integration passed on #1783 head `03aa98d`. Local validation remains blocked by the lease; no local tests or formatter have run. No in-code bound should be increased based on these measurements alone.

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

The opt-in benchmark results named above were run during earlier implementation work and are preserved in the progress log. Hosted CI on #1783 head `03aa98d` passed the boundary tests listed above, all three app test shards, Serverpod integration, generation/drift checks, analysis, code health, Linux build, and coverage/Sonar; Harness Verification, Lint PR, CodeQL, and SonarCloud Code Analysis also passed. The current follow-up adds localized client copy for typed table limits and workspace File size errors; hosted validation for that follow-up is pending. Local leased checks remain blocked. No production deployment, live provider write, or legal/store review was performed.

## Server/client protocol compatibility

The repository has a separate app release workflow and no checked-in coordinated server deployment workflow, so server-first rollout cannot be ruled out. To preserve compatibility with already-installed generated clients, the size-limit response keeps the existing `CloudWorkspaceErrorCode.validationFailed` wire value and adds optional `resourceLimitKind: "resourceSizeLimitExceeded"` metadata. Older generated clients read the known error code and ignore unknown JSON fields; the current app reads the additive field to retain a typed error code while using the existing generic validation copy. Do not replace the legacy wire enum value unless a client/server capability negotiation is introduced or the server deployment process guarantees the compatible client is already available.

Hosted CI regenerated the server/client protocol model from the source schema on #1783 head `03aa98d`; generation/drift checks and server integration passed. Local validation remains blocked by the lease; no local tests or formatter have run.
