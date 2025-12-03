import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/models/providers/model_providers_repository_providers.dart';
import 'package:auravibes_app/features/tools/providers/conversation_tools_provider.dart';
import 'package:auravibes_app/providers/chatbot_service_provider.dart';
import 'package:auravibes_app/providers/tool_calling_manager_provider.dart';
import 'package:auravibes_app/services/chatbot_service/models/chat_message_models.dart';
import 'package:auravibes_app/services/tools/tool_service.dart';
import 'package:auravibes_app/services/tools/user_tools_entity.dart';
import 'package:auravibes_app/utils/drain.dart';
import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:langchain/langchain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'messages_manager_provider.freezed.dart';
part 'messages_manager_provider.g.dart';

enum StreamingMessageStatus {
  created,
  streaming,
  done,
  error,
  awaitingToolConfirmation,
  executingTools,
}

class _CoalescingSaver<T> {
  // tracks the freshest state we've observed

  _CoalescingSaver({
    required this.storeMessage,
    required this.storeDoneMessage,
  });
  final Future<void> Function(T state) storeMessage;
  final Future<void> Function(T state) storeDoneMessage;

  bool _saving = false;
  bool _closed = false; // after done runs, ignore pushes
  bool _doneRequested = false; // a terminal write has been requested

  T? _pending; // latest state waiting to be saved (normal)
  T? _latestSeen;

  /// Push each concatenated state here (e.g., from your .scan()).
  void push(T state) {
    if (_closed) return; // ignore after terminal write
    _pending = state; // coalesce
    _latestSeen = state; // remember the freshest version
    if (!_saving) _run();
  }

  /// Request a terminal write. Optionally pass the final state; if omitted,
  /// we use the latest seen state.
  void complete([T? finalState]) {
    if (_closed) return; // already finalized
    if (finalState != null) {
      _pending = finalState; // ensure pending reflects terminal content
      _latestSeen = finalState;
    }
    _doneRequested = true;
    if (!_saving) _run();
  }

  Future<void> _run() async {
    _saving = true;
    try {
      while (true) {
        // Drain normal pending saves first
        if (_pending != null) {
          final toSave = _pending as T;
          _pending = null;
          try {
            await storeMessage(toSave);
          } on Exception catch (_) {
            // Policy choice: swallow/log so loop continues,
            // or set a retry/backoff strategy.
          }
          // Loop continues — if new states arrived during await,
          // _pending will be non-null and we'll save again.
          continue;
        }

        // If no normal pending save, but a terminal write is requested, do it.
        if (_doneRequested) {
          // Use the freshest state we've seen for the terminal save.
          final toDone = _latestSeen;
          _doneRequested = false;
          _closed = true; // No more pushes accepted after terminal write.
          if (toDone != null) {
            try {
              await storeDoneMessage(toDone);
            } on Exception catch (_) {
              // Decide your policy here too.
            }
          }
          break; // we're closed; finish
        }

        // Nothing left to do.
        break;
      }
    } finally {
      _saving = false;
    }
  }
}

@freezed
abstract class ToolCallMessageResult with _$ToolCallMessageResult {
  const factory ToolCallMessageResult({
    required bool success,
    required String result,
    required String? error,
    required DateTime executedAt,
  }) = _ToolCallMessageResult;
}

@freezed
abstract class ToolCallMessageItem with _$ToolCallMessageItem {
  const factory ToolCallMessageItem({
    required String id,
    required String name,
    required Map<String, dynamic> arguments,
    required String argumentsRaw,
    ToolCallMessageResult? result,
  }) = _ToolCallMessageItem;
}

@freezed
abstract class StreamingMessage with _$StreamingMessage {
  const factory StreamingMessage({
    required String messageId,
    required String conversationId,
    required String responseMesageId,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
    required StreamingMessageStatus status,
    MessageMetadataEntity? metadata,
    List<ToolCallMessageItem>? toolCalls,
  }) = _StreamingMessage;
}

@Riverpod(keepAlive: true)
class MessagesManagerNotifier extends _$MessagesManagerNotifier {
  final Map<String, StreamSubscription<Never>> _subscriptions = {};
  final Map<String, StreamingDeltaPersister> _deltaPersisters = {};

  @override
  List<StreamingMessage> build() {
    ref.onDispose(() {
      for (final subscription in _subscriptions.values) {
        subscription.cancel();
      }

      for (final persister in _deltaPersisters.values) {
        persister.close();
      }
    });

    return [];
  }

  // Add a new stream to the management system
  void _addStream({
    required String messageId,
    required String conversationId,
    required String responseMessageId,
    required Stream<ChatResult> stream,
  }) {
    // Create streaming message entry
    final streamingMessage = StreamingMessage(
      messageId: messageId,
      conversationId: conversationId,
      responseMesageId: responseMessageId,
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: StreamingMessageStatus.created,
    );

    // Add to state
    state = [...state, streamingMessage];

    final subs = CompositeSubscription();
    final chats$ = stream.shareReplay().scan<ChatResult?>((
      accumulated,
      value,
      index,
    ) {
      if (accumulated == null) return value;
      return accumulated.concat(value);
    }, null).whereNotNull();

    // set message confirmation
    subs
      ..add(
        chats$
            .shareReplay()
            .take(1)
            .listen((event) => _confirmMessage(messageId: messageId)),
      )
      // update states
      ..add(
        chats$.shareReplay().listen(
          (chatResult) => _updateState(responseMessageId, chatResult),
        ),
      );

    final coalescingSaver = _CoalescingSaver<ChatResult>(
      storeMessage: (chatResult) => _updateMessage(
        chatResult: chatResult,
        responseMessageId: responseMessageId,
      ),
      storeDoneMessage: (chatResult) => _doneMessage(
        chatResult: chatResult,
        responseMessageId: responseMessageId,
      ),
    );
    // store message update
    subs.add(
      chats$.shareReplay().listen(
        coalescingSaver.push,
        onDone: coalescingSaver.complete,
      ),
    );

    // _deltaPersisters[responseMessageId] = deltaPersister;
    _subscriptions[responseMessageId] = subs;
  }

  void _updateState(String responseMessageId, ChatResult chatResult) {
    state = state.map((msg) {
      if (msg.responseMesageId == responseMessageId) {
        return msg.copyWith(
          status: StreamingMessageStatus.streaming,
          content: chatResult.outputAsString,
          updatedAt: DateTime.now(),
          metadata: _getMetadata(chatResult),
        );
      }
      return msg;
    }).toList();
  }

  Future<void> _confirmMessage({required String messageId}) async {
    final repo = ref.read(messageRepositoryProvider);

    await repo.updateMessage(
      messageId,
      const MessageToUpdate(status: MessageStatus.sent),
    );
  }

  List<MessageToolCallEntity> _getTools(ChatResult chatResult) {
    if (chatResult.output.toolCalls.isEmpty) {
      return [];
    }

    return chatResult.output.toolCalls.map((e) {
      return MessageToolCallEntity(
        argumentsRaw: e.argumentsRaw,
        id: e.id,
        name: e.name,
      );
    }).toList();
  }

  MessageMetadataEntity? _getMetadata(ChatResult chatResult) {
    if (chatResult.output.toolCalls.isEmpty) {
      return null;
    }

    return MessageMetadataEntity(toolCalls: _getTools(chatResult));
  }

  Future<void> _updateMessage({
    required String responseMessageId,
    required ChatResult chatResult,
  }) async {
    final repo = ref.read(messageRepositoryProvider);

    await repo.updateMessage(
      responseMessageId,
      MessageToUpdate(
        content: chatResult.outputAsString,
        metadata: _getMetadata(chatResult),
      ),
    );
  }

  Future<void> _doneMessage({
    required String responseMessageId,
    required ChatResult chatResult,
  }) async {
    final repo = ref.read(messageRepositoryProvider);
    state = state.where((msg) {
      return msg.responseMesageId != responseMessageId;
    }).toList();

    await _subscriptions[responseMessageId]?.cancel();

    final toolsToCall = _getTools(chatResult);
    if (toolsToCall.isNotEmpty) {
      ref
          .read(toolCallingManagerProvider.notifier)
          .runTask(_getTools(chatResult), responseMessageId);
    }

    await repo.updateMessage(
      responseMessageId,
      MessageToUpdate(
        status: MessageStatus.sent,
        content: chatResult.outputAsString,
        metadata: _getMetadata(chatResult),
      ),
    );
  }

  Future<MessageEntity> _waitMessage({
    required String createdMessageId,
    required String conversationId,
    required List<UserToolType> toolTypes,
  }) async {
    final conversation = await ref
        .read(conversationRepositoryProvider)
        .getConversationById(conversationId);
    final modelId = conversation?.modelId;
    if (modelId == null) {
      throw Exception('no model id for conversation');
    }
    final credentialsModelsRepository = ref.read(
      credentialsModelsRepositoryProvider,
    );
    final foundModel = await credentialsModelsRepository
        .getCredentialsModelById(
          modelId,
        );
    if (foundModel == null) {
      throw Exception('Selected model not found');
    }

    final messages = await ref
        .read(messageRepositoryProvider)
        .getMessagesByConversation(conversationId);
    // Create response message
    final responseMessage = await ref
        .read(messageRepositoryProvider)
        .createMessage(
          MessageToCreate(
            conversationId: conversationId,
            content: '',
            messageType: MessageType.text,
            isUser: false,
            status: MessageStatus.sending,
          ),
        );

    final chatbotService = ref.watch(chatbotServiceProvider);
    final aiMessages = messages.map<ChatbotMessage>((message) {
      if (message.isUser) {
        return ChatbotMessage.humanText(message.content);
      }

      return ChatbotMessage.ai(
        message: message.content,
        toolCalls: [
          for (final toolCall
              in message.metadata?.toolCalls ?? <MessageToolCallEntity>[])
            ChatbotToolCall(
              id: toolCall.id,
              name: toolCall.name,
              arguments: toolCall.arguments,
              argumentsRaw: toolCall.argumentsRaw,
              responseRaw: toolCall.responseRaw,
            ),
        ],
      );
    }).toList();

    final stream = chatbotService.sendMessage(
      foundModel,
      aiMessages,
      tools: ToolService.getTools(
        only: toolTypes,
      ).map((e) => e.getTool()).toList(),
    );
    _addStream(
      messageId: createdMessageId,
      conversationId: conversationId,
      responseMessageId: responseMessage.id,
      stream: stream,
    );

    return responseMessage;
  }

  Future<(MessageEntity userMessage, MessageEntity systemMessage)>
  _messageSent({
    required String conversationId,
    required String content,
    required List<UserToolType> toolTypes,
    List<ToolResponseItem>? toolResponses,
  }) async {
    final createdMessage = await ref
        .read(messageRepositoryProvider)
        .createMessage(
          MessageToCreate(
            conversationId: conversationId,
            content: content,
            messageType: MessageType.text,
            isUser: toolResponses == null,
            status: MessageStatus.sending,
          ),
        );

    final responseMessage = await _waitMessage(
      createdMessageId: createdMessage.id,
      conversationId: conversationId,
      toolTypes: toolTypes,
    );

    return (createdMessage, responseMessage);
  }

  Future<ConversationEntity> addConversation({
    required String workspaceId,
    required String modelId,
    required String message,
    required List<UserToolType> toolTypes,
  }) async {
    // generate a title
    // store conversation
    // create message
    // start message streaming

    // Get chat model provider
    final credentialsModelsRepository = ref.read(
      credentialsModelsRepositoryProvider,
    );
    final foundModel = await credentialsModelsRepository
        .getCredentialsModelById(
          modelId,
        );
    if (foundModel == null) {
      throw Exception('Selected model not found');
    }

    final conversationToolsRepository = ref.read(
      conversationToolsRepositoryProvider,
    );

    // Generate title for conversation
    final chatbotService = ref.watch(chatbotServiceProvider);
    final title = await chatbotService.generateTitle(foundModel, message);

    // Create conversation
    final conversation = await ref
        .read(conversationsListProvider.notifier)
        .addConversation(title, modelId);

    final toolsToRemove = ToolService.getTypes(
      without: toolTypes,
    ).map((e) => e.value).toList();

    await conversationToolsRepository.setConversationToolsDisabled(
      conversation.id,
      toolsToRemove,
    );
    await _messageSent(
      content: message,
      conversationId: conversation.id,
      toolTypes: toolTypes,
    );

    return conversation;
  }

  Future<(MessageEntity userMessage, MessageEntity systemMessage)> sendMessage({
    required String conversationId,
    required String message,
  }) async {
    // Get chat model provider
    final conversation = await ref
        .read(conversationRepositoryProvider)
        .getConversationById(conversationId);

    // Get conversation tools
    final workspaceId = conversation?.workspaceId ?? '';
    final contextAwareTools = await ref.read(
      contextAwareToolsProvider(
        conversationId: conversationId,
        workspaceId: workspaceId,
      ).future,
    );

    // Convert tool strings to UserToolType and get enabled tools
    final enabledToolTypes = contextAwareTools
        .map(UserToolType.fromValue)
        .where((toolType) => toolType != null)
        .cast<UserToolType>()
        .toList();

    final (createdMessage, responseMessage) = await _messageSent(
      content: message,
      conversationId: conversationId,
      toolTypes: enabledToolTypes,
    );

    return (createdMessage, responseMessage);
  }

  Future<void> sendToolsResponse(
    List<ToolResponseItem> responses,
    String responseMessageId,
  ) async {
    final message = await ref
        .read(messageRepositoryProvider)
        .getMessageById(responseMessageId);
    if (message == null) return;

    final conversation = await ref
        .read(conversationRepositoryProvider)
        .getConversationById(message.conversationId);

    if (conversation == null) return;

    // Get conversation tools
    final workspaceId = conversation.workspaceId;
    final contextAwareTools = await ref.read(
      contextAwareToolsProvider(
        conversationId: message.conversationId,
        workspaceId: workspaceId,
      ).future,
    );

    // Convert tool strings to UserToolType and get enabled tools
    final enabledToolTypes = contextAwareTools
        .map(UserToolType.fromValue)
        .where((toolType) => toolType != null)
        .cast<UserToolType>()
        .toList();

    final orignalMetadata = message.metadata ?? const MessageMetadataEntity();

    ref
        .read(messageRepositoryProvider)
        .updateMessage(
          responseMessageId,
          MessageToUpdate(
            metadata: orignalMetadata.copyWith(
              toolCalls: orignalMetadata.toolCalls.map((toolCall) {
                return toolCall.copyWith(
                  responseRaw: responses
                      .firstWhereOrNull((element) => element.id == toolCall.id)
                      ?.content,
                );
              }).toList(),
            ),
          ),
        );

    await _waitMessage(
      createdMessageId: responseMessageId,
      conversationId: message.conversationId,
      toolTypes: enabledToolTypes,
    );
  }
}
