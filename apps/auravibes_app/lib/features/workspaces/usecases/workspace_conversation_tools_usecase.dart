import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_command_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_context_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_command_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

typedef _ConversationTarget = ({String workspaceId, String conversationId});
typedef _ToolScope = ({
  String receiptScopeId,
  WorkspaceContextSelection selection,
});
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
  Future<Object?> call({
    required String conversationId,
    required Map<String, dynamic> arguments,
    String? operationId,
  }) async {
    final target = await _target(conversationId);
    final receiptScopeId = await _receiptScopeId(target);
    final scope = (
      receiptScopeId: receiptScopeId,
      selection: WorkspaceContextSelection(
        workspaceId: target.workspaceId,
        conversationId: conversationId,
        itemId: '',
        kind: 'directory',
      ),
    );

    return await _SelectedCommand(this, target, scope, (
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

  Future<String> _receiptScopeId(_ConversationTarget target) async {
    final context = await this
        .context(target.workspaceId)
        .readOrInitialize(target.conversationId);

    return context.id ?? (throw const WorkspaceTableException());
  }
}

class const _SelectedCommand(
  final WorkspaceConversationToolsUsecase owner,
  final _ConversationTarget target,
  final _ToolScope shared,
  final _CommandRequest request,
) {
  Future<Map<String, Object?>> call() async =>
      await _dispatch(await _prepare());

  Future<_PreparedCommand> _prepare() async {
    final command = await owner.commands(target.workspaceId);

    final selection = await _directoryTarget(command, shared.selection);

    return (
      command: command,
      selection: selection,
      references: WorkspaceReferenceScope(shared.selection, const []),
    );
  }

  Future<WorkspaceContextSelection> _directoryTarget(
    WorkspaceConversationCommandUsecase command,
    WorkspaceContextSelection selection,
  ) async {
    if (selection.kind != 'directory') return selection;
    final arguments = request.arguments;
    final target = _directoryTargetId(arguments);
    if (target is! String || target.isEmpty) return selection;

    return await _DirectorySearch(
      command,
      selection,
      target,
      workspaceTargetKind(arguments),
      _authorize,
    ).find();
  }

  Future<Map<String, Object?>> _dispatch(_PreparedCommand prepared) {
    final action = request.arguments['action'];

    return action == 'read' || action == 'readDirectory'
        ? _read(prepared)
        : _write(prepared);
  }

  Future<Map<String, Object?>> _read(_PreparedCommand prepared) async {
    final result = await _run(prepared);
    await _authorize();

    return result;
  }

  Future<void> _authorize() async {
    final current = await owner._target(target.conversationId);
    if (current.workspaceId != target.workspaceId) {
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
    selectionId: shared.receiptScopeId,
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

Object? _directoryTargetId(Map<String, dynamic> arguments) =>
    switch (arguments['action']) {
      'read' => arguments['tableId'] ?? arguments['id'],
      'createFolder' || 'createTable' => arguments['parentId'],
      'renameFolder' || 'saveView' => arguments['id'],
      'renameTable' ||
      'saveColumn' ||
      'createView' ||
      'createRecord' ||
      'updateRecord' => arguments['tableId'],
      _ => null,
    };

class _DirectorySearch {
  new(this.command, this.root, this.target, this.expectedKind, this.authorize);
  final WorkspaceConversationCommandUsecase command;
  final WorkspaceContextSelection root;
  final String target;
  final String? expectedKind;
  final Future<void> Function() authorize;
  final visited = <String>{};
  WorkspaceContextSelection? match;

  Future<WorkspaceContextSelection> find() async {
    final pending = <WorkspaceContextSelection>[root];
    while (pending.isNotEmpty) {
      final parent = pending.removeLast();
      if (!visited.add(parent.itemId)) continue;
      if (await _scanParent(parent, pending) case final found?) return found;
    }

    return match ?? (throw const WorkspaceTableException(denied: true));
  }

  Future<WorkspaceContextSelection?> _scanParent(
    WorkspaceContextSelection parent,
    List<WorkspaceContextSelection> pending,
  ) async {
    await authorize();
    final data = await command.call(
      selection: parent,
      arguments: {'action': 'read', 'id': parent.itemId},
    );

    return _scan(data, parent, pending);
  }

  WorkspaceContextSelection? _scan(
    Map<String, Object?> data,
    WorkspaceContextSelection parent,
    List<WorkspaceContextSelection> pending,
  ) {
    for (final item in (data['items']! as List).cast<Map<String, Object?>>()) {
      final found = _visit(item, parent, pending);
      if (found != null) return found;
    }

    return null;
  }

  WorkspaceContextSelection? _visit(
    Map<String, Object?> item,
    WorkspaceContextSelection parent,
    List<WorkspaceContextSelection> pending,
  ) {
    final child = _child(item, parent);
    if (child == null) return null;
    if (child.kind == 'folder') pending.add(child);
    if (!_matches(child)) return null;
    if (expectedKind != null) return child;
    if (match != null) throw const WorkspaceTableException(denied: true);
    match = child;

    return null;
  }

  WorkspaceContextSelection? _child(
    Map<String, Object?> item,
    WorkspaceContextSelection parent,
  ) {
    final id = item['id'];
    final kind = item['kind'];
    if (id is! String || kind is! String) return null;

    return WorkspaceContextSelection(
      workspaceId: root.workspaceId,
      conversationId: root.conversationId,
      itemId: id,
      kind: kind,
      parentId: parent.kind == 'directory' ? null : parent.itemId,
    );
  }

  bool _matches(WorkspaceContextSelection child) {
    if (child.itemId != target) return false;
    if (expectedKind == null) return child.kind != 'table';

    return child.kind == expectedKind;
  }
}
