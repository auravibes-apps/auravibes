import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../workspace_state/workspace_table_access.dart';
import '../workspace_views/workspace_view_store.dart';

class const WorkspaceContextStore(
  final Session session,
  final int workspaceId,
  final String conversationId,
  final String actorUserId,
) {
  Future<String> read() => session.db.transaction((transaction) async {
    final context = await _authorize(transaction);
    final event = await WorkspaceConversationContext.db.findFirstRow(
      session,
      where: (row) =>
          row.workspaceId.equals(workspaceId) &
          row.conversationId.equals(context.conversation.id) &
          row.actorUserId.equals(actorUserId),
      orderBy: (row) => row.id.desc(),
      transaction: transaction,
    );
    final selection = _decode(event?.selectionJson);
    if (selection != null)
      await _validate(selection, context.member, transaction);
    return jsonEncode({
      'id': event?.stableId,
      'selection': selection?.toJson(),
    });
  });

  Future<String> save(
    String requestId,
    String? selectionJson,
  ) => session.db.transaction((transaction) async {
    final context = await _authorize(transaction);
    if (requestId.isEmpty || requestId.length > 100) _invalid();
    final selection = _decode(selectionJson);
    if (selectionJson != null && selection == null) _invalid();
    if (selection != null)
      await _validate(selection, context.member, transaction);
    final encoded = selection == null ? null : jsonEncode(selection.toJson());
    final previous = await WorkspaceConversationContext.db.findFirstRow(
      session,
      where: (row) =>
          row.workspaceId.equals(workspaceId) & row.stableId.equals(requestId),
      transaction: transaction,
    );
    if (previous != null) {
      if (previous.conversationId != context.conversation.id ||
          previous.actorUserId != actorUserId ||
          previous.selectionJson != encoded) {
        throw CloudWorkspaceException(code: .idempotencyConflict);
      }
      return jsonEncode({
        'id': previous.stableId,
        'selection': selection?.toJson(),
      });
    }
    await WorkspaceConversationContext.db.insertRow(
      session,
      WorkspaceConversationContext(
        workspaceId: workspaceId,
        conversationId: context.conversation.id!,
        stableId: requestId,
        actorUserId: actorUserId,
        selectionJson: encoded,
        createdAt: DateTime.now().toUtc(),
      ),
      transaction: transaction,
    );
    return jsonEncode({'id': requestId, 'selection': selection?.toJson()});
  });

  WorkspaceContextSelection? _decode(String? value) {
    if (value == null) return null;
    return WorkspaceContextSelection.decode(
      jsonDecode(value),
      '$workspaceId',
      conversationId,
    );
  }

  Future<({WorkspaceMember member, Conversation conversation})> _authorize(
    Transaction transaction,
  ) async {
    final workspace = await CloudWorkspace.db.findById(
      session,
      workspaceId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (workspace == null) _denied();
    final member = await WorkspaceMember.db.findFirstRow(
      session,
      where: (row) =>
          row.workspaceId.equals(workspaceId) &
          row.userId.equals(actorUserId) &
          row.removedAt.equals(null),
      transaction: transaction,
    );
    if (member == null) _denied();
    final conversation = await Conversation.db.findFirstRow(
      session,
      where: (row) =>
          row.workspaceId.equals(workspaceId) &
          row.stableId.equals(conversationId) &
          row.deletedAt.equals(null),
      transaction: transaction,
    );
    if (conversation == null) _denied();
    return (member: member, conversation: conversation);
  }

  Future<void> _validate(
    WorkspaceContextSelection selection,
    WorkspaceMember member,
    Transaction transaction,
  ) async {
    if (selection.kind == 'directory') {
      if (selection.itemId.isNotEmpty || selection.recordIds.isNotEmpty)
        _invalid();
      return;
    }
    if (selection.kind == 'view') {
      final view = await WorkspaceViewStore(
        session,
        member,
        transaction,
      ).read(selection.itemId);
      final data = jsonDecode(view.data) as Map<String, dynamic>;
      await _records(
        selection.recordIds,
        data['tableId'] as String,
        member,
        transaction,
      );
      return;
    }
    final kind = selection.kind == 'folder'
        ? WorkspaceResourceKind.folder
        : WorkspaceResourceKind.table;
    final item = await _visible(kind, selection.itemId, member, transaction);
    if (kind == .folder && selection.recordIds.isNotEmpty) _invalid();
    if (kind == .table)
      await _records(selection.recordIds, item.resourceId, member, transaction);
  }

  Future<void> _records(
    List<String> ids,
    String tableId,
    WorkspaceMember member,
    Transaction transaction,
  ) async {
    for (final id in ids) {
      final record = await _visible(.tableRecord, id, member, transaction);
      if ((jsonDecode(record.data) as Map)['tableId'] != tableId) _denied();
    }
  }

  Future<WorkspaceResource> _visible(
    WorkspaceResourceKind kind,
    String id,
    WorkspaceMember member,
    Transaction transaction,
  ) async {
    final row = await WorkspaceResource.db.findFirstRow(
      session,
      where: (row) =>
          row.workspaceId.equals(workspaceId) &
          row.resourceKind.equals(kind) &
          row.resourceId.equals(id) &
          row.deletedAt.equals(null),
      transaction: transaction,
    );
    if (row == null) _denied();
    final visible = await WorkspaceTableAccess(transaction: transaction)
        .visible(session, member, row);
    if (visible == null) _denied();
    return visible;
  }
}

Never _denied() => throw CloudWorkspaceException(code: .permissionDenied);
Never _invalid() => throw CloudWorkspaceException(code: .validationFailed);
