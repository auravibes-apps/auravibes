import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/message_bookmark_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/message_bookmarks_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/data/cloud_account_session.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_workspaces/models/cloud_workspace_view_state.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class _Client extends Mock implements Client;

class _ConversationEndpoint extends Mock implements EndpointConversation;
class _MessageRepository extends Mock implements MessageRepository;
class _WorkspaceRepository extends Mock implements WorkspaceRepository;

void main() {
  setUpAll(() {
    registerFallbackValue(ListMessageBookmarksRequest(workspaceId: 0));
  });

  test(
    'includes authorized bookmarks from unmirrored cloud workspaces',
    () async {
      const account = CloudAccountSession(
        serverUrl: 'https://cloud.example',
        userId: 'user-1',
        email: 'user@example.com',
      );
      final client = _Client();
      final conversation = _ConversationEndpoint();
      final workspaces = [
        _cloudWorkspace(11, 'Mirrored'),
        _cloudWorkspace(12, 'Unmirrored'),
        _cloudWorkspace(13, 'Unavailable'),
      ];
      when(() => client.conversation).thenReturn(conversation);
      when(() => conversation.listMessageBookmarks(any()))
          .thenAnswer((call) async {
            final request =
                call.positionalArguments.single as ListMessageBookmarksRequest;
            final workspace = workspaces.singleWhere(
              (workspace) => workspace.id == request.workspaceId,
            );
            if (workspace.id == 13) {
              throw ConversationException(code: .permissionDenied);
            }

            return [
              MessageBookmarkView(
                conversationId: 'conversation-${workspace.id}',
                messageId: 'message-${workspace.id}',
                excerpt: 'Saved in ${workspace.name}',
                conversationTitle: 'Conversation ${workspace.name}',
                workspaceName: workspace.name,
                createdAt: .utc(2026),
              ),
            ];
          });

      final container = ProviderContainer(
        overrides: [
          messageRepositoryProvider.overrideWithValue(_MessageRepository()),
          workspaceRepositoryProvider.overrideWithValue(_WorkspaceRepository()),
          cloudAccountsProvider.overrideWith((ref) async => [account]),
          allWorkspacesProvider.overrideWith(
            (ref) => Stream.value([
              WorkspaceEntity(
                id: 'mirror-11',
                name: 'Mirrored',
                type: .remote,
                createdAt: .utc(2026),
                updatedAt: .utc(2026),
                url: account.serverUrl,
                cloudWorkspaceId: '11',
                cloudAccountId: account.userId,
              ),
            ]),
          ),
          cloudWorkspaceStateProvider.overrideWith(
            (ref, _) async => CloudWorkspaceViewState(
              workspaces: workspaces,
              pendingInvites: const [],
            ),
          ),
          serverpodClientForAccountProvider.overrideWith(
            (ref, _) async => client,
          ),
        ],
      );
      addTearDown(container.dispose);
      final workspaceSubscription = container.listen(
        allWorkspacesProvider,
        (_, next) => expect(next.asData?.value, isNotNull),
      );
      addTearDown(workspaceSubscription.close);

      expect(await container.read(allWorkspacesProvider.future), hasLength(1));
      expect(await container.read(cloudAccountsProvider.future), [account]);

      final bookmarks = await container.read(
        cloudMessageBookmarksProvider.future,
      );
      final byMessageId = {
        for (final bookmark in bookmarks) bookmark.details.messageId: bookmark,
      };

      expect(byMessageId, hasLength(2));
      expect(byMessageId['message-11']?.workspace.workspaceId, 'mirror-11');
      expect(byMessageId['message-12']?.workspace.workspaceId, isNull);
      expect(
        byMessageId['message-12']?.workspace.cloudServerUrl,
        account.serverUrl,
      );
      expect(
        byMessageId['message-12']?.workspace.cloudAccountId,
        account.userId,
      );
      expect(byMessageId['message-12']?.workspace.cloudWorkspaceId, 12);
      verify(() => conversation.listMessageBookmarks(any())).called(3);
    },
  );

  test('surfaces unexpected cloud bookmark fetch failures', () async {
    const account = CloudAccountSession(
      serverUrl: 'https://cloud.example',
      userId: 'user-1',
      email: 'user@example.com',
    );
    final client = _Client();
    final conversation = _ConversationEndpoint();
    final mirrors = [
      WorkspaceEntity(
        id: 'mirror-11',
        name: 'Workspace',
        type: .remote,
        createdAt: .utc(2026),
        updatedAt: .utc(2026),
        url: account.serverUrl,
        cloudWorkspaceId: '11',
        cloudAccountId: account.userId,
      ),
    ];
    when(() => client.conversation).thenReturn(conversation);
    when(() => conversation.listMessageBookmarks(any()))
        .thenThrow(StateError('Cloud unavailable.'));
    final container = ProviderContainer(
      overrides: [
        messageRepositoryProvider.overrideWithValue(_MessageRepository()),
        workspaceRepositoryProvider.overrideWithValue(_WorkspaceRepository()),
        cloudAccountsProvider.overrideWith((ref) async => [account]),
        allWorkspacesProvider.overrideWith((ref) => Stream.value(mirrors)),
        cloudWorkspaceStateProvider.overrideWith(
          (ref, _) async => CloudWorkspaceViewState(
            workspaces: [_cloudWorkspace(11, 'Workspace')],
            pendingInvites: const [],
          ),
        ),
        serverpodClientForAccountProvider.overrideWith(
          (ref, _) async => client,
        ),
      ],
    );
    addTearDown(container.dispose);
    final workspaceSubscription = container.listen(
      allWorkspacesProvider,
      (_, next) => expect(next.asData?.value, isNotNull),
    );
    addTearDown(workspaceSubscription.close);
    final bookmarkSubscription = container.listen(
      cloudMessageBookmarksProvider,
      (_, next) =>
          expect(next.isLoading || next.hasValue || next.hasError, isTrue),
    );
    addTearDown(bookmarkSubscription.close);
    expect(await container.read(allWorkspacesProvider.future), mirrors);
    expect(await container.read(cloudAccountsProvider.future), [account]);

    await expectLater(
      container.read(cloudMessageBookmarksProvider.future),
      throwsA(isA<CloudAppException>()),
    );
  });

  test('keeps local bookmarks when cloud fetch fails', () async {
    const workspaceId = 'local-1';
    final localBookmark = MessageBookmarkEntity(
      details: .new(
        messageId: 'message-local',
        conversationId: 'conversation-local',
        excerpt: 'Local saved message',
        workspaceName: 'Local workspace',
        createdAt: .utc(2026),
      ),
      workspace: const MessageBookmarkWorkspace(workspaceId: workspaceId),
    );
    final messageRepository = _MessageRepository();
    when(messageRepository.watchBookmarkedMessages)
        .thenAnswer((_) => Stream.value([localBookmark]));
    final container = ProviderContainer(
      overrides: [
        messageRepositoryProvider.overrideWithValue(messageRepository),
        workspaceRepositoryProvider.overrideWithValue(_WorkspaceRepository()),
        workspaceSessionForRouteProvider(workspaceId).overrideWithValue(
          const AsyncData(
            WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: workspaceId)),
          ),
        ),
        cloudMessageBookmarksProvider.overrideWith(
          (ref) => Future.error(StateError('Cloud unavailable.')),
        ),
      ],
    );
    addTearDown(container.dispose);
    final bookmarkStates = <AsyncValue<List<MessageBookmarkEntity>>>[];
    final bookmarksSubscription = container.listen(
      messageBookmarksProvider(workspaceId),
      (_, next) => bookmarkStates.add(next),
    );
    addTearDown(bookmarksSubscription.close);
    expect(await container.read(messageBookmarksProvider(workspaceId).future), [
      localBookmark,
    ]);
    expect(bookmarkStates.last.asData?.value, [localBookmark]);
    await expectLater(
      container.read(cloudMessageBookmarksProvider.future),
      throwsA(isA<StateError>()),
    );
  });
}

CloudWorkspaceSummary _cloudWorkspace(int id, String name) =>
    CloudWorkspaceSummary(
      id: id,
      name: name,
      role: 'member',
      revision: 1,
      sequence: 1,
      createdAt: .utc(2026),
      updatedAt: .utc(2026),
    );
