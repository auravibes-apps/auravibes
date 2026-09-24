# Model Catalog Sync Reliability

Date: 2026-09-24
Status: Implemented — verification pending
Issues: #941, #943, #944

## Problem

Startup sync currently swallows failures, so UI cannot report catalog freshness or failure. The use case forwards any parsed snapshot—including empty provider/model collections—to the repository. `ApiModelRepository.replaceAllData` already upserts and prunes inside one Drift transaction, but rollback after pruning is not directly tested.

## Decisions

### Catalog validation (#941)

- Reject snapshots with no providers or no models across all providers **before** calling `replaceAllData`; rejected snapshots make no database writes.
- Permit individual providers with no models when another provider has models. `models.dev` may include such providers.
- Do not impose a minimum model count or percentage floor. A smaller non-empty snapshot may be a legitimate upstream removal and must still prune stale rows (#944).
- The upstream schema exposes no completeness marker. A truncated response that still contains models is indistinguishable from a legitimate smaller full snapshot; stronger detection needs an upstream version/checksum/completeness signal.

### Sync state and retry (#943)

- Keep app-lifetime sync state in a keep-alive Riverpod notifier: syncing, last attempt time, last successful time, and current failure.
- Automatic sync gets at most three total attempts, with 250 ms and 500 ms backoff. Retry only Dio connection/timeouts and HTTP 429/5xx. Do not retry invalid catalog data, parsing errors, or local write failures.
- Manual sync makes one attempt and reports its outcome. Existing localized sync icon remains manual retry action.
- Coalesce concurrent callers across the full automatic retry sequence.
- Show localized success/failure status and locale-aware timestamps in service connections screen; show syncing through the existing button spinner. Timestamps remain in memory for current app process; durable history would need separate persistence scope.

### Transaction safety (#944)

- Keep repository implementation/schema unchanged. `replaceAllData` already wraps upserts and stale-model/provider pruning in one database transaction.
- Add a real in-memory Drift test that fails provider deletion after stale-model deletion, then verifies original rows remain and incoming rows were rolled back.

## Acceptance map

| Issue | Acceptance | Evidence |
|---|---|---|
| #941 | Empty-provider and provider-only/no-model snapshots fail before repository write; valid snapshots sync; an empty individual provider is allowed when aggregate models exist. | Use-case unit tests verify exception/no `replaceAllData` and valid forwarding. |
| #943 | Automatic transient retry is bounded; permanent/validation/write failures do not retry; manual retry is one attempt; UI exposes attempt/success/failure and remains manually retryable. | Notifier tests cover status, retry classification, bounds, and coalescing; screen test covers localized status and retry control. |
| #944 | A failure during stale pruning leaves original provider/model catalog intact. | In-memory repository test injects delete failure after model pruning and verifies transaction rollback. |

## Self-review and boundaries

- Empty data is rejected without blocking legitimate non-empty catalog shrink; this avoids turning a temporary count heuristic into permanent stale rows.
- Status is process-local; no schema/dependency change or cross-restart history in this scope.
- No code in #894–#896 is included; peer confirmed paths disjoint. No additional issue is needed because existing related issues cover adjacent behavior.
