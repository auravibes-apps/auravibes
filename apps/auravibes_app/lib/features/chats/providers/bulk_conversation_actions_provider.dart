import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_archive_state_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_draft_cleanup_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/delete_conversation_provider.dart';
import 'package:auravibes_app/features/chats/usecases/bulk_conversation_actions_usecase.dart';
import 'package:riverpod/riverpod.dart';

final bulkConversationActionsUsecaseProvider =
    Provider<BulkConversationActionsUsecase>((ref) {
      final archiveRepository = ref.watch(
        conversationArchiveStateRepositoryProvider,
      );

      return BulkConversationActionsUsecase(
        conversationRepository: ref.watch(conversationRepositoryProvider),
        deleteConversation: (conversation) => ref
            .read(deleteConversationUsecaseProvider)
            .call(
              workspaceId: conversation.workspaceId,
              conversationId: conversation.id,
            ),
        resolveCloudConversation: (workspaceId) =>
            ref.read(cloudConversationUsecaseProvider(workspaceId).future),
        clearConversationDraft: ref
            .watch(conversationDraftCleanupUsecaseProvider)
            .clearConversation,
        clearConversationArchive: (workspaceId, conversationId) =>
            archiveRepository.clearConversationArchive(
              workspaceId: workspaceId,
              conversationId: conversationId,
            ),
      );
    });
