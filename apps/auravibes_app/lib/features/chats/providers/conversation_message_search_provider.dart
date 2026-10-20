import 'package:auravibes_app/domain/entities/conversation_message_search_result.dart'
    as search;
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:riverpod/misc.dart' show FutureProviderFamily;
import 'package:riverpod/riverpod.dart';

const conversationMessageSearchPageSize = 25;

typedef ConversationMessageSearchPageRequest = ({
  String query,
  String? workspaceId,
  int offset,
});

typedef ConversationMessageSearchPage = ({
  List<search.ConversationMessageSearchResult> results,
  bool hasMore,
  bool hasError,
});

final FutureProviderFamily<
  ConversationMessageSearchPage,
  ConversationMessageSearchPageRequest
>
conversationMessageSearchPageProvider = FutureProvider.autoDispose
    .family<
      ConversationMessageSearchPage,
      ConversationMessageSearchPageRequest
    >((ref, request) async {
      final query = request.query.trim();
      if (query.isEmpty) {
        return (
          results: const <search.ConversationMessageSearchResult>[],
          hasMore: false,
          hasError: false,
        );
      }

      final workspaces = await ref.watch(allWorkspacesProvider.future);
      final selectedWorkspaces = request.workspaceId == null
          ? workspaces
          : workspaces
                .where((workspace) => workspace.id == request.workspaceId)
                .toList();
      final localWorkspaceIds = selectedWorkspaces
          .where((workspace) => workspace.type.isLocal)
          .map((workspace) => workspace.id)
          .toSet();
      final localFuture = localWorkspaceIds.isEmpty
          ? Future.value(const <search.ConversationMessageSearchResult>[])
          : ref
                .read(messageRepositoryProvider)
                .searchMessages(
                  query: query,
                  workspaceIds: localWorkspaceIds,
                  limit: conversationMessageSearchPageSize,
                  offset: request.offset,
                );
      // Shortcut: 25 hits per workspace. Use global paging if count grows.
      final remoteFuture = Future.wait(
        selectedWorkspaces.where((workspace) => workspace.type.isRemote).map((
          workspace,
        ) async {
          try {
            final session = await ref.watch(
              workspaceSessionForRouteProvider(workspace.id).future,
            );
            final gateway = await ref.watch(
              cloudWorkspaceStateGatewayProvider(session).future,
            );
            if (gateway == null) throw StateError('Cloud search unavailable');

            final page = await CloudChatGateway(gateway).searchMessages(
              query: query,
              limit: conversationMessageSearchPageSize,
              offset: request.offset,
            );

            return (
              hasError: false,
              workspaceId: workspace.id,
              workspaceName: workspace.name,
              hasMore: page.length == conversationMessageSearchPageSize,
              results: [
                for (final result in page)
                  search.ConversationMessageSearchResult(
                    workspaceId: workspace.id,
                    workspaceName: workspace.name,
                    conversationId: result.conversationId,
                    conversationTitle: result.conversationTitle,
                    messageId: result.messageId,
                    role: result.role,
                    createdAt: result.createdAt,
                    excerpt: result.excerpt,
                  ),
              ],
            );
          } on Object {
            return (
              hasError: true,
              workspaceId: workspace.id,
              workspaceName: workspace.name,
              hasMore: false,
              results: const <search.ConversationMessageSearchResult>[],
            );
          }
        }),
      );
      final localResults = await localFuture;
      final remoteResults = await remoteFuture;
      final hasMore = localResults.length == conversationMessageSearchPageSize;
      final results = [
        ...localResults,
        for (final workspaceResults in remoteResults)
          ...workspaceResults.results,
      ]..sort(compareConversationMessageSearchResults);

      return (
        results: results,
        hasMore: hasMore || remoteResults.any((page) => page.hasMore),
        hasError: remoteResults.any((page) => page.hasError),
      );
    });

int compareConversationMessageSearchResults(
  search.ConversationMessageSearchResult left,
  search.ConversationMessageSearchResult right,
) {
  final createdAt = right.createdAt.compareTo(left.createdAt);
  if (createdAt != 0) return createdAt;
  final workspaceId = right.workspaceId.compareTo(left.workspaceId);
  if (workspaceId != 0) return workspaceId;

  return right.messageId.compareTo(left.messageId);
}
