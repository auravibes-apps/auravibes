// ignore_for_file: implementation_imports
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:convert';

import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/providers/chatbot_service_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_turn_provider.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/services/chatbot/build_prompt_chat_messages.dart';
import 'package:auravibes_app/features/chats/services/chatbot/chatbot_service.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_compaction_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/select_compaction_range_usecase.dart';
import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show
        ChatMessage,
        ChatResult,
        conversationCompactionRequestPrompt,
        conversationCompactionSystemPrompt,
        requireCompactionSummary;
import 'package:riverpod/src/providers/provider.dart';

typedef _LocalCompactionRequest = ({
  ConversationRepository conversations,
  Future<ModelSelectionStore> Function(String workspaceId) getModelStore,
  MessageRepository messagesRepository,
  SelectCompactionRangeUsecase selectRange,
  String conversationId,
  CompactionTrigger trigger,
});

typedef _CompactionInput = ({
  List<ChatMessage> chatHistory,
  CompactionRange range,
});

class const CompactConversationUsecase({
  required final CompactionExecutionRuntime compactionExecution,
  final MessageRepository? messageRepository,
  final ConversationRepository? conversationRepository,
  final Future<ModelSelectionStore> Function(String workspaceId)?
  modelSelectionStore,
  final ChatbotService? chatbotService,
  final SelectCompactionRangeUsecase? selectCompactionRangeUsecase,
  final CloudCompactionUsecase? cloudCompaction,
  final Future<ConversationEntity?> Function(String id)? cloudConversation,
}) {
  static const String _failureMessageKey =
      LocaleKeys.compaction_errors_auto_blocked;
  static const BuildPromptChatMessages _buildPromptChatMessages = .new();

  Future<CompactionExecutionState> call({
    required String conversationId,
    required CompactionTrigger trigger,
  }) async {
    final cloud = cloudCompaction;
    if (cloud != null) {
      return await _compactCloud(
        cloud: cloud,
        conversationId: conversationId,
        trigger: trigger,
      );
    }

    return await _compactLocal(
      conversationId: conversationId,
      trigger: trigger,
    );
  }

  Future<List<ChatMessage>> _buildCompactionPrompt(
    List<MessageEntity> messages,
  ) async {
    return [
      ChatMessage.system(conversationCompactionSystemPrompt),
      ...await _buildPromptChatMessages.call(messages),
      ChatMessage.user(conversationCompactionRequestPrompt),
    ];
  }

  Future<String> _generateSummary(
    WorkspaceModelSelectionWithConnectionEntity model,
    List<ChatMessage> chatHistory,
  ) async {
    final service = chatbotService;
    if (service == null) {
      throw StateError('Local chatbot service unavailable');
    }
    final stream = service.sendMessage(model, chatHistory);

    return requireCompactionSummary(await _collectSummaryText(stream));
  }

  Future<String> _collectSummaryText(
    Stream<ChatResult<ChatMessage>> stream,
  ) async {
    final chunks = <String>[];
    await for (final chunk in stream) {
      chunks.add(chunk.output.text);
    }

    return chunks.join();
  }

  Future<void> _persistCompactionSummary({
    required String conversationId,
    required String summaryText,
    required CompactionRange range,
    required CompactionTrigger trigger,
  }) async {
    final metadata = _compactionSummaryMetadata(range, trigger);

    final repository = messageRepository;
    if (repository == null) {
      throw StateError('Local message repository unavailable');
    }
    final created = await _createCompactionSummaryMessage(
      repository,
      conversationId,
      summaryText,
      metadata,
    );
    await _markCompactionMessageSent(repository, created.id);
  }

  Future<MessageEntity> _createCompactionSummaryMessage(
    MessageRepository repository,
    String conversationId,
    String summaryText,
    MessageMetadataEntity metadata,
  ) => repository.createMessage(
    .new(
      conversationId: conversationId,
      content: summaryText,
      messageType: MessageType.system,
      isUser: false,
      status: MessageStatus.sending,
      metadata: jsonEncode(metadata.toJson()),
    ),
  );

  MessageMetadataEntity _compactionSummaryMetadata(
    CompactionRange range,
    CompactionTrigger trigger,
  ) => MessageMetadataEntity(
    metadataVersion: 2,
    isCompactionSummary: true,
    compactionKind: trigger == CompactionTrigger.auto
        ? CompactionKind.auto
        : CompactionKind.manual,
    compactedFromMessageId: range.fromMessageId,
    compactedThroughMessageId: range.throughMessageId,
    compactedMessageIds: range.messageIds,
    compactionCreatedAt: .now(),
  );

  Future<void> _markCompactionMessageSent(
    MessageRepository repository,
    String messageId,
  ) async {
    final _ = await repository.patchMessage(
      messageId,
      const MessagePatch(status: .sent),
    );
  }

  Future<void> _persistRequiredFailureMessage({
    required String conversationId,
  }) async {
    final repository = messageRepository;
    if (repository == null) {
      throw StateError('Local message repository unavailable');
    }
    final created = await _createFailureMessage(repository, conversationId);
    final _ = await repository.patchMessage(
      created.id,
      const MessagePatch(status: .error),
    );
  }

  Future<MessageEntity> _createFailureMessage(
    MessageRepository repository,
    String conversationId,
  ) => repository.createMessage(
    .new(
      conversationId: conversationId,
      content: _failureMessageKey,
      messageType: MessageType.system,
      isUser: false,
      status: MessageStatus.sending,
    ),
  );
}

extension on CompactConversationUsecase {
  Future<CompactionExecutionState> _compactCloud({
    required CloudCompactionUsecase cloud,
    required String conversationId,
    required CompactionTrigger trigger,
  }) async {
    final getCloudConversation = cloudConversation;
    if (getCloudConversation == null) {
      throw StateError('Cloud conversation dependency unavailable');
    }
    final conversation = await getCloudConversation(conversationId);
    if (conversation == null) throw const CompactionUnavailableException();
    if (conversation.modelId == null) {
      throw const CompactionNoModelSelectedException();
    }

    return await cloud(conversation: conversation, trigger: trigger);
  }

  Future<CompactionExecutionState> _compactLocal({
    required String conversationId,
    required CompactionTrigger trigger,
  }) {
    final dependencies = _requiredLocalDependencies();
    final startedAt = DateTime.now();
    final executionState = _runningState(conversationId, trigger, startedAt);
    final request = _localCompactionRequest(
      dependencies,
      conversationId,
      trigger,
    );

    return compactionExecution.run(
      runningState: executionState,
      operation: () => _completeLocalCompaction(this, request, startedAt),
    );
  }

  CompactionExecutionState _runningState(
    String conversationId,
    CompactionTrigger trigger,
    DateTime startedAt,
  ) => .new(
    conversationId: conversationId,
    trigger: trigger,
    startedAt: startedAt,
    status: CompactionExecutionStatus.running,
  );

  ({
    ConversationRepository conversations,
    MessageRepository messagesRepository,
    Future<ModelSelectionStore> Function(String workspaceId) getModelStore,
    SelectCompactionRangeUsecase selectRange,
  })
  _requiredLocalDependencies() {
    final conversations = this.conversationRepository;
    final getModelStore = this.modelSelectionStore;
    final messagesRepository = this.messageRepository;
    final selectRange = selectCompactionRangeUsecase;
    if (conversations == null ||
        getModelStore == null ||
        messagesRepository == null ||
        selectRange == null) {
      throw StateError('Local compaction dependencies unavailable');
    }

    return (
      conversations: conversations,
      messagesRepository: messagesRepository,
      getModelStore: getModelStore,
      selectRange: selectRange,
    );
  }

  Future<void> _executeLocalCompaction(_LocalCompactionRequest request) async {
    final conversation = await request.conversations.getConversationById(
      request.conversationId,
    );
    if (conversation == null) {
      throw const CompactionUnavailableException();
    }

    final foundModel = await _findCompactionModel(request, conversation);
    final input = await _buildCompactionInput(request, conversation);
    await _persistGeneratedSummary(request, foundModel, input);
  }

  Future<void> _persistGeneratedSummary(
    _LocalCompactionRequest request,
    WorkspaceModelSelectionWithConnectionEntity model,
    _CompactionInput input,
  ) async {
    final summaryText = await _generateCompactionSummary(
      model,
      input.chatHistory,
      conversationId: request.conversationId,
      trigger: request.trigger,
    );
    await _persistCompactionSummary(
      conversationId: request.conversationId,
      summaryText: summaryText,
      range: input.range,
      trigger: request.trigger,
    );
  }

  Future<_CompactionInput> _buildCompactionInput(
    _LocalCompactionRequest request,
    ConversationEntity conversation,
  ) async {
    final messages = await request.messagesRepository.getMessagesByConversation(
      conversation.id,
    );
    final range = request.selectRange(messages);
    if (range == null) throw const CompactionUnsafeException();

    return (
      chatHistory: await _buildCompactionPrompt(
        _compactableMessages(messages, range),
      ),
      range: range,
    );
  }

  Future<WorkspaceModelSelectionWithConnectionEntity> _findCompactionModel(
    _LocalCompactionRequest request,
    ConversationEntity conversation,
  ) async {
    final modelId = conversation.modelId;
    if (modelId == null) {
      throw const CompactionNoModelSelectedException();
    }

    final model = await (await request.getModelStore(conversation.workspaceId))
        .getById(modelId);
    if (model == null) throw const CompactionModelMissingException();

    return model;
  }

  List<MessageEntity> _compactableMessages(
    List<MessageEntity> messages,
    CompactionRange range,
  ) => messages
      .where((message) => range.messageIds.contains(message.id))
      .toList();

  Future<String> _generateCompactionSummary(
    WorkspaceModelSelectionWithConnectionEntity model,
    List<ChatMessage> chatHistory, {
    required String conversationId,
    required CompactionTrigger trigger,
  }) async {
    try {
      return await _generateSummary(model, chatHistory);
    } on Exception catch (error, stackTrace) {
      if (trigger == CompactionTrigger.auto) {
        await _persistRequiredFailureMessage(conversationId: conversationId);
      }

      Error.throwWithStackTrace(
        CompactionFailedException(cause: error),
        stackTrace,
      );
    }
  }
}

Future<CompactionExecutionState> _completeLocalCompaction(
  CompactConversationUsecase usecase,
  _LocalCompactionRequest request,
  DateTime startedAt,
) async {
  await usecase._executeLocalCompaction(request);

  return _successState(request.conversationId, request.trigger, startedAt);
}

_LocalCompactionRequest _localCompactionRequest(
  ({
    ConversationRepository conversations,
    MessageRepository messagesRepository,
    Future<ModelSelectionStore> Function(String workspaceId) getModelStore,
    SelectCompactionRangeUsecase selectRange,
  })
  dependencies,
  String conversationId,
  CompactionTrigger trigger,
) => (
  conversations: dependencies.conversations,
  getModelStore: dependencies.getModelStore,
  messagesRepository: dependencies.messagesRepository,
  selectRange: dependencies.selectRange,
  conversationId: conversationId,
  trigger: trigger,
);

CompactionExecutionState _successState(
  String conversationId,
  CompactionTrigger trigger,
  DateTime startedAt,
) => CompactionExecutionState(
  conversationId: conversationId,
  trigger: trigger,
  startedAt: startedAt,
  status: .success,
);

final ProviderFamily<CompactConversationUsecase, String>
compactConversationUsecaseProvider =
    Provider.family<CompactConversationUsecase, String>((ref, workspaceId) {
      final isCloud =
          ref
              .watch(workspaceSessionForRouteProvider(workspaceId))
              .requireValue
              .cloud !=
          null;
      if (isCloud) {
        final execution = ref.watch(compactionExecutionRuntimeProvider);
        final conversations = ref
            .watch(cloudConversationUsecaseProvider(workspaceId))
            .value;
        final turns = ref.watch(cloudTurnUsecaseProvider(workspaceId)).value;
        if (conversations == null || turns == null) {
          throw StateError('Cloud compaction dependencies unavailable');
        }

        return CompactConversationUsecase(
          compactionExecution: execution,
          cloudCompaction: .new(
            conversations: conversations,
            turns: turns,
            execution: execution,
          ),
          cloudConversation: (id) => ref.read(
            conversationByIdStreamProvider(
              workspaceId,
              conversationId: id,
            ).future,
          ),
        );
      }

      return CompactConversationUsecase(
        compactionExecution: ref.watch(compactionExecutionRuntimeProvider),
        messageRepository: ref.watch(messageRepositoryProvider),
        conversationRepository: ref.watch(conversationRepositoryProvider),
        modelSelectionStore: (workspaceId) =>
            ref.read(modelSelectionStoreProvider(workspaceId).future),
        chatbotService: ref.watch(chatbotServiceProvider),
        selectCompactionRangeUsecase: ref.watch(
          selectCompactionRangeUsecaseProvider,
        ),
      );
    });
