# Data Model: Agent Conversation Compaction Settings

## CompactionSettings

Per-workspace compaction settings stored in Drift workspace_compaction_settings table.

### Fields

- `autoCompactionEnabled`: bool, default `true`
- `usagePercentageThreshold`: int percent, default `80`
- `remainingTokenThreshold`: int, default dynamic value `max(maxOutputTokens, 20% of selected model context limit)` capped at `15000`
- `updatedAt`: DateTime, optional diagnostics

### Validation Rules

- `usagePercentageThreshold` must be within the accepted UI range, recommended `5..100` inclusive.
- `remainingTokenThreshold` must be greater than `0`.
- If selected model context limit is known, `remainingTokenThreshold` must be lower than that context limit to be saveable.
- Reset restores auto-enabled `true`, usage percentage `80`, and dynamic remaining-token default.

## ConversationPromptEstimate

Derived estimate used by automatic compaction policy.

### Fields

- `conversationId`: String
- `selectedModelId`: String
- `selectedProviderId`: String
- `estimatedPromptTokens`: int
- `contextLimit`: int?
- `maxOutputTokens`: int
- `remainingTokens`: int?
- `usagePercentage`: double?

### Rules

- If `contextLimit` is unknown, percentage-based auto compaction must not run.
- Estimates may use provider response usage plus conservative local approximation until exact tokenizers are available.
- The estimate is advisory for triggering; provider context-overflow errors still use retry-once recovery.

## CompactionDecision

Result of deterministic policy evaluation.

### Fields

- `shouldCompact`: bool
- `reason`: enum `disabled | belowPercentageThreshold | aboveRemainingTokenThreshold | unsafeState | eligible | unknownContextLimit`
- `trigger`: enum `auto | manual`
- `estimate`: ConversationPromptEstimate?
- `settings`: CompactionSettings

### Rules

- Auto compaction requires enabled settings, safe conversation state, and either usage percentage at or above threshold or remaining tokens at or below threshold.
- Manual compaction does not require automatic threshold conditions but still requires enough eligible context and safe conversation state.

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
- Compaction summaries must not carry thinking output or tool-call metadata.
- Non-summary messages must ignore or omit compaction range fields.
- Existing message rows without compaction fields are treated as non-summary messages.

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

## CompactionRange

Set of messages represented by a compaction summary.

### Fields

- `fromMessageId`: String
- `throughMessageId`: String
- `messageIds`: List<String>
- `keptTailMessageIds`: List<String>

### Rules

- Range must not include unresolved tool approvals, active tool calls, unsent/sending/error messages, or failed messages unless explicitly handled.
- Range must not split an assistant tool call from its result representation.
- Range must keep at least the latest user turn, latest assistant turn, and complete tool-call/result groups outside compacted content.
- Range must not include both a previous compaction summary and messages already represented by it unless recursive replacement is explicitly implemented.

## AgentCompactionRequest

Command sent to the AI agent service for summary generation.

### Fields

- `conversationId`: String
- `modelProviderId`: String matching active conversation provider
- `modelId`: String matching active conversation model
- `systemPrompt`: localized/internal compaction-specific instructions
- `messagesToCompact`: ordered prompt-safe message content and metadata facts
- `trigger`: enum `manual | auto`

### Rules

- Must use the same provider/model selected for the active conversation.
- Must use a compaction-specific system prompt that preserves goals, constraints, decisions, current status, files/identifiers, errors/resolutions, pending tasks, and concise tool-output facts.
- Must instruct the model not to invent unseen code state, preserve sensitive tool output verbatim, or mark unresolved tool calls as completed.

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
- Summary is emitted as system/context content before the unsummarized recent tail.

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
- Indicates blocked continuation reason and recovery path.

## ContextOverflowRetryState

Ephemeral guard preventing repeated assistant-request retries after context overflow.

### Fields

- `conversationId`: String
- `assistantRequestId`: String
- `hasRetriedAfterCompaction`: bool

### Rules

- A provider context-overflow failure can trigger safe auto compaction and retry once.
- Retry must not run if compaction is unsafe or if the request has already retried.
