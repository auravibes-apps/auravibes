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
- `percentUsed: int` (raw percent; may exceed 100 when usage overflows limit)
- `progress: double` (clamped 0.0..1.0)

### Derivation Rules

1. `usedTokens` is taken from the latest assistant message usage (with streaming overlay when in-progress).
2. `percentUsed = round((usedTokens / limitTokens) * 100)` when `limitTokens > 0`, else `0`.
3. `progress = clamp(percentUsed / 100, 0.0, 1.0)`.

## State Transitions

1. Assistant message created as unfinished with initial metadata.
2. During stream, message content and metadata updated incrementally.
3. On completion, final metadata persisted with final usage snapshot.
