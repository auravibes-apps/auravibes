# Data Model: Agent Conversation Compaction Settings

## CompactionSettings

Global app-level preferences controlling auto-compaction behavior.

### Fields

- `autoCompactionEnabled`: bool, default `true`
- `usagePercentageThreshold`: int percent, default `80`
- `remainingTokenThreshold`: int, default `4000`
- `updatedAt`: DateTime, optional diagnostics

### Validation Rules

- `usagePercentageThreshold` in accepted range (spec-defined; currently 5-100 inclusive).
- `remainingTokenThreshold` > 0.
- If selected model context limit known, threshold must be lower than model context limit to be saveable.
- Reset restores defaults.

## MessageMetadata (extended)

Existing metadata JSON structure with compaction fields.

### Existing Fields (unchanged)

- `toolCalls`
- `promptTokens`
- `completionTokens`
- `totalTokens`

### New Fields

- `metadataVersion`: int (required on new writes)
- `isCompactionSummary`: bool, default `false`
- `compactionKind`: enum `manual | auto`, nullable when not summary
- `compactedFromMessageId`: String?
- `compactedThroughMessageId`: String?
- `compactedMessageIds`: List<String>, default `[]`
- `compactionCreatedAt`: DateTime?

### Metadata Invariants

- If `isCompactionSummary == true`, `compactionKind`, range fields, timestamp, and non-empty `compactedMessageIds` are required.
- Compaction summaries must not carry tool-call metadata.
- Non-summary messages must ignore/omit compaction range fields.

## CompactionSummaryMessage

Persisted message row representing compacted context.

### Fields

- `id`, `conversationId`, `createdAt`, `updatedAt`: existing message identity/timestamps
- `messageType`: `system`
- `isUser`: `false`
- `status`: `sent`
- `content`: summary text stored in original untrimmed form
- `metadata`: `MessageMetadata` with compaction fields populated

### Behavior Rules

- Visible in chat transcript as dedicated `Compacted` widget.
- Tappable to open compaction details view.
- Used as prompt boundary anchor.
- Must not contain thinking output or tool-call metadata.

## CompactionExecutionState

Ephemeral UI/domain state for an ongoing compaction run.

### Fields

- `conversationId`: String
- `trigger`: enum `manual | auto`
- `startedAt`: DateTime
- `status`: enum `running | success | failure`

### Behavior Rules

- While `running`, conversation list shows temporary `Compacting` row.
- While `running`, send flow treats conversation as busy and routes sends through existing queue.
- Row is removed when status changes to `success` or `failure`.

## PromptPayloadSegment (derived)

Derived message list sent to model.

### Construction Rules

1. Load prompt-eligible conversation messages in chronological order.
2. Find latest sent message with `metadata.isCompactionSummary == true`.
3. If none exists, include all prompt-eligible messages.
4. If one exists, include that summary and all later prompt-eligible messages.
5. Apply content normalization (trim/whitespace handling) at payload-build time only.

### Invariants

- Never include both compacted-predecessor content and its summary.
- Stored message content remains unchanged by payload normalization.

## AutoCompactionFailureMessage

Persisted visible recoverable error message when required auto compaction fails.

### Fields

- Existing message identity fields
- `messageType`: `system`
- `status`: `error`
- Localized user-facing failure content/key
- Metadata without `isCompactionSummary`

### Rules

- Visible in chat transcript.
- Does not move prompt compaction boundary.
- Indicates blocked continuation reason.
