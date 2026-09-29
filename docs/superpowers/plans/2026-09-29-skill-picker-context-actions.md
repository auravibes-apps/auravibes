# Skill Picker and Context Actions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship an add-only, searchable conversation-skill picker with visible readiness, safe recovery, typed assistant suggestions, and explicit Use now actions.

**Architecture:** Keep persisted selection and prepared context in their existing repositories/runtime. Share one app action usecase between picker and A2UI suggestions; validate trusted workspace/conversation, current catalog revision, skill availability, and credential readiness before add or invocation. Build Retry from existing skill-context and tool sources through read-only preview APIs, without model calls or transcript writes.

**Tech Stack:** Flutter 3.47.5, Dart 3.13, Riverpod, Drift, A2UI shared engine contract, Easy Localization.

**Spec:** `docs/superpowers/specs/2026-09-29-skill-picker-context-actions-design.md`

## Global Constraints

- No new dependency.
- All user-visible strings and errors are localized in English and Spanish.
- Do not touch #868 or #947.
- Do not reimplement closed dependencies #879, #616, or #864.
- Retry sends no model request and creates no message or transcript row.
- Add sends no message or request; Use now creates one localized visible request through normal continuation.
- Preserve existing false conversation-skill rows; do not delete historical rows or add a data-rewriting migration.
- Use FVM Flutter 3.47.5 and pinned workspace commands.

## Review Focus

- A malformed or stale A2UI payload cannot select or run a skill. Test invalid schema, unknown slug, and changed catalog revision at engine and app boundaries.
- Duplicate Add or Use now taps cannot persist twice or create multiple requests. Test concurrent calls for the same skill/action.
- A selected skill that loses credentials remains selected and routes to credential setup. Test user and app skill credential routes.
- A fork or resumed conversation with old context never displays Ready before fresh preparation. Test status before and after read-only preparation.
- Local and cloud actions enforce same revision and credential rules. Test both repository/usecase variants where production routing differs.

---

### Task 1: Shared A2UI suggestion contract and catalog revision metadata

**Files:**
- Modify: `packages/auravibes_engine/lib/src/a2ui/a2ui_catalog.dart`
- Modify: `packages/auravibes_engine/lib/src/a2ui/a2ui_chat_contract.dart`
- Modify: `packages/auravibes_engine/lib/src/a2ui/a2ui_skill_definition.dart`
- Modify: `packages/auravibes_engine/lib/src/skill_context_messages.dart`
- Test: `packages/auravibes_engine/test/a2ui_chat_contract_test.dart`
- Test: `packages/auravibes_engine/test/a2ui/a2ui_skill_definition_test.dart`
- Test: `packages/auravibes_engine/test/build_skill_context_messages_test.dart`
- Test: `apps/auravibes_server/test/features/conversations/engine/a2ui_protocol_test.dart`

**Interfaces:**
- Produces passive-only `SkillSuggestion` with required `slug` and 64-character lowercase SHA-256 `catalogRevision`; no title, description, or executable arguments. Server supported-component filtering includes it only when negotiated.
- Produces `skillCatalogRevisionMetadataKey` on the existing `skill_catalog` context message metadata, matching the revision in its XML.
- Keeps `SkillSuggestion` schema out of A2UI core and forms resources.

- [x] **Step 1: Write failing engine tests** for exact required payload, malformed slug/revision rejection, passive-only resource exposure, form/core omission, and metadata/XML revision equality.
- [x] **Step 2: Run** the engine focused tests and `cd apps/auravibes_server && fvm dart test test/features/conversations/engine/a2ui_protocol_test.dart`; confirm failures name missing contract behavior.
- [x] **Step 3: Implement** the shared schema, supported-component id, bounded passive instructions, passive resource filtering, and revision metadata.
- [x] **Step 4: Run the same focused tests**; expect all pass.
- [ ] **Step 5: Commit** as `feat(engine): define bounded skill suggestion contract`.

### Task 2: Shared add/use action and read-only context preparation

**Files:**
- Create: `apps/auravibes_app/lib/features/skills/usecases/apply_conversation_skill_action_usecase.dart`
- Create: `apps/auravibes_app/lib/features/chats/usecases/prepare_conversation_skill_context_usecase.dart`
- Modify: `apps/auravibes_app/lib/features/tools/usecases/load_conversation_tool_specs_usecase.dart`
- Modify: `apps/auravibes_app/lib/features/chats/agent_adapters/app_agent_continuation_adapter.dart`
- Modify: `apps/auravibes_app/lib/features/chats/agent_adapters/build_skill_context_messages_service.dart`
- Test: `apps/auravibes_app/test/features/skills/usecases/apply_conversation_skill_action_usecase_test.dart`
- Test: `apps/auravibes_app/test/features/chats/usecases/prepare_conversation_skill_context_usecase_test.dart`
- Test: `apps/auravibes_app/test/features/tools/usecases/load_conversation_tool_specs_usecase_test.dart`

**Interfaces:**
- `ApplyConversationSkillActionUsecase.call({required workspaceId, required conversationId, required slug, required action, String? expectedCatalogRevision, required String Function(String title) userRequestForSkill})` returns a bounded result: added, already added, in progress, used, stale, unavailable, unauthorized, credentials missing, or credentials unknown.
- Add validates then calls `LoadConversationSkillUsecase`; it never calls `SendMessageUsecase`.
- Use now validates, loads if needed, then calls `SendMessageUsecase` once with the caller-built localized request.
- `LoadConversationToolSpecsUsecase.preview({required conversationId, required workspaceId})` builds the current tool catalog without syncing permissions.
- `AppAgentContinuationAdapter.supportsToolsForConversation(conversationId)` reuses the selected/projected model capability check without preparing a turn.
- `PrepareConversationSkillContextUsecase.call({required workspaceId, required conversationId})` returns selected revisions and `canActivate` from read-only context/tool/model capability sources; known failures use bounded categories.

- [ ] **Step 1: Write failing tests** for workspace ownership, current revision, unavailable slug, missing/unknown credentials, already-added idempotence, concurrent duplicate actions, promptless Add, one visible Use now request, and read-only preparation failure categories.
- [ ] **Step 2: Run the three focused app tests**; confirm expected failures, not fixture errors.
- [ ] **Step 3: Implement** shared action orchestration plus read-only preview. Derive catalog revision and selected revisions from existing `BuildSkillContextMessagesService` output; derive activation capability from the same dynamic skill tool catalog used by continuation.
- [ ] **Step 4: Run the same tests**; expect no send/message path for Add or Retry, and exactly one normal send for Use now.
- [ ] **Step 5: Commit** as `feat(skills): add validated conversation skill actions`.

### Task 3: Add-only picker, recovery, and unload cleanup

**Files:**
- Modify: `apps/auravibes_app/lib/features/skills/widgets/conversation_skill_selector_modal.dart`
- Modify: `apps/auravibes_app/lib/features/skills/providers/conversation_skill_selector_state.dart`
- Modify: `apps/auravibes_app/lib/features/skills/providers/conversation_skill_selector_provider.dart`
- Modify: `apps/auravibes_app/lib/features/chats/providers/conversation_skill_context_runtime.dart`
- Delete: `apps/auravibes_app/lib/features/skills/usecases/unload_conversation_skill_usecase.dart`
- Modify: `apps/auravibes_app/lib/features/skills/services/cloud_skill_store.dart`
- Modify: `apps/auravibes_app/lib/features/skills/services/cloud_skill_settings_adapter.dart`
- Modify: unload-specific assertions in `apps/auravibes_app/test/features/skills/providers/cloud_skill_production_routing_test.dart` and `apps/auravibes_app/test/data/repositories/skills_repository_impl_test.dart`
- Test: `apps/auravibes_app/test/features/skills/widgets/conversation_skill_selector_modal_test.dart`
- Test: `apps/auravibes_app/test/features/skills/providers/conversation_skill_selector_provider_test.dart`
- Test: `apps/auravibes_app/test/features/skills/usecases/load_conversation_skill_usecase_test.dart`
- Test: `apps/auravibes_app/test/data/repositories/skills_repository_impl_test.dart`
- Modify: `apps/auravibes_app/assets/i18n/en.json`, `apps/auravibes_app/assets/i18n/es.json`

**Interfaces:**
- Selector state exposes per-skill bounded context failure causes: missing credentials, unavailable metadata, or preparation failure.
- Picker remains open after failed Add, displays localized error, pending indicator, and disabled duplicate actions; successful Add refreshes selected/context state.
- Search filters loaded and available title/description; empty query preserves existing section empty states.
- Missing credentials opens existing service-connection creation route; unavailable metadata refreshes selector; transient failure exposes explicit Retry.
- Loaded rows show selection and context status, have no remove action, and expose Use now separately.

- [ ] **Step 1: Write failing widget/provider/persistence tests** for both-section search, filtered empty states, Add pending/failure/success, retry and localized causes, credential route, no remove affordance, picker Use now, and legacy false-row re-add.
- [ ] **Step 2: Run focused tests**; confirm failures point to missing picker behavior.
- [ ] **Step 3: Implement** add-only searchable rows, error/retry/credential actions, duplicate guards, Use now, and remove only audited unload writers/usecase wiring while retaining false-row reads and re-add.
- [ ] **Step 4: Generate localization keys** with `fvm dart run melos run generate:localization`, then run focused picker/provider/persistence tests.
- [ ] **Step 5: Commit** as `feat(skills): make conversation picker add only`.

### Task 4: Visible composer Skills control and selected count

**Files:**
- Modify: `apps/auravibes_app/lib/features/chats/widgets/chat_input_widget.dart`
- Test: `apps/auravibes_app/test/features/chats/widgets/chat_input_widget_test.dart`
- Modify: `apps/auravibes_app/assets/i18n/en.json`, `apps/auravibes_app/assets/i18n/es.json`

**Interfaces:**
- When `onSkillsPress` exists, composer displays a compact Skills control with persisted selected count, localized tooltip/semantics, and existing overflow item remains.
- Count includes selected skills needing context recovery and updates after add, compaction, and runtime rehydration.

- [ ] **Step 1: Write failing widget tests** for zero, one, multiple counts, callback, accessible count label, and narrow width without layout exceptions.
- [ ] **Step 2: Run** `cd apps/auravibes_app && fvm flutter test test/features/chats/widgets/chat_input_widget_test.dart --no-pub --reporter compact`; confirm the new control assertions fail.
- [ ] **Step 3: Implement** compact count control backed by `conversationSkillSelectorProvider`; retain the overflow-menu entry.
- [ ] **Step 4: Generate localization keys and rerun the focused test**; expect pass.
- [ ] **Step 5: Commit** as `feat(chats): surface conversation skills beside composer`.

### Task 5: Render and handle typed assistant skill suggestions

**Files:**
- Modify: `apps/auravibes_app/lib/features/chats/agent_adapters/aura_chat_catalog_adapter.dart`
- Modify: `apps/auravibes_app/lib/features/chats/notifiers/chat_a2ui_runtime.dart`
- Modify: `apps/auravibes_app/lib/features/chats/widgets/chat_messages_widget.dart`
- Test: `apps/auravibes_app/test/features/chats/agent_adapters/aura_chat_catalog_adapter_test.dart`
- Test: `apps/auravibes_app/test/features/chats/notifiers/chat_a2ui_runtime_test.dart`
- Test: `apps/auravibes_app/test/features/chats/widgets/chat_messages_widget_test.dart` (create if no current coverage fits)
- Modify: `apps/auravibes_app/assets/i18n/en.json`, `apps/auravibes_app/assets/i18n/es.json`

**Interfaces:**
- Passive catalog renders title/description only from current app skill state; component has only slug/revision input.
- `ChatA2uiRuntime.setWorkspaceId(String workspaceId)` binds trusted route state before rendering and exposes `Stream<ChatSkillSuggestionIntent> skillSuggestions`.
- `ChatA2uiRuntime` emits typed Add or Use now intent only for a current, ready passive `SkillSuggestion` component.
- `ChatMessagesWidget` handles the intent through Task 2; stale, unavailable, or credential-blocked intent opens current picker and never mutates/starts a turn.
- App derives workspace and conversation from route/widget state; no model-supplied executable data is accepted.

- [ ] **Step 1: Write failing adapter/runtime/action tests** for app-resolved display text, typed Add/Use now events, stale fallback, untrusted component rejection, duplicate taps, and exactly one visible Use now request.
- [ ] **Step 2: Run focused A2UI tests**; confirm expected missing component/action failures.
- [ ] **Step 3: Implement** passive custom catalog item, event stream, handler subscription, picker fallback, and localized card controls.
- [ ] **Step 4: Run the same A2UI/action tests**; expect pass.
- [ ] **Step 5: Commit** as `feat(chats): add promptless skill suggestion actions`.

### Task 6: App continuation readiness regression and PR validation

**Files:**
- Test: `apps/auravibes_app/test/features/chats/usecases/prepare_conversation_skill_context_usecase_test.dart`
- Test: new `apps/auravibes_app/test/features/chats/agent_adapters/skill_context_preparation_flow_test.dart`
- Test: `apps/auravibes_app/test/features/chats/agent_adapters/app_agent_transcript_context_adapter_test.dart`
- Review: all changed production/test/localization files from Tasks 1–5

**Interfaces:**
- Deterministic regression starts from persisted selected skill state, exercises compacted/resumed/forked context and read-only preparation, checks selected revision and activation capability, and confirms status never reports Ready before fresh preparation.
- No network, model provider, transcript writes, or unrelated workspace changes.

- [ ] **Step 1: Write a failing app regression test** for selection through compaction, resume, fork, changed revision, and preparation failure.
- [ ] **Step 2: Run the focused regression**; confirm expected status/revision failures.
- [ ] **Step 3: Fix only defects revealed by that test** and rerun it.
- [ ] **Step 4: Review** all diffs and audit `rg -n "UnloadConversationSkill|unloadConversationSkill|selected: false" apps packages` plus cloud/local persistence callers; confirm no supported unload path remains and historical rows survive.
- [ ] **Step 5: Run one final verification pass:** focused touched tests; `fvm dart run melos run validate`; `fvm dart run dependency_validator`; `fvm dart run import_sorter:main --exit-if-changed`; `git diff --check` for final docs/localization patch review. Record every failure and unrun CI gate.
- [ ] **Step 6: Commit any final fixes** with Conventional Commit messages, create one PR, follow hosted checks/review to green, then merge as authorized.
