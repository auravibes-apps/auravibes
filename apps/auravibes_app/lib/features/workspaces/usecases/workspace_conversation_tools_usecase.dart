import 'dart:convert';

import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_command_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_context_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_command_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

typedef _ConversationTarget = ({String workspaceId, String conversationId});
typedef _SharedContext = ({String epoch, WorkspaceContextSelection selection});
typedef _CommandRequest = ({
  Map<String, dynamic> arguments,
  String? operationId,
});
typedef _PreparedCommand = ({
  WorkspaceConversationCommandUsecase command,
  WorkspaceContextSelection selection,
  WorkspaceReferenceScope references,
});

class const WorkspaceConversationToolsUsecase({
  required final ConversationRepository conversations,
  required final LocalWorkspaceContextRepository Function(String workspaceId)
  context,
  required final Future<WorkspaceConversationCommandUsecase> Function(String)
  commands,
  final LocalWorkspaceCommandRepository? receipts,
}) {
  Future<Map<String, Object?>?> verifiedMutation({
    required String conversationId,
    required String operationId,
    required Map<String, dynamic> arguments,
  }) async {
    final store = receipts;
    if (store == null || operationId.isEmpty) return null;
    final target = await _target(conversationId);
    final shared = await _selection(target);

    return await store.matchedResult(
      workspaceId: target.workspaceId,
      conversationId: target.conversationId,
      selectionId: shared.epoch,
      requestId: operationId,
      arguments: arguments,
    );
  }

  Future<Object?> call({
    required String conversationId,
    required Map<String, dynamic> arguments,
    String? operationId,
  }) async {
    final target = await _target(conversationId);
    final shared = await _selection(target);

    return await _SelectedCommand(this, target, shared, (
      arguments: arguments,
      operationId: operationId,
    )).call();
  }

  Future<_ConversationTarget> _target(String conversationId) async {
    final conversation = await conversations.getConversationById(
      conversationId,
    );
    if (conversation == null) throw const WorkspaceTableException(denied: true);

    return (
      workspaceId: conversation.workspaceId,
      conversationId: conversationId,
    );
  }

  Future<_SharedContext> _selection(_ConversationTarget target) async {
    final selected = await context(target.workspaceId)
        .read(target.conversationId);
    final epoch = selected.id;
    final selection = selected.selection;
    if (epoch == null || selection == null) {
      throw const WorkspaceTableException(denied: true);
    }

    return (epoch: epoch, selection: selection);
  }
}

class const _SelectedCommand(
  final WorkspaceConversationToolsUsecase owner,
  final _ConversationTarget target,
  final _SharedContext shared,
  final _CommandRequest request,
) {
  Future<Map<String, Object?>> call() async =>
      request.arguments['action'] == 'listCreated'
      ? await _listCreated()
      : await _dispatch(await _prepare());

  Future<_PreparedCommand> _prepare() async {
    final created = await _created();
    final command = await owner.commands(target.workspaceId);

    return _bind(command, created);
  }

  _PreparedCommand _bind(
    WorkspaceConversationCommandUsecase command,
    List<Map<String, Object?>> created,
  ) => (
    command: command,
    selection: workspaceCreatedContext(
      shared.selection,
      created,
      request.arguments,
    ),
    references: .new(shared.selection, created),
  );

  Future<Map<String, Object?>> _dispatch(_PreparedCommand prepared) {
    return request.arguments['action'] == 'read'
        ? _read(prepared)
        : _write(prepared);
  }

  Future<Map<String, Object?>> _listCreated() async {
    final cursor = request.arguments['cursor'];
    if (cursor != null &&
        (cursor is! String || cursor.isEmpty || cursor.length > 512)) {
      throw const WorkspaceTableException();
    }
    final created =
        await owner.receipts?.receiptPage(
          target.workspaceId,
          target.conversationId,
          cursor as String?,
        ) ??
        [];
    final command = await owner.commands(target.workspaceId);
    final items = <Map<String, Object?>>[];
    final nextCursor = created.length > 100 ? created[99].requestId : null;
    for (var index = 0; index < created.length && index < 100; index++) {
      final row = created[index];
      if (!row.created || row.selectionId != shared.epoch) continue;
      final item = (jsonDecode(row.result) as Map<String, dynamic>)
          .cast<String, Object?>();
      final kind = item['kind'];
      final id = item['id'];
      if (id is! String ||
          kind is! String ||
          !{'folder', 'table', 'view'}.contains(kind)) {
        continue;
      }
      await _authorize();
      try {
        final arguments = <String, dynamic>{
          'action': 'read',
          if (kind == 'table') 'tableId': id else 'id': id,
        };
        final itemsInScope = [item];
        final selection = workspaceCreatedContext(
          shared.selection,
          itemsInScope,
          arguments,
        );
        final data = await command.call(
          selection: selection,
          arguments: arguments,
          references: .new(shared.selection, [item]),
          conversationId: target.conversationId,
        );
        items.add({
          'id': id,
          'kind': kind,
          for (final key in ['name', 'revision', 'schemaRevision'])
            if (data.containsKey(key)) key: data[key],
        });
      } on WorkspaceTableException {
        // Deleted or no longer authorized items are not disclosed.
      }
    }
    await _authorize();

    return {'items': items, 'nextCursor': nextCursor};
  }

  Future<List<Map<String, Object?>>> _created() async =>
      await owner.receipts?.created(
        target.workspaceId,
        target.conversationId,
        shared.epoch,
      ) ??
      [];

  Future<Map<String, Object?>> _read(_PreparedCommand prepared) async {
    final result = await _run(prepared);
    await _authorize();

    return result;
  }

  Future<void> _authorize() async {
    final current = await owner
        .context(target.workspaceId)
        .read(target.conversationId);
    if (current.id != shared.epoch) {
      throw const WorkspaceTableException(denied: true);
    }
  }

  Future<Map<String, Object?>> _write(_PreparedCommand prepared) async {
    final store = owner.receipts;
    final operationId = request.operationId;
    if (store == null || operationId == null || operationId.isEmpty) {
      throw const WorkspaceTableException();
    }

    return await store.execute(_receipt(prepared, operationId));
  }

  WorkspaceReceiptWrite _receipt(
    _PreparedCommand prepared,
    String operationId,
  ) => (
    workspaceId: target.workspaceId,
    conversationId: target.conversationId,
    selectionId: shared.epoch,
    requestId: operationId,
    arguments: request.arguments,
    run: () => _run(prepared),
    authorizeReplay: prepared.command.authorizeReceipt,
  );

  Future<Map<String, Object?>> _run(_PreparedCommand prepared) =>
      prepared.command.call(
        selection: prepared.selection,
        arguments: request.arguments,
        references: prepared.references,
        conversationId: target.conversationId,
      );
}
