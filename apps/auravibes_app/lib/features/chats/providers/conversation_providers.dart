import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/features/chats/notifiers/titles_streams_notifier.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_providers.g.dart';

@riverpod
Stream<ConversationEntity?> conversationByIdStream(
  Ref ref, {
  required String conversationId,
}) {
  final repo = ref.watch(conversationRepositoryProvider);
  return repo.watchConversationById(conversationId);
}

@riverpod
Stream<List<ConversationEntity>> conversationsStream(
  Ref ref, {
  required String workspaceId,
  int? limit,
}) {
  final repo = ref.watch(conversationRepositoryProvider);
  return repo.watchConversationsByWorkspace(workspaceId, limit: limit);
}

@riverpod
String? streamingTitle(Ref ref, String conversationId) {
  final titles = ref.watch(titlesStreamsProvider);
  return titles[conversationId];
}
