# Data Model: Conversation Token Usage Indicator

## Entity: MessageMetadataEntity (extended)

Represents persisted metadata for one chat message.

### Fields

- `toolCalls: List<MessageToolCallEntity>` (existing)
- `promptTokens: int?` (new)
- `completionTokens: int?` (new)
- `totalTokens: int?` (new)

### Validation Rules

- Token fields are optional.
- When present, values are non-negative integers.
- Serialization remains JSON-compatible with previous metadata payloads.

## Derived View Model: ConversationTokenUsage

Runtime-only aggregate used by chat top bar.

### Fields

- `usedTokens: int`
- `limitTokens: int`
- `percentUsed: int` (0..100)
- `progress: double` (0.0..1.0)

### Derivation Rules

For each message:

1. `messageUsed = totalTokens ?? (promptTokens + completionTokens) ?? 0`
2. Conversation used = sum(`messageUsed`) across conversation messages.
3. If a message is currently streaming, overlay with latest `ChatResult.usage`-derived value.
4. `percentUsed = clamp(round((usedTokens / limitTokens) * 100), 0, 100)` when `limitTokens > 0`, else `0`.
5. `progress = percentUsed / 100`.

## State Transitions

1. Assistant message created as unfinished with initial metadata.
2. During stream, message content and metadata updated incrementally.
3. On completion, final metadata persisted with final usage snapshot.
