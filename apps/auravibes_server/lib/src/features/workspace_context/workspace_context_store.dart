import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/auth_user_lock.dart';
import '../workspace_state/workspace_table_access.dart';
import '../workspace_views/workspace_view_store.dart';

class const WorkspaceContextStore(
  final Session session,
  final int workspaceId,
  final String conversationId,
  final String actorUserId,
) {
  Future<String> read() => session.db.transaction(readInTransaction);

  Future<String> readOrInitialize() => session.db.transaction((
    transaction,
  ) async {
    final reader = _WorkspaceContextSelectionReader(this);
    final context = await _authorize(transaction);
    final event = await reader._latestEvent(context.conversation, transaction);
    if (event != null) return reader.read(transaction);
    final selection = WorkspaceContextSelection(
      workspaceId: '$workspaceId',
      conversationId: conversationId,
      itemId: '',
      kind: 'directory',
    );
    final id = const Uuid().v7();
    await _WorkspaceContextSelectionSaver(this)._insert(
      transaction,
      id,
      context.conversation.id!,
      jsonEncode(selection.toJson()),
    );
    return _selectionResult(id, selection);
  });

  Future<String> readInTransaction(Transaction transaction) =>
      _WorkspaceContextSelectionReader(this).read(transaction);

  Future<String> save(
    String requestId,
    String? selectionJson,
  ) => _WorkspaceContextSelectionSaver(this).save(requestId, selectionJson);

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
  ) => _WorkspaceContextAuthorizer(this).authorize(transaction);

  Future<void> _validate(
    WorkspaceContextSelection selection,
    WorkspaceMember member,
    Transaction transaction,
  ) => _WorkspaceContextSelectionValidator(this).validate(
    selection,
    member,
    transaction,
  );

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

class _WorkspaceContextSelectionReader {
  const _WorkspaceContextSelectionReader(this.store);

  final WorkspaceContextStore store;

  Future<String> read(Transaction transaction) async {
    final context = await store._authorize(transaction);
    final event = await _latestEvent(context.conversation, transaction);
    final selection = store._decode(event?.selectionJson);
    if (selection != null) {
      await store._validate(selection, context.member, transaction);
    }

    return jsonEncode({
      'id': event?.stableId,
      'selection': selection?.toJson(),
    });
  }

  Future<WorkspaceConversationContext?> _latestEvent(
    Conversation conversation,
    Transaction transaction,
  ) => WorkspaceConversationContext.db.findFirstRow(
    store.session,
    where: (row) =>
        row.workspaceId.equals(store.workspaceId) &
        row.conversationId.equals(conversation.id) &
        row.actorUserId.equals(store.actorUserId),
    orderBy: (row) => row.id.desc(),
    transaction: transaction,
  );
}

class _WorkspaceContextSelectionSaver {
  const _WorkspaceContextSelectionSaver(this.store);

  final WorkspaceContextStore store;

  Future<String> save(String requestId, String? selectionJson) =>
      store.session.db.transaction(
        (transaction) => _saveInTransaction(
          transaction,
          requestId,
          selectionJson,
        ),
      );

  Future<String> _saveInTransaction(
    Transaction transaction,
    String requestId,
    String? selectionJson,
  ) async {
    final context = await store._authorize(transaction);
    final selection = await _validatedSelection(
      transaction,
      requestId,
      selectionJson,
      context.member,
    );
    final encoded = _encode(selection);
    final previous = await _previous(requestId, transaction);
    if (previous != null) return _replay(previous, context, selection, encoded);

    await _insert(
      transaction,
      requestId,
      context.conversation.id!,
      encoded,
    );

    return _selectionResult(requestId, selection);
  }

  Future<WorkspaceContextSelection?> _validatedSelection(
    Transaction transaction,
    String requestId,
    String? selectionJson,
    WorkspaceMember member,
  ) async {
    if (requestId.isEmpty || requestId.length > 100) _invalid();
    final selection = store._decode(selectionJson);
    if (selectionJson != null && selection == null) _invalid();
    if (selection != null) {
      await store._validate(selection, member, transaction);
    }

    return selection;
  }

  String? _encode(WorkspaceContextSelection? selection) =>
      selection == null ? null : jsonEncode(selection.toJson());

  Future<WorkspaceConversationContext?> _previous(
    String requestId,
    Transaction transaction,
  ) => WorkspaceConversationContext.db.findFirstRow(
    store.session,
    where: (row) =>
        row.workspaceId.equals(store.workspaceId) &
        row.stableId.equals(requestId),
    transaction: transaction,
  );

  String _replay(
    WorkspaceConversationContext previous,
    ({WorkspaceMember member, Conversation conversation}) context,
    WorkspaceContextSelection? selection,
    String? encoded,
  ) {
    if (previous.conversationId != context.conversation.id ||
        previous.actorUserId != store.actorUserId ||
        previous.selectionJson != encoded) {
      throw CloudWorkspaceException(code: .idempotencyConflict);
    }

    return _selectionResult(previous.stableId, selection);
  }

  Future<void> _insert(
    Transaction transaction,
    String requestId,
    int conversationId,
    String? encoded,
  ) => WorkspaceConversationContext.db.insertRow(
    store.session,
    WorkspaceConversationContext(
      workspaceId: store.workspaceId,
      conversationId: conversationId,
      stableId: requestId,
      actorUserId: store.actorUserId,
      selectionJson: encoded,
      createdAt: DateTime.now().toUtc(),
    ),
    transaction: transaction,
  );
}

class _WorkspaceContextSelectionValidator {
  const _WorkspaceContextSelectionValidator(this.store);

  final WorkspaceContextStore store;

  Future<void> validate(
    WorkspaceContextSelection selection,
    WorkspaceMember member,
    Transaction transaction,
  ) async {
    if (selection.kind == 'directory') {
      _validateDirectory(selection);
      return;
    }
    if (selection.kind == 'view') {
      await _validateView(selection, member, transaction);
      return;
    }
    await _validateItem(selection, member, transaction);
  }

  void _validateDirectory(WorkspaceContextSelection selection) {
    if (selection.itemId.isNotEmpty || selection.recordIds.isNotEmpty) {
      _invalid();
    }
  }

  Future<void> _validateView(
    WorkspaceContextSelection selection,
    WorkspaceMember member,
    Transaction transaction,
  ) async {
    final view = await WorkspaceViewStore(
      store.session,
      member,
      transaction,
    ).read(selection.itemId);
    final data = jsonDecode(view.data) as Map<String, dynamic>;
    await store._records(
      selection.recordIds,
      data['tableId'] as String,
      member,
      transaction,
    );
  }

  Future<void> _validateItem(
    WorkspaceContextSelection selection,
    WorkspaceMember member,
    Transaction transaction,
  ) async {
    final kind = switch (selection.kind) {
      'folder' => WorkspaceResourceKind.folder,
      'file' => WorkspaceResourceKind.file,
      _ => WorkspaceResourceKind.table,
    };
    final item = await store._visible(
      kind,
      selection.itemId,
      member,
      transaction,
    );
    if (kind != .table && selection.recordIds.isNotEmpty) _invalid();
    if (kind == .table) {
      await store._records(
        selection.recordIds,
        item.resourceId,
        member,
        transaction,
      );
    }
  }
}

class _WorkspaceContextAuthorizer {
  const _WorkspaceContextAuthorizer(this.store);

  final WorkspaceContextStore store;

  Future<({WorkspaceMember member, Conversation conversation})> authorize(
    Transaction transaction,
  ) async {
    final authUser = await const AuthUserLock().lock(
      store.session,
      userId: store.actorUserId,
      transaction: transaction,
    );
    if (authUser == null) {
      throw CloudWorkspaceException(code: .authenticationRequired);
    }
    final _ = await _workspace(transaction);
    final member = await _member(transaction);
    final conversation = await _conversation(transaction);

    return (member: member, conversation: conversation);
  }

  Future<CloudWorkspace> _workspace(Transaction transaction) async {
    final workspace = await CloudWorkspace.db.findFirstRow(
      store.session,
      where: (row) =>
          row.id.equals(store.workspaceId) &
          row.deletedAt.equals(null) &
          row.erasureRequestedAt.equals(null),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (workspace == null) _denied();

    return workspace;
  }

  Future<WorkspaceMember> _member(Transaction transaction) async {
    final member = await WorkspaceMember.db.findFirstRow(
      store.session,
      where: (row) =>
          row.workspaceId.equals(store.workspaceId) &
          row.userId.equals(store.actorUserId) &
          row.removedAt.equals(null),
      transaction: transaction,
    );
    if (member == null) _denied();

    return member;
  }

  Future<Conversation> _conversation(Transaction transaction) async {
    final conversation = await Conversation.db.findFirstRow(
      store.session,
      where: (row) =>
          row.workspaceId.equals(store.workspaceId) &
          row.stableId.equals(store.conversationId) &
          row.deletedAt.equals(null),
      transaction: transaction,
    );
    if (conversation == null) _denied();

    return conversation;
  }
}

String _selectionResult(
  String? id,
  WorkspaceContextSelection? selection,
) => jsonEncode({'id': id, 'selection': selection?.toJson()});

Never _denied() => throw CloudWorkspaceException(code: .permissionDenied);
Never _invalid() => throw CloudWorkspaceException(code: .validationFailed);
