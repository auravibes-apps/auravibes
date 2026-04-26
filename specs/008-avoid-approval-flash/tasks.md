# Tasks: Avoid Approval Flash

**Input**: Design documents from `/specs/008-avoid-approval-flash/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/approval-display-contract.md, quickstart.md

**Tests**: Included because the implementation plan requires TDD and quickstart lists tests-first verification.

**Organization**: Tasks are grouped by user story to keep each behavior independently implementable and testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it touches different files and has no dependency on incomplete tasks
- **[Story]**: User story label from `spec.md`
- All tasks include exact file paths

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the current approval path and test baseline before changing behavior.

- [ ] T001 Review current approval UI source in `apps/auravibes_app/lib/features/chats/providers/messages_providers.dart`
- [ ] T002 Review current approval card usage in `apps/auravibes_app/lib/features/chats/widgets/chat_tool_approval_card.dart`
- [ ] T003 Review current tool execution permission flow in `apps/auravibes_app/lib/features/tools/usecases/run_allowed_tools_usecase.dart`
- [ ] T004 Run baseline targeted tests with `fvm flutter test test/features/tools/usecases/run_allowed_tools_usecase_test.dart --no-pub` from `apps/auravibes_app`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add the shared permission decision seam that both execution and approval visibility will use.

**CRITICAL**: No user story implementation can begin until this phase is complete.

- [ ] T005 Create `ToolApprovalDecision` result type and `ResolveToolApprovalDecisionUsecase` API in `apps/auravibes_app/lib/features/tools/usecases/resolve_tool_approval_decision_usecase.dart`
- [ ] T006 Move permission-table resolution currently private to `RunAllowedToolsUsecase` into `ResolveToolApprovalDecisionUsecase` in `apps/auravibes_app/lib/features/tools/usecases/resolve_tool_approval_decision_usecase.dart`
- [ ] T007 Add provider wiring for `ResolveToolApprovalDecisionUsecase` in `apps/auravibes_app/lib/features/tools/providers/tool_usecase_providers.dart`
- [ ] T008 Update generated provider exports by running build runner for `apps/auravibes_app/lib/features/tools/providers/tool_usecase_providers.g.dart`

**Checkpoint**: Shared decision use case exists and can be injected without changing user-visible behavior yet.

---

## Phase 3: User Story 1 - Approved Tools Run Without Flash (Priority: P1) MVP

**Goal**: Already-approved pending tools are never emitted to approval-card input and continue directly to execution.

**Independent Test**: Approve a tool for the conversation or always, trigger it again, and verify no approval controls appear before execution.

### Tests for User Story 1

> Write these tests first and confirm they fail before implementation.

- [ ] T009 [P] [US1] Add provider test proving an effective `granted` pending tool is omitted from approval UI input in `apps/auravibes_app/test/features/chats/providers/pending_tool_calls_provider_test.dart`
- [ ] T010 [P] [US1] Add use case test proving `RunAllowedToolsUsecase` executes an effective `granted` tool through the shared decision use case in `apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart`
- [ ] T011 [P] [US1] Add shared decision use case test for conversation-scoped and always-approved `granted` results in `apps/auravibes_app/test/features/tools/usecases/resolve_tool_approval_decision_usecase_test.dart`
- [ ] T012 [US1] Run US1 tests and get user approval for the expected failures before implementation in `apps/auravibes_app/test/features/chats/providers/pending_tool_calls_provider_test.dart`

### Implementation for User Story 1

- [ ] T013 [US1] Update `pendingToolCallsProvider` to use `ResolveToolApprovalDecisionUsecase` and return only decisions with `needsConfirmation` in `apps/auravibes_app/lib/features/chats/providers/messages_providers.dart`
- [ ] T014 [US1] Update `RunAllowedToolsUsecase` to consume `ResolveToolApprovalDecisionUsecase` instead of its private permission-check helper in `apps/auravibes_app/lib/features/tools/usecases/run_allowed_tools_usecase.dart`
- [ ] T015 [US1] Remove the duplicated private permission-check helper from `apps/auravibes_app/lib/features/tools/usecases/run_allowed_tools_usecase.dart`
- [ ] T016 [US1] Run US1 targeted tests with `fvm flutter test test/features/chats/providers/pending_tool_calls_provider_test.dart test/features/tools/usecases/resolve_tool_approval_decision_usecase_test.dart test/features/tools/usecases/run_allowed_tools_usecase_test.dart --no-pub` from `apps/auravibes_app`

**Checkpoint**: User Story 1 is fully functional and testable independently.

---

## Phase 4: User Story 2 - Unapproved Tools Still Require Approval (Priority: P2)

**Goal**: Tools with no applicable approval still show approval controls and wait for user approval or rejection.

**Independent Test**: Trigger a tool with no prior approval and verify the approval card appears and execution waits.

### Tests for User Story 2

> Write these tests first and confirm they fail before implementation.

- [ ] T017 [P] [US2] Add provider test proving `needsConfirmation` pending tools remain in approval UI input in `apps/auravibes_app/test/features/chats/providers/pending_tool_calls_provider_test.dart`
- [ ] T018 [P] [US2] Add use case test proving `RunAllowedToolsUsecase` returns `waitForToolApproval` for `needsConfirmation` decisions in `apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart`
- [ ] T019 [P] [US2] Add rejection regression test covering unchanged reject behavior in `apps/auravibes_app/test/features/tools/usecases/approve_tool_call_usecase_test.dart`
- [ ] T020 [US2] Run US2 tests and get user approval for the expected failures before implementation in `apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart`

### Implementation for User Story 2

- [ ] T021 [US2] Ensure `pendingToolCallsProvider` preserves `needsConfirmation` calls and their message IDs in `apps/auravibes_app/lib/features/chats/providers/messages_providers.dart`
- [ ] T022 [US2] Ensure `RunAllowedToolsUsecase` keeps `hasPendingTools` behavior and returns `waitForToolApproval` for confirmation-required decisions in `apps/auravibes_app/lib/features/tools/usecases/run_allowed_tools_usecase.dart`
- [ ] T023 [US2] Run US2 targeted tests with `fvm flutter test test/features/chats/providers/pending_tool_calls_provider_test.dart test/features/tools/usecases/run_allowed_tools_usecase_test.dart test/features/tools/usecases/approve_tool_call_usecase_test.dart --no-pub` from `apps/auravibes_app`

**Checkpoint**: User Story 2 preserves safety prompts independently of approved-tool flash removal.

---

## Phase 5: User Story 3 - Consistent Approval State Across Conversation Updates (Priority: P3)

**Goal**: Conversation updates, mixed tool requests, and permission changes stay consistent with the shared decision result.

**Independent Test**: Trigger mixed approved and unapproved tool requests across repeated updates and verify only unapproved requests show controls.

### Tests for User Story 3

> Write these tests first and confirm they fail before implementation.

- [ ] T024 [P] [US3] Add provider test for mixed granted and `needsConfirmation` tool calls in `apps/auravibes_app/test/features/chats/providers/pending_tool_calls_provider_test.dart`
- [ ] T025 [P] [US3] Add provider invalidation test for permission changes from pending to granted in `apps/auravibes_app/test/features/chats/providers/pending_tool_calls_provider_test.dart`
- [ ] T026 [P] [US3] Add provider test for 20 consecutive approved-tool updates with zero approval-card input in `apps/auravibes_app/test/features/chats/providers/pending_tool_calls_provider_test.dart`
- [ ] T027 [P] [US3] Add provider or widget test covering pending, approved/running, rejected, and completed display states in `apps/auravibes_app/test/features/chats/providers/pending_tool_calls_provider_test.dart`
- [ ] T028 [US3] Run US3 tests and get user approval for the expected failures before implementation in `apps/auravibes_app/test/features/chats/providers/pending_tool_calls_provider_test.dart`

### Implementation for User Story 3

- [ ] T029 [US3] Ensure approval visibility provider watches message and permission dependencies needed to refresh decisions in `apps/auravibes_app/lib/features/chats/providers/messages_providers.dart`
- [ ] T030 [US3] Ensure `ChatConversationScreen` approval-card visibility still follows filtered pending approval state in `apps/auravibes_app/lib/features/chats/screens/chat_conversation_screen.dart`
- [ ] T031 [US3] Run US3 targeted tests with `fvm flutter test test/features/chats/providers/pending_tool_calls_provider_test.dart --no-pub` from `apps/auravibes_app`

**Checkpoint**: User Story 3 keeps approval display stable across repeated conversation updates.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final verification, generated-code cleanup, and full project checks.

- [ ] T032 Verify approval decision state changes either use existing structured logging or add structured logging for decision failures in `apps/auravibes_app/lib/features/chats/providers/messages_providers.dart`
- [ ] T033 Manually verify already-approved tools progress without extra approval action in under 1 second in `specs/008-avoid-approval-flash/quickstart.md`
- [ ] T034 Run `fvm dart run build_runner build --delete-conflicting-outputs` from `apps/auravibes_app` and verify generated files under `apps/auravibes_app/lib/`
- [ ] T035 Run `fvm dart run melos analyze` from repository root for `apps/auravibes_app/lib/features/chats/providers/messages_providers.dart`
- [ ] T036 Run `fvm dart run melos format` from repository root for `apps/auravibes_app/lib/features/tools/usecases/resolve_tool_approval_decision_usecase.dart`
- [ ] T037 Run `fvm dart run melos run validate:quick` from repository root for `specs/008-avoid-approval-flash/quickstart.md`
- [ ] T038 Manually verify the approved-for-conversation, approve-always, unapproved, rejected, running, and completed flows described in `specs/008-avoid-approval-flash/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on Setup completion and blocks all user stories.
- **User Story 1 (Phase 3)**: Depends on Foundational and is the MVP.
- **User Story 2 (Phase 4)**: Depends on Foundational; can be implemented after US1 or in parallel once the shared decision seam exists.
- **User Story 3 (Phase 5)**: Depends on Foundational; best done after US1 and US2 tests define the main granted and pending cases.
- **Polish (Phase 6)**: Depends on completed desired user stories.

### User Story Dependencies

- **User Story 1 (P1)**: Starts after Foundational; no dependency on US2 or US3.
- **User Story 2 (P2)**: Starts after Foundational; shares provider/use case files with US1, so coordinate if parallel.
- **User Story 3 (P3)**: Starts after Foundational; depends conceptually on the filtered provider behavior from US1 and US2.

### Within Each User Story

- Tests must be written, fail, and receive user approval before implementation.
- Shared decision use case before execution wiring.
- Provider filtering before widget/screen verification.
- Story complete before moving to the next priority unless parallel workers coordinate file ownership.

---

## Parallel Opportunities

- T001, T002, and T003 can run in parallel because they read different files.
- T009, T010, and T011 can run in parallel because they create or edit different test files.
- T017, T018, and T019 can run in parallel because they cover provider, execution, and approval-action tests separately.
- T024, T025, T026, and T027 can be authored together in the same provider test file but should not be edited concurrently by separate workers.
- After Phase 2, US1 and US2 can be split by file ownership if one worker owns provider tests/provider code and another owns use case tests/use case code.

## Parallel Example: User Story 1

```bash
Task: "Add provider test proving an effective granted pending tool is omitted from approval UI input in apps/auravibes_app/test/features/chats/providers/pending_tool_calls_provider_test.dart"
Task: "Add use case test proving RunAllowedToolsUsecase executes an effective granted tool through the shared decision use case in apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart"
Task: "Add shared decision use case test for conversation-scoped and always-approved granted results in apps/auravibes_app/test/features/tools/usecases/resolve_tool_approval_decision_usecase_test.dart"
```

## Parallel Example: User Story 2

```bash
Task: "Add provider test proving needsConfirmation pending tools remain in approval UI input in apps/auravibes_app/test/features/chats/providers/pending_tool_calls_provider_test.dart"
Task: "Add use case test proving RunAllowedToolsUsecase returns waitForToolApproval for needsConfirmation decisions in apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart"
Task: "Add rejection regression test covering unchanged reject behavior in apps/auravibes_app/test/features/tools/usecases/approve_tool_call_usecase_test.dart"
```

## Parallel Example: User Story 3

```bash
Task: "Add provider test for mixed granted and needsConfirmation tool calls in apps/auravibes_app/test/features/chats/providers/pending_tool_calls_provider_test.dart"
Task: "Review ChatConversationScreen approval-card visibility after provider filtering in apps/auravibes_app/lib/features/chats/screens/chat_conversation_screen.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 setup checks.
2. Complete Phase 2 shared decision use case.
3. Write and fail US1 tests.
4. Get user approval for the expected failures.
5. Implement US1 provider and execution wiring.
6. Run US1 targeted tests and stop for validation.

### Incremental Delivery

1. Add US1 to remove flash for approved tools.
2. Add US2 to prove unapproved tools still wait for approval.
3. Add US3 to stabilize mixed and rapidly changing conversation updates.
4. Run full quick validation and manual quickstart scenario.

### Notes

- Keep approval semantics unchanged; only change where the effective permission decision is shared and consumed.
- Do not add persisted display flags or schema changes.
- Avoid duplicating conversation/workspace permission precedence in UI providers.
- Use FVM-prefixed commands for all Dart and Flutter work.
