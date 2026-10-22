import 'package:auravibes_app/domain/entities/message_bookmark_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/services/cloud_message_bookmark_gateway.dart';
import 'package:auravibes_app/features/chats/usecases/message_bookmark_usecase.dart';
import 'package:auravibes_app/features/cloud_accounts/data/cloud_account_session.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_session_identity.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_workspaces/models/cloud_workspace_view_state.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'message_bookmarks_provider.g.dart';

@Riverpod(retry: _doNotRetry)
Future<List<MessageBookmarkEntity>> cloudMessageBookmarks(Ref ref) =>
    _MessageBookmarksProvider(ref: ref).loadCloudBookmarks();

@Riverpod(retry: _doNotRetry)
Stream<List<MessageBookmarkEntity>> messageBookmarks(
  Ref ref,
  String workspaceId,
) => _MessageBookmarksProvider(ref: ref).watchBookmarks(workspaceId);

class const _MessageBookmarksProvider({required final Ref ref}) {
  Future<List<MessageBookmarkEntity>> loadCloudBookmarks() =>
      ref.watch(messageBookmarkUseCaseProvider).loadCloudBookmarks((
        resolveAccounts: _accounts,
        resolveMirrors: _mirrors,
        resolveWorkspaceState: _workspaceState,
        resolveGateway: _gateway,
      ));

  Stream<List<MessageBookmarkEntity>> watchBookmarks(
    String workspaceId,
  ) async* {
    final _ = await ref.watch(
      workspaceSessionForRouteProvider(workspaceId).future,
    );
    yield* _mergeBookmarkStreams(_localBookmarks(), _cloudBookmarks());
  }

  Future<List<CloudAccountSession>> _accounts() =>
      ref.watch(cloudAccountsProvider.future);

  Future<List<WorkspaceEntity>> _mirrors() =>
      ref.watch(allWorkspacesProvider.future);

  Future<CloudWorkspaceViewState?> _workspaceState(
    CloudAccountSession account,
  ) => ref.watch(cloudWorkspaceStateProvider(account.key).future);

  Future<CloudMessageBookmarkGateway?> _gateway(
    CloudAccountSession account,
  ) async {
    final client = await ref.watch(
      serverpodClientForAccountProvider(account.key).future,
    );

    return client == null ? null : CloudMessageBookmarkGateway(client);
  }

  Stream<List<MessageBookmarkEntity>> _localBookmarks() =>
      ref.watch(messageRepositoryProvider).watchBookmarkedMessages();

  List<MessageBookmarkEntity> _cloudBookmarks() =>
      ref.watch(cloudMessageBookmarksProvider).asData?.value ??
      const <MessageBookmarkEntity>[];
}

Stream<List<MessageBookmarkEntity>> _mergeBookmarkStreams(
  Stream<List<MessageBookmarkEntity>> localBookmarks,
  List<MessageBookmarkEntity> cloudBookmarks,
) => localBookmarks.map(
  (local) => _sortedBookmarks([...local, ...cloudBookmarks]),
);

List<MessageBookmarkEntity> _sortedBookmarks(
  Iterable<MessageBookmarkEntity> bookmarks,
) =>
    bookmarks.toList()
      ..sort((a, b) => b.details.createdAt.compareTo(a.details.createdAt));

Duration? _doNotRetry(int _, Object _) => null;
