import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_deletion_provider.g.dart';

typedef DeleteConversation = Future<void> Function(ConversationEntity);

@riverpod
Future<DeleteConversation> conversationDeletion(
  Ref ref,
  String workspaceId,
) async {
  final link = ref.keepAlive();
  try {
    final cloud = await ref.watch(
      cloudConversationUsecaseProvider(workspaceId).future,
    );
    if (cloud != null) return cloud.delete;
    final repository = ref.watch(conversationRepositoryProvider);

    Future<void> delete(ConversationEntity conversation) async {
      final _ = await repository.deleteConversation(conversation.id);
    }

    return delete;
  } finally {
    link.close();
  }
}
