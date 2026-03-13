# Tasks: UI Library Widget Expansion

**Input**: Design documents from `/specs/001-ui-library-widgets/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Widget tests required per SC-005 (80%+ code coverage)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **UI Package**: `packages/auravibes_ui/`
- **Source**: `packages/auravibes_ui/lib/src/`
- **Tests**: `packages/auravibes_ui/test/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify project structure and ensure dependencies are ready

- [ ] T001 Verify project structure matches plan.md in packages/auravibes_ui/
- [ ] T002 [P] Review existing AuraButton implementation in packages/auravibes_ui/lib/src/molecules/auravibes_button.dart
- [ ] T003 [P] Review existing AuraColorVariant and theme extensions in packages/auravibes_ui/lib/src/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: No foundational tasks required - all dependencies exist

**✅ FOUNDATION READY**: All required components (AuraColorVariant, AuraColorScheme, AuraTypographyTheme, AuraSpacingTheme) already exist in the package. Proceed directly to user story implementation.

---

## Phase 3: User Story 1 - Confirmation Dialogs (Priority: P1) 🎯 MVP

**Goal**: Provide AuraConfirmDialog, AuraAlertDialog, and helper functions for consistent styled dialogs

**Independent Test**: Create an AuraConfirmDialog and verify it displays title, message, cancel/confirm actions with proper styling and returns user selection

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T004 [P] [US1] Create AuraConfirmDialog widget test in packages/auravibes_ui/test/organisms/auravibes_dialog_test.dart
- [ ] T005 [P] [US1] Create AuraAlertDialog widget test in packages/auravibes_ui/test/organisms/auravibes_dialog_test.dart
- [ ] T006 [P] [US1] Create showAuraConfirmDialog helper test in packages/auravibes_ui/test/organisms/auravibes_dialog_test.dart
- [ ] T007 [P] [US1] Create showAuraAlertDialog helper test in packages/auravibes_ui/test/organisms/auravibes_dialog_test.dart

### Implementation for User Story 1

- [ ] T008 [US1] Create AuraConfirmDialog widget in packages/auravibes_ui/lib/src/organisms/auravibes_dialog.dart
- [ ] T009 [US1] Create AuraAlertDialog widget in packages/auravibes_ui/lib/src/organisms/auravibes_dialog.dart
- [ ] T010 [US1] Implement showAuraConfirmDialog() helper in packages/auravibes_ui/lib/src/organisms/auravibes_dialog.dart
- [ ] T011 [US1] Implement showAuraAlertDialog() helper in packages/auravibes_ui/lib/src/organisms/auravibes_dialog.dart
- [ ] T012 [US1] Export dialog components from packages/auravibes_ui/lib/src/organisms/organisms.dart
- [ ] T013 [US1] Run widget tests and verify 80%+ coverage for dialog components

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Text Button Component (Priority: P1)

**Goal**: Add `text` variant to AuraButton for transparent background, no border, inline use

**Independent Test**: Add a `text` variant to AuraButton and verify it renders text with no background, responds to taps, and supports color variants

### Tests for User Story 2

- [ ] T014 [P] [US2] Create AuraButton.text variant widget test in packages/auravibes_ui/test/molecules/auravibes_button_text_test.dart

### Implementation for User Story 2

- [ ] T015 [US2] Add `text` value to AuraButtonVariant enum in packages/auravibes_ui/lib/src/molecules/auravibes_button.dart
- [ ] T016 [US2] Update _getBackgroundColor() for text variant in packages/auravibes_ui/lib/src/molecules/auravibes_button.dart
- [ ] T017 [US2] Update _getForegroundColor() for text variant in packages/auravibes_ui/lib/src/molecules/auravibes_button.dart
- [ ] T018 [US2] Update _getBorder() for text variant in packages/auravibes_ui/lib/src/molecules/auravibes_button.dart
- [ ] T019 [US2] Update _getBoxShadow() for text variant in packages/auravibes_ui/lib/src/molecules/auravibes_button.dart
- [ ] T020 [US2] Add padding adjustments for text variant in packages/auravibes_ui/lib/src/molecules/auravibes_button.dart
- [ ] T021 [US2] Run widget tests and verify 80%+ coverage for text variant

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - SnackBar Notifications (Priority: P2)

**Goal**: Provide showAuraSnackBar() helper with semantic variants (default, success, error, warning, info)

**Independent Test**: Call showAuraSnackBar() and verify a styled notification appears at the bottom of the screen, auto-dismisses, and can be swiped away

### Tests for User Story 3

- [ ] T022 [P] [US3] Create AuraSnackBarVariant enum test in packages/auravibes_ui/test/molecules/auravibes_snackbar_test.dart
- [ ] T023 [P] [US3] Create showAuraSnackBar helper test in packages/auravibes_ui/test/molecules/auravibes_snackbar_test.dart

### Implementation for User Story 3

- [ ] T024 [US3] Create AuraSnackBarVariant enum in packages/auravibes_ui/lib/src/molecules/auravibes_snackbar.dart
- [ ] T025 [US3] Implement showAuraSnackBar() helper in packages/auravibes_ui/lib/src/molecules/auravibes_snackbar.dart
- [ ] T026 [US3] Implement _getBackgroundColor() helper for variants in packages/auravibes_ui/lib/src/molecules/auravibes_snackbar.dart
- [ ] T027 [US3] Export snackbar components from packages/auravibes_ui/lib/src/molecules/molecules.dart
- [ ] T028 [US3] Run widget tests and verify 80%+ coverage for snackbar components

**Checkpoint**: At this point, User Stories 1, 2, AND 3 should all work independently

---

## Phase 6: User Story 4 - Radio Selection Components (Priority: P2)

**Goal**: Provide AuraRadio, AuraRadioGroup, AuraRadioListTile for mutually exclusive selections

**Independent Test**: Create AuraRadioGroup with options and verify only one can be selected at a time

### Tests for User Story 4

- [ ] T029 [P] [US4] Create AuraRadio widget test in packages/auravibes_ui/test/molecules/auravibes_radio_test.dart
- [ ] T030 [P] [US4] Create AuraRadioOption class test in packages/auravibes_ui/test/molecules/auravibes_radio_test.dart
- [ ] T031 [P] [US4] Create AuraRadioGroup widget test in packages/auravibes_ui/test/organisms/auravibes_radio_group_test.dart
- [ ] T032 [P] [US4] Create AuraRadioListTile widget test in packages/auravibes_ui/test/organisms/auravibes_radio_group_test.dart

### Implementation for User Story 4

- [ ] T033 [US4] Create AuraRadioOption<T> class in packages/auravibes_ui/lib/src/molecules/auravibes_radio.dart
- [ ] T034 [US4] Create AuraRadio<T> widget in packages/auravibes_ui/lib/src/molecules/auravibes_radio.dart
- [ ] T035 [US4] Export radio components from packages/auravibes_ui/lib/src/molecules/molecules.dart
- [ ] T036 [US4] Create AuraRadioGroup<T> widget in packages/auravibes_ui/lib/src/organisms/auravibes_radio_group.dart
- [ ] T037 [US4] Create AuraRadioListTile<T> widget in packages/auravibes_ui/lib/src/organisms/auravibes_radio_group.dart
- [ ] T038 [US4] Export radio group components from packages/auravibes_ui/lib/src/organisms/organisms.dart
- [ ] T039 [US4] Run widget tests and verify 80%+ coverage for radio components

**Checkpoint**: At this point, User Stories 1-4 should all work independently

---

## Phase 7: User Story 5 - Tooltip Component (Priority: P3)

**Goal**: Provide AuraTooltip widget for contextual hints on hover/long-press

**Independent Test**: Wrap a widget with AuraTooltip and verify the tooltip appears on hover/long-press with the provided message

### Tests for User Story 5

- [ ] T040 [P] [US5] Create AuraTooltip widget test in packages/auravibes_ui/test/atoms/auravibes_tooltip_test.dart

### Implementation for User Story 5

- [ ] T041 [US5] Create AuraTooltip widget in packages/auravibes_ui/lib/src/atoms/auravibes_tooltip.dart
- [ ] T042 [US5] Export tooltip from packages/auravibes_ui/lib/src/atoms/atoms.dart
- [ ] T043 [US5] Run widget tests and verify 80%+ coverage for tooltip

**Checkpoint**: At this point, User Stories 1-5 should all work independently

---

## Phase 8: User Story 6 - Selectable Text (Priority: P3)

**Goal**: Provide AuraSelectableText for copyable text content

**Independent Test**: Use AuraSelectableText and verify text can be selected and copied via the platform's native selection mechanism

### Tests for User Story 6

- [ ] T044 [P] [US6] Create AuraSelectableText widget test in packages/auravibes_ui/test/atoms/auravibes_selectable_text_test.dart

### Implementation for User Story 6

- [ ] T045 [US6] Create AuraSelectableText widget in packages/auravibes_ui/lib/src/atoms/auravibes_selectable_text.dart
- [ ] T046 [US6] Export selectable text from packages/auravibes_ui/lib/src/atoms/atoms.dart
- [ ] T047 [US6] Run widget tests and verify 80%+ coverage for selectable text

**Checkpoint**: All user stories should now be independently functional

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, exports, and final validation

- [ ] T048 [P] Add dartdoc comments to AuraConfirmDialog in packages/auravibes_ui/lib/src/organisms/auravibes_dialog.dart
- [ ] T049 [P] Add dartdoc comments to AuraAlertDialog in packages/auravibes_ui/lib/src/organisms/auravibes_dialog.dart
- [ ] T050 [P] Add dartdoc comments to showAuraConfirmDialog in packages/auravibes_ui/lib/src/organisms/auravibes_dialog.dart
- [ ] T051 [P] Add dartdoc comments to showAuraAlertDialog in packages/auravibes_ui/lib/src/organisms/auravibes_dialog.dart
- [ ] T052 [P] Add dartdoc comments to AuraSnackBarVariant in packages/auravibes_ui/lib/src/molecules/auravibes_snackbar.dart
- [ ] T053 [P] Add dartdoc comments to showAuraSnackBar in packages/auravibes_ui/lib/src/molecules/auravibes_snackbar.dart
- [ ] T054 [P] Add dartdoc comments to AuraRadio in packages/auravibes_ui/lib/src/molecules/auravibes_radio.dart
- [ ] T055 [P] Add dartdoc comments to AuraRadioOption in packages/auravibes_ui/lib/src/molecules/auravibes_radio.dart
- [ ] T056 [P] Add dartdoc comments to AuraRadioGroup in packages/auravibes_ui/lib/src/organisms/auravibes_radio_group.dart
- [ ] T057 [P] Add dartdoc comments to AuraRadioListTile in packages/auravibes_ui/lib/src/organisms/auravibes_radio_group.dart
- [ ] T058 [P] Add dartdoc comments to AuraTooltip in packages/auravibes_ui/lib/src/atoms/auravibes_tooltip.dart
- [ ] T059 [P] Add dartdoc comments to AuraSelectableText in packages/auravibes_ui/lib/src/atoms/auravibes_selectable_text.dart
- [ ] T060 Update main export file packages/auravibes_ui/lib/ui.dart with all new components
- [ ] T061 Run full test suite and verify 80%+ coverage for all new components
- [ ] T062 Run dart analyze and fix any issues
- [ ] T063 Run dart format on all new files
- [ ] T064 Validate quickstart.md examples compile and work correctly

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: ✅ Already complete - proceed to user stories
- **User Stories (Phase 3-8)**: All can proceed in parallel after Setup
  - US1 (Dialogs) and US2 (Text Button) are both P1 priority
  - US3 (SnackBar) and US4 (Radio) are both P2 priority
  - US5 (Tooltip) and US6 (SelectableText) are both P3 priority
- **Polish (Phase 9)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: No dependencies on other stories
- **User Story 2 (P1)**: No dependencies on other stories
- **User Story 3 (P2)**: No dependencies on other stories
- **User Story 4 (P2)**: No dependencies on other stories
- **User Story 5 (P3)**: No dependencies on other stories
- **User Story 6 (P3)**: No dependencies on other stories

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Widget implementation before export updates
- Core implementation before running coverage verification
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All test tasks within a user story marked [P] can run in parallel
- All dartdoc tasks in Phase 9 marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1 (Dialogs)

```bash
# Launch all tests for User Story 1 together:
Task: "Create AuraConfirmDialog widget test in packages/auravibes_ui/test/organisms/auravibes_dialog_test.dart"
Task: "Create AuraAlertDialog widget test in packages/auravibes_ui/test/organisms/auravibes_dialog_test.dart"
Task: "Create showAuraConfirmDialog helper test in packages/auravibes_ui/test/organisms/auravibes_dialog_test.dart"
Task: "Create showAuraAlertDialog helper test in packages/auravibes_ui/test/organisms/auravibes_dialog_test.dart"
```

## Parallel Example: Phase 9 (Polish)

```bash
# Launch all dartdoc tasks together:
Task: "Add dartdoc comments to AuraConfirmDialog..."
Task: "Add dartdoc comments to AuraAlertDialog..."
Task: "Add dartdoc comments to showAuraConfirmDialog..."
# ... all other dartdoc tasks in parallel
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 3: User Story 1 (Dialogs)
3. Complete Phase 4: User Story 2 (Text Button)
4. **STOP and VALIDATE**: Test both P1 stories independently
5. Deploy/demo if ready - can replace 15+ dialog usages and 12+ TextButton usages

### Incremental Delivery

1. Complete Setup → Foundation ready
2. Add User Story 1 + 2 (P1) → Test independently → Deploy/Demo (MVP!)
3. Add User Story 3 + 4 (P2) → Test independently → Deploy/Demo
4. Add User Story 5 + 6 (P3) → Test independently → Deploy/Demo
5. Complete Polish → Full documentation and exports
6. Each priority level adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup together
2. Once Setup is done:
   - Developer A: User Story 1 (Dialogs)
   - Developer B: User Story 2 (Text Button)
   - Developer C: User Story 3 (SnackBar)
   - Developer D: User Story 4 (Radio)
3. Stories complete and integrate independently
4. P3 stories (Tooltip, SelectableText) can start when team has capacity

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Follow STYLE_GUIDE.md const-first design pattern
- Use AuraColorVariant enum, not Color parameters
- Wrap Material widgets with Aura styling (see research.md)
