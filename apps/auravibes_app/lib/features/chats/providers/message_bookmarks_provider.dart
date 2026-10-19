import 'package:auravibes_app/domain/entities/message_bookmark_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/services/cloud_message_bookmark_gateway.dart';
import 'package:auravibes_app/features/cloud_accounts/data/cloud_account_session.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart'
    show CloudWorkspaceException;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'message_bookmarks_provider.g.dart';

@Riverpod(retry: _doNotRetry)
Future<List<MessageBookmarkEntity>> cloudMessageBookmarks(Ref ref) async {
  final mirrors = await ref.watch(allWorkspacesProvider.future);
  final accounts = await ref.watch(cloudAccountsProvider.future);
  final groups = await Future.wait(
    accounts.map((account) => _bookmarksForCloudAccount(ref, account, mirrors)),
  );

  return [for (final group in groups) ...group]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

@Riverpod(retry: _doNotRetry)
Stream<List<MessageBookmarkEntity>> messageBookmarks(
  Ref ref,
  String workspaceId,
) async* {
  final _ = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  final cloudBookmarks =
      ref.watch(cloudMessageBookmarksProvider).asData?.value ??
      const <MessageBookmarkEntity>[];

  yield* ref.watch(messageRepositoryProvider).watchBookmarkedMessages().map((
    localBookmarks,
  ) {
    return [...localBookmarks, ...cloudBookmarks]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });
}

Duration? _doNotRetry(int _, Object _) => null;

Future<List<MessageBookmarkEntity>> _bookmarksForCloudAccount(
  Ref ref,
  CloudAccountSession account,
  List<WorkspaceEntity> mirrors,
) async {
  final key = account.key;
  try {
    final state = await ref.watch(cloudWorkspaceStateProvider(key).future);
    if (state == null) {
      throw const AppCloudWorkspaceException(
        LocaleKeys.cloud_errors_unavailable,
      );
    }
    if (state.authenticationRequired) return const [];

    final client = await ref.watch(
      serverpodClientForAccountProvider(key).future,
    );
    if (client == null) {
      throw const AppCloudWorkspaceException(
        LocaleKeys.cloud_errors_unavailable,
      );
    }
    final gateway = CloudMessageBookmarkGateway(client);

    final groups = await Future.wait(
      state.workspaces.map((workspace) async {
        final mirror = mirrors
            .where(
              (item) =>
                  item.type == WorkspaceType.remote &&
                  item.cloudWorkspaceId == workspace.id.toString() &&
                  item.cloudAccount == key,
            )
            .firstOrNull;
        try {
          return [
            for (final bookmark in await gateway.listForWorkspace(workspace.id))
              MessageBookmarkEntity(
                workspaceId: mirror?.id,
                messageId: bookmark.messageId,
                conversationId: bookmark.conversationId,
                excerpt: bookmark.excerpt,
                workspaceName: bookmark.workspaceName,
                createdAt: bookmark.createdAt,
                conversationTitle: bookmark.conversationTitle,
                cloudServerUrl: account.serverUrl,
                cloudAccountId: account.userId,
                cloudWorkspaceId: workspace.id,
              ),
          ];
        } on Object catch (error) {
          if (_isExpectedCloudAccessError(error)) {
            return const <MessageBookmarkEntity>[];
          }
          rethrow;
        }
      }),
    );

    return [for (final group in groups) ...group];
  } on Object catch (error) {
    if (_isExpectedCloudAccessError(error)) return const [];
    rethrow;
  }
}

bool _isExpectedCloudAccessError(Object error) => switch (error) {
  CloudAppException(:final code) =>
    code == 'authenticationRequired' ||
        code == 'emailAccountRequired' ||
        code == 'workspaceNotFound' ||
        code == 'membershipRequired' ||
        code == 'permissionDenied' ||
        code == 'notFound',
  CloudWorkspaceException(
    code: .authenticationRequired ||
        .emailAccountRequired ||
        .workspaceNotFound ||
        .membershipRequired ||
        .permissionDenied,
  ) =>
    true,
  _ => false,
};
