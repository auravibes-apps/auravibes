import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import 'sync_wakeups.dart';

class const WorkspaceStreamService() {
  static const pageSize = 100;
  static const pollInterval = Duration(seconds: 1);

  Stream<WorkspaceStreamEnvelope> subscribe(
    Session session, {
    required WorkspaceSubscribeRequest request,
    required String userId,
  }) async* {
    if (request.afterSequence < 0) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.invalidCursor,
      );
    }

    final wakeups = StreamIterator<WorkspaceSubscribeRequest>(
      session.messages.createStream<WorkspaceSubscribeRequest>(
        SyncWakeups.workspaceChannel(request.workspaceId),
      ),
    );
    var cursor = request.afterSequence;
    Future<bool>? pendingWakeup;
    try {
      while (true) {
        await _requireMembership(session, request.workspaceId, userId);
        final events = await WorkspaceEvent.db.find(
          session,
          where: (table) =>
              table.workspaceId.equals(request.workspaceId) &
              (table.sequence > cursor),
          orderBy: (table) => table.sequence,
          limit: pageSize,
        );

        for (final event in events) {
          cursor = event.sequence;
          yield envelopeFor(event);
        }

        if (events.length < pageSize) {
          final wakeup = pendingWakeup ??= wakeups.moveNext().whenComplete(
            () => pendingWakeup = null,
          );
          await Future.any<void>([
            wakeup.then<void>((_) {}),
            Future<void>.delayed(pollInterval),
          ]);
        }
      }
    } finally {
      await wakeups.cancel();
    }
  }

  static WorkspaceStreamEnvelope envelopeFor(WorkspaceEvent event) =>
      WorkspaceStreamEnvelope(
        kind: WorkspaceStreamEnvelopeKind.workspaceInvalidated,
        workspaceId: event.workspaceId,
        sequence: event.sequence,
        eventId: event.eventId,
        eventKind: event.kind,
        resourceKind: event.resourceKind,
        resourceId: event.resourceId,
        payloadJson: event.payloadJson,
        createdAt: event.createdAt,
      );

  Future<void> _requireMembership(
    Session session,
    int workspaceId,
    String userId,
  ) async {
    final member = await WorkspaceMember.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.userId.equals(userId) &
          table.removedAt.equals(null),
    );
    if (member == null) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.membershipRequired,
      );
    }
  }
}
