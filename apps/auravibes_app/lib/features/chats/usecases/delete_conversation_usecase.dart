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
      await _prepareBackgroundWorkDeletion(conversationId);
      await _stopConversation(conversationId);
      final deleted = boundaries == null
          ? await _repository.deleteConversation(conversationId)
          : await _repository.deleteConversationWithFrozenForkBoundaries(
              conversationId,
              frozenForkBoundaries: boundaries,
            );
      if (!deleted) {
        _restoreBackgroundWorkAfterFailedDeletion(conversationId);
      }

      return deleted;
    } on Object {
      _restoreBackgroundWorkAfterFailedDeletion(conversationId);
      rethrow;
    }
  }
}
