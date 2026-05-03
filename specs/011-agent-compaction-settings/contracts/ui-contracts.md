# UI and Behavior Contracts: Agent Conversation Compaction Settings

## Settings Section Contract

### Controls

- Dedicated compaction settings section.
- Auto compaction enabled toggle.
- Usage percentage threshold field/control.
- Remaining-token threshold field/control.
- Reset-to-default action.

### Validation

- Reject percentage values outside the accepted range, recommended `5..100` inclusive.
- Reject remaining-token threshold values less than or equal to `0`.
- Reject remaining-token threshold values greater than or equal to a known selected model context limit.
- Show localized validation messages and keep previous saved values until save succeeds.

### Defaults

- Auto compaction enabled: `true`.
- Usage percentage threshold: `80`.
- Remaining-token threshold: `max(maxOutputTokens, 20% of selected model context limit)`, capped at `15000`.

## Chat Input Manual Compact Contract

### Control

- Located in chat input controls.
- Localized tooltip/label.
- Uses existing app/UI component patterns.

### Enabled/Disabled Conditions

Enabled when:

- Conversation has compactable context.
- Conversation can safely keep the latest user turn, latest assistant turn, and complete tool-call/result groups outside the compacted range.
- No unresolved tool approval/call constraints.
- Conversation is not busy.

Disabled when:

- Conversation has no eligible range.
- Tool approval unresolved or unsafe compaction boundary.
- Manual compaction already running.
- Existing conversation busy state prevents new actions.

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
- Detail view renders stored original compaction content with no storage-time trim normalization.

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
- The prompt payload must not include both compacted predecessor messages and their summary.
- Prompt payload normalization is allowed only during payload construction; stored summary content remains unchanged.

## Agent Summary Generation Contract

- Compaction summary generation calls the AI agent service.
- Request uses the same model provider and model selected for the active conversation.
- Request includes a compaction-specific system prompt.
- Prompt instructs preservation of user goals, constraints, decisions, current status, files/identifiers, errors/resolutions, pending tasks, and concise tool-output facts.
- Prompt forbids inventing unseen state, preserving sensitive tool output verbatim, or completing unresolved tool calls.

## Storage vs Payload Content Contract

- Persist compaction summary `content` exactly as generated.
- Do not trim/normalize at persistence.
- Apply trimming/normalization only in model payload construction path.

## Required Auto-Compaction Failure Contract

- If auto compaction is required and fails, assistant continuation is blocked.
- Persist visible localized recoverable error message.
- Do not modify compaction boundary metadata on failure.

## Context Overflow Retry Contract

- If an assistant continuation fails with provider context overflow and safe compaction is possible, compact eligible context and retry once.
- Do not retry more than once for the same assistant request.
- If compaction is unsafe or retry fails, follow required auto-compaction failure behavior.
