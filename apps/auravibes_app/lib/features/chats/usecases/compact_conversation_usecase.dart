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
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_turn_provider.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution_runtime_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_compaction_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/select_compaction_range_usecase.dart';
import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/providers/chatbot_service_provider.dart';
import 'package:auravibes_app/services/chatbot_service/build_prompt_chat_messages.dart';
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show
        ChatMessage,
        conversationCompactionRequestPrompt,
        conversationCompactionSystemPrompt,
        requireCompactionSummary;
import 'package:riverpod/src/providers/provider.dart';

class CompactConversationUsecase {
  const CompactConversationUsecase({
    required this.compactionExecution,
    this.messageRepository,
    this.conversationRepository,
    this.modelSelectionStore,
    this.chatbotService,
    this.selectCompactionRangeUsecase,
    this.cloudCompaction,
    this.cloudConversation,
  });

  final MessageRepository? messageRepository;
  final ConversationRepository? conversationRepository;
  final Future<ModelSelectionStore> Function(String workspaceId)?
  modelSelectionStore;
  final ChatbotService? chatbotService;
  final SelectCompactionRangeUsecase? selectCompactionRangeUsecase;
  final CompactionExecutionRuntime compactionExecution;
  final CloudCompactionUsecase? cloudCompaction;
  final Future<ConversationEntity?> Function(String id)? cloudConversation;

  static const String _failureMessageKey =
      LocaleKeys.compaction_errors_auto_blocked;
  static const BuildPromptChatMessages _buildPromptChatMessages =
      BuildPromptChatMessages();

  Future<CompactionExecutionState> call({
    required String conversationId,
    required CompactionTrigger trigger,
  }) async {
    final cloud = cloudCompaction;
    if (cloud != null) {
      final getCloudConversation = cloudConversation;
      if (getCloudConversation == null) {
        throw StateError('Cloud conversation dependency unavailable');
      }
      final conversation = await getCloudConversation(conversationId);
      if (conversation == null) throw const CompactionUnavailableException();

      return cloud(conversation: conversation, trigger: trigger);
    }
    final conversations = conversationRepository;
    final getModelStore = modelSelectionStore;
    final messagesRepository = messageRepository;
    final selectRange = selectCompactionRangeUsecase;
    if (conversations == null ||
        getModelStore == null ||
        messagesRepository == null ||
        selectRange == null) {
      throw StateError('Local compaction dependencies unavailable');
    }
    final startedAt = DateTime.now();
    compactionExecution.markRunning(
      CompactionExecutionState(
        conversationId: conversationId,
        trigger: trigger,
        startedAt: startedAt,
        status: CompactionExecutionStatus.running,
      ),
    );

    try {
      final conversation = await conversations.getConversationById(
        conversationId,
      );
      if (conversation == null) {
        throw const CompactionUnavailableException();
      }

      final modelId = conversation.modelId;
      if (modelId == null) {
        throw const CompactionUnavailableException();
      }

      final foundModel = await (await getModelStore(
        conversation.workspaceId,
      )).getById(modelId);
      if (foundModel == null) {
        throw const CompactionUnavailableException();
      }

      final messages = await messagesRepository.getMessagesByConversation(
        conversationId,
      );

      final range = selectRange(messages);
      if (range == null) {
        throw const CompactionUnsafeException();
      }

      final compactableMessages = messages
          .where((m) => range.messageIds.contains(m.id))
          .toList();

      final chatHistory = await _buildCompactionPrompt(compactableMessages);

      String summaryText;
      try {
        summaryText = await _generateSummary(foundModel, chatHistory);
      } on Exception catch (e, stackTrace) {
        if (trigger == CompactionTrigger.auto) {
          await _persistRequiredFailureMessage(conversationId: conversationId);
        }

        Error.throwWithStackTrace(
          CompactionFailedException(cause: e),
          stackTrace,
        );
      }

      await _persistCompactionSummary(
        conversationId: conversationId,
        summaryText: summaryText,
        range: range,
        trigger: trigger,
      );

      compactionExecution.markSuccess(conversationId);

      return CompactionExecutionState(
        conversationId: conversationId,
        trigger: trigger,
        startedAt: startedAt,
        status: CompactionExecutionStatus.success,
      );
    } on Exception {
      compactionExecution.markFailure(conversationId);
      rethrow;
    }
  }

  Future<List<ChatMessage>> _buildCompactionPrompt(
    List<MessageEntity> messages,
  ) async {
    return [
      ChatMessage.system(conversationCompactionSystemPrompt),
      ...await _buildPromptChatMessages.call(messages),
      ChatMessage.user(
        conversationCompactionRequestPrompt,
      ),
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

    final chunks = <String>[];
    await for (final chunk in stream) {
      chunks.add(chunk.output.text);
    }

    return requireCompactionSummary(chunks.join());
  }

  Future<void> _persistCompactionSummary({
    required String conversationId,
    required String summaryText,
    required CompactionRange range,
    required CompactionTrigger trigger,
  }) async {
    final metadata = MessageMetadataEntity(
      metadataVersion: 2,
      isCompactionSummary: true,
      compactionKind: trigger == CompactionTrigger.auto
          ? CompactionKind.auto
          : CompactionKind.manual,
      compactedFromMessageId: range.fromMessageId,
      compactedThroughMessageId: range.throughMessageId,
      compactedMessageIds: range.messageIds,
      compactionCreatedAt: DateTime.now(),
    );

    final repository = messageRepository;
    if (repository == null) {
      throw StateError('Local message repository unavailable');
    }
    final created = await repository.createMessage(
      MessageToCreate(
        conversationId: conversationId,
        content: summaryText,
        messageType: MessageType.system,
        isUser: false,
        status: MessageStatus.sending,
        metadata: jsonEncode(metadata.toJson()),
      ),
    );

    switch (await repository.patchMessage(
      created.id,
      const MessagePatch(status: MessageStatus.sent),
    )) {
      case _:
        return;
    }
  }

  Future<void> _persistRequiredFailureMessage({
    required String conversationId,
  }) async {
    final repository = messageRepository;
    if (repository == null) {
      throw StateError('Local message repository unavailable');
    }
    final created = await repository.createMessage(
      MessageToCreate(
        conversationId: conversationId,
        content: _failureMessageKey,
        messageType: MessageType.system,
        isUser: false,
        status: MessageStatus.sending,
      ),
    );

    switch (await repository.patchMessage(
      created.id,
      const MessagePatch(status: MessageStatus.error),
    )) {
      case _:
        return;
    }
  }
}

final ProviderFamily<CompactConversationUsecase, String>
compactConversationUsecaseProvider =
    Provider.family<CompactConversationUsecase, String>(
      (ref, workspaceId) {
        final isCloud =
            ref
                .watch(
                  workspaceSessionForRouteProvider(workspaceId),
                )
                .requireValue
                .cloud !=
            null;
        if (isCloud) {
          final execution = ref.watch(compactionExecutionRuntimeProvider);
          final conversations = ref
              .watch(
                cloudConversationUsecaseProvider(workspaceId),
              )
              .value;
          final turns = ref.watch(cloudTurnUsecaseProvider(workspaceId)).value;
          if (conversations == null || turns == null) {
            throw StateError('Cloud compaction dependencies unavailable');
          }

          return CompactConversationUsecase(
            compactionExecution: execution,
            cloudCompaction: CloudCompactionUsecase(
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
          modelSelectionStore: (workspaceId) => ref.read(
            modelSelectionStoreProvider(workspaceId).future,
          ),
          chatbotService: ref.watch(chatbotServiceProvider),
          selectCompactionRangeUsecase: ref.watch(
            selectCompactionRangeUsecaseProvider,
          ),
        );
      },
    );
