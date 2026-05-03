# Tasks: Agent Conversation Compaction Settings

**Input**: Design documents from `/specs/011-agent-compaction-settings/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included due to changed chat behavior, prompt-boundary correctness, and constitution risk-based quality gates.

**Organization**: Tasks grouped by user story for independent implementation and verification.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Parallelizable (different files, no dependency on unfinished tasks)
- **[Story]**: User story label (`[US1]`, `[US2]`, `[US3]`)
- Every task includes an exact file path

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare scaffolding and localization keys used by all stories.

- [ ] T001 Add compaction/localization keys for compacting, compacted, details, and failure states in `apps/auravibes_app/lib/l10n/locale_keys.g.dart`
- [ ] T002 [P] Add/update translatable copy for compaction UI and errors in `apps/auravibes_app/assets/translations/en.json`
- [ ] T003 [P] Add compaction metadata enum/types scaffolding in `apps/auravibes_app/lib/data/database/drift/enums/message_table_enums.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core metadata, repositories, and prompt-selection plumbing required before story work.

**CRITICAL**: No user story implementation starts before this phase completes.

- [ ] T004 Extend message metadata entity with compaction fields and versioning in `apps/auravibes_app/lib/features/chats/domain/entities/message_metadata_entity.dart`
- [ ] T005 [P] Update message metadata JSON serialization mapping for new compaction fields in `apps/auravibes_app/lib/features/chats/domain/entities/message_metadata_entity.g.dart`
- [ ] T006 Persist/read compaction metadata fields in message data mapper in `apps/auravibes_app/lib/data/repositories/message_repository_impl.dart`
- [ ] T007 Add repository methods for latest compaction summary lookup and compaction summary insert in `apps/auravibes_app/lib/features/chats/domain/repositories/message_repository.dart`
- [ ] T008 Implement latest summary lookup and summary insert in `apps/auravibes_app/lib/data/database/drift/daos/message_dao.dart`
- [ ] T009 Add prompt normalization helper that preserves storage content but normalizes payload content in `apps/auravibes_app/lib/services/chatbot_service/build_prompt_chat_messages.dart`
- [ ] T010 Add compaction-aware prompt boundary selection use case in `apps/auravibes_app/lib/features/chats/usecases/select_prompt_messages_usecase.dart`

**Checkpoint**: Metadata + repository + prompt boundary infrastructure ready for story work.

---

## Phase 3: User Story 1 - Automatic Compaction Prevents Context Exhaustion (Priority: P1) 🎯 MVP

**Goal**: Automatically compact before assistant continuation when configured thresholds require compaction, including queue/busy and conversation-list loading behavior.

**Independent Test**: Trigger threshold crossing in an eligible conversation and verify compaction occurs before continuation, compacting row appears/disappears, and queued sends maintain order.

### Tests for User Story 1

- [ ] T011 [P] [US1] Add use case tests for threshold checks and tool-safety gating in `apps/auravibes_app/test/features/chats/usecases/should_auto_compact_usecase_test.dart`
- [ ] T012 [P] [US1] Add prompt-boundary tests ensuring no duplicate pre-summary payload in `apps/auravibes_app/test/features/chats/usecases/select_prompt_messages_usecase_test.dart`
- [ ] T013 [P] [US1] Add continuation failure-path test for required auto-compaction failure blocking in `apps/auravibes_app/test/features/chats/usecases/resume_conversation_if_ready_usecase_test.dart`
- [ ] T014 [P] [US1] Add widget test for temporary `Compacting` row lifecycle in conversation list in `apps/auravibes_app/test/features/chats/widgets/chat_list_widget_test.dart`

### Implementation for User Story 1

- [ ] T015 [US1] Implement auto-compaction eligibility/use case (both thresholds + safety guards) in `apps/auravibes_app/lib/features/chats/usecases/should_auto_compact_usecase.dart`
- [ ] T016 [US1] Implement compaction execution use case for `auto` mode with range metadata writes in `apps/auravibes_app/lib/features/chats/usecases/compact_conversation_usecase.dart`
- [ ] T017 [US1] Integrate required auto-compaction check before continuation and block on failure in `apps/auravibes_app/lib/features/chats/usecases/resume_conversation_if_ready_usecase.dart`
- [ ] T018 [US1] Add persisted localized failure message emission for required auto-compaction failure in `apps/auravibes_app/lib/features/chats/usecases/send_message_usecase.dart`
- [ ] T019 [US1] Add compaction execution state provider/notifier for running/success/failure state in `apps/auravibes_app/lib/features/chats/providers/compaction_execution_provider.dart`
- [ ] T020 [US1] Render temporary separate `Compacting` row while compaction runs in `apps/auravibes_app/lib/features/chats/widgets/sidebar_conversations_widget.dart`
- [ ] T021 [US1] Route sends through existing queue when compaction state is busy in `apps/auravibes_app/lib/features/chats/widgets/chat_input_widget.dart`

**Checkpoint**: US1 functional and independently testable.

---

## Phase 4: User Story 2 - Manual Compaction From Chat Input (Priority: P2)

**Goal**: User-triggered compaction from chat input with clear feedback, visible `Compacted` widget, and detail view showing stored original content.

**Independent Test**: Trigger manual compact, verify feedback and visible compacted widget, inspect details content fidelity, and confirm no auto-continue.

### Tests for User Story 2

- [ ] T022 [P] [US2] Add manual compaction use case tests for eligibility, success, and no auto-continue behavior in `apps/auravibes_app/test/features/chats/usecases/compact_conversation_usecase_test.dart`
- [ ] T023 [P] [US2] Add chat input widget tests for manual compact enable/disable states in `apps/auravibes_app/test/features/chats/widgets/chat_input_widget_test.dart`
- [ ] T024 [P] [US2] Add chat messages widget test for visible `Compacted` widget and tap-to-details behavior in `apps/auravibes_app/test/features/chats/widgets/chat_messages_widget_test.dart`
- [ ] T025 [P] [US2] Add storage-vs-payload fidelity test for untrimmed persisted content in `apps/auravibes_app/test/features/chats/usecases/build_prompt_chat_messages_test.dart`

### Implementation for User Story 2

- [ ] T026 [US2] Implement manual compaction trigger path and metadata `manual` kind in `apps/auravibes_app/lib/features/chats/usecases/compact_conversation_usecase.dart`
- [ ] T027 [US2] Add manual compact mutation/provider and user feedback states in `apps/auravibes_app/lib/features/chats/providers/manual_compaction_provider.dart`
- [ ] T028 [US2] Wire manual compact control enable/disable and progress state in `apps/auravibes_app/lib/features/chats/widgets/chat_input_widget.dart`
- [ ] T029 [US2] Render visible `Compacted` transcript widget with manual/auto badge in `apps/auravibes_app/lib/features/chats/widgets/chat_messages_widget.dart`
- [ ] T030 [US2] Implement tap-to-details modal/card for compacted message content in `apps/auravibes_app/lib/features/chats/widgets/tool_call_response_modal.dart`
- [ ] T031 [US2] Preserve original summary content at persistence time and move normalization to payload-build-only path in `apps/auravibes_app/lib/services/chatbot_service/build_prompt_chat_messages.dart`

**Checkpoint**: US2 functional and independently testable.

---

## Phase 5: User Story 3 - Configure Compaction Defaults (Priority: P3)

**Goal**: Global compaction settings in settings screen with validation, persistence, and reset behavior used by auto-compaction checks.

**Independent Test**: Change settings, restart/reopen conversation, confirm updated values drive auto-compaction decisions and invalid values cannot save.

### Tests for User Story 3

- [ ] T032 [P] [US3] Add notifier tests for compaction settings defaults, persistence, and reset behavior in `apps/auravibes_app/test/features/settings/compaction_settings_notifier_test.dart`
- [ ] T033 [P] [US3] Add settings screen widget tests for validation and save blocking in `apps/auravibes_app/test/features/settings/compaction_settings_screen_test.dart`
- [ ] T034 [P] [US3] Add integration-focused use case test asserting settings values drive auto check in `apps/auravibes_app/test/features/chats/usecases/should_auto_compact_usecase_test.dart`

### Implementation for User Story 3

- [ ] T035 [US3] Add compaction settings model/entity and defaults in `apps/auravibes_app/lib/features/settings/domain/entities/compaction_settings.dart`
- [ ] T036 [US3] Add shared-preferences-backed settings repository methods in `apps/auravibes_app/lib/data/repositories/workspace_repository_impl.dart`
- [ ] T037 [US3] Add Riverpod notifier for compaction settings load/save/reset in `apps/auravibes_app/lib/features/settings/providers/compaction_settings_provider.dart`
- [ ] T038 [US3] Add compaction settings section UI with localized labels and validation in `apps/auravibes_app/lib/features/settings/widgets/compaction_settings_section.dart`
- [ ] T039 [US3] Wire settings section into settings screen and navigation flow in `apps/auravibes_app/lib/features/settings/screens/settings_screen.dart`
- [ ] T040 [US3] Inject compaction settings values into auto-check path in `apps/auravibes_app/lib/features/chats/usecases/should_auto_compact_usecase.dart`

**Checkpoint**: US3 functional and independently testable.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Stabilization, docs alignment, and full verification.

- [ ] T041 [P] Update feature docs to reflect final compaction UX terms and behavior in `specs/011-agent-compaction-settings/quickstart.md`
- [ ] T042 Run focused and repo-wide validation commands listed in `specs/011-agent-compaction-settings/quickstart.md`
- [ ] T043 [P] Remove dead/obsolete compaction code paths and keep prompt selection single-source in `apps/auravibes_app/lib/features/chats/usecases/select_prompt_messages_usecase.dart`

---

## Dependencies & Execution Order

### Phase Dependencies

- Phase 1 (Setup): no dependencies.
- Phase 2 (Foundational): depends on Phase 1; blocks all user stories.
- Phase 3 (US1): depends on Phase 2.
- Phase 4 (US2): depends on Phase 2; can run after US1 foundations, but safest after Phase 3 due to shared compaction use case changes.
- Phase 5 (US3): depends on Phase 2; can run in parallel with late US2 tasks if staffed.
- Phase 6 (Polish): depends on all targeted stories complete.

### User Story Dependencies

- **US1 (P1)**: core MVP; no dependency on US2/US3.
- **US2 (P2)**: depends on shared compaction primitives from Phase 2; reuses US1 compaction execution.
- **US3 (P3)**: independent settings surface; feeds US1 auto-check logic through configuration.

### Parallel Opportunities

- Setup tasks marked `[P]` can run together.
- Foundational serialization/repository/prompt tasks `T005`, `T009`, `T010` can run in parallel after `T004`.
- Test tasks within each story marked `[P]` can run together.
- UI tasks and use case tasks touching different files can run in parallel within a story when dependencies are satisfied.

---

## Parallel Example: User Story 1

```bash
# Run US1 tests in parallel workstreams:
Task: "T011 should_auto_compact_usecase_test"
Task: "T012 select_prompt_messages_usecase_test"
Task: "T014 chat_list_widget_test"

# Run US1 implementation work in parallel after T015/T016 base:
Task: "T020 sidebar_conversations_widget compacting row"
Task: "T021 chat_input_widget queue-on-compacting"
```

## Parallel Example: User Story 2

```bash
Task: "T023 chat_input_widget_test manual states"
Task: "T024 chat_messages_widget_test compacted widget"
Task: "T030 compacted details modal behavior"
```

## Parallel Example: User Story 3

```bash
Task: "T032 compaction_settings_notifier_test"
Task: "T033 compaction_settings_screen_test"
Task: "T038 compaction_settings_section UI"
```

---

## Implementation Strategy

### MVP First (US1)

1. Complete Phase 1 and Phase 2.
2. Complete Phase 3 (US1) and validate independently.
3. Demo/release MVP auto-compaction safety behavior.

### Incremental Delivery

1. Add US2 manual compact UX and details transparency.
2. Add US3 settings configurability.
3. Execute Phase 6 polish and full validation.

### Format Validation

All tasks use required checklist format: `- [ ] T### [P?] [US?] Description with file path`.
