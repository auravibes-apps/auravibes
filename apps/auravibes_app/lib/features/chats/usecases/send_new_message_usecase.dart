// ignore_for_file: implementation_imports
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/services/cloud_conversation_creator.dart';
import 'package:auravibes_app/features/chats/usecases/generate_title_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/services/monitoring_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart' show Ref;
import 'package:riverpod/src/providers/provider.dart';

typedef _SendNewMessageRequest = ({
  String workspaceId,
  ChatDraft draft,
  String workspaceModelSelectionId,
  String? agentId,
  ConversationToolAccessMode toolAccessMode,
  ReasoningConfiguration? reasoningConfiguration,
});

class const SendNewMessageUsecase({
  required final ConversationRepository conversationRepo,
  required final SendMessageUsecase sendMessageUsecase,

  required final Future<ModelSelectionStore> Function(String workspaceId)
  modelSelectionStore,
  required final GenerateTitleUsecase generateTitleUsecase,
  required final MonitoringService monitoringService,
  final Future<ConversationEntity> Function(ConversationToCreate value)?
  cloudCreate,
  final void Function(String conversationId, AgentIterationDecision decision)?
  onAgentStop,
}) {
  Future<ConversationEntity> call(_SendNewMessageRequest request) =>
      _send(request);

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
        onAgentStop: onAgentStop,
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

  Future<ConversationEntity> _send(_SendNewMessageRequest request) async {
    final model = await _selectedModel(request);
    if (model == null) throw Exception('Selected model not found');

    final conversation = await _createConversation(
      _conversationToCreate(request),
    );
    _generateTitle(request, conversation, model);
    await _sendFirstMessage(conversation.id, request.draft);

    return conversation;
  }

  ConversationToCreate _conversationToCreate(_SendNewMessageRequest request) =>
      .new(
        title: 'New Conversation',
        workspaceId: request.workspaceId,
        toolAccessMode: request.toolAccessMode,
        modelId: request.workspaceModelSelectionId,
        agentId: request.agentId,
        reasoningConfiguration: request.reasoningConfiguration,
      );

  Future<WorkspaceModelSelectionWithConnectionEntity?> _selectedModel(
    _SendNewMessageRequest request,
  ) async {
    final store = await modelSelectionStore(request.workspaceId);

    return await store.getById(request.workspaceModelSelectionId);
  }

  void _generateTitle(
    _SendNewMessageRequest request,
    ConversationEntity conversation,
    WorkspaceModelSelectionWithConnectionEntity model,
  ) {
    final firstMessage = _firstMessage(request.draft);
    if (cloudCreate != null || firstMessage.isEmpty) return;

    generateTitleUsecase.call(
      conversationId: conversation.id,
      firstMessage: firstMessage,
      workspaceModelSelection: model,
    );
  }
}

SendNewMessageUsecase _sendNewMessageUsecase(Ref ref, String workspaceId) =>
    _buildSendNewMessageUsecase(ref, workspaceId, _isCloud(ref, workspaceId));

bool _isCloud(Ref ref, String workspaceId) =>
    ref
        .watch(workspaceSessionForRouteProvider(workspaceId))
        .requireValue
        .cloud !=
    null;

typedef _SendNewMessageUsecaseDependencies = ({
  ConversationRepository conversationRepo,
  SendMessageUsecase sendMessageUsecase,
  GenerateTitleUsecase generateTitleUsecase,
  MonitoringService monitoringService,
});

_SendNewMessageUsecaseDependencies _sendNewMessageUsecaseDependencies(
  Ref ref,
  String workspaceId,
) => (
  conversationRepo: ref.watch(conversationRepositoryProvider),
  sendMessageUsecase: ref.watch(sendMessageUsecaseProvider(workspaceId)),
  generateTitleUsecase: ref.watch(generateTitleUsecaseProvider),
  monitoringService: ref.watch(monitoringServiceProvider),
);

SendNewMessageUsecase _buildSendNewMessageUsecase(
  Ref ref,
  String workspaceId,
  bool isCloud,
) {
  final dependencies = _sendNewMessageUsecaseDependencies(ref, workspaceId);

  return SendNewMessageUsecase(
    conversationRepo: dependencies.conversationRepo,
    sendMessageUsecase: dependencies.sendMessageUsecase,
    modelSelectionStore: _loadModelSelectionStore(ref),
    generateTitleUsecase: dependencies.generateTitleUsecase,
    monitoringService: dependencies.monitoringService,
    cloudCreate: _cloudCreate(ref, workspaceId, isCloud),
    onAgentStop: _reportAgentStop(ref),
  );
}

Future<ModelSelectionStore> Function(String workspaceId)
_loadModelSelectionStore(Ref ref) =>
    (workspaceId) => ref.read(modelSelectionStoreProvider(workspaceId).future);

void Function(String conversationId, AgentIterationDecision decision)
_reportAgentStop(Ref ref) =>
    (conversationId, decision) => ref
        .read(conversationAgentStopDecisionProvider(conversationId).notifier)
        .markIfAgentStopDecision(decision);

Future<ConversationEntity> Function(ConversationToCreate)? _cloudCreate(
  Ref ref,
  String workspaceId,
  bool isCloud,
) => isCloud
    ? CloudConversationCreator(
        load: () =>
            ref.read(cloudConversationUsecaseProvider(workspaceId).future),
      ).call
    : null;

final ProviderFamily<SendNewMessageUsecase, String>
sendNewMessageUsecaseProvider = Provider.family<SendNewMessageUsecase, String>(
  _sendNewMessageUsecase,
  dependencies: [sendMessageUsecaseProvider],
);
