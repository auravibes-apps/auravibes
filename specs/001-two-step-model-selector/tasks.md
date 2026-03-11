# Tasks: Two-Step Model Selector

**Input**: Design documents from `/specs/001-two-step-model-selector/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Tests**: Widget tests included per constitution TDD requirement (Principle V).

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Monorepo structure**: `apps/auravibes_app/lib/` for main app code
- **Tests**: `apps/auravibes_app/test/` for widget/unit tests
- **i18n**: `apps/auravibes_app/lib/i18n/` for translations

---

## Phase 1: Setup

**Purpose**: Prepare locale keys and verify existing dependencies

- [ ] T001 Add locale key constants in `apps/auravibes_app/lib/i18n/locale_keys.dart`
- [ ] T002 [P] Add English translations in `apps/auravibes_app/lib/i18n/en.yaml`

---

## Phase 2: Foundational (State & Data Layer)

**Purpose**: Core state management and data providers that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T003 Add `providerId` field to `NewChatState` in `apps/auravibes_app/lib/features/chats/providers/new_chat_controller.dart`
- [ ] T004 Add `setProvider(String?)` method to `NewChatController` in `apps/auravibes_app/lib/features/chats/providers/new_chat_controller.dart`
- [ ] T005 Run code generation for new_chat_controller: `cd apps/auravibes_app && fvm dart run build_runner build --delete-conflicting-outputs`
- [ ] T006 Create `listModelsGroupedByProviderProvider` in `apps/auravibes_app/lib/features/models/providers/list_chat_models_providers.dart`
- [ ] T007 Run code generation for list_chat_models_providers: `cd apps/auravibes_app && fvm dart run build_runner build --delete-conflicting-outputs`

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Select Provider Then Model (Priority: P1) 🎯 MVP

**Goal**: Users can select a provider first, then choose a model from that provider's filtered list

**Independent Test**: Open new chat screen, select provider from first dropdown, select model from second dropdown, start conversation

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T008 [P] [US1] Create widget test file `apps/auravibes_app/test/features/models/widgets/select_chat_model_test.dart`
- [ ] T009 [P] [US1] Write test: "shows provider dropdown on load"
- [ ] T010 [P] [US1] Write test: "disables model dropdown when no provider selected"
- [ ] T011 [P] [US1] Write test: "enables model dropdown when provider selected"
- [ ] T012 [P] [US1] Write test: "shows only selected provider's models"
- [ ] T013 [US1] Run tests to verify they FAIL: `cd apps/auravibes_app && fvm flutter test test/features/models/widgets/select_chat_model_test.dart`

### Implementation for User Story 1

- [ ] T014 [US1] Refactor `SelectCredentialsModelWidget` to two-dropdown layout in `apps/auravibes_app/lib/features/models/widgets/select_chat_model.dart`
- [ ] T015 [US1] Create `_ProviderDropdown` private widget in `apps/auravibes_app/lib/features/models/widgets/select_chat_model.dart`
- [ ] T016 [US1] Create `_ModelDropdown` private widget in `apps/auravibes_app/lib/features/models/widgets/select_chat_model.dart`
- [ ] T017 [US1] Add loading/error state handling in `apps/auravibes_app/lib/features/models/widgets/select_chat_model.dart`
- [ ] T018 [US1] Wire up provider selection in `apps/auravibes_app/lib/features/chats/screens/new_chat_screen.dart`
- [ ] T019 [US1] Run tests to verify they PASS: `cd apps/auravibes_app && fvm flutter test test/features/models/widgets/select_chat_model_test.dart`

**Checkpoint**: User Story 1 complete - Provider/model selection works end-to-end

---

## Phase 4: User Story 2 - Quick Model Switching (Priority: P2)

**Goal**: Users can quickly switch between models within the same provider

**Independent Test**: Select provider, switch between multiple models in second dropdown without touching provider dropdown

### Tests for User Story 2

- [ ] T020 [P] [US2] Write test: "can switch models without changing provider"
- [ ] T021 [US2] Run tests to verify they FAIL: `cd apps/auravibes_app && fvm flutter test test/features/models/widgets/select_chat_model_test.dart`

### Implementation for User Story 2

- [ ] T022 [US2] Verify existing search/filter works in model dropdown (no code change needed if AuraDropdownSelector supports it)
- [ ] T023 [US2] Run tests to verify they PASS: `cd apps/auravibes_app && fvm flutter test test/features/models/widgets/select_chat_model_test.dart`

**Checkpoint**: User Story 2 complete - Model switching is smooth

---

## Phase 5: User Story 3 - Single Provider Auto-Selection (Priority: P3)

**Goal**: When only one provider exists, pre-select it to reduce steps

**Independent Test**: Configure only one provider, open new chat screen, verify provider is pre-selected

### Tests for User Story 3

- [ ] T024 [P] [US3] Write test: "auto-selects provider when only one exists"
- [ ] T025 [US3] Run tests to verify they FAIL: `cd apps/auravibes_app && fvm flutter test test/features/models/widgets/select_chat_model_test.dart`

### Implementation for User Story 3

- [ ] T026 [US3] Add single-provider auto-selection logic in `apps/auravibes_app/lib/features/models/widgets/select_chat_model.dart`
- [ ] T027 [US3] Run tests to verify they PASS: `cd apps/auravibes_app && fvm flutter test test/features/models/widgets/select_chat_model_test.dart`

**Checkpoint**: User Story 3 complete - Single provider UX optimized

---

## Phase 6: Polish & Validation

**Purpose**: Final validation and cleanup

- [ ] T028 Run melos analyze: `fvm dart run melos analyze`
- [ ] T029 Run melos format check: `fvm dart run melos format`
- [ ] T030 Run all tests: `fvm dart run melos run test`
- [ ] T031 Run quick validation: `fvm dart run melos run validate:quick`
- [ ] T032 Manual test: Open new chat screen, verify full user flow
- [ ] T033 Commit all changes with conventional commit message

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational - No dependencies on other stories
- **User Story 2 (P2)**: Can start after US1 complete - Builds on US1 widget
- **User Story 3 (P3)**: Can start after US1 complete - Builds on US1 widget

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Widget implementation before screen wiring
- Story complete before moving to next priority

### Parallel Opportunities

- T001, T002 can run in parallel (different files)
- T008-T012 can run in parallel (different test cases)
- T020, T021 can run in parallel with T024, T025 (different test files)

---

## Parallel Example: User Story 1 Tests

```bash
# Launch all tests for User Story 1 together:
Task: "Write test: shows provider dropdown on load"
Task: "Write test: disables model dropdown when no provider selected"
Task: "Write test: enables model dropdown when provider selected"
Task: "Write test: shows only selected provider's models"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (locale keys)
2. Complete Phase 2: Foundational (state + providers)
3. Complete Phase 3: User Story 1 (core selection)
4. **STOP and VALIDATE**: Test provider/model selection end-to-end
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add User Story 1 → Test → Deploy (MVP!)
3. Add User Story 2 → Test → Deploy
4. Add User Story 3 → Test → Deploy
5. Polish → Final validation

---

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 33 |
| **Setup Phase** | 2 tasks |
| **Foundational Phase** | 5 tasks |
| **User Story 1 (P1)** | 12 tasks |
| **User Story 2 (P2)** | 4 tasks |
| **User Story 3 (P3)** | 4 tasks |
| **Polish Phase** | 6 tasks |
| **Parallel Opportunities** | 12 tasks marked [P] |
| **Estimated Time** | 2-3 hours |

## Files Modified/Created

| File | Action |
|------|--------|
| `apps/auravibes_app/lib/i18n/locale_keys.dart` | MODIFY |
| `apps/auravibes_app/lib/i18n/en.yaml` | MODIFY |
| `apps/auravibes_app/lib/features/chats/providers/new_chat_controller.dart` | MODIFY |
| `apps/auravibes_app/lib/features/models/providers/list_chat_models_providers.dart` | MODIFY |
| `apps/auravibes_app/lib/features/models/widgets/select_chat_model.dart` | REFACTOR |
| `apps/auravibes_app/lib/features/chats/screens/new_chat_screen.dart` | MODIFY |
| `apps/auravibes_app/test/features/models/widgets/select_chat_model_test.dart` | CREATE |

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently testable
- Verify tests fail before implementing (TDD)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
