import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/message_bookmark_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'message_bookmark_usecase.g.dart';

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
  Future<bool> toggle({
    required String workspaceId,
    required String conversationId,
    required MessageEntity message,
    required bool isBookmarked,
    required Future<CloudConversationUsecase?> Function()
    resolveCloudConversation,
  }) async {
    final cloud = await resolveCloudConversation();
    if (cloud == null) {
      final persisted = isBookmarked
          ? await _messageRepository.unbookmarkMessage(
              workspaceId: workspaceId,
              conversationId: conversationId,
              messageId: message.id,
            )
          : await _messageRepository.bookmarkMessage(
              workspaceId: workspaceId,
              conversationId: conversationId,
              messageId: message.id,
            );
      if (!persisted) {
        throw StateError('Failed to update saved message.');
      }

      return false;
    }

    final sourceConversationId = message.sourceConversationId ?? conversationId;
    final sourceMessageId = message.sourceMessageId ?? message.id;
    if (isBookmarked) {
      await cloud.unbookmarkMessage(
        conversationId: conversationId,
        sourceConversationId: sourceConversationId,
        messageId: sourceMessageId,
      );
    } else {
      await cloud.bookmarkMessage(
        conversationId: conversationId,
        sourceConversationId: sourceConversationId,
        messageId: sourceMessageId,
      );
    }

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
    final workspaces = await _workspaceRepository.getAllWorkspaces();
    final workspace = workspaces
        .where((workspace) => _matchesBookmarkWorkspace(workspace, bookmark))
        .firstOrNull;
    if (workspace != null) return workspace;

    final serverUrl = bookmark.cloudServerUrl;
    final accountId = bookmark.cloudAccountId;
    final cloudWorkspaceId = bookmark.cloudWorkspaceId;
    if (serverUrl == null || accountId == null || cloudWorkspaceId == null) {
      throw const CloudAppException(
        localizationKey: LocaleKeys.cloud_errors_unavailable,
        context: .workspace,
      );
    }

    final account = CloudAccountKeyFactory.fromIdentity(serverUrl, accountId);

    return await attachAuthorizedWorkspace(
      account: account,
      workspaceId: cloudWorkspaceId,
    );
  }
}

bool _matchesBookmarkWorkspace(
  WorkspaceEntity workspace,
  MessageBookmarkEntity bookmark,
) {
  if (workspace.id != bookmark.workspaceId) return false;
  final cloudWorkspaceId = bookmark.cloudWorkspaceId;
  if (cloudWorkspaceId == null) return workspace.type == WorkspaceType.local;

  return workspace.type == WorkspaceType.remote &&
      workspace.cloudWorkspaceId == cloudWorkspaceId.toString() &&
      workspace.cloudAccountId == bookmark.cloudAccountId &&
      workspace.url == bookmark.cloudServerUrl;
}
