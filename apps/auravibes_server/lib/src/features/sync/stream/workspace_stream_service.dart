import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../accounts/auth_user_lock.dart';
import '../../workspace_state/repositories/workspace_state_repository.dart';
import '../../workspace_state/workspace_table_access.dart';
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
        final events = await session.db.transaction((transaction) async {
          final member = await _requireMembership(
            session,
            request.workspaceId,
            userId,
            transaction,
          );
          final rows = await WorkspaceEvent.db.find(
            session,
            where: (table) =>
                table.workspaceId.equals(request.workspaceId) &
                (table.sequence > cursor),
            orderBy: (table) => table.sequence,
            limit: pageSize,
            transaction: transaction,
          );
          final access = WorkspaceTableAccess(transaction: transaction);
          return [
            for (final event in rows)
              await access.visibleEvent(session, member, event),
          ];
        });

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

  Future<WorkspaceMember> _requireMembership(
    Session session,
    int workspaceId,
    String userId,
    Transaction transaction,
  ) async {
    final authUser = await const AuthUserLock().lock(
      session,
      userId: userId,
      transaction: transaction,
    );
    if (authUser == null) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.authenticationRequired,
      );
    }
    final repository = WorkspaceStateRepository();
    final workspace = await repository.findWorkspace(
      session,
      workspaceId,
      transaction: transaction,
      lock: true,
    );
    final member = await repository.findMember(
      session,
      workspaceId: workspaceId,
      userId: userId,
      transaction: transaction,
    );
    if (workspace == null || member == null) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.membershipRequired,
      );
    }
    return member;
  }
}
