# Quickstart: Agent Conversation Compaction Settings

## Prerequisites

- Run commands from repository root.
- Use FVM-pinned SDK.

```bash
fvm dart run melos bs
```

## Implementation Flow

1. Extend message metadata entity/model with compaction fields and metadata version.
2. Add global compaction settings persistence and validation for enabled state, percentage threshold, remaining-token threshold, and reset defaults.
3. Implement compaction use cases:
   - prompt-token estimate
   - deterministic auto-compaction eligibility check
   - safe compaction-range selection
   - AI-agent-service summary generation with active conversation provider/model
   - prompt selection from latest summary
4. Integrate auto check before assistant continuation.
5. Add provider context-overflow recovery: compact safely and retry the assistant request once.
6. Add UI states:
   - settings compaction section
   - conversation list temporary `Compacting` row
   - chat transcript `Compacted` widget with detail tap
7. Treat active compaction as busy for send; reuse existing queue.
8. Persist raw compaction content; normalize only for payload-building path.
9. Add localized typed errors for invalid settings, failed compaction, unsafe compaction, unavailable context limits, and retry failure.

## Manual Validation Scenarios

### Settings threshold editing

1. Open settings.
2. Navigate to compaction section.
3. Change auto compaction enabled state, usage percentage threshold, and remaining-token threshold.
4. Save and restart the app.
5. Confirm saved settings remain active.
6. Enter invalid values and confirm localized validation prevents saving.
7. Reset to defaults and confirm the remaining-token default uses the dynamic capped safety gap.

### Manual compaction below automatic thresholds

1. Open chat with eligible history below automatic thresholds.
2. Trigger manual compact.
3. Confirm transcript shows `Compacted` widget.
4. Tap widget and verify details show original untrimmed stored text.
5. Confirm no automatic assistant continuation starts.

### Auto compaction

1. Enable auto compaction and set thresholds for test trigger.
2. Send a message that crosses both thresholds.
3. Confirm temporary `Compacting` row appears in conversation list.
4. Confirm compaction uses the AI agent service with the active conversation provider/model.
5. Confirm compaction completes before continuation.
6. Confirm row disappears after completion.

### Safe recent tail and tool boundaries

1. Create a conversation with user, assistant, and tool-call/result messages.
2. Trigger compaction.
3. Confirm the compacted range excludes at least the latest user turn, latest assistant turn, and complete tool-call/result groups.
4. Confirm no unresolved tool call or pending approval is split from its result.

### Queue during compaction

1. Start compaction.
2. Send multiple user messages while compaction runs.
3. Confirm messages enter existing queue.
4. Confirm queued messages send in original order after compaction completes.

### Required auto-compaction failure

1. Force compaction failure when thresholds require compaction.
2. Attempt continuation.
3. Confirm continuation is blocked.
4. Confirm visible recoverable error message is persisted.
5. Confirm no compaction boundary changes are applied.

### Context-overflow retry

1. Force a provider context-overflow error during assistant continuation.
2. Confirm safe auto compaction runs.
3. Confirm the assistant request retries exactly once.
4. Confirm a second failure does not trigger another retry and follows recoverable failure behavior.

### Payload normalization vs storage fidelity

1. Create compaction content with extra whitespace/newlines.
2. Inspect stored compaction details view; verify whitespace preserved.
3. Inspect outbound payload construction path/test fixtures; verify normalized version used.

## Suggested Verification Commands

```bash
fvm flutter test test/features/chats/usecases --no-pub
fvm flutter test test/features/chats/widgets --no-pub
fvm flutter test test/features/settings --no-pub
fvm flutter test test/services/chatbot_service --no-pub
fvm dart run melos analyze
fvm dart run melos format
fvm dart run melos run test
```
