# Feature Specification: Migrate AI Orchestration Framework

**Feature Branch**: `004-migrate-langchain-dartantic`  
**Created**: 2026-04-21  
**Status**: Draft  
**Input**: User description: "the change from LangChain to dartantic_ai"

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Seamless Chat Experience (Priority: P1)

As an end user, I can start a conversation, send messages, and receive AI responses so that I can interact with the assistant without any disruption.

**Why this priority**: Chat is the core feature of the application. Any regression here directly impacts all users.

**Independent Test**: A user can open a new conversation, type a message, and receive a coherent response. The experience must be indistinguishable from the current implementation.

**Acceptance Scenarios**:

1. **Given** a new conversation, **When** the user sends a text message, **Then** the AI responds with a relevant answer within the same time bounds as before.
2. **Given** an ongoing conversation, **When** the user sends a follow-up message, **Then** the AI retains context and responds appropriately.
3. **Given** a conversation with multiple messages, **When** the user scrolls through history, **Then** all messages display correctly with proper sender attribution.

---

### User Story 2 - Tool-Assisted Conversations (Priority: P2)

As an end user, I can ask questions that require tools (such as calculations or web lookups) so that the AI can provide accurate, real-time information.

**Why this priority**: Tool calling is a key differentiator. Users expect the assistant to perform actions beyond simple text generation.

**Independent Test**: A user can ask a question that triggers a built-in tool, and the AI seamlessly incorporates the tool result into its response.

**Acceptance Scenarios**:

1. **Given** a conversation with no active tools, **When** the user asks for a calculation, **Then** the calculator tool executes and the AI includes the correct result.
2. **Given** a conversation with external tools enabled, **When** the user asks for a web page summary, **Then** the URL fetch tool retrieves content and the AI summarizes it.
3. **Given** a conversation with MCP tools connected, **When** the user invokes an MCP capability, **Then** the tool executes and the response is integrated into the chat.
4. **Given** a tool call that fails, **When** the error occurs, **Then** the AI receives the error context and responds gracefully without crashing.

**Agent Loop Architecture**: The app manages the agent loop using `ChatModel.sendStream()` directly (not `Agent.sendStream()`) to prevent dartantic from auto-executing tools. The flow is: model call -> detect tool calls in response -> check permissions via `ApproveToolCallUsecase` -> execute approved tools via `RunAllowedToolsUsecase` -> feed results back as tool messages -> loop. This ensures all tool invocations go through the user approval pipeline.

Example flows:

- **Tool execution**: User asks "What is 2+2?" -> AI generates `calculator` tool call -> app intercepts, auto-approves built-in tool -> calculator returns `4` -> AI incorporates result into response.
- **Tool failure**: User triggers URL fetch -> tool times out -> error wrapped as tool result -> AI acknowledges error and suggests alternatives.

---

### User Story 3 - Streaming Responses (Priority: P2)

As an end user, I can see the AI response appear word-by-word in real time so that the interaction feels responsive and engaging.

**Why this priority**: Streaming is a critical UX feature. Removing it would make the app feel slow and unresponsive.

**Independent Test**: A user can send a message and observe tokens appearing incrementally rather than waiting for the full response.

**Acceptance Scenarios**:

1. **Given** a stable network connection, **When** the user sends a message, **Then** the response streams token-by-token without stuttering or duplication.
2. **Given** a long-running response, **When** the stream is active, **Then** the UI remains responsive and the user can scroll and interact.
3. **Given** a streaming response with tool calls, **Then** the tool execution happens seamlessly and the final output incorporates results correctly.

---

### User Story 4 - Multi-Provider Support (Priority: P3)

As a power user or administrator, I can configure and switch between different AI providers (such as OpenAI, Anthropic, Google, Mistral, and others) so that I can choose models based on preference, cost, or capability.

**Why this priority**: Provider flexibility is important for advanced users but not required for basic chat functionality.

**Independent Test**: A user can select a different provider in settings and start a new conversation that routes to the selected provider.

**Acceptance Scenarios**:

1. **Given** provider configuration for OpenAI, **When** a conversation starts, **Then** messages route to the OpenAI endpoint.
2. **Given** provider configuration for Anthropic, **When** a conversation starts, **Then** messages route to the Anthropic endpoint.
3. **Given** provider configuration for any dartantic_ai built-in provider (e.g., Google, Mistral, Cohere), **When** a conversation starts, **Then** messages route to the selected provider's endpoint.
4. **Given** a custom provider endpoint URL, **When** configured, **Then** requests route to that URL instead of the default.

---

### User Story 5 - Token Usage Tracking (Priority: P3)

As a user or administrator, I can view token usage statistics for conversations so that I can monitor consumption and costs.

**Why this priority**: Usage tracking supports billing transparency and optimization but does not block core chat functionality.

**Independent Test**: After a conversation, the token count for prompt and response is accurately recorded and visible.

**Acceptance Scenarios**:

1. **Given** a completed conversation, **When** the user views conversation details, **Then** prompt tokens, response tokens, and total tokens are displayed accurately.
2. **Given** a conversation with tool calls, **When** the usage is calculated, **Then** token counts reflect both chat and tool-related overhead correctly.

---

### Edge Cases

- What happens when the configured API key is invalid or expired? The system should surface a clear error message (e.g., "Authentication failed. Please check your API key in Settings.") without crashing.
- What happens when a tool call times out or returns an unexpected format? The AI should receive an error result and attempt to recover. The partial response is preserved with error status.
- What happens when the network disconnects mid-stream? The partial response should be preserved and the user notified.
- What happens when switching providers mid-conversation? The conversation history should remain intact and the new provider should receive correct context.
- What happens when a provider returns empty or malformed usage metadata? The system should handle gracefully without breaking the UI. Token counts default to 0.

## Clarifications

### Session 2026-04-21

- **Q: Should this be a big-bang replacement or gradual rollout?** → **A: Big-bang** — Replace all LangChain usage in a single commit/PR. All providers switch simultaneously.
- **Q: Should the migration include a documented rollback procedure?** → **A: No rollback** — Once deployed, issues are fixed forward. No reversion to LangChain is planned or documented.
- **Q: Should the migration enable additional dartantic_ai providers beyond OpenAI and Anthropic?** → **A: Enable all dartantic providers** — The system uses models.dev to dynamically fetch LLM vendors, so all dartantic_ai built-in providers should be configured and available.
- **Q: Should the migration replace the existing custom MCP integration with dartantic_ai's built-in McpClient?** → **A: Keep existing MCP** — Retain the current custom MCP connection manager and tool spec lookup. MCP tool specs are normalized to domain `ToolSpec` entities and converted to dartantic `Tool` objects via `ToolAdapter` for registration with `ChatModel`. Actual tool invocation still routes through the app's agent loop and MCP manager. Only the LangChain chat model and tool execution layers are replaced.
- **Q: Should new tests be added for dartantic_ai-specific behavior, or only existing tests must pass?** → **A: Existing + targeted new tests** — All existing tests must pass, plus new tests are added for dartantic_ai-specific integration points (provider setup, message mapping, streaming behavior).

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: The system MUST support sending messages to AI providers and receiving text responses.
- **FR-002**: The system MUST stream AI responses token-by-token in real time.
- **FR-003**: The system MUST support multi-turn conversations with persistent history across messages.
- **FR-004**: The system MUST support built-in tools (e.g., calculator, URL fetcher). Tool execution is app-controlled via the approval pipeline — tools are not auto-executed by the AI framework.
- **FR-005**: The system MUST support external tools via the Model Context Protocol (MCP), allowing integration with third-party tool servers.
- **FR-006**: The system MUST support multiple AI providers and allow per-conversation or per-workspace provider selection. All dartantic_ai built-in providers MUST be available for selection.
- **FR-007**: The system MUST support custom provider endpoint URLs and custom HTTP headers for enterprise or proxy configurations.
- **FR-008**: The system MUST track and expose token usage (prompt tokens, response tokens, total tokens) for each AI interaction.
- **FR-009**: The system MUST generate conversation titles automatically based on the initial user message.
- **FR-010**: The system MUST handle tool execution errors gracefully, passing error context back to the AI for recovery.
- **FR-011**: The system MUST preserve all existing conversation data and behavior without requiring user action or data migration.
- **FR-012**: The system MUST maintain the same performance characteristics for first-token latency and total response time.
- **FR-013**: The migration MUST be performed as a big-bang replacement: all LangChain usage is removed and replaced with dartantic_ai in a single deployment. No gradual or partial migration is permitted.
- **FR-014**: The existing custom MCP integration (connection manager, tool spec lookup, and related infrastructure) MUST be preserved. Only the LangChain-specific chat model and tool execution layers are replaced.

### Key Entities _(include if feature involves data)_

- **Conversation**: A sequence of messages between a user and the AI. Attributes include title, provider configuration, creation timestamp, and associated workspace.
- **Message**: A single unit of communication within a conversation. Attributes include sender role (user/assistant/tool), content text, tool calls, tool results, token usage, and timestamps.
- **Tool**: A callable capability exposed to the AI. Attributes include name, description, input schema, and execution logic. Tools may be built-in, native, or sourced from external MCP servers.
- **Provider Configuration**: Settings defining which AI provider and model to use. Attributes include provider type, model identifier, base endpoint URL, API credentials reference, and custom headers.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: Users can complete a multi-turn conversation without experiencing regressions in response quality, latency, or functionality.
- **SC-002**: 100% of existing automated tests related to chat, tools, and streaming pass without modification to test assertions. Additionally, new targeted tests are added for dartantic_ai-specific integration points including provider initialization, message format conversion, and streaming behavior.
- **SC-003**: Token usage counts for prompt and response remain accurate within a 5% tolerance compared to the previous implementation.
- **SC-004**: First-token latency and end-to-end response time for equivalent prompts do not degrade by more than 10%.
- **SC-005**: All supported tool types (built-in, native, MCP) execute successfully and return results integrated into the AI response.
- **SC-006**: Custom provider endpoints and headers function identically to default endpoints, with no additional configuration steps required beyond URL and header input.
- **SC-007**: All dartantic_ai built-in providers are selectable and functional, with chat and streaming capabilities verified for each major provider category.
