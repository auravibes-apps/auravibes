# Tasks: Migrate AI Orchestration Framework (LangChain → dartantic_ai)

**Input**: Design documents from `specs/004-migrate-langchain-dartantic/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Existing tests must pass + new targeted tests for dartantic_ai integration points (per SC-002).

**Organization**: Tasks grouped by user story. Big-bang migration — all tasks land in a single commit.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Swap dependencies in pubspec.yaml

- [x] T001 Remove `langchain`, `langchain_anthropic`, `langchain_openai` from `apps/auravibes_app/pubspec.yaml` and add `dartantic_ai: ^3.4.0`
- [x] T002 Run `fvm flutter pub get` in `apps/auravibes_app/` and resolve any dependency conflicts

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create shared adapter types that all user stories depend on. MUST complete before any user story work begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T003 Create domain-level `ToolSpec` class in `apps/auravibes_app/lib/domain/entities/tool_spec.dart` to replace langchain's `ToolSpec` (fields: `name`, `description`, `inputJsonSchema`). This decouples the tool layer from langchain types.
- [ ] T004 [P] Create `ChatMessageAdapter` in `apps/auravibes_app/lib/services/chatbot_service/chat_message_adapter.dart` — converts domain `MessageEntity` list to dartantic `List<ChatMessage>`. Covers user, assistant (with tool calls), tool result, and system message mappings per `contracts/message_conversion.md`.
- [ ] T005 [P] Create `ToolAdapter` in `apps/auravibes_app/lib/services/chatbot_service/tool_adapter.dart` — converts domain `ToolSpec` to dartantic `Tool` (maps `name`, `description`, `inputJsonSchema` → `Schema.fromMap()`, and wires `onCall` callback). Per `contracts/tool_definition.md`.
- [ ] T006 [P] Create `ProviderFactory` in `apps/auravibes_app/lib/services/chatbot_service/provider_factory.dart` — maps provider configuration (type, model ID, base URL, headers, API key) to dartantic `Agent`. Supports built-in providers via prefix string and custom endpoints via `OpenAIProvider(baseUrl: ...)`. Per `contracts/chatbot_service.md`.
- [ ] T007 [P] Add new test for `ChatMessageAdapter` in `apps/auravibes_app/test/services/chatbot_service/chat_message_adapter_test.dart` — verify user/assistant/tool/system message conversions, tool call mapping, empty content handling
- [ ] T008 [P] Add new test for `ToolAdapter` in `apps/auravibes_app/test/services/chatbot_service/tool_adapter_test.dart` — verify ToolSpec→Tool conversion, schema mapping, onCall wiring
- [ ] T009 [P] Add new test for `ProviderFactory` in `apps/auravibes_app/test/services/chatbot_service/provider_factory_test.dart` — verify all built-in provider prefixes, custom base URL, custom headers, invalid provider handling

**Checkpoint**: Adapter layer complete — user story implementation can begin

---

## Phase 3: User Story 1 + 3 — Core Chat & Streaming (Priority: P1 + P2) 🎯 MVP

**Goal**: Replace ChatbotService core with dartantic_ai Agent. Chat and streaming are inseparable — both must work together.

**Independent Test**: User can open a conversation, send a message, and receive a streamed token-by-token response. Multi-turn context is preserved.

### Implementation

- [ ] T010 [US1] Rewrite `ChatbotService` in `apps/auravibes_app/lib/services/chatbot_service/chatbot_service.dart` — replace `BaseChatModel`/`ChatOpenAI`/`ChatAnthropic` with `Agent` via `ProviderFactory`. Replace `PromptValue.chat()` with direct `ChatMessage` list. Replace `model.stream()` with `agent.sendStream()`. Replace `ChatOpenAIOptions`/`ChatAnthropicOptions` with constructor parameters.
- [ ] T011 [US1] Rewrite `build_prompt_chat_messages.dart` in `apps/auravibes_app/lib/services/chatbot_service/build_prompt_chat_messages.dart` — replace langchain `ChatMessage.humanText()`/`.ai()`/`.tool()` factories with `ChatMessageAdapter` calls. Remove `AIChatMessageToolCall` references.
- [ ] T012 [US1] Update `chat_message_models.dart` in `apps/auravibes_app/lib/services/chatbot_service/models/chat_message_models.dart` — replace `AIChatMessageToolCall` with domain-level tool call type or dartantic `ToolCall`. Remove langchain import.
- [ ] T013 [US1] Update `chat_result_extension.dart` in `apps/auravibes_app/lib/utils/chat_result_extension.dart` — retarget extension from langchain `ChatResult` to dartantic `ChatResult`. Verify `LanguageModelUsage` access pattern (`.usage.promptTokens`, `.responseTokens`, `.totalTokens`).
- [ ] T014 [US3] Update `continue_agent_usecase.dart` in `apps/auravibes_app/lib/features/chats/usecases/continue_agent_usecase.dart` — replace langchain `ChatResult` with dartantic `ChatResult`. Update stream consumption pattern.
- [ ] T015 [US3] Update `messages_streaming_notifier.dart` in `apps/auravibes_app/lib/features/chats/notifiers/messages_streaming_notifier.dart` — replace langchain `ChatResult` with dartantic `ChatResult`.
- [ ] T016 [US3] Update `streaming_runtime_provider.dart` in `apps/auravibes_app/lib/features/chats/providers/streaming_runtime_provider.dart` — replace langchain `ChatResult` with dartantic `ChatResult`.
- [ ] T017 [US1] Update `chatbot_service.dart` title generation — replace `PromptValue.chat()` with `Agent.send()` using `ChatMessageAdapter`. Verify title extraction from response.

### Tests

- [ ] T018 [P] [US1] Update `build_prompt_chat_messages_test.dart` in `apps/auravibes_app/test/services/chatbot_service/build_prompt_chat_messages_test.dart` — replace `HumanChatMessage`/`AIChatMessage`/`ToolChatMessage` assertions with dartantic `ChatMessage` type checks.
- [ ] T019 [P] [US3] Update `continue_agent_usecase_test.dart` in `apps/auravibes_app/test/features/chats/usecases/continue_agent_usecase_test.dart` — replace langchain `ChatResult`/`AIChatMessage`/`LanguageModelUsage`/`FinishReason` mocks with dartantic equivalents.
- [ ] T020 [P] [US3] Update `chat_messages_provider_test.dart` in `apps/auravibes_app/test/features/chats/providers/chat_messages_provider_test.dart` — replace langchain `ChatResult`/`AIChatMessage`/`FinishReason`/`LanguageModelUsage` mocks with dartantic equivalents.

**Checkpoint**: Core chat works end-to-end with streaming. User can send messages and receive responses.

---

## Phase 4: User Story 2 — Tool-Assisted Conversations (Priority: P2)

**Goal**: All tool types (built-in, native, MCP) work with dartantic_ai agent.

**Independent Test**: User asks a question that triggers a tool call. The tool executes, result integrates into the AI response.

### Implementation

- [ ] T021 [US2] Convert `calculator_tool.dart` in `apps/auravibes_app/lib/services/tools/user_tools/calculator_tool.dart` — replace `Tool.fromFunction<>()` with dartantic `Tool(name, description, inputSchema, onCall)`. Remove `ToolSpec`, `Tool`, `ToolOptions` langchain imports.
- [ ] T022 [US2] Convert `url_tool.dart` in `apps/auravibes_app/lib/services/tools/native_tools/url_tool.dart` — replace `Tool.fromFunction<>()` with dartantic `Tool(name, description, inputSchema, onCall)`. Remove langchain imports.
- [ ] T023 [US2] Update `native_tool_entity.dart` in `apps/auravibes_app/lib/services/tools/native_tool_entity.dart` — replace langchain `ToolSpec` return type with domain `ToolSpec` (from T003). Remove langchain import.
- [ ] T024 [US2] Update `user_tools_entity.dart` in `apps/auravibes_app/lib/services/tools/user_tools_entity.dart` — replace langchain `ToolSpec` return type with domain `ToolSpec` (from T003). Remove langchain import.
- [ ] T025 [US2] Update `load_conversation_tool_specs_usecase.dart` in `apps/auravibes_app/lib/features/tools/usecases/load_conversation_tool_specs_usecase.dart` — replace langchain `ToolSpec` with domain `ToolSpec`. Remove langchain import.
- [ ] T026 [US2] Update `build_combined_tool_specs_usecase.dart` in `apps/auravibes_app/lib/domain/usecases/tools/mcp/build_combined_tool_specs_usecase.dart` — replace langchain `ToolSpec` with domain `ToolSpec`. Remove langchain import.
- [ ] T027 [US2] Update `mcp_tool_spec_lookup_provider.dart` in `apps/auravibes_app/lib/features/tools/providers/mcp_tool_spec_lookup_provider.dart` — replace langchain `ToolSpec` with domain `ToolSpec`. Remove langchain import.
- [ ] T028 [US2] Update `mcp_connection_notifier.dart` in `apps/auravibes_app/lib/notifiers/mcp_connection_notifier.dart` — replace langchain `ToolSpec` return type with domain `ToolSpec`. Remove langchain import. MCP connection logic stays unchanged per FR-014.
- [ ] T029 [US2] Wire `ToolAdapter` (from T005) into `ChatbotService` — convert domain `ToolSpec` list to dartantic `Tool` list before passing to `Agent`.

### Tests

- [ ] T030 [P] [US2] Update `load_conversation_tool_specs_usecase_test.dart` in `apps/auravibes_app/test/features/tools/usecases/load_conversation_tool_specs_usecase_test.dart` — replace langchain `ToolSpec` with domain `ToolSpec` assertions.
- [ ] T031 [P] [US2] Update `build_combined_tool_specs_usecase_test.dart` in `apps/auravibes_app/test/domain/usecases/tools/mcp/build_combined_tool_specs_usecase_test.dart` — replace langchain `ToolSpec` with domain `ToolSpec` assertions.

**Checkpoint**: All tool types work. Built-in, native, and MCP tools execute via dartantic_ai agent.

---

## Phase 5: User Story 4 — Multi-Provider Support (Priority: P3)

**Goal**: All dartantic_ai built-in providers are selectable and functional.

**Independent Test**: User selects a different provider (Google, Mistral, etc.) and starts a conversation that routes correctly.

### Implementation

- [ ] T032 [US4] Expand `ProviderFactory` in `apps/auravibes_app/lib/services/chatbot_service/provider_factory.dart` — add mapping for all dartantic_ai built-in providers (OpenAI, Anthropic, Google, Mistral, Cohere, Ollama, OpenRouter, xAI, xAI-Responses). Map models.dev vendor identifiers to dartantic provider prefixes.
- [ ] T033 [US4] Add custom endpoint support in `ProviderFactory` — when `baseUrl` is provided, create `OpenAIProvider(apiKey: ..., baseUrl: Uri.parse(baseUrl), headers: customHeaders)` and use `Agent.forProvider(provider)`.
- [ ] T034 [US4] Update `ProviderFactory` test in `apps/auravibes_app/test/services/chatbot_service/provider_factory_test.dart` — verify all 10 built-in provider prefixes resolve correctly. Verify custom URL routing.

**Checkpoint**: All providers selectable. Custom endpoints work.

---

## Phase 6: User Story 5 — Token Usage Tracking (Priority: P3)

**Goal**: Token usage (prompt, response, total) accurately recorded per conversation.

**Independent Test**: After a conversation, token counts are persisted and displayed within 5% tolerance.

### Implementation

- [ ] T035 [US5] Verify `chat_result_extension.dart` token extraction in `apps/auravibes_app/lib/utils/chat_result_extension.dart` — confirm dartantic `LanguageModelUsage` fields (`.promptTokens`, `.responseTokens`, `.totalTokens`) map correctly to domain token tracking. Already updated in T013; this task validates accuracy.
- [ ] T036 [US5] Verify token persistence — ensure streamed `ChatResult` final chunk contains usage data and is correctly saved to conversation metadata via existing Drift schema.

**Checkpoint**: Token usage accurate and persisted.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final cleanup, validation, and removal of all langchain remnants

- [ ] T037 Search entire `apps/auravibes_app/` for any remaining `langchain` or `langchain_` imports. Remove all references.
- [ ] T038 [P] Add streaming integration test in `apps/auravibes_app/test/services/chatbot_service/chatbot_service_test.dart` — verify end-to-end streaming with message history, tool calls, and token usage extraction using dartantic types.
- [ ] T039 [P] Add provider integration test in `apps/auravibes_app/test/services/chatbot_service/provider_factory_test.dart` — verify OpenAI and Anthropic provider creation with real configuration shapes (mocked HTTP).
- [ ] T040 Run `fvm dart format --set-exit-if-changed .` in `apps/auravibes_app/`
- [ ] T041 Run `fvm dart analyze --fatal-infos` in `apps/auravibes_app/`
- [ ] T042 Run `fvm flutter test --no-pub` in `apps/auravibes_app/`
- [ ] T043 Run `fvm dart run melos run validate` from monorepo root
- [ ] T044 Verify quickstart.md steps work by running the migration checklist in `specs/004-migrate-langchain-dartantic/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **US1+US3 Core Chat (Phase 3)**: Depends on Phase 2 — MVP delivery
- **US2 Tools (Phase 4)**: Depends on Phase 2. Can start in parallel with Phase 3 but T029 (wire ToolAdapter) depends on T010 (ChatbotService rewrite)
- **US4 Multi-Provider (Phase 5)**: Depends on Phase 3 (T010 ChatbotService rewrite). ProviderFactory expanded after core chat works.
- **US5 Token Usage (Phase 6)**: Depends on Phase 3 (T013 chat_result_extension)
- **Polish (Phase 7)**: Depends on all user stories complete

### User Story Dependencies

```
Phase 1 (Setup)
  └── Phase 2 (Foundational)
        ├── Phase 3 (US1+US3: Chat+Streaming) ← MVP
        │     └── Phase 5 (US4: Multi-Provider)
        │     └── Phase 6 (US5: Token Usage)
        ├── Phase 4 (US2: Tools) [partial parallel with Phase 3]
        │     └── T029 depends on T010
        └── Phase 7 (Polish) ← after all stories
```

### Parallel Opportunities

- T004, T005, T006, T007, T008, T009 can all run in parallel (different files)
- T018, T019, T020 can run in parallel (different test files)
- T030, T031 can run in parallel (different test files)
- T038, T039 can run in parallel (different test files)

---

## Parallel Example: Phase 2

```text
# All foundational adapters and tests can be built simultaneously:
Task: "Create ChatMessageAdapter in apps/auravibes_app/lib/services/chatbot_service/chat_message_adapter.dart"
Task: "Create ToolAdapter in apps/auravibes_app/lib/services/chatbot_service/tool_adapter.dart"
Task: "Create ProviderFactory in apps/auravibes_app/lib/services/chatbot_service/provider_factory.dart"
Task: "Add test for ChatMessageAdapter in apps/auravibes_app/test/services/chatbot_service/chat_message_adapter_test.dart"
Task: "Add test for ToolAdapter in apps/auravibes_app/test/services/chatbot_service/tool_adapter_test.dart"
Task: "Add test for ProviderFactory in apps/auravibes_app/test/services/chatbot_service/provider_factory_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1+3 Only)

1. Complete Phase 1: Setup (T001–T002)
2. Complete Phase 2: Foundational (T003–T009)
3. Complete Phase 3: US1+US3 Core Chat (T010–T020)
4. **STOP and VALIDATE**: Test basic chat with streaming independently
5. If working → continue to tools and providers

### Full Migration (All User Stories)

1. Setup + Foundational → Adapters ready
2. Core Chat + Streaming → MVP (US1+US3)
3. Tool System → Tools functional (US2)
4. Multi-Provider → All providers available (US4)
5. Token Usage → Accurate tracking (US5)
6. Polish → Clean, validated, production-ready

---

## Notes

- Big-bang migration: all tasks land in a single commit/PR
- MCP connection logic preserved per FR-014; only `ToolSpec` type reference changes
- No rollback per clarification — fix forward only
- All dartantic_ai built-in providers enabled per clarification
- Domain `ToolSpec` (T003) replaces langchain `ToolSpec` throughout codebase
- Verify `fvm` prefix on all Dart/Flutter commands per AGENTS.md
