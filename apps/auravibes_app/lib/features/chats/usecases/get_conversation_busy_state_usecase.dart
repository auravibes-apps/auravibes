import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/streaming_runtime_provider.dart';
import 'package:riverpod/riverpod.dart';

class ConversationBusyState {
  const ConversationBusyState({
    required this.isStreaming,
    required this.hasPendingTools,
  });

  final bool isStreaming;
  final bool hasPendingTools;

  bool get isBusy => isStreaming || hasPendingTools;
}

class GetConversationBusyStateUsecase {
  const GetConversationBusyStateUsecase({
    required this.messageRepository,
    required this.conversationStreamingRuntime,
  });

  final MessageRepository messageRepository;
  final ConversationStreamingRuntime conversationStreamingRuntime;

  Future<ConversationBusyState> call({
    required String conversationId,
  }) async {
    final messages = await messageRepository.getMessagesByConversation(
      conversationId,
    );

    final isStreaming = conversationStreamingRuntime.isStreaming(
      conversationId,
    );

    final latestAssistantMessage = _findLatestAssistantMessage(messages);
    final hasPendingTools =
        latestAssistantMessage?.metadata?.toolCalls.any(
          (toolCall) => toolCall.isPending,
        ) ??
        false;

    return ConversationBusyState(
      isStreaming: isStreaming,
      hasPendingTools: hasPendingTools,
    );
  }

  MessageEntity? _findLatestAssistantMessage(List<MessageEntity> messages) {
    for (final message in messages.reversed) {
      if (!message.isUser) {
        return message;
      }
    }

    return null;
  }
}

final getConversationBusyStateUsecaseProvider =
    Provider<GetConversationBusyStateUsecase>((ref) {
      return GetConversationBusyStateUsecase(
        messageRepository: ref.watch(messageRepositoryProvider),
        conversationStreamingRuntime: ref.watch(
          conversationStreamingRuntimeProvider,
        ),
      );
    });
