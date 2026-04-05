import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/features/chats/notifiers/titles_streams_notifier.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/selected_workspace.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_providers.g.dart';

@riverpod
Stream<List<ConversationEntity>> conversationsStream(
  Ref ref, {
  int? limit,
}) async* {
  final repo = ref.watch(conversationRepositoryProvider);
  final workspace = await ref.watch(selectedWorkspaceProvider.future);
  yield* repo.watchConversationsByWorkspace(workspace.id, limit: limit);
}

@riverpod
String? streamingTitle(Ref ref, String conversationId) {
  final titles = ref.watch(titlesStreamsProvider);
  return titles[conversationId];
}
