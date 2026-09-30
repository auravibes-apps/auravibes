# MCP Catalog and Service Connections Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete Group 31 in one PR: cloud-curated MCP catalog installs, safe connection recovery/editing, result-schema validation, deterministic discovery coverage, and atomic credential-definition safety with legacy repair.

**Architecture:** Serverpod owns the shared catalog definitions and exposes authenticated read access. The app copies a selected listing/option into workspace-owned local or cloud MCP state and stores submitted values in the existing secure credential paths. Connection diagnostics and credential mutations stay behind app usecases/repositories and the existing workspace state boundary; MCP output-schema checks stay provider-neutral in `auravibes_engine`.

**Tech Stack:** Dart 3.13.4, Flutter 3.47.5, Melos 8.7, Serverpod 4.0.3, Drift 2.35, Riverpod 3.4.3, `mcp_client` 2.2.1.

**Spec:** `docs/superpowers/specs/2026-09-29-mcp-catalog-service-connections-design.md`

## Global Constraints

- Shared catalog rows contain metadata and field definitions only; submitted values stay in the active workspace's secure credential storage.
- Local and cloud workspace installs copy selected catalog metadata and remain independent of later catalog edits/removal.
- MCP self-tests connect, initialize, list, and disconnect; they never invoke a tool or synchronize permissions.
- Persisted self-test summaries contain only normalized status/category, attempt time, transport, discovered-tool count, and elapsed duration.
- Self-test summaries exclude endpoint URLs, raw error payloads, credentials, authorization headers, schemas, tool metadata, arguments/results, and conversation content.
- Configuration edits clear prior summaries. Endpoint or authentication identity changes reset affected tool permission to `alwaysAsk`.
- Output schemas are optional. Validate structured results only when a schema exists; invalid content never reaches model context as successful output.
- MCP result model-context and persistence limits are 16 KiB and 256 KiB, measured independently in UTF-8 bytes.
- Local and cloud credential-definition updates/deletes are atomic against credential creation; preserve safe edits and metadata-only legacy records.
- User-facing text has matching English and Spanish localization keys. Do not hand-edit generated Serverpod, Drift, Freezed, Riverpod, route, or localization output.
- Use pinned FVM commands and the existing no-new-dependency setup.

## Review Focus

- **Catalog option field missing, optional, or secret:** form validates the configured requirement, keeps secret inputs blank, and writes values only to the active workspace. Cover in Task 2 catalog option form and workspace isolation tests.
- **Installed catalog entry edited or removed upstream:** workspace connection retains its copied listing/option data and remains editable. Cover in Task 2 local and cloud snapshot tests.
- **Endpoint/auth identity changes or unrelated edits:** unrelated edits preserve secrets and permissions; identity changes clear the summary and reset tool permissions to `alwaysAsk`. Cover in Task 3 edit tests.
- **Invalid structured output, nested mismatch, or absent schema:** declared schema mismatch fails with stable tool/path diagnostics and is not projected; absent schema remains unchanged. Cover in Task 4 engine/local/cloud tests.
- **Concurrent credential creation and schema update/deletion:** exactly one incompatible operation commits; legacy metadata-only rows remain protected and repairable. Cover in Task 5 local/cloud race tests and repair flow tests.
- **Repeated/invalid discovery cursor, catalog refresh, oversized UTF-8 result:** discovery stays deterministic; model and persistence byte ceilings are asserted independently. Cover in Task 4 fixture tests.

---

### Task 1: Cloud-managed MCP catalog read API (#1231)

**Files:**
- Create: `apps/auravibes_server/lib/src/features/mcp_catalog/mcp_catalog_endpoint.dart`
- Create: `apps/auravibes_server/lib/src/features/mcp_catalog/mcp_catalog_use_cases.dart`
- Create: `apps/auravibes_server/lib/src/features/mcp_catalog/mcp_catalog_repository.dart`
- Create: `apps/auravibes_server/lib/src/features/mcp_catalog/models/mcp_catalog_entry.spy.yaml`
- Create: `apps/auravibes_server/lib/src/features/mcp_catalog/models/mcp_catalog_listing.spy.yaml`
- Create: `apps/auravibes_server/lib/src/features/mcp_catalog/models/mcp_catalog_connection_option.spy.yaml`
- Create: `apps/auravibes_server/lib/src/features/mcp_catalog/models/mcp_catalog_credential_field.spy.yaml`
- Test: `apps/auravibes_server/test/features/mcp_catalog/mcp_catalog_use_cases_test.dart`
- Test: `apps/auravibes_server/test/integration/features/mcp_catalog/mcp_catalog_endpoint_test.dart`
- Generated: Serverpod protocol and migration output from declared source models only.

**Interfaces:**
- Produces `McpCatalogEndpoint.list(Session) -> Future<List<McpCatalogListing>>` for authenticated app clients.
- Each listing returns ID, display metadata, URL, transport, and zero or more options. Each option returns auth type and field definitions (`key`, `isSecret`, `isRequired`, optional label/description/help link).
- Catalog storage has no field for submitted values or workspace credentials.

- [ ] **Step 1: Write failing repository/usecase tests** for enabled listings, disabled listing exclusion, option/field mapping, invalid stored definitions, and database changes visible on the next read.
- [ ] **Step 2: Run focused server tests** with `fvm dart test test/features/mcp_catalog/mcp_catalog_use_cases_test.dart` from `apps/auravibes_server`; confirm expected missing feature failures.
- [ ] **Step 3: Implement catalog record, repository, authenticated endpoint, DTO validation, and Serverpod source models.** Keep catalog data read-only through the API; no admin endpoint or secret value field.
- [ ] **Step 4: Generate Serverpod code/migration** with `serverpod generate` and `serverpod create-migration --force` from `apps/auravibes_server`; inspect generated changes.
- [ ] **Step 5: Add endpoint integration tests** proving unauthenticated access is rejected and response JSON contains definitions but no submitted credentials.
- [ ] **Step 6: Re-run focused server tests** and record command/output.
- [ ] **Step 7: Commit** as `feat(mcp-catalog): serve cloud-managed listings`.

**Expected:** Focused unit and integration tests pass; catalog changes are returned after the next read without an app release; endpoint response contains no user/workspace values.

### Task 2: Workspace catalog browsing and install snapshots (#87, #1232–#1234)

**Files:**
- Modify: `apps/auravibes_app/lib/features/service_connections/screens/service_connections_screen.dart`
- Create: `apps/auravibes_app/lib/features/service_connections/models/mcp_catalog_installation.dart`
- Create: `apps/auravibes_app/lib/features/service_connections/providers/mcp_catalog_provider.dart`
- Create: `apps/auravibes_app/lib/features/service_connections/usecases/install_mcp_catalog_entry_usecase.dart`
- Modify: `apps/auravibes_app/lib/features/service_connections/providers/service_connection_operations_provider.dart`
- Modify: `apps/auravibes_app/lib/features/tools/providers/mcp_form_state.dart`
- Modify: `apps/auravibes_app/lib/features/tools/widgets/add_mcp_modal.dart`
- Modify: `apps/auravibes_app/lib/features/tools/data/cloud_tools_repository.dart`
- Modify: `apps/auravibes_app/lib/features/tools/services/cloud_mcp_gateway.dart`
- Modify: `apps/auravibes_app/lib/notifiers/mcp_connection_status.dart`
- Modify: `apps/auravibes_app/lib/domain/entities/mcp_transport_type.dart` and local/cloud MCP persistence adapters as required for a copied catalog snapshot and configured auth values.
- Modify: `apps/auravibes_app/assets/i18n/en.json`, `apps/auravibes_app/assets/i18n/es.json`; generate `locale_keys.dart`.
- Test: `apps/auravibes_app/test/features/service_connections/screens/service_connections_screen_test.dart`
- Test: `apps/auravibes_app/test/features/service_connections/usecases/`
- Test: `apps/auravibes_app/test/features/tools/widgets/add_mcp_modal_test.dart`
- Test: `apps/auravibes_app/test/notifiers/mcp_connection_notifier_test.dart`
- Test: `apps/auravibes_app/test/notifiers/mcp_connection_notifier_cloud_test.dart`
- Test: `apps/auravibes_app/test/data/repositories/mcp_servers_repository_impl_test.dart`

**Interfaces:**
- Consumes Task 1's `McpCatalogEndpoint.list()` response.
- Produces a selected-option install request that includes the copied listing/option definitions, transport, workspace ID, and transient submitted fields; values are never sent back to the catalog endpoint.
- Local install uses existing encrypted service-connection persistence; cloud install uses workspace-owned encrypted secret storage. Both continue through existing verification, discovery, and permission selection.

- [ ] **Step 1: Write failing tests** for listing search by name/description, transport/auth filters, empty/no-match views, required and optional fields, secret input behavior, active-workspace scoping, and catalog snapshot independence for local and cloud workspaces.
- [ ] **Step 2: Run focused app tests** for the new catalog tests and existing service-connection/MCP form tests; confirm the new assertions fail before implementation.
- [ ] **Step 3: Implement authenticated catalog fetch and client-side search/filter** over returned cloud listings. Keep manual MCP creation available.
- [ ] **Step 4: Implement selected-option fields and local/cloud install mapping.** Keep all submitted values out of catalog models; copy listing and option definitions into workspace MCP configuration and reuse verification/discovery/permissions.
- [ ] **Step 5: Add or update English/Spanish strings** for catalog browse, field form, validation, empty/error states, and install result; run `fvm dart run melos run generate:localization`.
- [ ] **Step 6: Re-run focused app/widget/notifier/repository tests** for local and cloud paths and inspect generated localization/Freezed/Riverpod/Drift output.
- [ ] **Step 7: Commit** as `feat(mcp-catalog): install listings into workspaces`.

**Expected:** Catalog fields render from the selected cloud option; local and cloud installs use only active-workspace storage, retain a metadata snapshot after catalog change/removal, and proceed through existing verification/discovery/permission flow.

### Task 3: MCP settings, durable self-test summaries, and recovery (#1116, #1166–#1168)

**Files:**
- Modify: `apps/auravibes_app/lib/features/service_connections/usecases/test_mcp_connection_usecase.dart`
- Modify: `apps/auravibes_app/lib/features/service_connections/models/mcp_connection_test_result.dart`
- Modify: `apps/auravibes_app/lib/features/service_connections/screens/service_connections_screen.dart`
- Modify: `apps/auravibes_app/lib/features/service_connections/screens/service_connection_edit_screen.dart`
- Modify: local MCP table/DAO/repository under `apps/auravibes_app/lib/data/database/drift/` and `apps/auravibes_app/lib/data/repositories/`; add the required `AppDatabase` schema migration.
- Modify: `apps/auravibes_app/lib/features/tools/data/cloud_tools_repository.dart` and `apps/auravibes_app/lib/features/tools/services/cloud_mcp_gateway.dart` for cloud MCP update/summary persistence.
- Modify: `apps/auravibes_app/lib/features/tools/` permission reset path for endpoint/auth identity changes.
- Modify: English/Spanish localization sources and generated keys.
- Test: `apps/auravibes_app/test/features/service_connections/usecases/test_mcp_connection_usecase_test.dart`
- Test: `apps/auravibes_app/test/features/service_connections/screens/service_connections_screen_test.dart`
- Test: `apps/auravibes_app/test/features/service_connections/screens/service_connection_edit_screen_test.dart`
- Test: `apps/auravibes_app/test/features/tools/data/cloud_tools_repository_test.dart`
- Test: local MCP repository/DAO tests and `apps/auravibes_server/test/features/mcp_servers/` tests if protocol changes require server support.

**Interfaces:**
- Consumes the Task 2 workspace MCP snapshot for edit labels/field definitions; manual MCP connections keep their current editor path.
- Produces a safe `McpConnectionTestResult` with normalized status, timestamp, transport, tool count, duration, and transient error details. Only normalized status/timestamp/transport/tool count/duration persist.
- Saved configuration update preserves untouched secrets; endpoint/auth identity changes reset affected tool permissions to `alwaysAsk` and clear the summary.

- [ ] **Step 1: Write failing tests** for persisted summary across route/app reopen, populated and zero-tool discovery counts, elapsed duration, config-change invalidation, removal, secret preservation on unrelated edits, endpoint/auth permission reset, and each #1116 recovery category/fallback.
- [ ] **Step 2: Run focused usecase, repository, widget, and cloud tests**; confirm expected failures before code changes.
- [ ] **Step 3: Extend the self-test result** to retain discovery count and elapsed duration while proving no tool invocation or permission synchronization.
- [ ] **Step 4: Persist only safe normalized summaries** in local and cloud workspace MCP records; clear summary on config changes and removal.
- [ ] **Step 5: Add in-place MCP edit** for endpoint, transport, and auth. Secret values stay blank; untouched secrets remain stored. Identity changes reset affected tool permissions to `alwaysAsk`.
- [ ] **Step 6: Wire recovery actions**: auth → existing reconnect; network/timeout → user-initiated retry; protocol/configuration → connection settings; unknown → existing details only. Actions never invoke MCP tools.
- [ ] **Step 7: Generate Drift/Serverpod/localization outputs as needed**, run focused local/cloud tests, and inspect generated diff.
- [ ] **Step 8: Commit** as `feat(service-connections): persist MCP diagnostics and edits`.

**Expected:** Test summaries survive reopen without forbidden data; edits preserve untouched credentials, invalidate old summaries, and reset permissions only for endpoint/auth identity changes; recovery actions remain user-initiated.

### Task 4: Validate MCP structured results and exercise discovery paths (#1136, #1160)

**Files:**
- Create: `packages/auravibes_engine/lib/src/mcp_output_schema_validator.dart` (or a focused equivalent beside `tool_schema.dart`).
- Modify: `packages/auravibes_engine/lib/auravibes_engine.dart` only if the app/server boundary must call a supported public API.
- Modify: local result adapter in `apps/auravibes_app/lib/services/mcp_service/mcp_manager_client.dart`.
- Modify: cloud result adapter in `apps/auravibes_server/lib/src/features/conversations/engine/server_tool_executor.dart`.
- Create/modify: deterministic offline MCP fixture helpers in app/server test support.
- Test: `packages/auravibes_engine/test/mcp_output_schema_validator_test.dart`
- Test: `packages/auravibes_engine/test/mcp_test.dart`
- Test: `apps/auravibes_app/test/services/mcp_service/mcp_manager_client_test.dart` and the smallest local discovery integration test.
- Test: `apps/auravibes_server/test/features/mcp_servers/mcp_server_probe_test.dart` and the smallest cloud discovery integration test.
- Test: relevant output-policy/context/persistence tests for independent 16 KiB and 256 KiB UTF-8 byte limits.

**Interfaces:**
- Validator consumes `(toolName, outputSchema, structuredContent)` and either accepts the original structured value or throws a typed protocol failure with a deterministic schema path and no payload/schema echo.
- Both local and cloud result adapters call the same engine validation contract before `toModelText()` projection.
- MCP discovery retains existing shared catalog bounds and refreshes the existing connection's discovered tools after a `notifications/tools/list_changed` event.

- [ ] **Step 1: Write failing engine tests** for valid content, missing required field, wrong scalar type, unexpected field under `additionalProperties: false`, nested path, absent schema, and ordinary text result.
- [ ] **Step 2: Run** `fvm dart test test/mcp_output_schema_validator_test.dart` from `packages/auravibes_engine`; confirm invalid structured results currently pass or validator is absent.
- [ ] **Step 3: Implement provider-neutral output validation** using the existing `ToolSchema` parsing/traversal contract; keep error text limited to tool name and schema path.
- [ ] **Step 4: Add local/cloud adapter tests** proving invalid structured content does not reach model context as success and absent-schema behavior is unchanged.
- [ ] **Step 5: Add deterministic local/cloud MCP fixture coverage** for paginated `tools/list`, invalid/repeated cursors, duplicate names, bounds, and `notifications/tools/list_changed` add/remove/change refresh without server deletion/re-add.
- [ ] **Step 6: Assert bounds independently**: UTF-8 model projection ≤16 KiB and persisted response ≤256 KiB, with oversized and deeply nested metadata/result cases in supported local/cloud paths.
- [ ] **Step 7: Run focused engine/app/server checks**, inspect failures and generated output if any, then commit as `fix(mcp): validate structured results and cover discovery refresh`.

**Expected:** Declared output contracts reject mismatches before projection; no-schema and ordinary text paths remain unchanged; deterministic offline tests prove refresh/cursor/catalog behavior and both byte budgets.

### Task 5: Atomic credential-definition safety and missing-secret repair (#1172, #1173)

**Files:**
- Modify: `apps/auravibes_app/lib/features/skills/usecases/update_skill_credential_definition_usecase.dart`
- Modify: `apps/auravibes_app/lib/features/skills/usecases/delete_skill_credential_definition_usecase.dart`
- Modify: `apps/auravibes_app/lib/data/database/drift/daos/skill_credentials_dao.dart`
- Modify: `apps/auravibes_app/lib/data/database/drift/daos/skill_credential_definitions_dao.dart`
- Modify: `apps/auravibes_app/lib/data/repositories/skill_credentials_repository.dart`
- Modify: `apps/auravibes_app/lib/data/repositories/skill_credential_definitions_repository.dart`
- Modify: `apps/auravibes_app/lib/features/skills/services/cloud_skill_store.dart`
- Modify: `apps/auravibes_server/lib/src/features/workspace_state/usecases/workspace_state_usecases.dart` and endpoint/protocol source only as required for one cloud transaction shared with credential creation.
- Modify: `apps/auravibes_app/lib/features/service_connections/screens/service_connections_screen.dart` and `service_connection_edit_screen.dart` for incomplete credential state and repair.
- Modify: English/Spanish localization sources and generated keys.
- Test: `apps/auravibes_app/test/features/skills/usecases/credential_definition_safety_test.dart`
- Test: `apps/auravibes_app/test/features/skills/usecases/cloud_credential_definition_safety_test.dart`
- Test: `apps/auravibes_app/test/features/service_connections/screens/service_connection_edit_screen_test.dart`
- Test: `apps/auravibes_app/test/features/service_connections/screens/service_connections_screen_test.dart`
- Test: relevant `workspace_state` server unit/integration tests.

**Interfaces:**
- Local repository transaction combines linked-credential check with incompatible definition update/delete. The credential insert path shares the same database transaction serialization boundary.
- Cloud mutation validates linked credentials and updates/deletes the definition within one Serverpod transaction; credential creation uses the same serialization boundary.
- Credential edit state exposes only secret presence, never secret values. New values make the saved credential ready; cancel and failed save preserve the prior record.
- Extend the existing credential-management screen/editor from Tasks 2–3 for incomplete skill credentials; preserve the MCP connection editing flow added in Task 3.

- [ ] **Step 1: Write failing local race tests** that interleave credential creation with incompatible schema update and definition deletion; assert one operation conflicts and no dangling credential remains.
- [ ] **Step 2: Write failing cloud race tests** against the server mutation boundary for the same races; include metadata-only legacy credentials.
- [ ] **Step 3: Run focused local/cloud safety tests** and confirm the new race cases expose the current check-then-write gap.
- [ ] **Step 4: Move local count/check and mutation into one atomic repository/DAO operation**; preserve existing safe schema changes and conflict details.
- [ ] **Step 5: Add the cloud atomic mutation** shared with credential creation and return the existing typed conflict/concurrency error when another operation wins.
- [ ] **Step 6: Add incomplete credential state and repair action** to credential management. Reuse existing edit controls; keep secret fields empty and preserve metadata on cancel/failure.
- [ ] **Step 7: Add task-level UI tests** for incomplete → editing → saving → success/failure/cancel and leave/return readiness; verify no stored secret is rendered or logged.
- [ ] **Step 8: Generate protocol/localization outputs if changed**, run focused local/cloud tests, and commit as `fix(credentials): make definition guards atomic and repair legacy secrets`.

**Expected:** Create-vs-update/delete races cannot both commit; legacy metadata-only credentials stay manageable and show a repair path; valid replacement secrets restore readiness without exposing stored values.

## Final verification

- Run focused test commands from all five tasks after the final code change.
- Run `fvm dart run melos run validate` once the implementation stabilizes, plus `fvm dart run dependency_validator` and `fvm dart run import_sorter:main --exit-if-changed` before PR creation.
- Run `fvm dart run melos run dcl:analyze` for production Dart changes.
- Re-read the assigned issue acceptance criteria, run a whole-branch code review, inspect the final diff, and report any unrun gate.
- Create one Conventional Commit PR closing only issues whose acceptance criteria are complete. Follow required review and CI; fix failures. Merge only after all required checks are green.
