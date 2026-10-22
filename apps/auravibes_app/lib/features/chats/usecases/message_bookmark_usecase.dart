import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/message_bookmark_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/services/cloud_message_bookmark_gateway.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';
import 'package:auravibes_app/features/cloud_accounts/data/cloud_account_session.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart'
    show CloudWorkspaceException, CloudWorkspaceSummary, MessageBookmarkView;
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'message_bookmark_usecase.g.dart';

typedef MessageBookmarkToggleRequest = ({
  String workspaceId,
  String conversationId,
  MessageEntity message,
  bool isBookmarked,
  Future<CloudConversationUsecase?> Function() resolveCloudConversation,
});

typedef _ResolveCloudWorkspaceState = Future<CloudWorkspaceViewState?> Function(
  CloudAccountSession account,
);
typedef _ResolveCloudMessageBookmarkGateway =
    Future<CloudMessageBookmarkGateway?> Function(CloudAccountSession account);
typedef MessageBookmarkCloudLoadRequest = ({
  Future<List<CloudAccountSession>> Function() resolveAccounts,
  Future<List<WorkspaceEntity>> Function() resolveMirrors,
  Future<CloudWorkspaceViewState?> Function(CloudAccountSession account)
  resolveWorkspaceState,
  Future<CloudMessageBookmarkGateway?> Function(CloudAccountSession account)
  resolveGateway,
});
typedef _CloudBookmarkInputs = ({
  List<CloudAccountSession> accounts,
  List<WorkspaceEntity> mirrors,
});
typedef _CloudBookmarkAccountSource = ({
  CloudAccountSession account,
  List<WorkspaceEntity> mirrors,
  _ResolveCloudWorkspaceState resolveWorkspaceState,
  _ResolveCloudMessageBookmarkGateway resolveGateway,
});
typedef _CloudBookmarkAccountContext = ({
  CloudAccountSession account,
  List<WorkspaceEntity> mirrors,
  List<CloudWorkspaceSummary> workspaces,
  CloudMessageBookmarkGateway gateway,
});
typedef _CloudBookmarkWorkspaceContext = ({
  CloudAccountSession account,
  WorkspaceEntity? mirror,
  int cloudWorkspaceId,
});

@riverpod
MessageBookmarkUseCase messageBookmarkUseCase(Ref ref) {
  return MessageBookmarkUseCase(
    workspaceRepository: ref.watch(workspaceRepositoryProvider),
    messageRepository: ref.watch(messageRepositoryProvider),
  );
}

class const MessageBookmarkUseCase({
  required final WorkspaceRepository _workspaceRepository,
  required final MessageRepository _messageRepository,
});

extension MessageBookmarkUseCaseCore on MessageBookmarkUseCase {
  Future<bool> toggle(MessageBookmarkToggleRequest request) async {
    final cloud = await request.resolveCloudConversation();
    if (cloud == null) {
      await _toggleLocalBookmark(_messageRepository, request);

      return false;
    }

    await _toggleCloudBookmark(cloud, request);

    return true;
  }

  Future<WorkspaceEntity> resolveWorkspace(
    MessageBookmarkEntity bookmark, {
    required Future<WorkspaceEntity> Function({
      required CloudAccountKey account,
      required int workspaceId,
    })
    attachAuthorizedWorkspace,
  }) async {
    final workspace = await _existingBookmarkWorkspace(
      _workspaceRepository,
      bookmark,
    );
    if (workspace != null) return workspace;

    final cloudWorkspace = _cloudBookmarkWorkspace(bookmark);

    return await attachAuthorizedWorkspace(
      account: cloudWorkspace.account,
      workspaceId: cloudWorkspace.workspaceId,
    );
  }
}

extension MessageBookmarkCloudLoading on MessageBookmarkUseCase {
  Future<List<MessageBookmarkEntity>> loadCloudBookmarks(
    MessageBookmarkCloudLoadRequest request,
  ) async {
    final inputs = await _cloudBookmarkInputs(request);

    return await _cloudBookmarksForAccounts(inputs, request);
  }
}

Future<_CloudBookmarkInputs> _cloudBookmarkInputs(
  MessageBookmarkCloudLoadRequest request,
) async {
  final values = await Future.wait<Object>([
    request.resolveAccounts(),
    request.resolveMirrors(),
  ]);
  final [accounts, mirrors] = values;

  return (
    accounts: accounts as List<CloudAccountSession>,
    mirrors: mirrors as List<WorkspaceEntity>,
  );
}

Future<List<MessageBookmarkEntity>> _cloudBookmarksForAccounts(
  _CloudBookmarkInputs inputs,
  MessageBookmarkCloudLoadRequest request,
) async {
  final groups = await Future.wait(
    inputs.accounts.map(
      (account) => _bookmarksForCloudAccount((
        account: account,
        mirrors: inputs.mirrors,
        resolveWorkspaceState: request.resolveWorkspaceState,
        resolveGateway: request.resolveGateway,
      )),
    ),
  );

  return [for (final group in groups) ...group];
}

Future<List<MessageBookmarkEntity>> _bookmarksForCloudAccount(
  _CloudBookmarkAccountSource source,
) async {
  try {
    return await _loadCloudAccountBookmarks(source);
  } on Object catch (error) {
    if (_isExpectedCloudAccessError(error)) return const [];
    rethrow;
  }
}

Future<List<MessageBookmarkEntity>> _loadCloudAccountBookmarks(
  _CloudBookmarkAccountSource source,
) async {
  final context = await _cloudBookmarkAccountContext(source);
  if (context == null) return const [];

  return await _loadBookmarksForCloudWorkspaces(context);
}

Future<_CloudBookmarkAccountContext?> _cloudBookmarkAccountContext(
  _CloudBookmarkAccountSource source,
) async {
  final account = source.account;
  final state = await source.resolveWorkspaceState(account);
  if (state == null) {
    throw const AppCloudWorkspaceException(LocaleKeys.cloud_errors_unavailable);
  }
  if (state.authenticationRequired) return null;

  final gateway = await source.resolveGateway(account);
  if (gateway == null) {
    throw const AppCloudWorkspaceException(LocaleKeys.cloud_errors_unavailable);
  }

  return (
    account: account,
    mirrors: source.mirrors,
    workspaces: state.workspaces,
    gateway: gateway,
  );
}

Future<List<MessageBookmarkEntity>> _loadBookmarksForCloudWorkspaces(
  _CloudBookmarkAccountContext context,
) async {
  final groups = await Future.wait(
    context.workspaces.map(
      (workspace) => _bookmarksForCloudWorkspace(context, workspace),
    ),
  );

  return [for (final group in groups) ...group];
}

Future<List<MessageBookmarkEntity>> _bookmarksForCloudWorkspace(
  _CloudBookmarkAccountContext context,
  CloudWorkspaceSummary workspace,
) => _cloudWorkspaceBookmarks(context, (
  account: context.account,
  mirror: _mirrorForCloudWorkspace(context, workspace.id),
  cloudWorkspaceId: workspace.id,
));

WorkspaceEntity? _mirrorForCloudWorkspace(
  _CloudBookmarkAccountContext context,
  int workspaceId,
) => context.mirrors.firstWhereOrNull(
  (item) =>
      item.type.isRemote &&
      item.cloudWorkspaceId == workspaceId.toString() &&
      item.cloudAccount == context.account.key,
);

Future<List<MessageBookmarkEntity>> _cloudWorkspaceBookmarks(
  _CloudBookmarkAccountContext context,
  _CloudBookmarkWorkspaceContext workspace,
) async {
  try {
    return _bookmarkEntities(
      await context.gateway.listForWorkspace(workspace.cloudWorkspaceId),
      workspace,
    );
  } on Object catch (error) {
    if (_isExpectedCloudAccessError(error)) return const [];
    rethrow;
  }
}

List<MessageBookmarkEntity> _bookmarkEntities(
  List<MessageBookmarkView> bookmarks,
  _CloudBookmarkWorkspaceContext context,
) => bookmarks
    .map((bookmark) => _bookmarkEntity(bookmark, context))
    .toList(growable: false);

MessageBookmarkEntity _bookmarkEntity(
  MessageBookmarkView bookmark,
  _CloudBookmarkWorkspaceContext context,
) => MessageBookmarkEntity(
  details: _bookmarkDetails(bookmark),
  workspace: _bookmarkWorkspace(context),
);

MessageBookmarkDetails _bookmarkDetails(MessageBookmarkView bookmark) =>
    MessageBookmarkDetails(
      messageId: bookmark.messageId,
      conversationId: bookmark.conversationId,
      excerpt: bookmark.excerpt,
      workspaceName: bookmark.workspaceName,
      createdAt: bookmark.createdAt,
      conversationTitle: bookmark.conversationTitle,
      isUser: bookmark.isUser,
    );

MessageBookmarkWorkspace _bookmarkWorkspace(
  _CloudBookmarkWorkspaceContext context,
) => MessageBookmarkWorkspace(
  workspaceId: context.mirror?.id,
  cloudServerUrl: context.account.serverUrl,
  cloudAccountId: context.account.userId,
  cloudWorkspaceId: context.cloudWorkspaceId,
);

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

Future<void> _toggleLocalBookmark(
  MessageRepository repository,
  MessageBookmarkToggleRequest request,
) async {
  final update = request.isBookmarked
      ? repository.unbookmarkMessage
      : repository.bookmarkMessage;
  final persisted = await update(
    workspaceId: request.workspaceId,
    conversationId: request.conversationId,
    messageId: request.message.id,
  );
  if (!persisted) throw StateError('Failed to update saved message.');
}

Future<void> _toggleCloudBookmark(
  CloudConversationUsecase cloud,
  MessageBookmarkToggleRequest request,
) {
  final message = request.message;
  final sourceConversationId =
      message.sourceConversationId ?? request.conversationId;
  final sourceMessageId = message.sourceMessageId ?? message.id;
  final operation = request.isBookmarked
      ? cloud.unbookmarkMessage
      : cloud.bookmarkMessage;

  return operation(
    conversationId: request.conversationId,
    sourceConversationId: sourceConversationId,
    messageId: sourceMessageId,
  );
}

Future<WorkspaceEntity?> _existingBookmarkWorkspace(
  WorkspaceRepository repository,
  MessageBookmarkEntity bookmark,
) async {
  final workspaces = await repository.getAllWorkspaces();

  return workspaces.firstWhereOrNull(
    (workspace) => _matchesBookmarkWorkspace(workspace, bookmark),
  );
}

({CloudAccountKey account, int workspaceId}) _cloudBookmarkWorkspace(
  MessageBookmarkEntity bookmark,
) => switch (bookmark.workspace) {
  MessageBookmarkWorkspace(
    cloudServerUrl: final serverUrl?,
    cloudAccountId: final accountId?,
    cloudWorkspaceId: final workspaceId?,
  ) =>
    (
      account: CloudAccountKeyFactory.fromIdentity(serverUrl, accountId),
      workspaceId: workspaceId,
    ),
  _ => throw const CloudAppException(
    localizationKey: LocaleKeys.cloud_errors_unavailable,
    context: .workspace,
  ),
};

bool _matchesBookmarkWorkspace(
  WorkspaceEntity workspace,
  MessageBookmarkEntity bookmark,
) {
  if (workspace.id != bookmark.workspace.workspaceId) return false;
  if (workspace.type == WorkspaceType.local) {
    return bookmark.workspace.cloudWorkspaceId == null;
  }

  return _matchesCloudBookmarkWorkspace(workspace, bookmark);
}

bool _matchesCloudBookmarkWorkspace(
  WorkspaceEntity workspace,
  MessageBookmarkEntity bookmark,
) =>
    workspace.type == WorkspaceType.remote &&
    workspace.cloudWorkspaceId ==
        bookmark.workspace.cloudWorkspaceId?.toString() &&
    workspace.cloudAccountId == bookmark.workspace.cloudAccountId &&
    workspace.url == bookmark.workspace.cloudServerUrl;
