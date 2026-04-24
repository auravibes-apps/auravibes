# Tasks: Reusable Agents

**Input**: Design documents from `specs/007-reusable-agents/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/reusable-agents-ui.md](./contracts/reusable-agents-ui.md), [quickstart.md](./quickstart.md)
**Tests**: Required by project constitution and quickstart. Write tests first, run them, and confirm they fail before implementation.
**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it touches different files and has no dependency on incomplete tasks.
- **[Story]**: Maps to the user story phase only.
- Every task includes exact file path(s).

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare feature folders and navigation targets without implementing behavior.

- [ ] T001 Create agents feature folders in `apps/auravibes_app/lib/features/agents/notifiers/`, `apps/auravibes_app/lib/features/agents/providers/`, `apps/auravibes_app/lib/features/agents/usecases/`, and `apps/auravibes_app/lib/features/agents/widgets/`
- [ ] T002 [P] Create agent test folders in `apps/auravibes_app/test/features/agents/notifiers/`, `apps/auravibes_app/test/features/agents/usecases/`, and `apps/auravibes_app/test/features/agents/widgets/`
- [ ] T003 [P] Create data test placeholders in `apps/auravibes_app/test/data/database/agents_dao_test.dart` and `apps/auravibes_app/test/data/repositories/agent_repository_impl_test.dart`
- [ ] T004 [P] Create chat agent-selection test placeholders in `apps/auravibes_app/test/features/chats/usecases/change_conversation_agent_usecase_test.dart` and `apps/auravibes_app/test/features/chats/notifiers/new_chat_notifier_test.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data/domain infrastructure required before user stories.

**CRITICAL**: No user story implementation begins until this phase is complete.

- [ ] T005 [P] Add failing Drift schema tests for `agents` table columns, `(workspace_id, slug)` uniqueness, and nullable `conversations.agent_id` in `apps/auravibes_app/test/data/database/agents_dao_test.dart`
- [ ] T006 [P] Add failing domain validation tests for `AgentToCreate`, `AgentPatch`, and slug generation in `apps/auravibes_app/test/domain/entities/agent_test.dart`
- [ ] T007 Create `Agents` Drift table with `workspaceId`, `name`, `slug`, `instructions`, timestamps, and workspace foreign key in `apps/auravibes_app/lib/data/database/drift/tables/agents_table.dart`
- [ ] T008 Update `Conversations` Drift table with nullable `agentId` foreign-key field in `apps/auravibes_app/lib/data/database/drift/tables/conversations_table.dart`
- [ ] T009 Register `Agents` table and `AgentsDao` in `apps/auravibes_app/lib/data/database/drift/app_database.dart`
- [ ] T010 Add Drift migration for schema version 6 with `agents` table, unique workspace slug index, and `conversations.agent_id` column in `apps/auravibes_app/lib/data/database/drift/app_database.dart`
- [ ] T011 Implement `AgentsDao` with create, update, delete, get-by-id, get-by-workspace, get-by-workspace-slug, and watch-by-workspace methods in `apps/auravibes_app/lib/data/database/drift/daos/agents_dao.dart`
- [ ] T012 Add `AgentEntity`, `AgentToCreate`, and `AgentPatch` Freezed models with validation helpers in `apps/auravibes_app/lib/domain/entities/agent.dart`
- [ ] T013 Add slug generation helper used by `AgentToCreate` and `AgentPatch` in `apps/auravibes_app/lib/domain/entities/agent.dart`
- [ ] T014 Add `AgentRepository` interface and explicit agent exceptions in `apps/auravibes_app/lib/domain/repositories/agent_repository.dart`
- [ ] T015 Implement `AgentRepositoryImpl` with validation, slug uniqueness mapping, and DAO calls in `apps/auravibes_app/lib/data/repositories/agent_repository_impl.dart`
- [ ] T016 Add Riverpod repository provider for agents in `apps/auravibes_app/lib/features/agents/providers/agent_repository_provider.dart`
- [ ] T017 Update `ConversationEntity`, `ConversationToCreate`, and `ConversationPatch` with optional `agentId` in `apps/auravibes_app/lib/domain/entities/conversation.dart`
- [ ] T018 Update `ConversationRepositoryImpl` mapping, create, patch, and validation for optional `agentId` in `apps/auravibes_app/lib/data/repositories/conversation_repository_impl.dart`
- [ ] T019 Run generated code for Drift, Freezed, and Riverpod from repo root using `fvm dart run melos run generate`

**Checkpoint**: Data/domain foundation builds and user-story work can begin.

---

## Phase 3: User Story 1 - Create a reusable agent (Priority: P1) MVP

**Goal**: User creates a workspace-scoped reusable agent with valid name and instructions.

**Independent Test**: Create an agent and confirm it appears in the workspace agent list; empty fields and duplicate slug are rejected.

### Tests for User Story 1

- [ ] T020 [P] [US1] Add failing repository tests for successful create, empty name, empty instructions, duplicate slug in same workspace, and same slug in another workspace in `apps/auravibes_app/test/data/repositories/agent_repository_impl_test.dart`
- [ ] T021 [P] [US1] Add failing create use-case tests for validation and duplicate slug errors in `apps/auravibes_app/test/features/agents/usecases/create_agent_usecase_test.dart`
- [ ] T022 [P] [US1] Add failing Agents notifier tests for create loading, success refresh, and validation error state in `apps/auravibes_app/test/features/agents/notifiers/agents_notifier_test.dart`
- [ ] T023 [P] [US1] Add failing widget tests for create-agent form required fields and duplicate slug error in `apps/auravibes_app/test/features/agents/widgets/agent_form_test.dart`

### Implementation for User Story 1

- [ ] T024 [US1] Implement create-agent repository path and map duplicate slug failures to `AgentDuplicateSlugException` in `apps/auravibes_app/lib/data/repositories/agent_repository_impl.dart`
- [ ] T025 [US1] Implement `CreateAgentUsecase` in `apps/auravibes_app/lib/features/agents/usecases/create_agent_usecase.dart`
- [ ] T026 [US1] Implement `AgentsNotifier` create flow, loading state, error state, and list refresh in `apps/auravibes_app/lib/features/agents/notifiers/agents_notifier.dart`
- [ ] T027 [US1] Implement reusable agent form widget with name and instructions inputs in `apps/auravibes_app/lib/features/agents/widgets/agent_form.dart`
- [ ] T028 [US1] Replace placeholder create state in `apps/auravibes_app/lib/features/agents/screens/agents_screen.dart` with create action wired to `AgentsNotifier`

**Checkpoint**: US1 works independently as MVP.

---

## Phase 4: User Story 2 - Select an agent for a new chat (Priority: P1)

**Goal**: User starts a new chat with "No Agent" or one workspace agent.

**Independent Test**: Select an agent on new chat, send first message, and confirm the new conversation stores the selected agent and prompt uses its latest instructions.

### Tests for User Story 2

- [ ] T029 [P] [US2] Add failing `SendNewMessageUsecase` tests for `agentId` persistence and cross-workspace rejection in `apps/auravibes_app/test/features/chats/usecases/send_new_message_usecase_test.dart`
- [ ] T030 [P] [US2] Add failing `NewChatNotifier` tests for default "No Agent", set agent, and start conversation with selected agent in `apps/auravibes_app/test/features/chats/notifiers/new_chat_notifier_test.dart`
- [ ] T031 [P] [US2] Add failing prompt tests for no-agent unchanged behavior and selected-agent instruction injection in `apps/auravibes_app/test/services/chatbot_service/build_prompt_chat_messages_test.dart`
- [ ] T032 [P] [US2] Add failing widget tests for new-chat agent selector options and default selection in `apps/auravibes_app/test/features/chats/widgets/chat_agent_selector_test.dart`

### Implementation for User Story 2

- [ ] T033 [US2] Update `SendNewMessageUsecase` to accept optional `agentId`, validate workspace ownership, and create conversation with selected agent in `apps/auravibes_app/lib/features/chats/usecases/send_new_message_usecase.dart`
- [ ] T034 [US2] Update `NewChatState` and `NewChatNotifier` with selected `agentId` and setter in `apps/auravibes_app/lib/features/chats/notifiers/new_chat_notifier.dart`
- [ ] T035 [US2] Implement read provider for workspace agents used by chat selectors in `apps/auravibes_app/lib/features/agents/providers/agents_provider.dart`
- [ ] T036 [US2] Implement `ChatAgentSelector` widget with "No Agent" plus workspace agents in `apps/auravibes_app/lib/features/chats/widgets/chat_agent_selector.dart`
- [ ] T037 [US2] Add `ChatAgentSelector` to `NewChatScreen` and pass selected `agentId` into `NewChatNotifier` in `apps/auravibes_app/lib/features/chats/screens/new_chat_screen.dart`
- [ ] T038 [US2] Update prompt construction to support optional selected agent instructions in `apps/auravibes_app/lib/services/chatbot_service/build_prompt_chat_messages.dart`
- [ ] T039 [US2] Update `ContinueAgentUsecase` to resolve the conversation's current agent and pass latest instructions to prompt construction in `apps/auravibes_app/lib/features/chats/usecases/continue_agent_usecase.dart`

**Checkpoint**: US2 works independently with US1-created agents.

---

## Phase 5: User Story 3 - Change the agent in an existing conversation (Priority: P2)

**Goal**: User changes a conversation's selected agent and only future responses use the new selection.

**Independent Test**: Change an existing conversation from "No Agent" to an agent, from one agent to another, and back to "No Agent"; verify future prompt behavior.

### Tests for User Story 3

- [ ] T040 [P] [US3] Add failing `ChangeConversationAgentUsecase` tests for set agent, switch agent, clear agent, and cross-workspace rejection in `apps/auravibes_app/test/features/chats/usecases/change_conversation_agent_usecase_test.dart`
- [ ] T041 [P] [US3] Add failing `ConversationChatNotifier` tests for setting conversation agent and refreshing selected state in `apps/auravibes_app/test/features/chats/notifiers/conversation_chat_notifier_test.dart`
- [ ] T042 [P] [US3] Add failing conversation selector widget tests for current value and change handling in `apps/auravibes_app/test/features/chats/widgets/conversation_agent_selector_test.dart`

### Implementation for User Story 3

- [ ] T043 [US3] Implement `ChangeConversationAgentUsecase` in `apps/auravibes_app/lib/features/chats/usecases/change_conversation_agent_usecase.dart`
- [ ] T044 [US3] Update `ConversationChatNotifier` with set-agent flow and error handling in `apps/auravibes_app/lib/features/chats/notifiers/conversation_chat_notifier.dart`
- [ ] T045 [US3] Add `ChatAgentSelector` to `ChatConversationScreen` with current conversation `agentId` and set-agent callback in `apps/auravibes_app/lib/features/chats/screens/chat_conversation_screen.dart`
- [ ] T046 [US3] Ensure `ContinueAgentUsecase` uses changed `agentId` only for future response generation in `apps/auravibes_app/lib/features/chats/usecases/continue_agent_usecase.dart`

**Checkpoint**: US3 works independently after foundation and agent creation.

---

## Phase 6: User Story 4 - Edit a reusable agent (Priority: P2)

**Goal**: User edits agent name or instructions; future responses use the latest saved instructions.

**Independent Test**: Edit an agent, confirm selectors/lists show new name/slug, and confirm next response uses updated instructions.

### Tests for User Story 4

- [ ] T047 [P] [US4] Add failing repository tests for update name, update instructions, duplicate slug on edit, and unchanged values in `apps/auravibes_app/test/data/repositories/agent_repository_impl_test.dart`
- [ ] T048 [P] [US4] Add failing update use-case tests for validation and latest-instructions behavior in `apps/auravibes_app/test/features/agents/usecases/update_agent_usecase_test.dart`
- [ ] T049 [P] [US4] Add failing prompt test proving edited instructions are used on the next response in `apps/auravibes_app/test/services/chatbot_service/build_prompt_chat_messages_test.dart`
- [ ] T050 [P] [US4] Add failing widget tests for edit-agent form prefill and save behavior in `apps/auravibes_app/test/features/agents/widgets/agent_form_test.dart`

### Implementation for User Story 4

- [ ] T051 [US4] Implement update-agent repository path and duplicate slug mapping in `apps/auravibes_app/lib/data/repositories/agent_repository_impl.dart`
- [ ] T052 [US4] Implement `UpdateAgentUsecase` in `apps/auravibes_app/lib/features/agents/usecases/update_agent_usecase.dart`
- [ ] T053 [US4] Extend `AgentsNotifier` with edit flow, loading state, and refresh in `apps/auravibes_app/lib/features/agents/notifiers/agents_notifier.dart`
- [ ] T054 [US4] Wire edit action and prefilled `AgentForm` in `apps/auravibes_app/lib/features/agents/screens/agents_screen.dart`
- [ ] T055 [US4] Ensure prompt resolution fetches latest agent instructions at response time in `apps/auravibes_app/lib/features/chats/usecases/continue_agent_usecase.dart`

**Checkpoint**: US4 works independently with existing selected conversations.

---

## Phase 7: User Story 5 - Browse agents in a workflow-oriented table (Priority: P3)

**Goal**: User scans workspace agents by name, slug, and instructions preview.

**Independent Test**: Create multiple agents and confirm management surface shows scannable rows/items with edit access.

### Tests for User Story 5

- [ ] T056 [P] [US5] Add failing Agents screen widget tests for empty state, loaded rows, slug display, instructions preview, and edit action in `apps/auravibes_app/test/features/agents/screens/agents_screen_test.dart`
- [ ] T057 [P] [US5] Add failing provider tests for workspace agent list ordering and current-workspace filtering in `apps/auravibes_app/test/features/agents/providers/agents_provider_test.dart`

### Implementation for User Story 5

- [ ] T058 [US5] Implement workspace agent list provider with current-workspace filtering in `apps/auravibes_app/lib/features/agents/providers/agents_provider.dart`
- [ ] T059 [US5] Implement agent list/table row widget showing name, slug, and instructions preview in `apps/auravibes_app/lib/features/agents/widgets/agent_list_item.dart`
- [ ] T060 [US5] Complete `AgentsScreen` empty, loading, error, and loaded management states in `apps/auravibes_app/lib/features/agents/screens/agents_screen.dart`
- [ ] T061 [US5] Add Agents route branch in `apps/auravibes_app/lib/router/app_router.dart`
- [ ] T062 [US5] Add Agents navigation item and branch handling in `apps/auravibes_app/lib/widgets/app_navigation_wrappers.dart`

**Checkpoint**: US5 management view is independently usable.

---

## Phase 8: User Story 6 - Delete a reusable agent (Priority: P3)

**Goal**: User deletes an agent; selectors remove it and affected conversations fall back to "No Agent".

**Independent Test**: Delete a selected agent, reopen affected conversation, and confirm no stale instructions are injected.

### Tests for User Story 6

- [ ] T063 [P] [US6] Add failing DAO/repository tests for delete and conversation fallback to null `agentId` in `apps/auravibes_app/test/data/repositories/agent_repository_impl_test.dart`
- [ ] T064 [P] [US6] Add failing delete use-case tests for deletion, missing agent, and fallback behavior in `apps/auravibes_app/test/features/agents/usecases/delete_agent_usecase_test.dart`
- [ ] T065 [P] [US6] Add failing prompt test proving deleted agent instructions are not injected in `apps/auravibes_app/test/services/chatbot_service/build_prompt_chat_messages_test.dart`
- [ ] T066 [P] [US6] Add failing Agents screen widget tests for delete confirmation, deleting state, and row removal in `apps/auravibes_app/test/features/agents/screens/agents_screen_test.dart`

### Implementation for User Story 6

- [ ] T067 [US6] Implement delete-agent repository transaction that removes the agent and nulls affected conversations in `apps/auravibes_app/lib/data/repositories/agent_repository_impl.dart`
- [ ] T068 [US6] Implement `DeleteAgentUsecase` in `apps/auravibes_app/lib/features/agents/usecases/delete_agent_usecase.dart`
- [ ] T069 [US6] Extend `AgentsNotifier` with delete flow, confirmation state, loading state, and refresh in `apps/auravibes_app/lib/features/agents/notifiers/agents_notifier.dart`
- [ ] T070 [US6] Wire delete action and confirmation UI in `apps/auravibes_app/lib/features/agents/screens/agents_screen.dart`
- [ ] T071 [US6] Add fallback notification when a conversation's deleted agent resolves to "No Agent" in `apps/auravibes_app/lib/features/chats/screens/chat_conversation_screen.dart`

**Checkpoint**: US6 lifecycle behavior works without stale prompt instructions.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Validation, generated files, accessibility, and documentation.

- [ ] T072 [P] Add localization keys for agent labels, validation errors, and delete confirmation in `apps/auravibes_app/lib/i18n/locale_keys.dart`
- [ ] T073 [P] Add localized agent strings to app translation files under `apps/auravibes_app/assets/i18n/`
- [ ] T074 [P] Review UI accessibility labels and keyboard focus behavior for agent forms/selectors in `apps/auravibes_app/lib/features/agents/widgets/agent_form.dart` and `apps/auravibes_app/lib/features/chats/widgets/chat_agent_selector.dart`
- [ ] T075 [P] Add failing integration test for create, edit, browse, and delete agent lifecycle in `apps/auravibes_app/integration_test/reusable_agents_management_flow_test.dart`
- [ ] T076 [P] Add failing integration test for new-chat agent selection and prompt behavior in `apps/auravibes_app/integration_test/reusable_agents_new_chat_flow_test.dart`
- [ ] T077 [P] Add failing integration test for existing-conversation agent change and deleted-agent fallback in `apps/auravibes_app/integration_test/reusable_agents_conversation_flow_test.dart`
- [ ] T078 Add structured logging assertions for create/edit/delete/select/fallback operations in `apps/auravibes_app/test/features/agents/notifiers/agents_notifier_test.dart` and `apps/auravibes_app/test/features/chats/notifiers/conversation_chat_notifier_test.dart`
- [ ] T079 Implement structured logging with user action, workspace id, conversation id when present, agent id when present, and error type in `apps/auravibes_app/lib/features/agents/notifiers/agents_notifier.dart` and `apps/auravibes_app/lib/features/chats/notifiers/conversation_chat_notifier.dart`
- [ ] T080 Review agent repository and use cases for `error-handling-exceptions`: keep validation, duplicate slug, not-found, and cross-workspace exceptions; remove generic catch-and-rethrow wrappers in `apps/auravibes_app/lib/data/repositories/agent_repository_impl.dart`, `apps/auravibes_app/lib/features/agents/usecases/`, and `apps/auravibes_app/lib/features/chats/usecases/change_conversation_agent_usecase.dart`
- [ ] T081 Run generated code from repo root using `fvm dart run melos run generate`
- [ ] T082 Run focused app tests from `apps/auravibes_app` using `fvm flutter test test/data/database/agents_dao_test.dart test/data/repositories/agent_repository_impl_test.dart test/services/chatbot_service/build_prompt_chat_messages_test.dart --no-pub`
- [ ] T083 Run integration tests from `apps/auravibes_app` using `fvm flutter test integration_test/reusable_agents_management_flow_test.dart integration_test/reusable_agents_new_chat_flow_test.dart integration_test/reusable_agents_conversation_flow_test.dart --no-pub`
- [ ] T084 Run coverage audit from `apps/auravibes_app` using `fvm flutter test --coverage --no-pub` and verify new feature coverage meets the project 80% minimum
- [ ] T085 Manually verify SC-001 through SC-006 timings and action counts from `specs/007-reusable-agents/quickstart.md`
- [ ] T086 Run repo validation from root using `fvm dart run melos run analyze`, `fvm dart run melos format`, and `fvm dart run melos run validate:quick`
- [ ] T087 Update `specs/007-reusable-agents/quickstart.md` with any final manual verification changes discovered during implementation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on Setup; blocks all user stories.
- **US1 Create Agent (Phase 3)**: Depends on Foundational; MVP.
- **US2 New Chat Selection (Phase 4)**: Depends on Foundational and uses agents from US1 for full manual demo.
- **US3 Existing Conversation Selection (Phase 5)**: Depends on Foundational and reusable agents from US1.
- **US4 Edit Agent (Phase 6)**: Depends on Foundational and reusable agents from US1.
- **US5 Browse Agents (Phase 7)**: Depends on Foundational; benefits from US1 data.
- **US6 Delete Agent (Phase 8)**: Depends on Foundational and reusable agents from US1.
- **Polish (Phase 9)**: Depends on completed target stories.

### User Story Dependencies

- **US1 (P1)**: First MVP slice; no other story dependency after foundation.
- **US2 (P1)**: Can be built after foundation but needs an existing agent to verify selected-agent behavior.
- **US3 (P2)**: Needs existing conversations and agents for full verification.
- **US4 (P2)**: Needs existing agents and selected conversations to verify latest instructions.
- **US5 (P3)**: Can be built after foundation, but meaningful with created agents.
- **US6 (P3)**: Needs existing agents and selected conversations to verify fallback.

### Parallel Opportunities

- T002, T003, and T004 can run in parallel after T001.
- T005 and T006 can run in parallel before schema/domain implementation.
- Within each user story, test tasks marked `[P]` can run in parallel before implementation.
- US3, US4, US5, and US6 can be developed in parallel after US1 creates reusable agents, with coordination on shared files noted below.

### Shared File Coordination

- `apps/auravibes_app/lib/features/agents/screens/agents_screen.dart` is touched by US1, US4, US5, and US6; sequence those tasks or merge carefully.
- `apps/auravibes_app/lib/features/agents/notifiers/agents_notifier.dart` is touched by US1, US4, and US6; sequence those tasks.
- `apps/auravibes_app/lib/features/chats/usecases/continue_agent_usecase.dart` is touched by US2, US3, and US4; sequence prompt-resolution changes.
- `apps/auravibes_app/test/services/chatbot_service/build_prompt_chat_messages_test.dart` is touched by US2, US4, and US6; keep test additions grouped by scenario.

---

## Parallel Example: User Story 1

```text
Task: "T020 [P] [US1] Add failing repository tests for successful create, empty name, empty instructions, duplicate slug in same workspace, and same slug in another workspace in apps/auravibes_app/test/data/repositories/agent_repository_impl_test.dart"
Task: "T021 [P] [US1] Add failing create use-case tests for validation and duplicate slug errors in apps/auravibes_app/test/features/agents/usecases/create_agent_usecase_test.dart"
Task: "T022 [P] [US1] Add failing Agents notifier tests for create loading, success refresh, and validation error state in apps/auravibes_app/test/features/agents/notifiers/agents_notifier_test.dart"
Task: "T023 [P] [US1] Add failing widget tests for create-agent form required fields and duplicate slug error in apps/auravibes_app/test/features/agents/widgets/agent_form_test.dart"
```

## Parallel Example: User Story 2

```text
Task: "T029 [P] [US2] Add failing SendNewMessageUsecase tests for agentId persistence and cross-workspace rejection in apps/auravibes_app/test/features/chats/usecases/send_new_message_usecase_test.dart"
Task: "T030 [P] [US2] Add failing NewChatNotifier tests for default No Agent, set agent, and start conversation with selected agent in apps/auravibes_app/test/features/chats/notifiers/new_chat_notifier_test.dart"
Task: "T031 [P] [US2] Add failing prompt tests for no-agent unchanged behavior and selected-agent instruction injection in apps/auravibes_app/test/services/chatbot_service/build_prompt_chat_messages_test.dart"
Task: "T032 [P] [US2] Add failing widget tests for new-chat agent selector options and default selection in apps/auravibes_app/test/features/chats/widgets/chat_agent_selector_test.dart"
```

## Implementation Strategy

### MVP First

1. Complete Phase 1 and Phase 2.
2. Complete Phase 3 (US1 Create Agent).
3. Stop and validate: user can create a workspace-scoped reusable agent and see validation failures.
4. Add Phase 4 (US2) for first end-to-end conversation value.

### Incremental Delivery

1. Foundation: Drift/domain/repository contracts.
2. US1: Create reusable agent.
3. US2: Select agent on new chat and inject instructions.
4. US3: Change agent in existing conversation.
5. US4: Edit latest instructions.
6. US5: Browse/manage table.
7. US6: Delete with fallback.

### TDD Rule

For each story phase, complete test tasks first, run focused tests to confirm failure, then implement story tasks and rerun the same tests until green.

### Explicit Exceptions Rule

Use meaningful domain exceptions only for expected business decisions: validation rejected, duplicate slug, missing agent, and cross-workspace selection. Let unexpected infrastructure errors bubble unless they can be mapped to one of those business cases.

### Agent Workflow Examples

See [agent-workflows.md](./agent-workflows.md) for UI-to-notifier-to-usecase sequences, prompt composition examples, and interface responsibilities for reusable-agent selection, edit, and delete flows.

## Notes

- No tasks add tool presets, model selection, scheduled/background tasks, or flow-builder behavior.
- Use `auravibes_ui` components and tokens for all UI work.
- Use Riverpod generated providers and run build_runner after adding generated annotations.
- Use Drift DAOs and migrations for persistence changes.
- Never log agent instructions, chat content, API keys, auth tokens, or other sensitive values in structured logs.
