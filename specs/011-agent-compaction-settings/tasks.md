# Tasks: Agent Conversation Compaction Settings

**Input**: Design documents from `/specs/011-agent-compaction-settings/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included because the feature changes assistant continuation, prompt construction, queue behavior, persisted metadata, and user-visible failure handling.

**Organization**: Tasks are grouped by user story so each story can be implemented and verified independently after shared foundations are complete.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Parallelizable because it touches different files and does not depend on unfinished tasks in the same phase
- **[Story]**: User story label (`[US1]`, `[US2]`, `[US3]`)
- Every task includes an exact file path

## Constitution Compliance

All implementation tasks must keep compaction business rules in use cases, use localized strings for UI/errors, use typed user-facing exceptions, use Riverpod Mutation or equivalent explicit mutation state for writes, avoid `AsyncValue.when()` in new UI, and keep domain-specific compaction UI inside `apps/auravibes_app` rather than `packages/auravibes_ui`.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare localization and generated-code scaffolding used by all stories.

- [ ] T001 Add English compaction settings, compacting, compacted, details, and failure strings in `apps/auravibes_app/assets/i18n/en.json`
- [ ] T002 [P] Add Spanish compaction settings, compacting, compacted, details, and failure strings in `apps/auravibes_app/assets/i18n/es.json`
- [ ] T003 Regenerate localization keys for new compaction copy in `apps/auravibes_app/lib/i18n/locale_keys.dart`
- [ ] T004 Confirm build_runner, Freezed, JSON, and Riverpod generator dependencies remain available in `apps/auravibes_app/pubspec.yaml`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core metadata, settings entities, typed errors, prompt selection, and compaction primitives required before user stories.

**CRITICAL**: No user story implementation starts before this phase completes.

- [ ] T005 Extend message metadata with `metadataVersion`, `isCompactionSummary`, `compactionKind`, range IDs, message IDs, and created-at fields in `apps/auravibes_app/lib/domain/entities/messages.dart`
- [ ] T006 [P] Add compaction domain entities for settings, prompt estimates, decisions, ranges, execution state, and retry state in `apps/auravibes_app/lib/domain/entities/compaction.dart`
- [ ] T007 [P] Add typed compaction exceptions carrying localization keys and recovery context in `apps/auravibes_app/lib/domain/exceptions/compaction_exception.dart`
- [ ] T008 Update message metadata serialization tests for old rows, summary rows, and no-tool-metadata invariants in `apps/auravibes_app/test/domain/entities/messages_test.dart`
- [ ] T009 Update message repository tests for compaction summary insertion and latest-summary lookup in `apps/auravibes_app/test/data/repositories/message_repository_impl_test.dart`
- [ ] T010 Add repository contract methods for creating compaction summaries and reading the latest summary in `apps/auravibes_app/lib/domain/repositories/message_repository.dart`
- [ ] T011 Implement repository support for compaction summary writes and latest-summary lookup in `apps/auravibes_app/lib/data/repositories/message_repository_impl.dart`
- [ ] T012 Implement Drift DAO support for latest compaction summary lookup by conversation in `apps/auravibes_app/lib/data/database/drift/daos/message_dao.dart`
- [ ] T013 [P] Add compaction settings repository/provider backed by shared preferences in `apps/auravibes_app/lib/features/settings/providers/compaction_settings_provider.dart`
- [ ] T014 [P] Add compaction prompt-message selection use case anchored at the latest summary in `apps/auravibes_app/lib/features/chats/usecases/select_prompt_messages_usecase.dart`
- [ ] T015 [P] Add compaction-range selection use case that preserves recent tail and complete tool-call/result groups in `apps/auravibes_app/lib/features/chats/usecases/select_compaction_range_usecase.dart`
- [ ] T016 [P] Update prompt builder to map `MessageType.system` compaction summaries to system/context messages and normalize payload text only in `apps/auravibes_app/lib/services/chatbot_service/build_prompt_chat_messages.dart`
- [ ] T017 Add provider registrations for compaction use cases and mutations in `apps/auravibes_app/lib/features/chats/providers/compaction_providers.dart`

**Checkpoint**: Metadata, settings persistence, typed errors, range selection, prompt selection, and provider wiring are ready for story implementation.

---

## Phase 3: User Story 1 - Automatic Compaction Prevents Context Exhaustion (Priority: P1) MVP

**Goal**: Automatically compact eligible older context before assistant continuation when deterministic thresholds require it, show busy/queue state, block on required failure, and retry provider context overflow once.

**Independent Test**: Start an eligible conversation that crosses both thresholds, send a message, and verify compaction happens before assistant continuation while visible history remains intact and queued sends keep order.

### Tests for User Story 1

- [ ] T018 [P] [US1] Add token estimate and threshold-decision tests for auto compaction in `apps/auravibes_app/test/features/chats/usecases/should_compact_conversation_usecase_test.dart`
- [ ] T019 [P] [US1] Add compaction range tests for safe tail, resolved tool-call groups, unresolved tools, failed messages, and pending approvals in `apps/auravibes_app/test/features/chats/usecases/select_compaction_range_usecase_test.dart`
- [ ] T020 [P] [US1] Add prompt payload tests proving latest summary anchoring and no duplicated compacted predecessors in `apps/auravibes_app/test/features/chats/usecases/select_prompt_messages_usecase_test.dart`
- [ ] T021 [P] [US1] Add auto compaction execution tests proving active provider/model, compaction system prompt, metadata writes, and failure no-boundary-change behavior in `apps/auravibes_app/test/features/chats/usecases/compact_conversation_usecase_test.dart`
- [ ] T022 [P] [US1] Add continuation tests for pre-continuation compaction, required-failure blocking, visible error persistence, and context-overflow retry-once in `apps/auravibes_app/test/features/chats/usecases/continue_agent_usecase_test.dart`
- [ ] T023 [P] [US1] Add queue behavior tests for compaction-as-busy ordering in `apps/auravibes_app/test/features/chats/notifiers/conversation_send_queue_notifier_test.dart`
- [ ] T024 [P] [US1] Add conversation list widget test for temporary separate `Compacting` row lifecycle in `apps/auravibes_app/test/features/chats/widgets/sidebar_conversations_widget_test.dart`

### Implementation for User Story 1

- [ ] T025 [US1] Implement prompt-token estimation using latest usage data and conservative fallback approximation in `apps/auravibes_app/lib/features/chats/usecases/estimate_conversation_prompt_tokens_usecase.dart`
- [ ] T026 [US1] Implement deterministic auto/manual compaction decisions with both threshold checks and unsafe-state reasons in `apps/auravibes_app/lib/features/chats/usecases/should_compact_conversation_usecase.dart`
- [ ] T027 [US1] Implement AI-agent-service summary generation with active conversation provider/model and compaction-specific system prompt in `apps/auravibes_app/lib/features/chats/usecases/compact_conversation_usecase.dart`
- [ ] T028 [US1] Persist auto compaction summary messages and visible required-failure system error messages without moving boundaries on failure in `apps/auravibes_app/lib/features/chats/usecases/compact_conversation_usecase.dart`
- [ ] T029 [US1] Integrate auto compaction before assistant history construction and assistant continuation in `apps/auravibes_app/lib/features/chats/usecases/continue_agent_usecase.dart`
- [ ] T030 [US1] Add provider context-overflow detection and retry-once guard around assistant continuation in `apps/auravibes_app/lib/features/chats/usecases/continue_agent_usecase.dart`
- [ ] T031 [US1] Treat active compaction as conversation busy state for send flow in `apps/auravibes_app/lib/features/chats/usecases/get_conversation_busy_state_usecase.dart`
- [ ] T032 [US1] Route sends during compaction through the existing queue in `apps/auravibes_app/lib/features/chats/usecases/send_message_usecase.dart`
- [ ] T033 [US1] Expose compaction execution state for conversation list rendering in `apps/auravibes_app/lib/features/chats/providers/compaction_providers.dart`
- [ ] T034 [US1] Render and remove the temporary separate `Compacting` row in the conversations list in `apps/auravibes_app/lib/features/chats/widgets/sidebar_conversations_widget.dart`

**Checkpoint**: US1 is functional and independently testable as the MVP auto-compaction safety behavior.

---

## Phase 4: User Story 2 - Manual Compaction From Chat Input (Priority: P2)

**Goal**: Let users manually compact eligible conversations from chat input, with clear feedback, no automatic continuation, a visible `Compacted` transcript widget, and details showing stored raw content.

**Independent Test**: Open an eligible conversation below auto thresholds, press compact, verify a summary checkpoint appears, inspect raw details, and confirm no assistant continuation starts.

### Tests for User Story 2

- [ ] T035 [P] [US2] Add manual compaction tests for below-threshold eligibility, busy/unsafe disabled reasons, success metadata kind, failure unchanged state, and no auto-continue in `apps/auravibes_app/test/features/chats/usecases/compact_conversation_usecase_test.dart`
- [ ] T036 [P] [US2] Add chat input widget tests for manual compact button enabled, disabled, running, success, and failure feedback states in `apps/auravibes_app/test/features/chats/widgets/chat_input_widget_test.dart`
- [ ] T037 [P] [US2] Add chat messages widget tests for visible `Compacted` widget, manual/auto origin, and details tap behavior in `apps/auravibes_app/test/features/chats/widgets/chat_messages_widget_test.dart`
- [ ] T038 [P] [US2] Add payload-vs-storage fidelity tests for raw stored summary content and normalized model payload content in `apps/auravibes_app/test/services/chatbot_service/build_prompt_chat_messages_test.dart`

### Implementation for User Story 2

- [ ] T039 [US2] Add manual trigger support to compaction execution while ignoring auto thresholds but enforcing safe eligible context in `apps/auravibes_app/lib/features/chats/usecases/compact_conversation_usecase.dart`
- [ ] T040 [US2] Add manual compact mutation state and localized feedback mapping in `apps/auravibes_app/lib/features/chats/providers/compaction_providers.dart`
- [ ] T041 [US2] Add manual compact control, tooltip, disabled reason, and running state to chat input in `apps/auravibes_app/lib/features/chats/widgets/chat_input_widget.dart`
- [ ] T042 [US2] Wire manual compaction callbacks from conversation screen to chat input in `apps/auravibes_app/lib/features/chats/screens/chat_conversation_screen.dart`
- [ ] T043 [US2] Render visible `Compacted` transcript widget for compaction summary messages in `apps/auravibes_app/lib/features/chats/widgets/chat_messages_widget.dart`
- [ ] T044 [US2] Implement compacted-message details modal/card that displays stored untrimmed content in `apps/auravibes_app/lib/features/chats/widgets/compacted_message_details.dart`
- [ ] T045 [US2] Ensure manual compaction does not call assistant continuation after success in `apps/auravibes_app/lib/features/chats/usecases/run_agent_iteration_usecase.dart`

**Checkpoint**: US2 is functional and independently testable without requiring auto thresholds.

---

## Phase 5: User Story 3 - Configure Compaction Defaults (Priority: P3)

**Goal**: Provide a dedicated settings section to edit auto-enabled state, usage percentage threshold, remaining-token threshold, validation, persistence, and reset defaults.

**Independent Test**: Change settings, restart/reopen the app, verify values persist, invalid values cannot save, reset restores defaults, and auto compaction decisions use saved values.

### Tests for User Story 3

- [ ] T046 [P] [US3] Add provider tests for default settings, shared-preferences persistence, save validation, reset defaults, and dynamic capped remaining-token fallback in `apps/auravibes_app/test/features/settings/providers/compaction_settings_provider_test.dart`
- [ ] T047 [P] [US3] Add settings section widget tests for localized labels, editing, invalid save blocking, and reset behavior in `apps/auravibes_app/test/features/settings/widgets/compaction_settings_section_test.dart`
- [ ] T048 [P] [US3] Add integration tests proving saved settings feed auto compaction decisions in `apps/auravibes_app/test/features/chats/usecases/should_compact_conversation_usecase_test.dart`

### Implementation for User Story 3

- [ ] T049 [US3] Implement settings validation, default calculation, save, load, and reset logic in `apps/auravibes_app/lib/features/settings/providers/compaction_settings_provider.dart`
- [ ] T050 [US3] Add compaction settings section UI with auto toggle, usage threshold field, remaining-token field, save, validation, and reset controls in `apps/auravibes_app/lib/features/settings/widgets/compaction_settings_section.dart`
- [ ] T051 [US3] Wire compaction settings section into the existing settings screen card layout in `apps/auravibes_app/lib/features/settings/screens/settings_screen.dart`
- [ ] T052 [US3] Inject saved compaction settings into auto compaction decision logic in `apps/auravibes_app/lib/features/chats/usecases/should_compact_conversation_usecase.dart`
- [ ] T053 [US3] Localize settings validation errors and reset/save feedback in `apps/auravibes_app/assets/i18n/en.json`
- [ ] T054 [US3] Localize settings validation errors and reset/save feedback in `apps/auravibes_app/assets/i18n/es.json`

**Checkpoint**: US3 is functional and independently testable as a settings-only increment plus auto-check integration.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Generated-code, formatting, validation, and documentation alignment after selected stories are complete.

- [ ] T055 Regenerate Freezed/JSON/Riverpod outputs after implementation changes in `apps/auravibes_app/lib/domain/entities/messages.g.dart`
- [ ] T056 [P] Update quickstart validation notes with final implemented file names and commands in `specs/011-agent-compaction-settings/quickstart.md`
- [ ] T057 Run focused chat use case tests from quickstart and fix failures in `apps/auravibes_app/test/features/chats/usecases/continue_agent_usecase_test.dart`
- [ ] T058 Run focused chat widget tests from quickstart and fix failures in `apps/auravibes_app/test/features/chats/widgets/chat_messages_widget_test.dart`
- [ ] T059 Run focused settings tests from quickstart and fix failures in `apps/auravibes_app/test/features/settings/providers/compaction_settings_provider_test.dart`
- [ ] T060 Run `fvm dart run melos analyze`, `fvm dart run melos format`, and `fvm dart run melos run test` using workspace config `melos.yaml`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: no dependencies; can start immediately.
- **Phase 2 (Foundational)**: depends on Phase 1; blocks all user story phases.
- **Phase 3 (US1)**: depends on Phase 2; delivers MVP auto compaction.
- **Phase 4 (US2)**: depends on Phase 2; can start after the shared compaction execution API is stable, and is safest after T027.
- **Phase 5 (US3)**: depends on Phase 2; can proceed in parallel with US2 after settings provider shape is agreed.
- **Phase 6 (Polish)**: depends on all selected user stories being complete.

### User Story Dependencies

- **US1 (P1)**: independent MVP after foundations; no dependency on US2 or US3.
- **US2 (P2)**: independent manual checkpoint flow after foundations; reuses the compaction execution API from US1 when implemented sequentially.
- **US3 (P3)**: independent settings surface after foundations; feeds US1 auto decisions through `ShouldCompactConversationUsecase`.

### Within Each User Story

- Tests should be written before or alongside implementation when practical.
- Domain entities and typed errors precede use cases.
- Use cases precede providers/notifiers.
- Providers/notifiers precede widgets and screens.
- Each story reaches its checkpoint before proceeding to the next priority when working sequentially.

---

## Parallel Opportunities

- T002 can run in parallel with T001; T003 runs after locale JSON changes.
- T006, T007, T013, T014, T015, and T016 can run in parallel after T005 shape is agreed.
- US1 tests T018-T024 can be authored in parallel against the contracts before implementation.
- US2 tests T035-T038 can be authored in parallel after foundational entities are defined.
- US3 tests T046-T048 can be authored in parallel after `CompactionSettings` is defined.
- US2 UI tasks T041-T044 can run in parallel with US2 use case task T039 once provider contracts are stable.
- US3 UI task T050 can run in parallel with T049 after entity fields and validation requirements are fixed.

## Parallel Example: User Story 1

```bash
Task: "T018 should_compact_conversation_usecase_test in apps/auravibes_app/test/features/chats/usecases/should_compact_conversation_usecase_test.dart"
Task: "T019 select_compaction_range_usecase_test in apps/auravibes_app/test/features/chats/usecases/select_compaction_range_usecase_test.dart"
Task: "T020 select_prompt_messages_usecase_test in apps/auravibes_app/test/features/chats/usecases/select_prompt_messages_usecase_test.dart"
Task: "T024 sidebar_conversations_widget_test in apps/auravibes_app/test/features/chats/widgets/sidebar_conversations_widget_test.dart"
```

## Parallel Example: User Story 2

```bash
Task: "T036 chat_input_widget_test manual compact states in apps/auravibes_app/test/features/chats/widgets/chat_input_widget_test.dart"
Task: "T037 chat_messages_widget_test compacted widget in apps/auravibes_app/test/features/chats/widgets/chat_messages_widget_test.dart"
Task: "T038 build_prompt_chat_messages_test storage fidelity in apps/auravibes_app/test/services/chatbot_service/build_prompt_chat_messages_test.dart"
```

## Parallel Example: User Story 3

```bash
Task: "T046 compaction_settings_provider_test in apps/auravibes_app/test/features/settings/providers/compaction_settings_provider_test.dart"
Task: "T047 compaction_settings_section_test in apps/auravibes_app/test/features/settings/widgets/compaction_settings_section_test.dart"
Task: "T050 compaction_settings_section UI in apps/auravibes_app/lib/features/settings/widgets/compaction_settings_section.dart"
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 1 setup.
2. Complete Phase 2 foundational metadata, prompt, settings, and compaction primitives.
3. Complete Phase 3 US1 auto compaction.
4. Stop and validate US1 independently with the US1 tests and quickstart auto-compaction scenarios.

### Incremental Delivery

1. Deliver US1 automatic compaction safety first.
2. Add US2 manual compaction and transcript transparency.
3. Add US3 settings configurability and validation.
4. Run Phase 6 validation across all selected stories.

### Format Validation

All tasks follow the required checklist format: `- [ ] T### [P?] [US?] Description with file path`.
