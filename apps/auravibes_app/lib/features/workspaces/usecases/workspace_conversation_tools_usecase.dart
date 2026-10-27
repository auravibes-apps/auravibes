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
  Future<bool> verifiedMutation({
    required String conversationId,
    required String operationId,
    required Map<String, dynamic> arguments,
  }) async {
    final store = receipts;
    if (store == null || operationId.isEmpty) return false;
    final target = await _target(conversationId);
    final shared = await _selection(target);
    return await store.matches(
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
      await _dispatch(await _prepare());

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

  Future<Map<String, Object?>> _dispatch(_PreparedCommand prepared) =>
      request.arguments['action'] == 'read'
      ? _read(prepared)
      : _write(prepared);

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
