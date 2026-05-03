# UI and Behavior Contracts: Agent Conversation Compaction Settings

## Chat Input Manual Compact Contract

### Control

- Located in chat input controls.
- Localized tooltip/label.
- Uses existing app/UI component patterns.

### Enabled/Disabled Conditions

Enabled when:

- Conversation has compactable context.
- No unresolved tool approval/call constraints.
- Conversation not in blocked state.

Disabled when:

- Conversation has no eligible range.
- Tool approval unresolved or unsafe compaction boundary.
- Manual compaction already running.

### Feedback

- Start: visible running state.
- Success: checkpoint created, no auto-continue.
- Failure: visible recoverable localized error.

## Conversation List Compacting Contract

- While compaction executes (manual or auto), list shows a separate temporary `Compacting` row with tool-like loading.
- Existing conversation row remains unchanged.
- Temporary row is removed on success or failure.

## Chat Transcript Compacted Widget Contract

- Every compaction summary appears as a visible `Compacted` widget in chat transcript.
- Widget indicates manual/auto origin.
- Tap opens detail view analogous to tool-result inspection.
- Detail view renders stored original compaction content (no storage-time trim normalization).

## Send Queue During Compaction Contract

- Active compaction is treated as a busy condition for send flow.
- Messages sent while compaction is active use existing queue implementation.
- After compaction success, queued messages are sent in original order.
- Queue behavior and ordering rules remain single-source-of-truth in existing queue subsystem.

## Prompt Selection Contract

- Input: ordered persisted messages for a conversation.
- Boundary anchor: latest sent message with `metadata.isCompactionSummary = true`.
- If no anchor exists: include all prompt-eligible messages.
- If anchor exists: include anchor and all later prompt-eligible messages.
- Summary is context/system content, never tool-call output.

## Storage vs Payload Content Contract

- Persist compaction summary `content` exactly as generated.
- Do not trim/normalize at persistence.
- Apply trimming/normalization only in model payload construction path.

## Required Auto-Compaction Failure Contract

- If auto compaction is required and fails, assistant continuation is blocked.
- Persist visible localized recoverable error message.
- Do not modify compaction boundary metadata on failure.
