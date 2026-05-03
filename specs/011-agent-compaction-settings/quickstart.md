# Quickstart: Agent Conversation Compaction Settings

## Prerequisites

- Run commands from repository root.
- Use FVM-pinned SDK.

```bash
fvm dart run melos bs
```

## Implementation Flow

1. Extend message metadata entity/model with compaction fields and metadata version.
2. Implement/adjust compaction use cases:
   - compact conversation
   - auto-compaction eligibility check
   - prompt selection from latest summary
3. Integrate auto check before assistant continuation.
4. Add UI states:
   - conversation list temporary `Compacting` row
   - chat transcript `Compacted` widget with detail tap
5. Treat active compaction as busy for send; reuse existing queue.
6. Persist raw compaction content; normalize only for payload-building path.
7. Add/adjust compaction settings section and validation.

## Manual Validation Scenarios

### Manual compaction

1. Open chat with eligible history.
2. Trigger manual compact.
3. Confirm transcript shows `Compacted` widget.
4. Tap widget and verify details show original untrimmed stored text.
5. Confirm no automatic assistant continuation starts.

### Auto compaction

1. Enable auto compaction and set thresholds for test trigger.
2. Send a message that crosses thresholds.
3. Confirm temporary `Compacting` row appears in conversation list.
4. Confirm compaction completes before continuation.
5. Confirm row disappears after completion.

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

### Payload normalization vs storage fidelity

1. Create compaction content with extra whitespace/newlines.
2. Inspect stored compaction details view; verify whitespace preserved.
3. Inspect outbound payload construction path/log/test fixtures; verify normalized version used.

## Suggested Verification Commands

```bash
fvm flutter test test/features/chats/usecases --no-pub
fvm flutter test test/features/chats/widgets --no-pub
fvm flutter test test/features/settings --no-pub
fvm dart run melos analyze
fvm dart run melos format
fvm dart run melos run test
```
