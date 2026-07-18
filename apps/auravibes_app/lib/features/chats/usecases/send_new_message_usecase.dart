// ignore_for_file: implementation_imports
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/generate_title_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/services/monitoring_service.dart';
import 'package:riverpod/src/providers/provider.dart';

class SendNewMessageUsecase {
  const SendNewMessageUsecase({
    required this.conversationRepo,
    required this.sendMessageUsecase,

    required this.modelSelectionStore,
    required this.generateTitleUsecase,
    required this.monitoringService,
    this.cloudCreate,
  });

  final ConversationRepository conversationRepo;
  final SendMessageUsecase sendMessageUsecase;
  final Future<ModelSelectionStore> Function(String workspaceId)
  modelSelectionStore;
  final GenerateTitleUsecase generateTitleUsecase;
  final MonitoringService monitoringService;
  final Future<ConversationEntity> Function(ConversationToCreate value)?
  cloudCreate;
  Future<ConversationEntity> call({
    required String workspaceId,
    required ChatDraft draft,
    required String workspaceModelSelectionId,
    String? agentId,
  }) async {
    // Validate model selection exists before creating conversation.
    final workspaceModelSelection = await (await modelSelectionStore(
      workspaceId,
    )).getById(workspaceModelSelectionId);

    if (workspaceModelSelection == null) {
      throw Exception('Selected model not found');
    }

    // Create conversation.
    final value = ConversationToCreate(
      title: 'New Conversation',
      workspaceId: workspaceId,
      modelId: workspaceModelSelectionId,
      agentId: agentId,
    );
    final createCloudConversation = cloudCreate;
    final newConversation = createCloudConversation == null
        ? await conversationRepo.createConversation(value)
        : await createCloudConversation(value);

    final firstMessage = draft.text.isEmpty
        ? draft.attachments
              .map((attachment) => attachment.displayName)
              .join(', ')
        : draft.text;
    if (createCloudConversation == null && firstMessage.isNotEmpty) {
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

final ProviderFamily<SendNewMessageUsecase, String>
sendNewMessageUsecaseProvider = Provider.family<SendNewMessageUsecase, String>(
  (ref, workspaceId) {
    final isCloud =
        ref
            .watch(
              workspaceSessionForRouteProvider(workspaceId),
            )
            .requireValue
            .cloud !=
        null;

    return SendNewMessageUsecase(
      conversationRepo: ref.watch(conversationRepositoryProvider),
      sendMessageUsecase: ref.watch(sendMessageUsecaseProvider(workspaceId)),
      modelSelectionStore: (workspaceId) => ref.read(
        modelSelectionStoreProvider(workspaceId).future,
      ),
      generateTitleUsecase: ref.watch(generateTitleUsecaseProvider),
      monitoringService: ref.watch(monitoringServiceProvider),
      cloudCreate: isCloud
          ? (value) async {
              final usecase = await ref.read(
                cloudConversationUsecaseProvider(workspaceId).future,
              );
              if (usecase == null) {
                throw StateError('Cloud workspace unavailable');
              }
              final created = await usecase.create(value);

              return ConversationEntity(
                id: created.id,
                title: created.title,
                workspaceId: value.workspaceId,
                isPinned: created.isPinned,
                createdAt: created.createdAt,
                updatedAt: created.updatedAt,
                revision: created.revision,
                modelId: created.modelId,
                agentId: created.agentId,
                parentConversationId: created.parentConversationId,
              );
            }
          : null,
    );
  },
);
