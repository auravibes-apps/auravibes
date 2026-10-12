import 'package:auravibes_app/data/repositories/conversation_repository.dart';

class const DeleteConversationUsecase(
  final ConversationRepository _repository,
  final Future<void> Function(String conversationId) _stopConversation, {
  required final Future<void> Function(
    String workspaceId,
    String conversationId,
  )
  clearConversationDraft,
  final Future<Map<String, String?>> Function(String conversationId)?
  captureForkBoundaries,
}) {
  Future<bool> call({
    required String workspaceId,
    required String conversationId,
  }) async {
    final boundaries = await captureForkBoundaries?.call(conversationId);
    await _stopConversation(conversationId);

    final deleted = boundaries == null
        ? await _repository.deleteConversation(conversationId)
        : await _repository.deleteConversationWithFrozenForkBoundaries(
            conversationId,
            frozenForkBoundaries: boundaries,
          );
    if (deleted) {
      await clearConversationDraft(workspaceId, conversationId);
    }

    return deleted;
  }
}
