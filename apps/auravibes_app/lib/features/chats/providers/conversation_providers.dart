// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/notifiers/titles_streams_notifier.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_providers.g.dart';

@riverpod
Stream<ConversationEntity?> conversationByIdStream(
  Ref ref,
  String workspaceId, {
  required String conversationId,
}) {
  final session = ref
      .watch(workspaceSessionForRouteProvider(workspaceId))
      .value;
  if (session == null) return const Stream.empty();
  if (session.cloud case final cloud?) {
    return _cloudConversationById(ref, cloud, conversationId);
  }

  return _localConversationById(ref, conversationId);
}

Stream<ConversationEntity?> _cloudConversationById(
  Ref ref,
  CloudWorkspaceRef cloud,
  String conversationId,
) => _cloudConversations(ref, cloud).map(
  (conversations) => conversations
      .where((conversation) => conversation.id == conversationId)
      .firstOrNull,
);

Stream<ConversationEntity?> _localConversationById(
  Ref ref,
  String conversationId,
) => ref
    .watch(conversationRepositoryProvider)
    .watchConversationById(conversationId);

@riverpod
Stream<List<ConversationEntity>> conversationsStream(
  Ref ref, {
  required String workspaceId,
  String search = '',
  int? limit,
  int offset = 0,
}) async* {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  if (!ref.mounted) return;
  yield* _conversationsForSession(
    ref,
    session,
    workspaceId,
    search: search,
    offset: offset,
    limit: limit,
  );
}

Stream<List<ConversationEntity>> _conversationsForSession(
  Ref ref,
  WorkspaceSession session,
  String workspaceId, {
  required String search,
  required int offset,
  int? limit,
}) {
  if (session.cloud case final cloud?) {
    return _cloudConversations(
      ref,
      cloud,
      search: search,
      offset: offset,
      limit: limit,
    );
  }

  return ref
      .watch(conversationRepositoryProvider)
      .watchConversationsByWorkspace(
        workspaceId,
        search: search,
        limit: limit,
        offset: offset,
      );
}

@riverpod
Stream<List<ConversationEntity>> childConversationsStream(
  Ref ref,
  String workspaceId, {
  required String parentConversationId,
}) {
  final session = ref
      .watch(workspaceSessionForRouteProvider(workspaceId))
      .value;
  if (session == null) return const Stream.empty();
  if (session.cloud case final cloud?) {
    return _cloudChildConversations(ref, cloud, parentConversationId);
  }

  return _localChildConversations(ref, parentConversationId);
}

Stream<List<ConversationEntity>> _cloudChildConversations(
  Ref ref,
  CloudWorkspaceRef cloud,
  String parentConversationId,
) => _cloudConversations(ref, cloud).map(
  (conversations) => conversations
      .where(
        (conversation) =>
            conversation.parentConversationId == parentConversationId,
      )
      .toList(),
);

Stream<List<ConversationEntity>> _localChildConversations(
  Ref ref,
  String parentConversationId,
) => ref
    .watch(conversationRepositoryProvider)
    .watchChildConversations(parentConversationId);

@riverpod
String? streamingTitle(Ref ref, String conversationId) {
  final titles = ref.watch(titlesStreamsProvider);

  return titles[conversationId];
}

Stream<List<ConversationEntity>> _cloudConversations(
  Ref ref,
  CloudWorkspaceRef cloud, {
  String search = '',
  int offset = 0,
  int? limit,
}) async* {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayForWorkspaceProvider(cloud.localWorkspaceId)
        .future,
  );
  if (gateway == null) return;

  yield (await CloudChatGateway(
        gateway,
      ).listConversations(search: search, limit: limit ?? 100, offset: offset))
      .map(
        (conversation) =>
            _cloudConversation(conversation, cloud.localWorkspaceId),
      )
      .toList();
}

ConversationEntity _cloudConversation(
  ConversationSummary conversation,
  String localWorkspaceId,
) {
  return ConversationEntity(
    id: conversation.id,
    title: conversation.title,
    workspaceId: localWorkspaceId,
    isPinned: conversation.isPinned,
    createdAt: conversation.createdAt,
    updatedAt: conversation.updatedAt,
    revision: conversation.revision,
    modelId: conversation.modelId,
    agentId: conversation.agentId,
    parentConversationId: conversation.parentConversationId,
  );
}
