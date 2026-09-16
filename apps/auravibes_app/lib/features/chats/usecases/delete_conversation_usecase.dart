import 'package:auravibes_app/data/repositories/conversation_repository.dart';

class const DeleteConversationUsecase(
  final ConversationRepository _repository,
  final Future<void> Function(String conversationId) _stopConversation, [
  final Future<Map<String, String?>> Function(String conversationId)?
  _captureForkBoundaries,
]) {
  Future<bool> call(String conversationId) async {
    final boundaries = await _captureForkBoundaries?.call(conversationId);
    await _stopConversation(conversationId);

    if (boundaries == null) {
      return await _repository.deleteConversation(conversationId);
    }

    return await _repository.deleteConversationWithFrozenForkBoundaries(
      conversationId,
      frozenForkBoundaries: boundaries,
    );
  }
}
