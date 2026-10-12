import 'package:auravibes_app/features/chats/notifiers/conversation_draft.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_draft_cleanup_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/local_chat_attachment_usecase.dart';
import 'package:riverpod/riverpod.dart';

final conversationDraftCleanupUsecaseProvider =
    Provider<ConversationDraftCleanupUsecase>((ref) {
      return ConversationDraftCleanupUsecase(
        registry: ref.watch(conversationDraftRegistryProvider),
        attachmentUsecase: ref.watch(localChatAttachmentUsecaseProvider),
      );
    });
