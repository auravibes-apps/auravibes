// ignore_for_file: implementation_imports
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/services/cloud_conversation_creator.dart';
import 'package:auravibes_app/features/chats/usecases/generate_title_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/services/monitoring_service.dart';
import 'package:riverpod/riverpod.dart' show Ref;
import 'package:riverpod/src/providers/provider.dart';

class const SendNewMessageUsecase({
  required final ConversationRepository conversationRepo,
  required final SendMessageUsecase sendMessageUsecase,

  required final Future<ModelSelectionStore> Function(String workspaceId)
  modelSelectionStore,
  required final GenerateTitleUsecase generateTitleUsecase,
  required final MonitoringService monitoringService,
  final Future<ConversationEntity> Function(ConversationToCreate value)?
  cloudCreate,
}) {}

extension on SendNewMessageUsecase {
  Future<ConversationEntity> call({
    required String workspaceId,
    required ChatDraft draft,
    required String workspaceModelSelectionId,
    String? agentId,
  }) async {
    final workspaceModelSelection = await (await modelSelectionStore(
      workspaceId,
    )).getById(workspaceModelSelectionId);
    if (workspaceModelSelection == null) {
      throw Exception('Selected model not found');
    }

    final value = ConversationToCreate(
      title: 'New Conversation',
      workspaceId: workspaceId,
      modelId: workspaceModelSelectionId,
      agentId: agentId,
    );
    final newConversation = await _createConversation(value);
    final firstMessage = _firstMessage(draft);
    if (cloudCreate == null && firstMessage.isNotEmpty) {
      generateTitleUsecase.call(
        conversationId: newConversation.id,
        firstMessage: firstMessage,
        workspaceModelSelection: workspaceModelSelection,
      );
    }

    await _sendFirstMessage(newConversation.id, draft);

    return newConversation;
  }

  Future<ConversationEntity> _createConversation(ConversationToCreate value) {
    final createCloudConversation = cloudCreate;

    return createCloudConversation == null
        ? conversationRepo.createConversation(value)
        : createCloudConversation(value);
  }

  String _firstMessage(ChatDraft draft) => draft.text.isEmpty
      ? draft.attachments.map((attachment) => attachment.displayName).join(', ')
      : draft.text;

  Future<void> _sendFirstMessage(String conversationId, ChatDraft draft) async {
    try {
      await sendMessageUsecase.sendFirstMessage(
        conversationId: conversationId,
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
  }
}

SendNewMessageUsecase _sendNewMessageUsecase(Ref ref, String workspaceId) {
  final isCloud =
      ref
          .watch(workspaceSessionForRouteProvider(workspaceId))
          .requireValue
          .cloud !=
      null;

  return SendNewMessageUsecase(
    conversationRepo: ref.watch(conversationRepositoryProvider),
    sendMessageUsecase: ref.watch(sendMessageUsecaseProvider(workspaceId)),
    modelSelectionStore: (workspaceId) =>
        ref.read(modelSelectionStoreProvider(workspaceId).future),
    generateTitleUsecase: ref.watch(generateTitleUsecaseProvider),
    monitoringService: ref.watch(monitoringServiceProvider),
    cloudCreate: isCloud
        ? CloudConversationCreator(
            load: () =>
                ref.read(cloudConversationUsecaseProvider(workspaceId).future),
          ).call
        : null,
  );
}

final ProviderFamily<SendNewMessageUsecase, String>
sendNewMessageUsecaseProvider = Provider.family<SendNewMessageUsecase, String>(
  _sendNewMessageUsecase,
  dependencies: [sendMessageUsecaseProvider],
);
