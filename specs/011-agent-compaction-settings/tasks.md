# Tasks: Agent Conversation Compaction Settings

**Input**: Design documents from `specs/011-agent-compaction-settings/`
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/ui-contracts.md](contracts/ui-contracts.md), [quickstart.md](quickstart.md)

**Tests**: Included because the project constitution requires tests for provider/domain/data behavior, critical chat journeys, metadata shape changes, and user-facing UI behavior.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story the task belongs to (US1, US2, US3)
- All paths are repository-relative

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish shared metadata, settings defaults, typed errors, and localization scaffolding used by all stories.

- [ ] T001 [P] Add compaction metadata fields, `CompactionKind`, `metadataVersion`, and helper getters to `apps/auravibes_app/lib/domain/entities/messages.dart`
- [ ] T002 [P] Add compaction failure and settings validation exception types with localization-key payloads to `apps/auravibes_app/lib/core/exceptions/conversation_exceptions.dart`
- [ ] T003 [P] Add compaction settings and chat error localization keys to `apps/auravibes_app/assets/translations/en.json`
- [ ] T004 Add generated key declarations for compaction settings and chat errors to `apps/auravibes_app/lib/i18n/locale_keys.dart`
- [ ] T005 [P] Add `CompactionSettings` value object defaults and validation rules to `apps/auravibes_app/lib/features/settings/notifiers/compaction_settings_notifier.dart`
- [ ] T006 Run `fvm dart run build_runner build --delete-conflicting-outputs` from `apps/auravibes_app`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core prompt selection, visibility filtering, summary generation, and settings persistence required before user stories.

**Critical**: No user story work can begin until this phase is complete.

- [ ] T007 [P] Add metadata serialization tests for compaction summary fields in `apps/auravibes_app/test/domain/entities/messages_compaction_metadata_test.dart`
- [ ] T008 [P] Add compaction settings validation/default tests in `apps/auravibes_app/test/features/settings/notifiers/compaction_settings_notifier_test.dart`
- [ ] T009 [P] Add prompt selection tests for no summary, latest summary, older summary exclusion, and visible error exclusion in `apps/auravibes_app/test/features/chats/usecases/select_prompt_messages_usecase_test.dart`
- [ ] T010 [P] Add hidden-summary visible-message filtering tests in `apps/auravibes_app/test/features/chats/providers/visible_chat_messages_provider_test.dart`
- [ ] T011 Implement shared preferences persistence for compaction settings in `apps/auravibes_app/lib/features/settings/notifiers/compaction_settings_notifier.dart`
- [ ] T012 Implement `SelectPromptMessagesUsecase` that selects latest compaction summary forward in `apps/auravibes_app/lib/features/chats/usecases/select_prompt_messages_usecase.dart`
- [ ] T013 Update prompt mapping for `MessageType.system` and compaction summaries in `apps/auravibes_app/lib/services/chatbot_service/build_prompt_chat_messages.dart`
- [ ] T014 Add visible chat message provider that hides compaction summary messages in `apps/auravibes_app/lib/features/chats/providers/messages_providers.dart`
- [ ] T015 Add summary generation entrypoint for compaction summaries in `apps/auravibes_app/lib/services/chatbot_service/chatbot_service.dart`
- [ ] T016 Run `fvm dart run build_runner build --delete-conflicting-outputs` from `apps/auravibes_app`

**Checkpoint**: Metadata, settings persistence, prompt selection, and visible filtering are ready.

---

## Phase 3: User Story 1 - Automatic Compaction Prevents Context Exhaustion (Priority: P1) MVP

**Goal**: Automatically compact eligible conversations before assistant continuation when configured thresholds are met, block continuation on required auto-compaction failure, and persist a visible chat error message.

**Independent Test**: Configure thresholds to force auto compaction, send/continue a safe conversation, verify an `auto` compaction summary is created before assistant response, prompt selection starts at it, hidden summary is not visible in normal chat, and failure blocks continuation with visible chat error.

### Tests for User Story 1

- [ ] T017 [P] [US1] Add auto compaction threshold decision tests including repeated eligible checks in `apps/auravibes_app/test/features/chats/usecases/should_auto_compact_usecase_test.dart`
- [ ] T018 [P] [US1] Add auto compaction success tests for metadata kind `auto`, prompt boundary, and hidden transcript behavior in `apps/auravibes_app/test/features/chats/usecases/compact_conversation_usecase_test.dart`
- [ ] T019 [P] [US1] Add unsafe tool boundary tests for pending approvals, unresolved tool calls, active tools, unfinished assistant messages, and sending user messages in `apps/auravibes_app/test/features/chats/usecases/compaction_eligibility_usecase_test.dart`
- [ ] T020 [P] [US1] Add continuation integration tests for auto compaction before model call in `apps/auravibes_app/test/features/chats/usecases/continue_agent_usecase_auto_compaction_test.dart`
- [ ] T021 [P] [US1] Add auto compaction failure tests for blocked continuation and visible error message in `apps/auravibes_app/test/features/chats/usecases/continue_agent_usecase_auto_compaction_failure_test.dart`

### Implementation for User Story 1

- [ ] T022 [US1] Implement `ShouldAutoCompactUsecase` with enabled, context-limit, percent, and 4,000-token default threshold behavior in `apps/auravibes_app/lib/features/chats/usecases/should_auto_compact_usecase.dart`
- [ ] T023 [US1] Implement compaction eligibility checks that reject unsafe tool/message states in `apps/auravibes_app/lib/features/chats/usecases/compaction_eligibility_usecase.dart`
- [ ] T024 [US1] Implement `CompactConversationUsecase` with `CompactionKind.auto`, range metadata, empty `toolCalls`, and hidden system summary creation in `apps/auravibes_app/lib/features/chats/usecases/compact_conversation_usecase.dart`
- [ ] T025 [US1] Add compaction provider wiring for eligibility, auto policy, and compact use case in `apps/auravibes_app/lib/features/chats/providers/compaction_providers.dart`
- [ ] T026 [US1] Wire auto compaction before prompt building in `apps/auravibes_app/lib/features/chats/usecases/continue_agent_usecase.dart`
- [ ] T027 [US1] Persist visible localized chat error message and block assistant continuation on required auto-compaction failure in `apps/auravibes_app/lib/features/chats/usecases/continue_agent_usecase.dart`
- [ ] T028 [US1] Replace direct prompt construction with `SelectPromptMessagesUsecase` in `apps/auravibes_app/lib/features/chats/usecases/continue_agent_usecase.dart`
- [ ] T029 [US1] Update message rendering to display auto-compaction failure messages while hidden summaries remain absent in `apps/auravibes_app/lib/features/chats/widgets/chat_messages_widget.dart`
- [ ] T030 [US1] Add redacted structured monitoring for compaction checks, summary generation, persistence, and failure paths in `apps/auravibes_app/lib/features/chats/usecases/continue_agent_usecase.dart`

**Checkpoint**: User Story 1 is independently functional and testable as MVP.

---

## Phase 4: User Story 2 - Manual Compaction From Chat Input (Priority: P2)

**Goal**: Let users manually compact eligible conversations from the chat input area as a checkpoint-only action, with success/failure feedback and no automatic assistant continuation.

**Independent Test**: Open an eligible conversation, press compact in chat input, verify a `manual` compaction summary is created, hidden from visible transcript, prompt selection starts at it, and the assistant does not auto-continue.

### Tests for User Story 2

- [ ] T031 [P] [US2] Add manual compaction use case tests for metadata kind `manual`, hidden summary, unchanged visible transcript, and no auto-continuation in `apps/auravibes_app/test/features/chats/usecases/manual_compact_conversation_usecase_test.dart`
- [ ] T032 [P] [US2] Add manual compact button state widget tests for busy, pending approval, no eligible context, running mutation, and enabled states in `apps/auravibes_app/test/features/chats/widgets/chat_input_compaction_test.dart`
- [ ] T033 [P] [US2] Add manual compaction screen integration tests for success and recoverable failure feedback in `apps/auravibes_app/test/features/chats/screens/chat_conversation_compaction_test.dart`

### Implementation for User Story 2

- [ ] T034 [US2] Add manual compaction mutation and status providers in `apps/auravibes_app/lib/features/chats/providers/compaction_providers.dart`
- [ ] T035 [US2] Add `onCompact` callback, compact button, localized tooltip, loading state, and disabled state to `apps/auravibes_app/lib/features/chats/widgets/chat_input_widget.dart`
- [ ] T036 [US2] Wire manual compaction callback, success feedback, and recoverable failure feedback in `apps/auravibes_app/lib/features/chats/screens/chat_conversation_screen.dart`
- [ ] T037 [US2] Ensure manual compaction creates only a checkpoint and does not call assistant continuation in `apps/auravibes_app/lib/features/chats/usecases/compact_conversation_usecase.dart`

**Checkpoint**: User Story 2 works independently after foundational prompt/metadata support.

---

## Phase 5: User Story 3 - Configure Compaction Defaults (Priority: P3)

**Goal**: Add a dedicated settings section where users can enable/disable auto compaction, edit usage percentage threshold, edit remaining-token threshold, and reset defaults.

**Independent Test**: Open settings, change compaction settings, verify invalid values are rejected, verify settings persist after restart, and verify later auto compaction uses updated values.

### Tests for User Story 3

- [ ] T038 [P] [US3] Add settings notifier persistence tests for save, restart reload, reset defaults, and invalid value rejection in `apps/auravibes_app/test/features/settings/notifiers/compaction_settings_notifier_test.dart`
- [ ] T039 [P] [US3] Add compaction settings section widget tests for toggle, percentage input, token input, reset, and validation feedback in `apps/auravibes_app/test/features/settings/widgets/compaction_settings_section_test.dart`
- [ ] T040 [P] [US3] Add auto policy test proving updated settings are used on next check in `apps/auravibes_app/test/features/chats/usecases/should_auto_compact_usecase_settings_test.dart`
- [ ] T041 [P] [US3] Add model-context-limit validation tests for remaining-token threshold behavior in `apps/auravibes_app/test/features/settings/notifiers/compaction_settings_notifier_test.dart`

### Implementation for User Story 3

- [ ] T042 [US3] Complete save, reset, and model-limit-aware validation APIs in `apps/auravibes_app/lib/features/settings/notifiers/compaction_settings_notifier.dart`
- [ ] T043 [US3] Create compaction settings UI section with toggle, numeric controls, validation display, and reset action in `apps/auravibes_app/lib/features/settings/widgets/compaction_settings_section.dart`
- [ ] T044 [US3] Insert compaction settings section into `apps/auravibes_app/lib/features/settings/screens/settings_screen.dart`
- [ ] T045 [US3] Wire `ShouldAutoCompactUsecase` to read current persisted settings for each auto-compaction check in `apps/auravibes_app/lib/features/chats/usecases/should_auto_compact_usecase.dart`

**Checkpoint**: User Story 3 is independently usable and settings affect future auto compaction.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Generated code, validation, documentation sync, and end-to-end confidence.

- [ ] T046 Run `fvm dart run build_runner build --delete-conflicting-outputs` from `apps/auravibes_app`
- [ ] T047 Run focused tests for compaction in `apps/auravibes_app` with `fvm flutter test test/features/chats/usecases test/features/chats/widgets test/features/settings --no-pub`
- [ ] T048 Run `fvm dart run melos analyze` from repository root
- [ ] T049 Run `fvm dart run melos format` from repository root
- [ ] T050 Run `fvm dart run melos run test` from repository root
- [ ] T051 [P] Update implementation notes in `specs/011-agent-compaction-settings/quickstart.md` if behavior or commands changed during implementation
- [ ] T052 [P] Review hidden-summary and visible-error behavior against `specs/011-agent-compaction-settings/contracts/ui-contracts.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on Setup; blocks all user stories.
- **US1 Automatic Compaction (Phase 3)**: Depends on Foundational; MVP.
- **US2 Manual Compaction (Phase 4)**: Depends on Foundational; can start after core compaction use case exists, but does not require US1 UI.
- **US3 Settings (Phase 5)**: Depends on Foundational; policy wiring overlaps with US1 but UI can proceed independently after settings notifier exists.
- **Polish (Phase 6)**: Depends on desired user stories being complete.

### User Story Dependencies

- **US1 (P1)**: No dependency on US2/US3 after Foundational, but uses default settings from Setup.
- **US2 (P2)**: No dependency on US1 auto continuation; depends on shared compact use case and visible filtering.
- **US3 (P3)**: No dependency on US2; settings UI can be validated independently, then US1 policy consumes it.

### Within Each User Story

- Tests should be written before or with implementation.
- Metadata/settings foundations before prompt and UI work.
- Use cases before provider wiring.
- Providers before widgets/screens.
- Story checkpoint before moving to next priority when working sequentially.

## Parallel Opportunities

- T001-T005 can run in parallel.
- T007-T010 can run in parallel after setup.
- US1 test tasks T017-T021 can run in parallel.
- US2 test tasks T031-T033 can run in parallel.
- US3 test tasks T038-T041 can run in parallel.
- T051-T052 can run in parallel during polish.

## Parallel Example: User Story 1

```text
Task: "T017 [US1] Add auto compaction threshold decision tests"
Task: "T018 [US1] Add auto compaction success tests"
Task: "T019 [US1] Add unsafe tool boundary tests"
Task: "T020 [US1] Add continuation integration tests"
Task: "T021 [US1] Add auto compaction failure tests"
```

## Parallel Example: User Story 2

```text
Task: "T031 [US2] Add manual compaction use case tests"
Task: "T032 [US2] Add manual compact button state widget tests"
Task: "T033 [US2] Add manual compaction screen integration tests"
```

## Parallel Example: User Story 3

```text
Task: "T038 [US3] Add settings notifier persistence tests"
Task: "T039 [US3] Add compaction settings section widget tests"
Task: "T040 [US3] Add auto policy settings test"
Task: "T041 [US3] Add model-context-limit validation tests"
```

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 setup.
2. Complete Phase 2 foundations.
3. Complete Phase 3 automatic compaction.
4. Stop and validate SC-001, SC-006, SC-007, SC-008, SC-009, and SC-011.

### Incremental Delivery

1. Foundation: metadata, prompt selection, visible filtering, settings defaults.
2. US1: automatic compaction and visible failure behavior.
3. US2: manual chat input compaction.
4. US3: settings UI and persistence controls.
5. Polish: generated code, analyzer, format, full tests.

### Notes

- `[P]` tasks use different files or are independent test files.
- Every user story phase has independent test criteria.
- No new Drift schema migration is planned.
- Compaction summaries are persisted but hidden from normal chat transcript.
- Auto-failure messages are visible and must not move the prompt boundary.
