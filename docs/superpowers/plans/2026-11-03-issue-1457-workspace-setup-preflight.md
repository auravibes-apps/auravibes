# Workspace Setup Preflight Implementation Plan

> **For agentic workers:** Use the approved plan task by task. Work only in the dedicated issue worktree. Do not bypass the repository validation lease; hosted CI is the validation path while the local pinned SDK lease is blocked.

**Goal:** Give a user an explicit, workspace-scoped view of whether saved setup appears ready, needs attention, or cannot be verified, with clear recovery routes and a privacy-safe support summary.

**Spec:** [Issue #1457](https://github.com/auravibes-apps/auravibes/issues/1457). Related context: [#1280](https://github.com/auravibes-apps/auravibes/issues/1280) (privacy-safe activity diagnostics) and [#1432](https://github.com/auravibes-apps/auravibes/issues/1432) (MCP connection diagnostic phases).

**Baseline:** `23e8c5c31d9d15e9acf7799a364ae77a4014faf5` (`origin/main`).

## Alignment with the issue

- Summarize provider-credential presence, selected-model capability metadata, current workspace-storage availability, and configured MCP status.
- Distinguish `pass`, `warning`, `fail`, and `unknown`; missing optional configuration is not presented as a storage or connection failure.
- Use cached/local app-owned configuration and last-known results by default. The initial render does not issue a cloud read, probe a model provider or MCP endpoint, refresh credentials, send conversation content, or mutate configuration. A separately labeled, user-triggered refresh may read only saved workspace configuration from the workspace service; it never probes a configured provider/MCP endpoint. If data is unavailable or stale, say that it is unverified and direct the user to the existing detail screen, where any service live check remains an explicit action.
- Keep every read keyed to the active `workspaceId`. A cloud configuration read may use the existing workspace store, but no prompt, transcript, attachment, tool argument/result, credential value, service URL, or raw exception is sent to any configured provider or copied into the report.
- Leave workspace data, secrets, database schema, and model/provider configuration unchanged.

## Architecture

The workspace feature owns the cross-cutting, workspace-scoped readiness summary. Keep source data in the existing owners: model connections and model selections in `features/models`, MCP/service connection state in `features/service_connections`, and workspace identity/storage mode in `features/workspaces`. A workspace-scoped provider gathers local/cached snapshots; a pure use case maps those snapshots into small presentation-neutral checks. The screen renders localized results and invokes only existing navigation or an explicit saved-configuration refresh. Do not watch eager cloud providers from initial `build()` if they perform network reads; cloud-only fields begin as unknown until the user requests that refresh.

Do not call `WorkspaceAvailability` merely to label storage: its cloud-account health path performs a live account request. Use the already-resolved workspace/session and saved app metadata. If cloud reachability is not known from saved state, report `unknown` rather than probe it. Do not call `TestMcpConnectionUsecase` or model-provider verification from the preflight.

### User flow brief

- **User goal:** Quickly see whether the selected workspace has enough saved setup to begin work, and know where to fix a missing prerequisite.
- **Entry:** Add a `Setup preflight` action in the active workspace settings screen. It opens a typed workspace route carrying the same `workspaceId`.
- **View:** A short summary followed by four ordered check cards: workspace storage, provider credentials, selected model, and MCP connections. State, freshness, and next action remain visible together. Clearly label results as based on saved configuration, not a live service test.
- **Actions:** Link to the existing workspace/model/service-connection destinations. Local retry reloads local/cached app metadata only. A separate cloud-configuration refresh can be started explicitly; it reads saved app configuration only and never tests provider/MCP connectivity. After changes, the user can return and refresh.
- **Back/close:** Normal workspace route Back returns to the originating settings page. The new route must preserve workspace scope and obey the existing shell/router behavior.
- **Composition:** The main result and any blocking issue lead. Supporting check cards follow in a flat list with house components, readable status text, and one recovery action per relevant check. No dashboard charts, raw diagnostics, or configuration form are added.
- **States:** Loading; successful summary; partial data with unknown checks; unavailable workspace metadata with retry; no providers configured; no selected model; no MCP servers configured; credential missing; stale/failed saved MCP test; and copy success/failure. An empty optional MCP configuration is reported as “not configured,” not failed.
- **Realistic scenario:** A user opens workspace settings, sees that a provider credential is missing and the selected model has no current capability record, then opens the existing provider/model screen to correct it. The screen never claims a network connection was tested.

## Global constraints

- Read only the current workspace's metadata. Provider/read model queries, MCP records, workspace session, retry state, and tests must all carry `workspaceId`; test with a second workspace containing sentinel values and prove they do not appear.
- Inspect only presence/status/capability fields. Never read, stringify, log, or copy API keys, OAuth tokens, encrypted credential blobs, endpoint URLs, auth headers, raw provider exceptions, prompts, transcripts, attachments, tool arguments, or tool output.
- Build the copyable summary from a strict allowlist of check identifiers, localized status labels, app version, and report timestamp. Do not serialize source entities or database records. Do not include workspace ID/name unless a later privacy-reviewed requirement demands it.
- Do not call external model APIs, MCP tests, account health probes, or any agent/runtime/dispatch path. Opening the screen and local retry use only local/cached data; any cloud workspace configuration read requires the explicit refresh action. “Unknown” is correct when saved metadata cannot establish a result. Existing detail screens remain the explicit path for live service checks.
- No schema or generated protocol changes. Do not hand-edit generated Riverpod/router/localization files.
- Follow feature ownership: UI renders state; provider wires dependencies; use case owns status mapping and safe summary formatting. Reuse existing connection/model projections rather than duplicating secret handling.
- Local FVM/lease checks are currently blocked by the `.fvm/flutter_sdk` mismatch. Do not change SDK links/configuration, delete caches, bootstrap, or bypass the lease. Rely on hosted CI and report local validation as blocked until the lease is available.
- Because this changes UI, include same-fixture before/after screenshots in the PR. Use the repository’s deterministic UX route fixture and its PNG plus JSON sidecar, with matching viewport, theme, locale, and source fingerprints. Capture the existing workspace-settings state before and the resulting preflight flow after. Do not claim visual verification if the capture path cannot run; document the exact missing capture instead.

## Data and status contract

| Check | Safe source | Pass | Warning / fail | Unknown |
| --- | --- | --- | --- | --- |
| Workspace storage | Resolved local workspace record or cached account/session metadata | The workspace record and local storage mode resolve | A local record is missing/invalid; cached cloud metadata says sign-in is needed | A cloud workspace is configured but its saved metadata is not cached or reachability is not known |
| Provider credentials | `ModelConnectionEntity.hasKey` / auth mode and saved credential-presence metadata | The currently selected model's provider has a saved credential; if no model is selected, at least one configured provider has a saved credential | No provider configured is a non-blocking warning with “Add a provider”; a configured provider with no key is also a warning while unselected. A selected model whose provider is absent or has no saved credential is a failure with “Review provider” because that credential is required for the selected model | Credential state could not be read or its auth mode is unsupported |
| Selected model | Current new-chat selection plus matching `WorkspaceModelSelectionEntity` capability metadata | The selected model still exists and its saved provider/model capability metadata is available; show known input/output modalities, tool-call support, and reasoning support without inventing requirements | No model selected is an actionable, non-blocking warning with “Choose a model”; a selected ID no longer configured in this workspace is a failure with “Choose another model” | A selected model exists but capability metadata is missing/unavailable; do not infer capabilities |
| MCP connections | Workspace-scoped `ServiceConnectionListItem` and its saved `lastTestSummary` | No MCP connection is configured (optional), or the last saved test succeeded | A connection is disabled, needs reauthorization, or its saved last test failed | A configured connection has no test result or saved state is unavailable; do not test it automatically |

Result mapping is explicit. Per-check `fail` means an already selected/required model cannot be used because its workspace selection or saved provider credential is missing, or the current workspace record is invalid. Per-check `warning` means optional absence (no provider configured), a configured but unselected provider without credentials, or no model selected. Per-check `unknown` means a required source or selected-model capability metadata cannot be read; `pass` means saved state meets that check's stated condition. Missing optional MCP configuration is `pass` with neutral “not configured” copy. A configured disabled MCP server is a non-blocking warning; an enabled server with a saved failure/reauthorization result is a warning, and a connection with no saved test is unknown. MCP results do not block the overall workspace readiness result.

The overall roll-up is separate from per-check status: `ready` only when storage is available, a model is selected, that model still belongs to this workspace, its capability metadata is known, and its provider has a saved credential. `needsSetup` when no provider is configured or no model is selected, even though those are non-blocking warnings rather than failures; include the corresponding add-provider/choose-model recovery actions. If both are absent, show both actions and `needsSetup`, never “ready.” `blocked` when a selected model is stale, its required provider credential is missing, or the workspace record is invalid. `unverified` when a required storage/model/credential source or selected-model capability metadata is unknown. Optional MCP absence or MCP warnings do not change `ready` once model and storage prerequisites pass. Status labels explain that saved configuration is not equivalent to a live provider/MCP test. Copy text is localized, minimal, and contains no raw diagnostic data.

## Review focus

- No credential or conversation sentinel can escape into logs, UI details, or copied text; no external provider/MCP call occurs when opening, refreshing, or copying the report.
- A selected model's name/capabilities come only from a matching workspace-scoped saved selection; missing metadata remains unknown rather than receiving optimistic defaults.
- Workspace and service-connection reads cannot cross workspace boundaries, including remote workspace references.
- Cloud reachability is not mislabeled as ready when it was not checked; local workspace readiness is based only on a successful local workspace read.
- Optional unconfigured services do not block readiness. “Not configured,” “not tested,” and “failed” are distinct states.
- Retry re-reads app-owned metadata and preserves the selected workspace; it never starts a chat, changes settings, or tests a remote service.
- Route entry, Back, narrow layout, long localized labels, keyboard focus, and accessible status semantics remain coherent.

## Implementation tasks

### Task 1: Define the presentation-neutral check/result model and mapper

**Files:**
- Create `apps/auravibes_app/lib/features/workspaces/models/workspace_setup_preflight.dart`.
- Create `apps/auravibes_app/lib/features/workspaces/usecases/build_workspace_setup_preflight_usecase.dart`.
- Test `apps/auravibes_app/test/features/workspaces/usecases/build_workspace_setup_preflight_usecase_test.dart`.

**Behavior:** Define the four-state status enum, typed check IDs, a compact result object, and optional typed recovery destination. The use case accepts snapshots and an injected report timestamp; it maps saved provider credential presence, model metadata, workspace state, and saved MCP result without touching the database, context, or network. Keep display strings out of the use case. Add an allowlisted formatter that accepts localized labels and app version rather than arbitrary source objects.

**Tests:** Cover each status transition, unconfigured optional MCP, unselected model, missing model metadata, absent credential versus unavailable source, stale/failed saved MCP tests, deterministic report formatting, and omission of secret/URL/prompt/transcript/tool sentinel values. Add focused overall-roll-up cases: no provider plus no model returns `needsSetup` with both recovery actions (not `ready` and not `blocked`); configured provider with credential but no model returns `needsSetup` with choose-model action; a saved selected model/provider with known metadata and no optional MCP returns `ready`.

### Task 2: Add workspace-scoped data wiring

**Files:**
- Create `apps/auravibes_app/lib/features/workspaces/providers/workspace_setup_preflight_provider.dart`.
- Reuse `chatModelConnectionsProvider`, `listWorkspaceModelSelectionsProvider`, `serviceConnectionsProvider`, and the existing workspace session/workspace record providers where their values are already available.
- Test `apps/auravibes_app/test/features/workspaces/providers/workspace_setup_preflight_provider_test.dart`.

**Behavior:** Assemble only the selected workspace's local/cached safe projections and call the pure mapper. Initial load and retry do not watch providers that make eager network reads. A distinct explicit action can request the existing cloud workspace configuration read for cloud-only metadata; it does not verify provider or MCP connectivity. Use saved status/capability data; do not add provider-specific or MCP verification requests. If one source fails, retain other check results and mark that check unknown with a retry path. Do not convert raw exceptions into UI text or logs. The current draft model selection is read from the existing new-chat state when present; no implicit default selection is invented. With no selected model, return a warning and choose-model recovery action; missing capability metadata for an existing selection returns unknown.

**Tests:** Local and cloud workspace fixtures; two-workspace isolation with credential, URL, and provider-name sentinels; source failure yields partial/unknown results; opening/retry/copy never invokes cloud, live provider, or MCP adapters; explicit cloud configuration refresh invokes only the workspace configuration reader; model selection only matches within the requested workspace.

### Task 3: Add the route, settings entry, and localized screen

**Files:**
- Create `apps/auravibes_app/lib/features/workspaces/screens/workspace_setup_preflight_screen.dart`.
- Create feature widgets only if needed under `features/workspaces/widgets/`.
- Modify `apps/auravibes_app/lib/router/workspace_route.dart` and `features/settings/screens/workspace_settings_screen.dart`.
- Modify `apps/auravibes_app/assets/i18n/en.json` and `es.json`; generate the locale keys using the repository generator.
- Add focused screen/route tests under `apps/auravibes_app/test/features/workspaces/` and update the workspace-settings screen test.

**Behavior:** Add one entry in workspace settings and a typed route containing `workspaceId`. Render loading, partial data, unavailable, ready/attention, and copy feedback using house components. Show one recovery link per actionable status, preserve the current workspace in every destination, and provide a refresh that invalidates only this preflight/read sources. Every user-facing string is localized and accessible. Do not show raw status/error fields or create setup forms in this screen.

**Tests:** Verify the four cards and distinct states, local and cloud scope, retry, copy, navigation targets, Back, screen-reader labels, no accidental chat dispatch/config mutation, and English/Spanish layout with long labels.

### Task 4: Capture exact before/after UI evidence and prepare PR

**Files:** Add the requested screenshot evidence and sidecars under `docs/evidence/issue-1457/`; include both images in the PR description using links to those files.

**Exact production harness:** Extend `apps/auravibes_app/test/widgets/ux_validation_layout_test.dart` and its route matrix with `WorkspaceSetupPreflightRoute`. Use the existing `UxValidationFixture.create()` seeded local “Design studio” workspace for both images, with no provider, MCP server, cloud account, or remote request. Keep the fixture description identical for both captures. Capture the existing `WorkspaceSettingsRoute` (`$base/workspace-settings`) as the **before** view from the PR base SHA, and the new `WorkspaceSetupPreflightRoute` (`$base/setup-preflight`) as the **after** view from the PR head SHA. Run the exact production-harness tests `production direct route WorkspaceSettingsRoute duo_closed light` and `production direct route WorkspaceSetupPreflightRoute duo_closed light`. Both use the harness's 466×678 logical viewport, English locale, text scale 1, light theme, controlled fonts, and in-memory database. The harness emits PNGs and JSON sidecars containing route, fixture, renderer, viewport, locale, scale, theme, fonts, and `UX_SOURCE_FINGERPRINT`.

**Hosted capture procedure:** Add a temporary job to `.github/workflows/ci.yml` triggered by the PR, explicitly outside branch protection's required-check list. Read the exact `github.event.pull_request.base.sha` and `head.sha`; check out each in turn and run its named production-harness test with separate `UX_CAPTURE_DIR` values and `--dart-define=UX_SOURCE_FINGERPRINT=<that exact SHA>`. Upload the two PNG/JSON pairs as an Actions artifact. Download the artifact into `docs/evidence/issue-1457/`, rename the pair to stable before/after filenames, and validate that all four files exist, each PNG is non-empty and decodes, each JSON fingerprint matches its expected base/head SHA, and both sidecars agree on the identical fixture, viewport, locale, scale, theme, renderer, and fonts while naming the expected routes. Confirm the two PNGs are not byte-identical. Preserve the JSON sidecars with the images and embed the committed image paths in the PR description. Do not reuse the unrelated hard-coded `6137bbf...` baseline or treat it as evidence for this issue. If the current PR head advances after the workflow run, rerun capture for the latest base/head pair. Remove the temporary CI job and any temporary workflow changes from the PR branch after downloading the artifact; verify no CI-only change remains. Then re-read the PR head and run all final hosted CI checks on that cleaned exact head. Sidecars record the precise base/head app revisions used for the evidence even though the final PR SHA includes the evidence and cleanup commits.

**Verification:** Run the normal hosted Flutter CI and required repository gates on the exact PR head. Local test/analyzer commands remain blocked by the pinned SDK/validation lease and must not be run through a bypass. Re-read the PR head after checks, perform code review against `main`, address every actionable finding, and repeat until there are no findings.

## Acceptance checklist

- [ ] Workspace-scoped result covers provider credential presence, selected-model metadata, storage availability, and configured MCP status.
- [ ] Each check distinguishes pass, warning, fail, and unknown; no selected model and no configured provider are actionable warnings, a credential missing for a selected model is a failure, and unknown is reserved for unavailable data/capability metadata.
- [ ] The overall result remains `needsSetup` when no model is selected or no provider is configured, even though those optional absences are warnings; it becomes ready only when storage, selected-model metadata, and its saved provider credential are present.
- [ ] The screen is explicitly user-triggered and provides practical recovery destinations.
- [ ] No external provider/MCP connectivity check occurs automatically.
- [ ] Copy output is generated from an allowlist and excludes all secret and conversation sentinel data.
- [ ] Local/cloud and cross-workspace tests pass in hosted CI.
- [ ] UI has matching, deterministic before/after screenshots in the PR, or exact visual-verification blocker is reported.
- [ ] All hosted CI checks are green and code review has no actionable findings before merge consideration.
