# Research: LangChain → dartantic_ai Migration

**Date**: 2026-04-21  
**Feature**: Migrate AI Orchestration Framework  
**Scope**: Service layer replacement within `apps/auravibes_app`

---

## Decision Log

### 1. Framework Choice: dartantic_ai

**Decision**: Use `dartantic_ai` (v3.4.0) as the replacement for LangChain Dart.

**Rationale**:

- Active maintenance (last published 2026-04-02) vs. LangChain Dart which has been lagging
- Simpler unified API across all providers
- Built-in retry logic, streaming, tool calling, MCP support, and embeddings
- Better Flutter ecosystem integration (optional `dartantic_chat` package)
- Supports all required features: custom base URLs, custom headers, streaming, tool calling, token usage tracking

**Alternatives considered**:

- Keep LangChain Dart: Rejected due to maintenance concerns and limited provider support
- Use raw HTTP clients per provider: Rejected due to excessive boilerplate and loss of unified abstractions
- Use `ollama_dart` + other SDKs directly: Rejected due to fragmentation

### 2. Migration Strategy: Big-Bang

**Decision**: Replace all LangChain usage in a single commit/PR.

**Rationale**:

- LangChain types permeate the service layer; partial migration would create hybrid state
- 22 files affected but mostly concentrated in 3-4 core service files
- dartantic_ai provides a clean break with no need for transitional abstractions
- User explicitly chose big-bang during clarification

**Risk mitigation**:

- Comprehensive test coverage required before merge
- Feature branch isolation allows full validation
- No runtime toggles or fallback code needed

### 3. Provider Scope: All Built-In Providers

**Decision**: Enable all dartantic_ai built-in providers via models.dev integration.

**Rationale**:

- dartantic_ai ships with 10+ providers (OpenAI, Anthropic, Google, Mistral, Cohere, Ollama, OpenRouter, xAI, etc.)
- models.dev already provides dynamic LLM vendor fetching
- Minimal extra work once the first provider is wired correctly

**Implementation note**:

- Provider configuration mapping needs to translate models.dev vendor IDs to dartantic_ai provider prefixes
- Custom provider endpoints use `OpenAIProvider(baseUrl: ...)` via `Agent.forProvider()`

### 4. MCP Integration: Preserve Existing

**Decision**: Keep the existing custom MCP connection manager and tool spec lookup.

**Rationale**:

- MCP infrastructure is separate from the LangChain chat model layer
- dartantic_ai has built-in `McpClient`, but migration scope should be focused
- Existing MCP code works with `ToolSpec` which is conceptually similar to dartantic's `Tool`
- Reduces risk by not touching working MCP code

### 5. Tool System: Adapt to dartantic Tool API

**Decision**: Convert tool definitions from LangChain's `ToolSpec` + `Tool.fromFunction` to dartantic_ai's `Tool` class.

**Rationale**:

- dartantic_ai unifies tool schema and execution in a single `Tool` class
- Input schema uses `Schema.fromMap()` or `S.object()` instead of raw JSON schema maps
- `onCall` callback replaces `Tool.fromFunction` pattern
- Built-in tools (calculator, URL fetcher) need conversion
- MCP tools remain unchanged since they use existing infrastructure

**Mapping**:
| LangChain | dartantic_ai |
|-----------|-------------|
| `ToolSpec(name, description, inputJsonSchema)` | `Tool(name, description, inputSchema, onCall)` |
| `Tool.fromFunction<Input, Output>()` | `Tool(name, description, inputSchema, onCall)` |
| `ToolOptions` | Not needed (options embedded in `Tool`) |

### 6. Message Format: dartantic ChatMessage

**Decision**: Convert domain `MessageEntity` objects to dartantic_ai's `ChatMessage` format.

**Rationale**:

- dartantic_ai uses `ChatMessage` list for history instead of LangChain's `ChatMessage.humanText()` / `.ai()` / `.tool()` factory constructors
- History is passed explicitly to each `agent.send()` / `agent.sendStream()` call
- Message parts include text, tool calls, tool results, and thinking parts

**Mapping**:
| LangChain | dartantic_ai |
|-----------|-------------|
| `ChatMessage.humanText(content)` | `ChatMessage.user(content)` |
| `ChatMessage.ai(content, toolCalls: ...)` | `ChatMessage.assistant(content, toolCalls: ...)` |
| `ChatMessage.tool(content, toolCallId: ...)` | `ChatMessage.tool(content, toolCallId: ...)` |
| `PromptValue.chat(messages)` | Pass `List<ChatMessage>` directly |

### 7. Streaming: agent.sendStream()

**Decision**: Use `agent.sendStream()` for streaming responses.

**Rationale**:

- Returns `Stream<ChatResult>` just like LangChain's `BaseChatModel.stream()`
- Chunks have `.output` (string) and `.usage` properties
- Accumulate chunks with `.concat()` equivalent (manual accumulation or use result)

**Mapping**:
| LangChain | dartantic_ai |
|-----------|-------------|
| `model.stream(PromptValue.chat(messages))` | `agent.sendStream(prompt, history: messages)` |
| `ChatResult.outputAsString` | `ChatResult.output` (or chunk text) |
| `ChatResult.concat(results)` | Manual accumulation or use final result |

### 8. Token Usage: LanguageModelUsage

**Decision**: Use dartantic_ai's `LanguageModelUsage` for token tracking.

**Rationale**:

- dartantic_ai exposes `result.usage.promptTokens`, `responseTokens`, `totalTokens`
- Same structure as LangChain's `LanguageModelUsage`
- Minimal changes needed in `chat_result_extension.dart`

### 9. Testing Strategy: Existing + Targeted New Tests

**Decision**: All existing tests pass + add new tests for dartantic-specific integration.

**Rationale**:

- Existing tests validate user-facing behavior (regression prevention)
- New tests cover provider initialization, message mapping, and streaming behavior
- dartantic_ai has different internal types that need mock coverage

**New test areas**:

- Provider factory mapping (models.dev vendor → dartantic provider)
- Message entity → dartantic ChatMessage conversion
- Tool spec → dartantic Tool conversion
- Streaming chunk accumulation
- Custom base URL / header configuration

---

## Open Questions Resolved

| Question            | Resolution                                           | Source           |
| ------------------- | ---------------------------------------------------- | ---------------- |
| Custom URL support? | `OpenAIProvider(baseUrl: Uri.parse(...))`            | dartantic docs   |
| Custom headers?     | `headers: {...}` on any provider                     | dartantic docs   |
| Tool calling API?   | `Tool` class with `inputSchema` + `onCall`           | dartantic docs   |
| MCP support?        | Built-in `McpClient` available, but we keep existing | Clarification Q4 |
| All providers?      | Yes, enable all built-in providers                   | Clarification Q3 |
| Rollback?           | No rollback, fix forward                             | Clarification Q2 |

---

## Risk Assessment

| Risk                          | Likelihood | Impact | Mitigation                        |
| ----------------------------- | ---------- | ------ | --------------------------------- |
| dartantic_ai API changes      | Low        | High   | Pin version, monitor changelog    |
| Provider-specific quirks      | Medium     | Medium | Test each major provider category |
| Tool call format differences  | Medium     | Medium | Comprehensive tool tests          |
| Streaming behavior changes    | Low        | High   | Validate token-by-token output    |
| Performance regression        | Low        | Medium | Benchmark before/after            |
| Missing provider in dartantic | Low        | High   | Verify models.dev vendor mapping  |
