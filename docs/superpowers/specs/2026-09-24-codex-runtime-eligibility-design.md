# Codex Runtime Model Eligibility — Design Spec

## Intent

Keep Codex OAuth model availability capability-based and consistent between `auravibes_engine` and the app. Generic OpenAI API-key users must continue to see the complete OpenAI catalog. When a saved Codex selection is no longer eligible, the app must identify it as unavailable, let the user choose another model, and explain recovery if continuation is attempted.

## Eligibility contract

A model is eligible for the Codex runtime exactly when all are true:

```text
supportsPriorityMode
&& inputModalities contains "text"
&& outputModalities contains "text"
&& limitOutput > 0
```

Neither model ID/name (including Spark naming), canonical status, nor tool-call support affects eligibility. App and engine results must match for the same catalog capability fixtures. Existing predicates appear aligned; the implementation should preserve them and add contract coverage rather than introduce a new abstraction.

## Catalog and selection boundaries

- Keep the general OpenAI catalog unfiltered. Restrict only Codex OAuth's persisted `modelIds` and Codex-specific workspace projections.
- Continue excluding unsupported Codex selections from the selectable workspace-model list. Resolve an ineligible persisted selection by ID as unavailable rather than returning the stale selection as usable.
- When a selected ID is absent from current selector options, show the existing localized “Model unavailable” state. The existing model selector sheet is the recovery action and must still offer eligible replacement models.
- Reject continuation of an ineligible Codex selection with the existing `SelectedModelNotFoundException` path. The chat screen already maps that exception to localized guidance to select another model.
- Preserve projected modalities and tool-call capability for eligible selections; do not modify persistence schema, OAuth flow, dependencies, or generated files.

## Acceptance mapping

| Issue | Acceptance |
| --- | --- |
| #894 | Fixture coverage includes priority, non-priority, and Spark-named entries. General OpenAI catalog returns all fixture entries; Codex OAuth saves only capability-eligible IDs. |
| #895 | Unsupported persisted Codex selections are unavailable in workspace resolution and the compact selector, can be replaced through the existing model sheet, and continuation errors use selected-model recovery guidance. |
| #896 | Engine/app table-driven coverage agrees for priority mode, input/output modalities, output limit, canonical aliases, and tool support; no ID-based or Spark-specific rule exists. |

## Alternatives considered

- **Model-ID allowlist or Spark exclusions:** rejected; brittle and contradicts the capability contract.
- **Filter the shared OpenAI catalog:** rejected; would hide models from API-key connections and couple unrelated consumers to Codex.
- **Duplicate/rewrite the eligibility predicate behind a new shared abstraction:** rejected; existing engine and app predicates match. A cross-layer parity test is the smaller guard against drift.

## Self-review

Scope stays within the existing engine capability contract, app catalog/selection flow, compact selector, and continuation error path. No behavior is added for unrelated providers. Failure coverage must distinguish non-priority, missing text input/output, zero output limit, Spark-named eligible models, and canonical/tool-call variants. Reuse existing localized messages and selector sheet; no localization or generated-file changes are required.
