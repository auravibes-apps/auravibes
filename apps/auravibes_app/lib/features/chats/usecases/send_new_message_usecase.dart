import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_model_selection_repository.dart';
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
    required String firstMessage,
    required String workspaceModelSelectionId,
  }) async {
    // Validate model selection exists before creating conversation
    final workspaceModelSelection = await workspaceModelSelectionRepository
        .getWorkspaceModelSelectionById(workspaceModelSelectionId);

    if (workspaceModelSelection == null) {
      throw Exception('Selected model not found');
    }

    // create conversation
    final newConversation = await conversationRepo.createConversation(
      .new(
        title: 'New Conversation',
        workspaceId: workspaceId,
        modelId: workspaceModelSelectionId,
      ),
    );

    // stream title
    generateTitleUsecase.call(
      conversationId: newConversation.id,
      firstMessage: firstMessage,
      workspaceModelSelection: workspaceModelSelection,
    );

    sendMessageUsecase
        .call(
          conversationId: newConversation.id,
          content: firstMessage,
        )
        .onError((error, stackTrace) {
          monitoringService.trackError(
            'Failed to send first message',
            error: error,
            stackTrace: stackTrace,
          );
        });
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
