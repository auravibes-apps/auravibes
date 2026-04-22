# Contract: ChatbotService Interface

**Scope**: Service layer contract for AI chat interactions  
**Consumer**: `ContinueAgentUsecase`, `MessagesStreamingNotifier`, title generation

---

## Interface

```dart
abstract class ChatbotService {
  /// Sends a message and returns a stream of response chunks.
  ///
  /// [message] - The user's input text
  /// [history] - Previous conversation messages (domain entities)
  /// [tools] - Available tools for this conversation
  /// [providerConfig] - Selected provider and model configuration
  ///
  /// Returns a stream of [ChatResult] chunks that can be concatenated
  /// to form the complete response.
  Stream<ChatResult> sendMessage({
    required String message,
    required List<MessageEntity> history,
    required List<Tool> tools,
    required ProviderConfiguration providerConfig,
  });

  /// Generates a title for a new conversation based on the first message.
  ///
  /// [message] - The first user message
  /// [providerConfig] - Provider configuration for title generation
  ///
  /// Returns the generated title string.
  Future<String> generateTitle({
    required String message,
    required ProviderConfiguration providerConfig,
  });
}
```

---

## Key Changes from LangChain

| Aspect         | Before (LangChain)                          | After (dartantic_ai)                                  |
| -------------- | ------------------------------------------- | ----------------------------------------------------- |
| Model type     | `BaseChatModel`                             | `Agent`                                               |
| Model creation | `ChatOpenAI(...)`, `ChatAnthropic(...)`     | `Agent('provider:model')` or `Agent.forProvider(...)` |
| Options        | `ChatOpenAIOptions`, `ChatAnthropicOptions` | Constructor parameters on `Agent`                     |
| Prompt wrapper | `PromptValue.chat(messages)`                | Pass `List<ChatMessage>` directly to `sendStream()`   |
| Streaming      | `model.stream(promptValue)`                 | `agent.sendStream(prompt, history: messages)`         |

---

## Invariants

1. **Provider initialization MUST NOT block** the UI thread
2. **Stream MUST emit at least one chunk** for every valid request
3. **Usage metadata MUST be available** on the final chunk of the stream
4. **Error in stream MUST be catchable** by the consumer without crashing the app
5. **History MUST be immutable** — the service must not mutate the input list

---

## Error Contract

The service MUST handle these errors and surface them via the stream:

| Error Condition        | Behavior                                                        |
| ---------------------- | --------------------------------------------------------------- |
| Invalid API key        | Stream emits error with clear message                           |
| Network timeout        | Stream emits error after configured timeout                     |
| Invalid model ID       | Stream emits error before first chunk                           |
| Tool execution failure | Error context passed back to AI, stream continues               |
| Rate limit             | Automatic retry with exponential backoff (handled by dartantic) |

---

## Provider Configuration Mapping

```dart
class ProviderConfiguration {
  final String providerType;      // e.g., 'openai', 'anthropic', 'google'
  final String modelId;           // e.g., 'gpt-4o', 'claude-sonnet-4-0'
  final String? baseUrl;          // Custom endpoint (optional)
  final Map<String, String>? customHeaders;  // Custom headers (optional)
  final String apiKey;            // Decrypted API key
}
```

**Mapping to dartantic**:

- Built-in providers: `Agent('${providerType}:${modelId}')`
- Custom endpoint: `Agent.forProvider(OpenAIProvider(apiKey: ..., baseUrl: Uri.parse(baseUrl!)))`
- Custom headers: Passed to provider constructor

---

## Performance Contract

- **First-token latency**: <2 seconds for standard prompts
- **Stream chunk interval**: Tokens emitted as received from provider
- **Memory per stream**: Bounded by conversation context window
- **Concurrent streams**: Single stream per conversation (serialized by UI)
