import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';

import 'package:auravibes_app/features/chats/models/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:riverpod/riverpod.dart';

// Required: Existing helpers remain top-level for local feature use.
export '../models/conversation_busy_state.dart';

class const GetConversationBusyStateUsecase({
  required final MessageRepository messageRepository,
  required final ConversationStreamingRuntime conversationStreamingRuntime,
}) {
  Future<ConversationBusyState> call({
    required String conversationId,
    bool isCompacting = false,
  }) async {
    final messages = await messageRepository.getMessagesByConversation(
      conversationId,
    );

    return ConversationBusyState(
      isStreaming: conversationStreamingRuntime.isStreaming(conversationId),
      hasPendingTools: _hasPendingTools(messages),
      isCompacting: isCompacting,
    );
  }
}

bool _hasPendingTools(List<MessageEntity> messages) {
  final message = ConversationBusyStateQueries.latestAssistantMessage(messages);

  return message?.metadata?.toolCalls.any((toolCall) => toolCall.isPending) ??
      false;
}

abstract final class ConversationBusyStateQueries {
  static MessageEntity? latestAssistantMessage(List<MessageEntity> messages) {
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
