# Tasks: Workspace Management

**Input**: Design documents from `specs/009-workspace-management/`  
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/ui-contracts.md, research.md, quickstart.md

**Tests**: Include test tasks per risk-based quality gates (constitution V) — widget tests for UI, unit tests for provider logic.

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4, US5)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify existing data layer and prepare feature directories

- [ ] T001 Verify `WorkspaceRepository` supports create/update/delete/cascade and has required methods in `apps/auravibes_app/lib/features/workspaces/data/repositories/workspace_repository.dart` — if verification fails, create implementation tasks for missing CRUD or cascade behavior before proceeding
- [ ] T002 [P] Create feature directories: `apps/auravibes_app/lib/features/workspaces/providers/` and `apps/auravibes_app/lib/features/workspaces/screens/` if missing
- [ ] T003 [P] Create UI package directory: `packages/auravibes_ui/lib/src/molecules/` for dropdown widget

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core providers and routing that MUST be complete before user stories can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 Add GoRouter route for workspace management screen (e.g., `/workspaces/:workspaceId/settings/workspaces`) in `apps/auravibes_app/lib/routing/app_router.dart`
- [ ] T005 [P] Create `workspaceSwitchState` model (idle/loading/error enum + target workspace) in `apps/auravibes_app/lib/features/workspaces/models/workspace_switch_state.dart`
- [ ] T006 [P] Create `workspaceManagementState` model (AsyncValue workspaces, create/edit/delete flags, validation error) in `apps/auravibes_app/lib/features/workspaces/models/workspace_management_state.dart`
- [ ] T007 Create `workspaceSwitcherProvider` (AsyncNotifier) with debounce, loading guard, error handling, URL navigation, and structured logging of switch timing in `apps/auravibes_app/lib/features/workspaces/providers/workspace_switcher_provider.dart` — MUST use `AsyncValue`, immutable Freezed state, and declare provider lifecycle (`autoDispose` vs `keepAlive`)
- [ ] T008 Create `workspaceManagementProvider` (AsyncNotifier) with CRUD orchestration, name validation (3–20 chars), active/last-workspace guards, and structured logging of CRUD operations in `apps/auravibes_app/lib/features/workspaces/providers/workspace_management_provider.dart` — MUST use `AsyncValue`, immutable Freezed state, and declare provider lifecycle (`autoDispose` vs `keepAlive`)
- [ ] T009 [P] Add sidebar navigation button (e.g., "Manage Workspaces" icon) in the sidebar footer section of `apps/auravibes_app/lib/widgets/app_navigation_wrappers.dart` — place alongside Settings for discoverability

**Checkpoint**: Foundation ready — switcher provider, management provider, route, and sidebar button exist. User story implementation can now begin.

---

## Phase 3: User Story 1 — Switch Active Workspace (Priority: P1) 🎯 MVP

**Goal**: Users can switch between workspaces via a dropdown in the sidebar with loading guard and debounce.

**Independent Test**: Select a different workspace from the sidebar dropdown; verify URL updates to `/workspaces/:newId/...`, sidebar shows new workspace name, and conversation list updates.

### Tests for User Story 1

- [ ] T010 [P] [US1] Widget test for `WorkspaceDropdown` showing active workspace and list in `packages/auravibes_ui/test/molecules/workspace_dropdown_test.dart`
- [ ] T011 [P] [US1] Unit test for `workspaceSwitcherProvider` debounce logic — rapid selections process only last in `apps/auravibes_app/test/features/workspaces/providers/workspace_switcher_provider_test.dart`
- [ ] T012 [P] [US1] Unit test for `workspaceSwitcherProvider` error handling — failed switch keeps current workspace in `apps/auravibes_app/test/features/workspaces/providers/workspace_switcher_provider_test.dart`

### Implementation for User Story 1

- [ ] T013 [US1] Implement `WorkspaceDropdown` widget in `packages/auravibes_ui/lib/src/molecules/workspace_dropdown.dart` — displays active workspace, opens dropdown list, handles selection callback, shows loading state, shows error inline
- [ ] T014 [US1] Integrate `WorkspaceDropdown` into `AuraSidebarWrapper` header in `apps/auravibes_app/lib/widgets/app_navigation_wrappers.dart` — pass active workspace, all workspaces, and switch handler
- [ ] T015 [US1] Wire `workspaceSwitcherProvider` to GoRouter navigation in `apps/auravibes_app/lib/features/workspaces/providers/workspace_switcher_provider.dart` — on success, navigate to `/workspaces/:id/chat/new`
- [ ] T016 [US1] Add loading indicator overlay/spinner during active switch in `apps/auravibes_app/lib/widgets/app_navigation_wrappers.dart` or dropdown
- [ ] T017 [US1] Add error retry UI when switch fails in `packages/auravibes_ui/lib/src/molecules/workspace_dropdown.dart` or wrapper

**Checkpoint**: User Story 1 is fully functional and testable independently. MVP achieved.

---

## Phase 4: User Story 5 — Manage Workspaces via Dedicated Screen (Priority: P2)

**Goal**: A full-screen workspace management page exists and is reachable from the sidebar.

**Independent Test**: Tap "Manage Workspaces" in sidebar; verify the management screen opens and displays all workspaces.

**Note**: This story is foundational for US2–US4 (create, edit, delete). It is P2 per spec but implemented before US2–US4 due to dependency.

### Tests for User Story 5

- [ ] T018 [P] [US5] Widget test for `WorkspaceManagementScreen` rendering workspace list in `apps/auravibes_app/test/features/workspaces/screens/workspace_management_screen_test.dart`
- [ ] T019 [P] [US5] Widget test for sidebar button navigating to management route in `apps/auravibes_app/test/widgets/app_navigation_wrappers_test.dart`

### Implementation for User Story 5

- [ ] T020 [US5] Implement `WorkspaceManagementScreen` shell in `apps/auravibes_app/lib/features/workspaces/screens/workspace_management_screen.dart` — scaffold with AppBar, workspace list, and provider wiring
- [ ] T021 [US5] Create `WorkspaceListItem` widget (or inline) in `apps/auravibes_app/lib/features/workspaces/screens/workspace_management_screen.dart` — displays workspace name with placeholder edit/delete actions
- [ ] T022 [US5] Wire sidebar "Manage Workspaces" button to navigate to management route in `apps/auravibes_app/lib/widgets/app_navigation_wrappers.dart`

**Checkpoint**: Management screen exists and is reachable. User Stories 2–4 can now build on it.

---

## Phase 5: User Story 2 — Create New Workspace (Priority: P1)

**Goal**: Users can create a new workspace from the management screen with name validation.

**Independent Test**: Open management screen, tap create, enter a 3–20 char name, save; verify workspace appears in list and sidebar dropdown.

### Tests for User Story 2

- [ ] T023 [P] [US2] Widget test for create form validation (too short, too long names) in `apps/auravibes_app/test/features/workspaces/screens/workspace_management_screen_test.dart`
- [ ] T024 [P] [US2] Unit test for `workspaceManagementProvider` create with valid name in `apps/auravibes_app/test/features/workspaces/providers/workspace_management_provider_test.dart`
- [ ] T025 [P] [US2] Integration test: create workspace → appears in `allWorkspacesProvider` list in `apps/auravibes_app/test/features/workspaces/providers/workspace_management_provider_test.dart`

### Implementation for User Story 2

- [ ] T026 [US2] Add "Create Workspace" button/form (inline or bottom sheet) to `WorkspaceManagementScreen` in `apps/auravibes_app/lib/features/workspaces/screens/workspace_management_screen.dart`
- [ ] T027 [US2] Implement name validation (3–20 chars) with clear error messages in `apps/auravibes_app/lib/features/workspaces/providers/workspace_management_provider.dart`
- [ ] T028 [US2] Wire create action through `workspaceManagementProvider` to `WorkspaceRepository.create()` in `apps/auravibes_app/lib/features/workspaces/providers/workspace_management_provider.dart`
- [ ] T029 [US2] Invalidate `allWorkspacesProvider` after successful creation so sidebar dropdown updates in `apps/auravibes_app/lib/features/workspaces/providers/workspace_management_provider.dart`

**Checkpoint**: User Stories 1 and 2 both work independently. Create operation is functional.

---

## Phase 6: User Story 3 — Edit Workspace Name (Priority: P2)

**Goal**: Users can rename an existing workspace from the management screen with validation.

**Independent Test**: Open management screen, tap edit on a workspace, change name to another valid name, save; verify name updates in list and sidebar dropdown.

### Tests for User Story 3

- [ ] T030 [P] [US3] Widget test for inline edit form with validation in `apps/auravibes_app/test/features/workspaces/screens/workspace_management_screen_test.dart`
- [ ] T031 [P] [US3] Unit test for `workspaceManagementProvider` edit with valid and invalid names in `apps/auravibes_app/test/features/workspaces/providers/workspace_management_provider_test.dart`

### Implementation for User Story 3

- [ ] T032 [US3] Add inline edit mode to `WorkspaceListItem` in `apps/auravibes_app/lib/features/workspaces/screens/workspace_management_screen.dart` — tap edit → text field with save/cancel
- [ ] T033 [US3] Wire edit action through `workspaceManagementProvider` to `WorkspaceRepository.update()` in `apps/auravibes_app/lib/features/workspaces/providers/workspace_management_provider.dart`
- [ ] T034 [US3] Invalidate `allWorkspacesProvider` and refresh active workspace display after successful edit in `apps/auravibes_app/lib/features/workspaces/providers/workspace_management_provider.dart`

**Checkpoint**: Edit operation is functional. User Stories 1, 2, and 3 work independently.

---

## Phase 7: User Story 4 — Delete Workspace (Priority: P2)

**Goal**: Users can delete a non-active, non-last workspace from the management screen with confirmation.

**Independent Test**: Open management screen, tap delete on a non-active workspace, confirm; verify workspace and related data are removed, and it disappears from sidebar dropdown.

### Tests for User Story 4

- [ ] T035 [P] [US4] Widget test for delete confirmation dialog in `apps/auravibes_app/test/features/workspaces/screens/workspace_management_screen_test.dart`
- [ ] T036 [P] [US4] Unit test for `workspaceManagementProvider` delete guard — blocks active and last workspace in `apps/auravibes_app/test/features/workspaces/providers/workspace_management_provider_test.dart`
- [ ] T037 [P] [US4] Unit test for `workspaceManagementProvider` successful delete and cascade in `apps/auravibes_app/test/features/workspaces/providers/workspace_management_provider_test.dart`

### Implementation for User Story 4

- [ ] T038 [US4] Add delete action with confirmation dialog to `WorkspaceListItem` in `apps/auravibes_app/lib/features/workspaces/screens/workspace_management_screen.dart`
- [ ] T039 [US4] Implement delete guards in `workspaceManagementProvider` — prevent deleting active workspace and last remaining workspace in `apps/auravibes_app/lib/features/workspaces/providers/workspace_management_provider.dart`
- [ ] T040 [US4] Wire delete action through `workspaceManagementProvider` to `WorkspaceRepository.delete()` in `apps/auravibes_app/lib/features/workspaces/providers/workspace_management_provider.dart`
- [ ] T041 [US4] Invalidate `allWorkspacesProvider` after successful delete in `apps/auravibes_app/lib/features/workspaces/providers/workspace_management_provider.dart`
- [ ] T042a [US4] Verify `WorkspaceRepository.delete()` cascades to related tables (`Conversations`, `Tools`, `ToolsGroups`, `McpServers`, `ModelConnections`) in `apps/auravibes_app/lib/features/workspaces/data/repositories/workspace_repository_impl.dart`
- [ ] T042b [US4] If T042a fails, implement cascade delete in `WorkspaceRepository.delete()` for all related tables — include migration test if schema changes are required

**Checkpoint**: All user stories are independently functional. Delete operation works with guards.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Accessibility, error handling polish, and validation

- [ ] T043 [P] Add semantic labels and accessibility support to `WorkspaceDropdown` in `packages/auravibes_ui/lib/src/molecules/workspace_dropdown.dart`
- [ ] T044 [P] Add semantic labels to management screen actions (create, edit, delete, confirm) in `apps/auravibes_app/lib/features/workspaces/screens/workspace_management_screen.dart`
- [ ] T045 Add loading/error state styling using `auravibes_ui` tokens in `packages/auravibes_ui/lib/src/molecules/workspace_dropdown.dart`
- [ ] T046 [P] Run `fvm dart run melos analyze` and fix static analysis issues across modified files
- [ ] T047 [P] Run `fvm dart run melos format` across modified files
- [ ] T048 Run quickstart.md validation: switch, create, edit, delete, edge cases per `specs/009-workspace-management/quickstart.md`
- [ ] T049 [P] Add dartdoc to public provider APIs in `apps/auravibes_app/lib/features/workspaces/providers/workspace_switcher_provider.dart` and `workspace_management_provider.dart`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational — can start immediately after Phase 2
- **User Story 5 (Phase 4)**: Depends on Foundational — can start in parallel with US1
- **User Story 2 (Phase 5)**: Depends on User Story 5 (management screen shell must exist)
- **User Story 3 (Phase 6)**: Depends on User Story 5
- **User Story 4 (Phase 7)**: Depends on User Story 5
- **Polish (Phase 8)**: Depends on all user stories

### User Story Dependencies

| Story      | Priority | Depends On | Can Run In Parallel With |
| ---------- | -------- | ---------- | ------------------------ |
| US1 Switch | P1       | Phase 2    | US5                      |
| US5 Screen | P2       | Phase 2    | US1                      |
| US2 Create | P1       | US5        | US3, US4                 |
| US3 Edit   | P2       | US5        | US2, US4                 |
| US4 Delete | P2       | US5        | US2, US3                 |

### Within Each User Story

- Tests can be written before or with implementation
- Provider logic before widget integration
- Widget before screen integration

### Parallel Opportunities

- T001–T003 (Setup) can run in parallel
- T004–T009 (Foundational) can run in parallel where marked [P]
- US1 and US5 can be implemented in parallel after Phase 2
- US2, US3, US4 can be implemented in parallel after US5
- All test tasks marked [P] can run in parallel with their implementation tasks
- T043–T049 (Polish) can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "T010 Widget test for WorkspaceDropdown"
Task: "T011 Unit test for switcher debounce"
Task: "T012 Unit test for switcher error handling"

# Launch models + provider + widget in parallel:
Task: "T005 Create workspaceSwitchState model"
Task: "T007 Create workspaceSwitcherProvider"

# Then integrate:
Task: "T013 Implement WorkspaceDropdown widget"
Task: "T014 Integrate dropdown into sidebar wrapper"
Task: "T015 Wire provider to GoRouter"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1 (Switch workspace)
4. **STOP and VALIDATE**: Test workspace switching independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational
2. Add US1 (Switch) → Test independently → Deploy/Demo (MVP!)
3. Add US5 (Management Screen) → Test independently
4. Add US2 (Create) → Test independently → Deploy/Demo
5. Add US3 (Edit) → Test independently → Deploy/Demo
6. Add US4 (Delete) → Test independently → Deploy/Demo
7. Add Polish → Final validation

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: US1 (Switch) + dropdown widget
   - Developer B: US5 (Management Screen shell)
3. Once US5 is done:
   - Developer A: US2 (Create)
   - Developer B: US3 (Edit)
   - Developer C: US4 (Delete)
4. All stories integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
