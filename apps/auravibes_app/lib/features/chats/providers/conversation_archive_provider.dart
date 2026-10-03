import 'package:auravibes_app/data/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/services/conversation_archive_file_service.dart';
import 'package:auravibes_app/features/chats/services/local_chat_attachment_service.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_archive_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod/riverpod.dart';

final conversationArchiveFileServiceProvider =
    Provider<ConversationArchiveFileService>(
      (_) => const ConversationArchiveFileService(),
    );

final conversationArchiveUsecaseProvider = Provider<ConversationArchiveUsecase>(
  (ref) {
    final database = ref.watch(appDatabaseProvider);
    final workspaceTools = WorkspaceToolsRepository(database);

    return ConversationArchiveUsecase(
      conversationRepository: ref.watch(conversationRepositoryProvider),
      messageRepository: ref.watch(messageRepositoryProvider),
      attachmentService: ref.watch(localChatAttachmentServiceProvider),
      conversationToolsRepository: .new(database, workspaceTools),
      workspaceToolsRepository: workspaceTools,
      toolsGroupsRepository: .new(database),
      attachmentFileStore: ref.watch(attachmentFileStoreProvider),
    );
  },
);
