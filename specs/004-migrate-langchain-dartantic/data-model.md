# Data Model: LangChain → dartantic_ai Migration

**Date**: 2026-04-21  
**Feature**: Migrate AI Orchestration Framework

---

## Entity Mapping Overview

This migration replaces framework-level types while preserving all domain entities. No database schema changes are required.

### Preserved Domain Entities (No Changes)

| Entity                                          | Storage        | Status    |
| ----------------------------------------------- | -------------- | --------- |
| **Conversation**                                | Drift (SQLite) | Unchanged |
| **MessageEntity**                               | Drift (SQLite) | Unchanged |
| **MessageToolCallEntity**                       | Drift (SQLite) | Unchanged |
| **WorkspaceModelSelectionWithConnectionEntity** | Drift (SQLite) | Unchanged |
| **Provider Configuration**                      | Drift (SQLite) | Unchanged |

### Replaced Framework Types

| Domain Concept    | Old Type (LangChain)                        | New Type (dartantic_ai)                           |
| ----------------- | ------------------------------------------- | ------------------------------------------------- |
| Chat model        | `BaseChatModel`                             | `Agent`                                           |
| Provider instance | `ChatOpenAI`, `ChatAnthropic`               | `Agent('openai')`, `Agent('anthropic')`           |
| Chat message      | `ChatMessage`                               | `ChatMessage`                                     |
| User message      | `ChatMessage.humanText()`                   | `ChatMessage.user()`                              |
| Assistant message | `ChatMessage.ai()`                          | `ChatMessage.assistant()`                         |
| Tool message      | `ChatMessage.tool()`                        | `ChatMessage.tool()`                              |
| Tool call         | `AIChatMessageToolCall`                     | `ToolCall`                                        |
| Tool spec         | `ToolSpec`                                  | `Tool` (unified)                                  |
| Executable tool   | `Tool.fromFunction()`                       | `Tool(name, description, inputSchema, onCall)`    |
| Prompt wrapper    | `PromptValue.chat()`                        | `List<ChatMessage>` (passed directly)             |
| Stream result     | `ChatResult`                                | `ChatResult`                                      |
| Token usage       | `LanguageModelUsage`                        | `LanguageModelUsage`                              |
| Finish reason     | `FinishReason`                              | Inferred from output                              |
| Model options     | `ChatOpenAIOptions`, `ChatAnthropicOptions` | Provider-specific options via `Agent` constructor |

---

## Message Conversion Flow

```
MessageEntity (domain)
  → ChatMessage (dartantic)
    → Agent.sendStream(history: [...])
      → ChatResult (stream chunk)
        → MessageEntity (domain, persisted)
```

### Conversion Rules

1. **User message** (`isUser == true`):
   - Input: `MessageEntity` with role `user`
   - Output: `ChatMessage.user(content: entity.content)`

2. **Assistant message** (`isUser == false`, no tool calls):
   - Input: `MessageEntity` with role `assistant`
   - Output: `ChatMessage.assistant(content: entity.content)`

3. **Assistant message with tool calls**:
   - Input: `MessageEntity` with `toolCalls` list
   - Output: `ChatMessage.assistant(content: entity.content, toolCalls: mappedCalls)`

4. **Tool result message**:
   - Input: `MessageEntity` with role `tool`
   - Output: `ChatMessage.tool(content: entity.content, toolCallId: entity.toolCallId)`

5. **System message**:
   - Input: System prompt string
   - Output: `ChatMessage.system(content: prompt)`

---

## Tool Conversion Flow

### Built-in Tools

```
NativeToolEntity
  → ToolSpec (existing, from LangChain)
    → Tool (dartantic)
```

**Mapping**:

- `name` → `name`
- `description` → `description`
- `inputJsonSchema` → `inputSchema` (via `Schema.fromMap()`)
- `execute()` function → `onCall` callback

### MCP Tools

```
McpServer
  → getToolSpec() → ToolSpec (existing)
    → Tool (dartantic)
```

**Note**: MCP tool specs are converted to dartantic `Tool` at the boundary where they are passed to the agent.

---

## Provider Configuration Mapping

### Built-in Provider Prefixes

| Provider      | dartantic Prefix | Default Model                 | API Key Env          |
| ------------- | ---------------- | ----------------------------- | -------------------- |
| OpenAI        | `openai`         | `gpt-4o`                      | `OPENAI_API_KEY`     |
| Anthropic     | `anthropic`      | `claude-sonnet-4-0`           | `ANTHROPIC_API_KEY`  |
| Google        | `google`         | `gemini-2.5-flash`            | `GEMINI_API_KEY`     |
| Mistral       | `mistral`        | `mistral-small-latest`        | `MISTRAL_API_KEY`    |
| Cohere        | `cohere`         | `command-r-08-2024`           | `COHERE_API_KEY`     |
| Ollama        | `ollama`         | `qwen2.5:7b-instruct`         | None (local)         |
| OpenRouter    | `openrouter`     | `google/gemini-2.5-flash`     | `OPENROUTER_API_KEY` |
| xAI           | `xai`            | `grok-4-1-fast-non-reasoning` | `XAI_API_KEY`        |
| xAI Responses | `xai-responses`  | `grok-4-1-fast-non-reasoning` | `XAI_API_KEY`        |

### Custom Provider

```dart
final provider = OpenAIProvider(
  apiKey: apiKey,
  baseUrl: Uri.parse(customUrl),
  headers: customHeaders,
);
final agent = Agent.forProvider(provider);
```

---

## State Transitions (Conversation Lifecycle)

No state transitions change. The same lifecycle applies:

1. **Created**: Conversation initialized with provider config
2. **Active**: Messages streaming, tools executing
3. **Completed**: Response finished, tokens recorded
4. **Error**: Failure handled, error context passed to AI

---

## Validation Rules

- Provider prefix MUST map to a dartantic_ai built-in provider or a registered custom provider
- Model ID MUST be valid for the selected provider
- Custom base URL MUST be a valid HTTP/HTTPS URI
- Tool schemas MUST conform to JSON Schema draft-07
- API keys MUST be decrypted before passing to provider constructors
