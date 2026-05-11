import 'dart:convert';

import 'package:auravibes_app/domain/entities/compaction.dart';
import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entities.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/features/chats/providers/compaction_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/select_compaction_range_usecase.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/providers/chatbot_service_provider.dart';
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
import 'package:dartantic_ai/dartantic_ai.dart' hide Provider;
import 'package:riverpod/riverpod.dart';

class CompactConversationUsecase {
  const CompactConversationUsecase({
    required this.messageRepository,
    required this.conversationRepository,
    required this.workspaceModelSelectionsRepository,
    required this.chatbotService,
    required this.selectCompactionRangeUsecase,
    required this.compactionExecution,
  });

  final MessageRepository messageRepository;
  final ConversationRepository conversationRepository;
  final WorkspaceModelSelectionRepository workspaceModelSelectionsRepository;
  final ChatbotService chatbotService;
  final SelectCompactionRangeUsecase selectCompactionRangeUsecase;
  final CompactionExecution compactionExecution;

  static const String _failureMessageKey =
      LocaleKeys.compaction_errors_auto_blocked;

  static const String _compactionSystemPrompt =
      ''
      'You are a conversation compaction assistant. Your task is to create '
      'a comprehensive but concise summary of the conversation messages '
      'provided. Preserve all of the following:\n'
      '- User goals and intents\n'
      '- Key constraints and requirements\n'
      '- Important decisions made\n'
      '- Current task status and progress\n'
      '- Files, identifiers, and technical references mentioned\n'
      '- Errors encountered and their resolutions\n'
      '- Pending tasks and open questions\n'
      '- Concise facts from tool outputs that affect the task\n\n'
      'Do NOT:\n'
      '- Invent code state or file contents you have not seen\n'
      '- Preserve sensitive tool output verbatim\n'
      '- Mark unresolved tool calls as completed\n'
      '- Add information not present in the conversation\n';

  Future<CompactionExecutionState> call({
    required String conversationId,
    required CompactionTrigger trigger,
  }) async {
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
      final conversation = await conversationRepository.getConversationById(
        conversationId,
      );
      if (conversation == null) {
        throw const CompactionUnavailableException();
      }

      final modelId = conversation.modelId;
      if (modelId == null) {
        throw const CompactionUnavailableException();
      }

      final foundModel = await workspaceModelSelectionsRepository
          .getWorkspaceModelSelectionById(modelId);
      if (foundModel == null) {
        throw const CompactionUnavailableException();
      }

      final messages = await messageRepository.getMessagesByConversation(
        conversationId,
      );

      final range = selectCompactionRangeUsecase(messages);
      if (range == null) {
        throw const CompactionUnsafeException();
      }

      final compactableMessages = messages
          .where((m) => range.messageIds.contains(m.id))
          .toList();

      final chatHistory = _buildCompactionPrompt(compactableMessages);

      String summaryText;
      try {
        summaryText = await _generateSummary(foundModel, chatHistory);
      } on Exception catch (e) {
        if (trigger == CompactionTrigger.auto) {
          await _persistRequiredFailureMessage(
            conversationId: conversationId,
          );
        }

        throw CompactionFailedException(cause: e);
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

  List<ChatMessage> _buildCompactionPrompt(List<MessageEntity> messages) {
    final history = <ChatMessage>[
      ChatMessage.system(_compactionSystemPrompt),
    ];

    for (final message in messages) {
      if (message.isUser) {
        history.add(ChatMessage.user(message.content));
      } else if (message.messageType == MessageType.system) {
        history.add(ChatMessage.system(message.content));
      } else {
        history.add(ChatMessage.model(message.content));
      }
    }

    history.add(
      ChatMessage.user(
        'Please create a comprehensive summary of the above conversation. '
        'Preserve all goals, decisions, technical details, and current status.',
      ),
    );

    return history;
  }

  Future<String> _generateSummary(
    WorkspaceModelSelectionWithConnectionEntity model,
    List<ChatMessage> chatHistory,
  ) async {
    final stream = chatbotService.sendMessage(model, chatHistory);

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

    final created = await messageRepository.createMessage(
      MessageToCreate(
        conversationId: conversationId,
        content: summaryText,
        messageType: MessageType.system,
        isUser: false,
        status: MessageStatus.sending,
        metadata: jsonEncode(metadata.toJson()),
      ),
    );

    await messageRepository.patchMessage(
      created.id,
      const MessagePatch(status: MessageStatus.sent),
    );
  }

  Future<void> _persistRequiredFailureMessage({
    required String conversationId,
  }) async {
    final created = await messageRepository.createMessage(
      MessageToCreate(
        conversationId: conversationId,
        content: _failureMessageKey,
        messageType: MessageType.system,
        isUser: false,
        status: MessageStatus.sending,
      ),
    );

    await messageRepository.patchMessage(
      created.id,
      const MessagePatch(status: MessageStatus.error),
    );
  }
}

final compactConversationUsecaseProvider = Provider<CompactConversationUsecase>(
  (ref) {
    return CompactConversationUsecase(
      messageRepository: ref.watch(messageRepositoryProvider),
      conversationRepository: ref.watch(conversationRepositoryProvider),
      workspaceModelSelectionsRepository: ref.watch(
        workspaceModelSelectionRepositoryProvider,
      ),
      chatbotService: ref.watch(chatbotServiceProvider),
      selectCompactionRangeUsecase: ref.watch(
        selectCompactionRangeUsecaseProvider,
      ),
      compactionExecution: ref.watch(compactionExecutionProvider.notifier),
    );
  },
);
