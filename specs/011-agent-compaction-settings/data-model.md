# Data Model: Agent Conversation Compaction Settings

## Compaction Settings

Global app preference controlling automatic compaction.

### Fields

- `autoCompactionEnabled`: boolean, default `true`.
- `usagePercentageThreshold`: integer percent, default `80`.
- `remainingTokenThreshold`: integer token count, default `4000`.
- `updatedAt`: timestamp for diagnostics/debug display if needed.

### Validation

- `usagePercentageThreshold` must be between `5` and `100`, inclusive.
- `remainingTokenThreshold` must be greater than `0`.
- If selected model context limit is known, `remainingTokenThreshold` must be lower than that context limit before auto compaction can run for that conversation.
- Reset restores all default values.

### Persistence

- Stored as global app settings.
- Applies to all conversations.
- Later features may add workspace/model overrides without changing MVP behavior.

## Message Metadata Compaction Fields

Existing message metadata is extended to describe compaction summaries.

### Fields

- `metadataVersion`: integer, required for new metadata writes, default `1` for legacy reads.
- `toolCalls`: existing list of tool-call metadata.
- `promptTokens`: existing optional prompt token count.
- `completionTokens`: existing optional completion token count.
- `totalTokens`: existing optional total token count.
- `isCompactionSummary`: boolean, default `false`.
- `compactionKind`: enum, nullable; values `manual` or `auto`.
- `compactedFromMessageId`: string, nullable; first message represented by this summary.
- `compactedThroughMessageId`: string, nullable; last message represented by this summary.
- `compactedMessageIds`: list of strings, default empty; message ids represented by this summary.
- `compactionCreatedAt`: timestamp, nullable.

### Validation

- If `isCompactionSummary` is `true`, `compactionKind`, `compactedFromMessageId`, `compactedThroughMessageId`, `compactionCreatedAt`, and at least one `compactedMessageIds` entry are required.
- If `isCompactionSummary` is `true`, `toolCalls` must be empty.
- If `isCompactionSummary` is `false`, compaction range fields should be absent or ignored.
- Compaction summary metadata must never mark unresolved tool-call content as compacted unless the full tool-call/result group is safely represented.

## Compaction Summary Message

A persisted message that contains the summary text used as model context for future responses.

### Fields

- `id`: existing message id.
- `conversationId`: existing conversation id.
- `content`: summary text.
- `messageType`: system.
- `isUser`: false.
- `status`: sent.
- `metadata`: `MessageMetadataEntity` with `isCompactionSummary = true`.
- `createdAt` / `updatedAt`: existing timestamps.

### Rules

- Compaction summary messages do not contain thinking output.
- Compaction summary messages do not contain tool calls.
- Compaction summary messages remain in the persisted conversation but may be hidden or rendered specially in the chat list.
- A newer compaction summary supersedes older compaction summaries for prompt selection.

## Compaction Range

The ordered conversation segment represented by a compaction summary.

### Fields

- `fromMessageId`: first compacted message.
- `throughMessageId`: last compacted message.
- `messageIds`: ordered compacted message ids.
- `kind`: `manual` or `auto`.

### Rules

- Range must be non-empty.
- Range must not include the new compaction summary message itself.
- Range must not split an unresolved tool call, pending approval, or tool result from the assistant message that produced it.
- Range should include all prior prompt-relevant messages before the new compaction summary.

## Prompt Message Selection

Derived list sent to the LLM agent service.

### Selection Rules

1. Load conversation messages in chronological order.
2. Find the latest sent message where metadata marks `isCompactionSummary = true`.
3. If no compaction summary exists, send all prompt-eligible messages.
4. If a compaction summary exists, send that compaction summary message and every later prompt-eligible message.
5. Exclude prompt-ineligible UI-only/error/unfinished messages according to existing prompt rules.
6. Map compaction summary/system messages as model context, not assistant tool output.

### Invariants

- The selected prompt list must never include both a compaction summary and messages older than that summary.
- The selected prompt list must never include tool-call metadata on the compaction summary.
- A conversation with no compaction summary behaves exactly as before.

## State Transitions

### Manual Compaction

1. User presses compact.
2. App validates conversation eligibility.
3. App generates summary.
4. App writes summary message with `compactionKind = manual`.
5. Future prompt selection starts at the summary message.

### Auto Compaction

1. Assistant continuation prepares to build prompt.
2. App checks settings and context thresholds.
3. App validates conversation eligibility.
4. App generates summary.
5. App writes summary message with `compactionKind = auto`.
6. Current continuation uses prompt selection from the latest summary.

### Failure

1. Summary generation or persistence fails.
2. No compaction summary is written.
3. No message range is marked compacted.
4. Manual path shows recoverable failure without continuing the assistant.
5. Required auto path blocks the pending assistant continuation and persists a visible chat error message.
