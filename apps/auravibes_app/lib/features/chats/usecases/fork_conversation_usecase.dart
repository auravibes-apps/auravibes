import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class const ForkConversationUsecase(final ConversationRepository _repository) {
  Future<ConversationEntity> call(
    ConversationEntity conversation, {
    String? throughMessageId,
  }) => _repository.forkConversation(
    conversation.id,
    throughMessageId: throughMessageId,
  );
}

final forkConversationUsecaseProvider = Provider<ForkConversationUsecase>(
  (ref) => ForkConversationUsecase(ref.watch(conversationRepositoryProvider)),
);
