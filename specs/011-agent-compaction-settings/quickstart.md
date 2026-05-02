# Quickstart: Agent Conversation Compaction Settings

## Prerequisites

- Use repository-pinned SDK commands with `fvm`.
- Run from repo root.
- Bootstrap workspace if dependencies are missing:

```bash
fvm dart run melos bs
```

## Development Flow

1. Add compaction metadata fields to message metadata.
2. Regenerate Freezed/JSON/Riverpod code:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

3. Add compaction settings notifier and settings UI section.
4. Add manual compact mutation and chat input control.
5. Add compaction use cases:
   - compact conversation
   - should auto compact
   - select prompt messages from latest compaction
6. Wire auto compaction before assistant continuation prompt building.
7. Update prompt mapping for system/compaction messages.

## Verification Scenarios

### Manual Compaction

1. Open a conversation with several sent messages.
2. Press compact in the chat input area.
3. Verify a summary message is created with compaction metadata kind `manual`.
4. Verify visible conversation history remains available.
5. Send another message.
6. Verify prompt selection starts at the latest compaction summary.

### Auto Compaction

1. Enable auto compaction in settings.
2. Set thresholds low enough for a test conversation.
3. Send a message in an eligible conversation.
4. Verify compaction occurs before assistant continuation.
5. Verify summary metadata kind is `auto`.

### Settings

1. Open Settings > Compaction.
2. Toggle auto compaction.
3. Change percentage and remaining-token thresholds.
4. Save and restart app.
5. Verify settings persist.
6. Try invalid values and verify save is blocked.

### Tool Safety

1. Create or simulate a conversation with pending tool approval.
2. Verify manual compact is disabled.
3. Verify auto compaction does not run.
4. Resolve tool approval/result.
5. Verify compaction can run after the tool state is safe.

## Suggested Checks

Focused checks during implementation:

```bash
fvm flutter test test/features/chats/usecases --no-pub
fvm flutter test test/features/settings --no-pub
```

Repo-level checks before completion:

```bash
fvm dart run melos analyze
fvm dart run melos format
fvm dart run melos run test
```
