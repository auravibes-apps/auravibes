# Contract: Message Conversion Interface

**Scope**: Conversion between domain entities and framework chat messages  
**Consumer**: `ChatbotService`, `BuildPromptChatMessagesUsecase`, tests

---

## Interface

```dart
/// Converts domain message entities to framework-specific chat messages.
///
/// This abstraction isolates the framework from the domain layer,
/// allowing the framework to be replaced without changing domain entities.
class MessageConverter {
  /// Converts a list of domain messages to framework chat messages.
  ///
  /// [messages] - Domain entities from the conversation history
  /// [systemPrompt] - Optional system prompt to prepend
  ///
  /// Returns ordered list of framework chat messages ready for the model.
  List<ChatMessage> toFrameworkMessages(
    List<MessageEntity> messages, {
    String? systemPrompt,
  });

  /// Converts a framework chat result to a domain message entity.
  ///
  /// [result] - The completed chat result from the framework
  /// [conversationId] - Parent conversation identifier
  ///
  /// Returns a domain message entity ready for persistence.
  MessageEntity toDomainMessage(
    ChatResult result, {
    required String conversationId,
  });

  /// Extracts token usage from a framework result.
  ///
  /// [result] - Chat result containing usage metadata
  ///
  /// Returns token usage statistics or null if unavailable.
  TokenUsage? extractTokenUsage(ChatResult result);
}

/// Token usage statistics.
class TokenUsage {
  final int? promptTokens;
  final int? responseTokens;
  final int? totalTokens;

  TokenUsage({
    this.promptTokens,
    this.responseTokens,
    this.totalTokens,
  });
}
```

---

## Conversion Rules

### Domain → Framework

| Domain Role | Domain Properties                       | Framework Type                                      |
| ----------- | --------------------------------------- | --------------------------------------------------- |
| `user`      | `content: String`                       | `ChatMessage.user(content)`                         |
| `assistant` | `content: String`, no tool calls        | `ChatMessage.assistant(content)`                    |
| `assistant` | `content: String`, `toolCalls: [...]`   | `ChatMessage.assistant(content, toolCalls: mapped)` |
| `tool`      | `content: String`, `toolCallId: String` | `ChatMessage.tool(content, toolCallId: id)`         |
| `system`    | `content: String`                       | `ChatMessage.system(content)`                       |

### Tool Call Mapping

```dart
List<ToolCall> mapToolCalls(List<MessageToolCallEntity> entities) {
  return entities.map((e) => ToolCall(
    id: e.id,
    name: e.name,
    arguments: e.arguments,
  )).toList();
}
```

### Framework → Domain

| Framework Output          | Domain Properties                               |
| ------------------------- | ----------------------------------------------- |
| `result.output` (text)    | `content: output`, `role: assistant`            |
| `result.output.toolCalls` | `toolCalls: mapped`                             |
| `result.usage`            | `promptTokens`, `responseTokens`, `totalTokens` |

---

## Framework-Specific Details

### LangChain (Before)

```dart
// Message creation
ChatMessage.humanText('Hello');
ChatMessage.ai(content: 'Hi!', toolCalls: [...]);
ChatMessage.tool('Result', toolCallId: 'call_123');

// Prompt wrapper
final prompt = PromptValue.chat(messages);

// Result extraction
final text = result.outputAsString;
final toolCalls = result.output.toolCalls;
final usage = result.usage;
```

### dartantic_ai (After)

```dart
// Message creation
ChatMessage.user('Hello');
ChatMessage.assistant('Hi!', toolCalls: [...]);
ChatMessage.tool('Result', toolCallId: 'call_123');

// No prompt wrapper needed — pass list directly
final stream = agent.sendStream('Hello', history: messages);

// Result extraction
final text = result.output;
final toolCalls = result.toolCalls; // or from messages
final usage = result.usage;
```

---

## Invariants

1. **Order preservation**: Messages MUST maintain chronological order after conversion
2. **Idempotency**: Same domain input MUST produce same framework output
3. **Immutability**: Converter MUST NOT mutate input lists or entities
4. **Completeness**: All domain message types MUST have a framework mapping
5. **Reversibility**: Framework output MUST contain enough information to create a valid domain entity

---

## Error Contract

| Error Condition      | Behavior                                         |
| -------------------- | ------------------------------------------------ |
| Unknown message role | Throw `ArgumentError` with clear message         |
| Malformed tool call  | Skip tool call, log warning, continue conversion |
| Missing tool call ID | Generate synthetic ID, log warning               |
| Null content         | Convert to empty string `""`                     |

---

## Performance Contract

- **Conversion time**: O(n) where n = message count, must complete in <10ms for 100 messages
- **Memory**: No intermediate copies of message content (pass by reference where possible)
- **Streaming**: Incremental conversion not needed — full history converted once per request
