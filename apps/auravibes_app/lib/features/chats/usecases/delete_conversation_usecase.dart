import 'package:auravibes_app/data/repositories/conversation_repository.dart';

class DeleteConversationUsecase {
  const new(
    this._repository,
    this._stopConversation, {
    required this._prepareBackgroundWorkDeletion,
    required this._restoreBackgroundWorkAfterFailedDeletion,
    this._captureForkBoundaries,
  });

  final ConversationRepository _repository;
  final Future<void> Function(String conversationId) _stopConversation;
  final Future<void> Function(String conversationId)
  _prepareBackgroundWorkDeletion;
  final void Function(String conversationId)
  _restoreBackgroundWorkAfterFailedDeletion;
  final Future<Map<String, String?>> Function(String conversationId)?
  _captureForkBoundaries;

  Future<bool> call(String conversationId) async {
    final boundaries = await _captureForkBoundaries?.call(conversationId);
    try {
      return await _deleteAfterPreparation(conversationId, boundaries);
    } on Object {
      _restoreBackgroundWorkAfterFailedDeletion(conversationId);
      rethrow;
    }
  }

  Future<bool> _deleteAfterPreparation(
    String conversationId,
    Map<String, String?>? boundaries,
  ) async {
    await _prepareBackgroundWorkDeletion(conversationId);
    await _stopConversation(conversationId);
    final deleted = await _deleteConversation(conversationId, boundaries);
    if (!deleted) _restoreBackgroundWorkAfterFailedDeletion(conversationId);

    return deleted;
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
