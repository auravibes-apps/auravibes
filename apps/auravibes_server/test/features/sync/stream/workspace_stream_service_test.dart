import 'package:auravibes_server/src/features/sync/stream/workspace_stream_service.dart';
import 'package:auravibes_server/src/features/sync/stream/sync_wakeups.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('uses tenant-scoped canonical wakeup channels', () {
    expect(SyncWakeups.workspaceChannel(7), 'auravibes.workspace.7');
    expect(
      SyncWakeups.conversationJobsChannel,
      'auravibes.conversation.jobs',
    );
  });

  test('maps durable events to workspace invalidations', () {
    final createdAt = DateTime.utc(2026, 7, 11);

    final invalidation = WorkspaceStreamService.envelopeFor(
      WorkspaceEvent(
        eventId: 'event-1',
        workspaceId: 7,
        sequence: 11,
        actorUserId: 'user-1',
        kind: 'workspace.patched',
        resourceKind: 'workspace',
        createdAt: createdAt,
      ),
    );
    expect(
      invalidation.kind,
      WorkspaceStreamEnvelopeKind.workspaceInvalidated,
    );
  });
}
