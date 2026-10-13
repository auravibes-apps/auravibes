import 'package:auravibes_app/data/repositories/conversation_repository.dart';

class DeleteConversationUsecase {
  const new(
    this._repository,
    this._stopConversation, {
    required this._prepareBackgroundWorkDeletion,
    required this._restoreBackgroundWorkAfterFailedDeletion,
    required this._clearConversationDraft,
    this._captureForkBoundaries,
  });

  final ConversationRepository _repository;
  final Future<void> Function(String conversationId) _stopConversation;
  final Future<void> Function(String conversationId)
  _prepareBackgroundWorkDeletion;
  final void Function(String conversationId)
  _restoreBackgroundWorkAfterFailedDeletion;
  final Future<void> Function(String workspaceId, String conversationId)
  _clearConversationDraft;
  final Future<Map<String, String?>> Function(String conversationId)?
  _captureForkBoundaries;

  Future<bool> call({
    required String workspaceId,
    required String conversationId,
  }) async {
    final boundaries = await _captureForkBoundaries?.call(conversationId);
    final bool deleted;
    try {
      await _prepareBackgroundWorkDeletion(conversationId);
      await _stopConversation(conversationId);
      deleted = await _deleteConversation(conversationId, boundaries);
    } on Object {
      _restoreBackgroundWorkAfterFailedDeletion(conversationId);
      rethrow;
    }
    if (!deleted) {
      _restoreBackgroundWorkAfterFailedDeletion(conversationId);

      return false;
    }
    await _clearConversationDraft(workspaceId, conversationId);

    return true;
  }

  Future<bool> _deleteConversation(
    String conversationId,
    Map<String, String?>? boundaries,
  ) => boundaries == null
      ? _repository.deleteConversation(conversationId)
      : _repository.deleteConversationWithFrozenForkBoundaries(
          conversationId,
          frozenForkBoundaries: boundaries,
        );
}
