// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/generate_title_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/services/monitoring_service.dart';
import 'package:riverpod/riverpod.dart';

class SendNewMessageUsecase {
  const SendNewMessageUsecase({
    required this.conversationRepo,
    required this.sendMessageUsecase,

    required this.workspaceModelSelectionRepository,
    required this.generateTitleUsecase,
    required this.monitoringService,
  });

  final ConversationRepository conversationRepo;
  final SendMessageUsecase sendMessageUsecase;
  final WorkspaceModelSelectionRepository workspaceModelSelectionRepository;
  final GenerateTitleUsecase generateTitleUsecase;
  final MonitoringService monitoringService;
  Future<ConversationEntity> call({
    required String workspaceId,
    required ChatDraft draft,
    required String workspaceModelSelectionId,
    String? agentId,
  }) async {
    // Validate model selection exists before creating conversation.
    final workspaceModelSelection = await workspaceModelSelectionRepository
        .getWorkspaceModelSelectionById(workspaceModelSelectionId);

    if (workspaceModelSelection == null) {
      throw Exception('Selected model not found');
    }

    // Create conversation.
    final newConversation = await conversationRepo.createConversation(
      .new(
        title: 'New Conversation',
        workspaceId: workspaceId,
        modelId: workspaceModelSelectionId,
        agentId: agentId,
      ),
    );

    final firstMessage = draft.text.isEmpty
        ? draft.attachments
              .map((attachment) => attachment.displayName)
              .join(', ')
        : draft.text;
    if (firstMessage.isNotEmpty) {
      // Stream title.
      generateTitleUsecase.call(
        conversationId: newConversation.id,
        firstMessage: firstMessage,
        workspaceModelSelection: workspaceModelSelection,
      );
    }

    try {
      await sendMessageUsecase.sendFirstMessage(
        conversationId: newConversation.id,
        draft: draft,
        onContinueError: (error, stackTrace) {
          monitoringService.trackError(
            'Failed to continue first message',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );
    } on Object catch (error, stackTrace) {
      monitoringService.trackError(
        'Failed to send first message',
        error: error,
        stackTrace: stackTrace,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }

    return newConversation;
  }
}

final sendNewMessageUsecaseProvider = Provider<SendNewMessageUsecase>(
  (ref) {
    return SendNewMessageUsecase(
      conversationRepo: ref.watch(conversationRepositoryProvider),
      sendMessageUsecase: ref.watch(sendMessageUsecaseProvider),
      workspaceModelSelectionRepository: ref.watch(
        workspaceModelSelectionRepositoryProvider,
      ),
      generateTitleUsecase: ref.watch(generateTitleUsecaseProvider),
      monitoringService: ref.watch(monitoringServiceProvider),
    );
  },
);
