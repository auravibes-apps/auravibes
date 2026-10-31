// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/notifiers/titles_streams_notifier.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_providers.g.dart';

typedef _ConversationPagination = ({int? limit, int offset});

typedef _ConversationListOptions = ({
  String search,
  _ConversationPagination pagination,
  bool fetchAllPages,
});

const _cloudConversationPageSize = 100;

const _ConversationPagination _defaultConversationPagination = (
  limit: null,
  offset: 0,
);

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
) async* {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayForWorkspaceProvider(cloud.localWorkspaceId)
        .future,
  );
  if (gateway == null) return;

  final conversation = await CloudChatGateway(gateway)
      .getConversation(conversationId);
  yield _cloudConversation(conversation, cloud.localWorkspaceId);
}

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
  _ConversationPagination pagination = _defaultConversationPagination,
}) async* {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  if (!ref.mounted) return;
  yield* _conversationsForSession(ref, session, workspaceId, (
    search: search,
    pagination: pagination,
    fetchAllPages: false,
  ));
}

Stream<List<ConversationEntity>> _conversationsForSession(
  Ref ref,
  WorkspaceSession session,
  String workspaceId,
  _ConversationListOptions options,
) {
  if (session.cloud case final cloud?) {
    return _cloudConversations(ref, cloud, options);
  }

  return ref
      .watch(conversationRepositoryProvider)
      .watchConversationsByWorkspace(
        workspaceId,
        search: options.search,
        limit: options.pagination.limit,
        offset: options.pagination.offset,
      );
}

@Riverpod(retry: _childConversationRetry)
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

Duration? _childConversationRetry(int retryCount, Object error) {
  if (error is CloudAppException && error.code == 'invalidCursor') return null;

  return ProviderContainer.defaultRetry(retryCount, error);
}

Stream<List<ConversationEntity>> _cloudChildConversations(
  Ref ref,
  CloudWorkspaceRef cloud,
  String parentConversationId,
) =>
    _cloudConversations(ref, cloud, (
      search: '',
      pagination: _defaultConversationPagination,
      fetchAllPages: true,
    )).map(
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
  CloudWorkspaceRef cloud, [
  _ConversationListOptions options = (
    search: '',
    pagination: _defaultConversationPagination,
    fetchAllPages: false,
  ),
]) async* {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayForWorkspaceProvider(cloud.localWorkspaceId)
        .future,
  );
  if (gateway == null) return;

  yield* _watchCloudConversations(gateway, cloud, options);
}

Stream<List<ConversationEntity>> _watchCloudConversations(
  CloudWorkspaceStateGateway gateway,
  CloudWorkspaceRef cloud,
  _ConversationListOptions options,
) {
  const resourceKinds = {'conversation'};
  Future<({List<ConversationEntity> value, int currentSequence})> read() =>
      _readCloudConversations(gateway, cloud, options);

  return gateway.watch(resourceKinds, read);
}

Future<({List<ConversationEntity> value, int currentSequence})>
_readCloudConversations(
  CloudWorkspaceStateGateway gateway,
  CloudWorkspaceRef cloud,
  _ConversationListOptions options,
) async {
  final conversations = options.fetchAllPages
      ? await _readAllCloudConversationPages(gateway, cloud)
      : await _readCloudConversationPage(gateway, cloud, options);
  final currentSequence = await _cloudConversationSequence(gateway);

  return _cloudConversationSnapshot(
    conversations,
    cloud.localWorkspaceId,
    currentSequence,
  );
}

({List<ConversationEntity> value, int currentSequence})
_cloudConversationSnapshot(
  List<ConversationSummary> conversations,
  String localWorkspaceId,
  int currentSequence,
) => (
  value: _mapCloudConversations(conversations, localWorkspaceId),
  currentSequence: currentSequence,
);

Future<List<ConversationSummary>> _readCloudConversationPage(
  CloudWorkspaceStateGateway gateway,
  CloudWorkspaceRef cloud,
  _ConversationListOptions options,
) async {
  final page = await gateway.client.conversation.listPage(
    .new(
      workspaceId: cloud.cloudWorkspaceId,
      limit: options.pagination.limit ?? _cloudConversationPageSize,
      search: options.search.isEmpty ? null : options.search,
      offset: options.pagination.offset,
    ),
  );

  return page.conversations;
}

Future<List<ConversationSummary>> _readAllCloudConversationPages(
  CloudWorkspaceStateGateway gateway,
  CloudWorkspaceRef cloud,
) async {
  final conversations = <ConversationSummary>[];
  final seenCursors = <String>{};
  String? cursor;

  while (true) {
    final page = await _readCloudConversationPageAtCursor(
      gateway,
      cloud,
      cursor,
    );
    conversations.addAll(page.conversations);

    cursor = _nextCloudConversationCursor(page.nextCursor, seenCursors);
    if (cursor == null) return conversations;
  }
}

Future<ConversationPage> _readCloudConversationPageAtCursor(
  CloudWorkspaceStateGateway gateway,
  CloudWorkspaceRef cloud,
  String? cursor,
) => gateway.client.conversation.listPage(
  .new(
    workspaceId: cloud.cloudWorkspaceId,
    limit: _cloudConversationPageSize,
    cursor: cursor,
  ),
);

String? _nextCloudConversationCursor(
  String? nextCursor,
  Set<String> seenCursors,
) {
  if (nextCursor == null) return null;
  if (nextCursor.isEmpty || !seenCursors.add(nextCursor)) {
    _throwInvalidCloudConversationCursor();
  }

  return nextCursor;
}

Never _throwInvalidCloudConversationCursor() => throw const CloudAppException(
  localizationKey: LocaleKeys.cloud_errors_malformed_resource,
  context: .conversation,
  code: 'invalidCursor',
);

Future<int> _cloudConversationSequence(
  CloudWorkspaceStateGateway gateway,
) async {
  final state = await gateway.read(pages: const [], eventLimit: 0);

  return state.currentSequence;
}

List<ConversationEntity> _mapCloudConversations(
  List<ConversationSummary> conversations,
  String localWorkspaceId,
) => conversations
    .map((conversation) => _cloudConversation(conversation, localWorkspaceId))
    .toList();

ConversationEntity _cloudConversation(
  ConversationSummary conversation,
  String localWorkspaceId,
) {
  final mapped = _cloudConversationCore(conversation, localWorkspaceId);

  return mapped.copyWith(
    activeCompactionCheckpointId: conversation.activeCompactionCheckpointId,
    forkSourceConversationId: conversation.forkSourceConversationId,
    forkSourceTitle: conversation.forkSourceTitle,
    forkThroughMessageId: conversation.forkThroughMessageId,
    forkMaterializedAt: conversation.forkMaterializedAt,
  );
}

ConversationEntity _cloudConversationCore(
  ConversationSummary conversation,
  String localWorkspaceId,
) => _cloudConversationFields(conversation, localWorkspaceId).copyWith(
  toolAccessMode: ConversationToolAccessModeStorage.decode(
    conversation.toolAccessMode,
  ),
);

ConversationEntity _cloudConversationFields(
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
    reasoningConfiguration: .decode(conversation.reasoningConfigJson),
    parentConversationId: conversation.parentConversationId,
  );
}
