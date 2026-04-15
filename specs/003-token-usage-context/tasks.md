# Tasks: Conversation Token Usage Indicator

**Input**: Design documents from `/specs/003-token-usage-context/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Included (feature requires streaming + persistence correctness).

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare feature docs and verify baseline test targets.

- [X] T001 Verify baseline chat tests in `apps/auravibes_app/test/features/chats/usecases/continue_agent_usecase_test.dart` and `apps/auravibes_app/test/features/chats/providers/chat_messages_provider_test.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add shared domain primitives and reusable computations.

- [X] T002 Extend `MessageMetadataEntity` with usage fields in `apps/auravibes_app/lib/domain/entities/messages.dart`
- [X] T003 [P] Add `ChatResult` usage mapping helpers in `apps/auravibes_app/lib/utils/chat_result_extension.dart`
- [X] T004 [P] Add shared usage formatting/aggregation helpers in `apps/auravibes_app/lib/features/chats/providers/messages_providers.dart`

**Checkpoint**: Shared usage model ready.

---

## Phase 3: User Story 1 - View live context usage while chatting (Priority: P1) 🎯 MVP

**Goal**: Show live used/limit/percent and progress circle in conversation top bar.

**Independent Test**: Stream assistant response and verify top bar updates before message finalization.

### Tests for User Story 1

- [X] T005 [P] [US1] Add usage-mapping unit tests in `apps/auravibes_app/test/features/chats/usecases/continue_agent_usecase_test.dart`
- [X] T006 [P] [US1] Add conversation usage aggregation tests in `apps/auravibes_app/test/features/chats/providers/chat_messages_provider_test.dart`

### Implementation for User Story 1

- [X] T007 [US1] Persist streaming usage metadata in `apps/auravibes_app/lib/features/chats/usecases/continue_agent_usecase.dart`
- [X] T008 [US1] Add provider for conversation token usage summary in `apps/auravibes_app/lib/features/chats/providers/messages_providers.dart`
- [X] T009 [US1] Render usage text + circular progress in app bar at `apps/auravibes_app/lib/features/chats/screens/chat_conversation_screen.dart`

**Checkpoint**: Live usage shown and updates during stream.

---

## Phase 4: User Story 2 - Preserve usage across app restarts (Priority: P2)

**Goal**: Ensure persisted metadata reconstructs conversation usage.

**Independent Test**: Usage aggregate from repository-loaded messages equals expected stored totals.

### Tests for User Story 2

- [X] T010 [P] [US2] Add metadata serialization regression test in `apps/auravibes_app/test/features/chats/providers/chat_messages_provider_test.dart`

### Implementation for User Story 2

- [X] T011 [US2] Verify/update metadata round-trip mapping in `apps/auravibes_app/lib/data/repositories/message_repository_impl.dart`

**Checkpoint**: Persisted usage survives reload.

---

## Phase 5: User Story 3 - Graceful behavior with partial usage data (Priority: P3)

**Goal**: Handle missing usage fields safely and consistently.

**Independent Test**: Null/partial usage inputs compute expected fallback and clamped percent.

### Tests for User Story 3

- [X] T012 [P] [US3] Add fallback/clamp tests in `apps/auravibes_app/test/features/chats/providers/chat_messages_provider_test.dart`

### Implementation for User Story 3

- [X] T013 [US3] Apply fallback + clamp logic in provider computation at `apps/auravibes_app/lib/features/chats/providers/messages_providers.dart`

**Checkpoint**: Missing data and edge limits produce stable UI.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T014 [P] Update any impacted docs/comments in `specs/003-token-usage-context/quickstart.md` and inline code comments where needed
- [X] T015 Run targeted tests and app analysis for changed scope

---

## Dependencies & Execution Order

### Phase Dependencies

- Phase 1 → Phase 2 → Phase 3/4/5 → Phase 6
- US2/US3 depend on foundational usage model from Phase 2.

### User Story Dependencies

- **US1 (P1)**: starts after Phase 2.
- **US2 (P2)**: starts after Phase 2, independent from US1 UI pieces.
- **US3 (P3)**: starts after Phase 2, validates fallback behavior used by US1/US2.

### Parallel Opportunities

- T003 and T004 can run in parallel.
- T005 and T006 can run in parallel.
- T010 and T012 can run in parallel.

---

## Parallel Example: User Story 1

```bash
Task: "Add usage-mapping unit tests in continue_agent_usecase_test.dart"
Task: "Add conversation usage aggregation tests in chat_messages_provider_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Complete Phases 1 and 2.
2. Complete US1 tests + implementation.
3. Validate live top-bar usage behavior.

### Incremental Delivery

1. Add persisted metadata behavior (US2).
2. Add fallback/clamp hardening (US3).
3. Execute final verification (Phase 6).
