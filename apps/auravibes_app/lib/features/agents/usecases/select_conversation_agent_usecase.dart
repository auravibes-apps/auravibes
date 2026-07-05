import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:riverpod/riverpod.dart';

class SelectConversationAgentUsecase {
  const SelectConversationAgentUsecase(this._repository);

  final ConversationRepository _repository;

  Future<ConversationEntity> call(String conversationId, String? agentId) {
    return _repository.patchConversation(
      conversationId,
      agentId == null
          ? const ConversationPatch(clearAgent: true)
          : ConversationPatch(agentId: agentId),
    );
  }
}

final selectConversationAgentUsecaseProvider =
    Provider<SelectConversationAgentUsecase>((ref) {
      return SelectConversationAgentUsecase(
        ref.watch(conversationRepositoryProvider),
      );
    });
