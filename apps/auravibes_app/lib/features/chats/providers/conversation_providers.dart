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
    return _cloudConversations(ref, cloud).map(
      (conversations) => conversations
          .where((conversation) => conversation.id == conversationId)
          .firstOrNull,
    );
  }

  return ref
      .watch(conversationRepositoryProvider)
      .watchConversationById(conversationId);
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Stream<List<ConversationEntity>> conversationsStream(
  Ref ref, {
  required String workspaceId,
  int? limit,
}) async* {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  if (!ref.mounted) return;
  if (session.cloud case final cloud?) {
    yield* _cloudConversations(ref, cloud).map(
      (conversations) =>
          conversations.take(limit ?? conversations.length).toList(),
    );

    return;
  }

  yield* ref
      .watch(conversationRepositoryProvider)
      .watchConversationsByWorkspace(workspaceId, limit: limit);
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
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
    return _cloudConversations(ref, cloud).map(
      (conversations) => conversations
          .where(
            (conversation) =>
                conversation.parentConversationId == parentConversationId,
          )
          .toList(),
    );
  }

  return ref
      .watch(conversationRepositoryProvider)
      .watchChildConversations(parentConversationId);
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
String? streamingTitle(Ref ref, String conversationId) {
  final titles = ref.watch(titlesStreamsProvider);

  return titles[conversationId];
}

Stream<List<ConversationEntity>> _cloudConversations(
  Ref ref,
  CloudWorkspaceRef cloud,
) async* {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayForWorkspaceProvider(
      cloud.localWorkspaceId,
    ).future,
  );
  if (gateway == null) return;

  yield (await CloudChatGateway(gateway).listConversations())
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
