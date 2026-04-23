# Tasks: Fix Native Tool Permissions

**Input**: Design documents from `/specs/006-fix-native-tool-permissions/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md

**Tests**: TDD required per constitution principle V. Write tests first, ensure they fail, then implement.

**Organization**: Tasks grouped by user story. Each story is independently implementable and testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **App source**: `apps/auravibes_app/lib/`
- **App tests**: `apps/auravibes_app/test/`

---

## Phase 1: Setup

**Purpose**: Verify existing codebase compiles and identify current test coverage for tool use cases.

- [x] T001 Run `fvm flutter test` in `apps/auravibes_app/` to verify baseline tests pass
- [x] T002 Run `fvm dart analyze apps/auravibes_app/lib/features/tools/usecases/` to check current state

---

## Phase 2: Foundational

**Purpose**: No shared infrastructure needed — this is a bug fix in existing code. This phase is empty. User story work begins immediately.

---

## Phase 3: User Story 1 — Permission Prompt Shows Correctly (Priority: P1) 🎯 MVP

**Goal**: Native tools with "always ask" permission display the tool approval card in the chat UI instead of silently failing.

**Independent Test**: Enable a native tool with "always ask" permission. Send a message that triggers the tool. Verify the approval card appears with action buttons.

### Tests (TDD — write first, must FAIL)

- [x] T003 [P] [US1] Write failing test: native tool with `alwaysAsk` permission returns `needsConfirmation` (not `notConfigured`) in `apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart`
- [x] T004 [P] [US1] Write failing test: native tool with `alwaysAllow` permission returns `granted` and executes in `apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart`
- [x] T005 [P] [US1] Write failing test: native tool resolution from composite ID `native_<tableId>_<toolId>` produces correct `ResolvedTool` with valid `tableId` in `apps/auravibes_app/test/features/tools/usecases/load_latest_message_tool_calls_usecase_test.dart`

### Implementation

- [x] T006 [US1] Fix `_resolvePermissionTableId` — return `toolIdentifier` for non-MCP tools so workspace lookup by type string works
- [x] T007 [US1] Fix `checkToolPermission` — use `workspaceTool.id` (PK) for conversation tool lookup
- [x] T008 [US1] Run tests T003-T005 — 13/13 passed

**Checkpoint**: Native tool permission prompt now works. Users see the approval card for native tools with "always ask" permission.

---

## Phase 4: User Story 2 — No Retry Loop on Tool Failure (Priority: P2)

**Goal**: When a native tool call fails, the agent loop does not retry the same tool call in subsequent iterations.

**Independent Test**: Trigger a native tool call that fails (e.g., not configured). Verify the agent does not generate a new call to the same tool in the next iteration.

### Tests (TDD — write first, must FAIL)

- [ ] T009 [US2] Write failing test: agent loop tracks failed tool names across iterations and stops retrying in `apps/auravibes_app/test/features/chats/usecases/run_agent_iteration_usecase_test.dart`
- [ ] T010 [P] [US2] Write failing test: tool call with `notConfigured` status is persisted to message metadata and not re-attempted in `apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart`

### Implementation

- [ ] T011 [US2] Add `Set<String> failedToolNames` tracking to the agent loop in `apps/auravibes_app/lib/features/chats/usecases/run_agent_iteration_usecase.dart` — after `runAllowedToolsUsecase` returns, collect tool call names with error statuses; on next iteration, check new tool calls against the set (lines 41-77)
- [ ] T012 [US2] Ensure `LoadLatestMessageToolCallsUsecase` in `apps/auravibes_app/lib/features/tools/usecases/load_latest_message_tool_calls_usecase.dart` correctly filters pending tool calls — only `isPending` calls are loaded, error-status calls are excluded (line 55)
- [ ] T013 [US2] Run tests T009-T010 — verify all pass: `fvm flutter test apps/auravibes_app/test/features/chats/usecases/run_agent_iteration_usecase_test.dart apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart --no-pub`

**Checkpoint**: Agent no longer enters infinite retry loops for failed native tool calls.

---

## Phase 5: User Story 3 — Diagnosable Error Messages (Priority: P3)

**Goal**: Failed native tool calls include the tool name and human-readable reason in the error response, both for the LLM and the user.

**Independent Test**: Trigger a native tool call for a tool not configured in the workspace. Verify the error message includes the tool name and actionable guidance.

### Tests (TDD — write first, must FAIL)

- [ ] T014 [P] [US3] Write failing test: `notConfigured` error includes tool name and descriptive message in `responseRaw` in `apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart`
- [ ] T015 [P] [US3] Write failing test: `toolNotFound` error includes the composite tool name in `responseRaw` in `apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart`
- [ ] T016 [P] [US3] Write failing test: `disabledInWorkspace` and `disabledInConversation` errors include tool name and context in `responseRaw` in `apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart`

### Implementation

- [ ] T017 [US3] Add descriptive `responseRaw` to error status cases in `RunAllowedToolsUsecase` in `apps/auravibes_app/lib/features/tools/usecases/run_allowed_tools_usecase.dart` — for `notConfigured` (lines 93-99), `disabledInWorkspace` (lines 86-92), `disabledInConversation` (lines 79-85), and `toolNotFound` (lines 55-64)
- [ ] T018 [US3] Add descriptive `responseRaw` to `notFoundToolCallIds` mapping in `RunAllowedToolsUsecase` in `apps/auravibes_app/lib/features/tools/usecases/run_allowed_tools_usecase.dart` (lines 55-64) — include the composite tool name that could not be resolved
- [ ] T019 [US3] Run tests T014-T016 — verify all pass: `fvm flutter test apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart --no-pub`

**Checkpoint**: All native tool errors include actionable context for users and the LLM.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Format, analyze, and run full validation.

- [ ] T020 Run `fvm dart format apps/auravibes_app/lib/features/tools/usecases/ apps/auravibes_app/lib/features/chats/usecases/ apps/auravibes_app/test/features/tools/usecases/ apps/auravibes_app/test/features/chats/usecases/`
- [ ] T021 Run `fvm dart analyze apps/auravibes_app/` — fix any warnings or errors
- [ ] T022 Run full test suite: `fvm flutter test apps/auravibes_app/ --no-pub`
- [ ] T023 Run quickstart.md validation — manually test the approval card flow with a native tool

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Empty — skip
- **User Story 1 (Phase 3)**: Depends on Setup completion
- **User Story 2 (Phase 4)**: Depends on US1 (retry guard builds on permission fix)
- **User Story 3 (Phase 5)**: Depends on US1 (error messages added to same code path)
- **Polish (Phase 6)**: Depends on all user stories complete

### User Story Dependencies

- **US1 (P1)**: No story dependencies — can start after Setup
- **US2 (P2)**: Depends on US1 — retry guard needs the permission flow working first
- **US3 (P3)**: Depends on US1 — error messages are added to the same code paths fixed in US1

### Within Each User Story

- Tests written FIRST and must FAIL (TDD red phase)
- Implementation makes tests pass (TDD green phase)
- Run tests to verify (TDD verify phase)

### Parallel Opportunities

- T003, T004, T005 can run in parallel (different test scenarios, same file but different test functions)
- T014, T015, T016 can run in parallel (different error message test scenarios)
- US2 and US3 can potentially run in parallel after US1 completes (different code paths)

---

## Parallel Example: User Story 1

```bash
# Launch all US1 tests together:
Task: "Write failing test: native tool with alwaysAsk returns needsConfirmation"
Task: "Write failing test: native tool with alwaysAllow returns granted"
Task: "Write failing test: native tool composite ID resolves correctly"
```

## Parallel Example: User Story 3

```bash
# Launch all US3 tests together:
Task: "Write failing test: notConfigured error includes tool name"
Task: "Write failing test: toolNotFound error includes composite name"
Task: "Write failing test: disabled errors include tool name and context"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (verify tests pass)
2. Complete Phase 3: US1 — fix permission resolution
3. **STOP and VALIDATE**: Test that native tool approval card appears
4. Deploy if ready — this fixes the core user blocker

### Incremental Delivery

1. US1 → Permission prompt works → MVP!
2. US2 → No retry loops → Stable agent behavior
3. US3 → Clear error messages → Self-service debugging
4. Polish → Clean codebase → Ready for review

---

## Notes

- [P] tasks = different test functions, no file conflicts
- [Story] label maps task to specific user story for traceability
- All changes in `apps/auravibes_app/` only — no package changes
- Constitution requires TDD — tests MUST fail before implementation
- Commit after each task or logical group
- No database schema changes — uses existing tables
