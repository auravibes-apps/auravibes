// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/models/conversation_list_scope.dart';
import 'package:auravibes_app/features/chats/notifiers/titles_streams_notifier.dart';
import 'package:auravibes_app/features/chats/providers/conversation_archive_state_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/filtered_cloud_conversation_page_reader.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_providers.g.dart';

typedef _ConversationPagination = ({int? limit, int offset});

typedef _ConversationListOptions = ({
  String search,
  _ConversationPagination pagination,
  bool fetchAllPages,
  ConversationListScope scope,
  Set<String> archivedIds,
});
typedef _ForkedConversationRequest = ({
  String workspaceId,
  String sourceConversationId,
});

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

/// Riverpod generates a family call from these named inputs; keeping this
/// signature preserves the provider API used by its consumers.
// ignore: number-of-parameters - Keep Riverpod's generated family signature.
@riverpod
Stream<List<ConversationEntity>> conversationsStream(
  Ref ref, {
  required String workspaceId,
  String search = '',
  _ConversationPagination pagination = _defaultConversationPagination,
  ConversationListScope scope = ConversationListScope.active,
}) async* {
  final session = await _workspaceSession(ref, workspaceId);
  if (!ref.mounted) return;

  final archivedIds = await _archiveIdsForSession(ref, workspaceId, session);
  if (!ref.mounted) return;

  yield* _conversationsForSession(ref, session, workspaceId, (
    search: search,
    pagination: pagination,
    fetchAllPages: false,
    scope: scope,
    archivedIds: archivedIds,
  ));
}

Future<WorkspaceSession> _workspaceSession(Ref ref, String workspaceId) =>
    ref.watch(workspaceSessionForRouteProvider(workspaceId).future);

Future<Set<String>> _archiveIdsForSession(
  Ref ref,
  String workspaceId,
  WorkspaceSession session,
) async => session.cloud == null
    ? const {}
    : await ref.watch(conversationArchiveStateIdsProvider(workspaceId).future);

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
        options: (
          search: options.search,
          archivedOnly: options.scope == ConversationListScope.archived,
          limit: options.pagination.limit,
          offset: options.pagination.offset,
        ),
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

// ignore: specify_nonobvious_property_types - Riverpod family type is verbose.
final forkedConversationsStreamProvider =
    StreamProvider.family<List<ConversationEntity>, _ForkedConversationRequest>(
      (ref, request) async* {
        final repository = ref.watch(conversationRepositoryProvider);
        final session = await ref.watch(
          workspaceSessionForRouteProvider(request.workspaceId).future,
        );
        if (!ref.mounted) return;
        if (session.cloud case final cloud?) {
          yield* _cloudForkedConversations(
            ref,
            cloud,
            request.sourceConversationId,
          );

          return;
        }

        yield* repository
            .watchConversationsByWorkspace(request.workspaceId)
            .map(
              (conversations) => conversations
                  .where(
                    (conversation) =>
                        conversation.forkSourceConversationId ==
                        request.sourceConversationId,
                  )
                  .toList(),
            );
      },
    );

Stream<List<ConversationEntity>> _cloudForkedConversations(
  Ref ref,
  CloudWorkspaceRef cloud,
  String sourceConversationId,
) async* {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayForWorkspaceProvider(cloud.localWorkspaceId)
        .future,
  );
  if (!ref.mounted || gateway == null) return;

  yield* _watchCloudForkedConversations(gateway, cloud, sourceConversationId);
}

Stream<List<ConversationEntity>> _watchCloudForkedConversations(
  CloudWorkspaceStateGateway gateway,
  CloudWorkspaceRef cloud,
  String sourceConversationId,
) {
  Future<({List<ConversationEntity> value, int currentSequence})> read() =>
      _readForkedCloudConversations(gateway, cloud, sourceConversationId);

  return gateway.watch(const {'conversation'}, read);
}

Future<({List<ConversationEntity> value, int currentSequence})>
_readForkedCloudConversations(
  CloudWorkspaceStateGateway gateway,
  CloudWorkspaceRef cloud,
  String sourceConversationId,
) async {
  final conversations = _mapCloudConversations(
    await FilteredCloudConversationPageReader.readAllPages(gateway, cloud),
    cloud.localWorkspaceId,
  );
  final currentSequence = await _cloudConversationSequence(gateway);

  return (
    value: conversations
        .where(
          (conversation) =>
              conversation.forkSourceConversationId == sourceConversationId,
        )
        .toList(),
    currentSequence: currentSequence,
  );
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
      scope: .active,
      archivedIds: const {},
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
    scope: .active,
    archivedIds: const {},
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
      ? await FilteredCloudConversationPageReader.readAllPages(gateway, cloud)
      : await FilteredCloudConversationPageReader(
          gateway,
          cloud,
          options.scope,
          options.pagination,
          options.search,
          options.archivedIds,
        ).read();
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
  taskBrief: conversation.taskBrief,
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
