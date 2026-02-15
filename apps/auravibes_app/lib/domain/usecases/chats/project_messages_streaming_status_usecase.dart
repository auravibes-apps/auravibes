import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';

class ProjectMessagesStreamingStatusUseCase {
  const ProjectMessagesStreamingStatusUseCase();

  List<MessageEntity> call({
    required List<MessageEntity> messages,
    required List<String> streamingMessageIds,
  }) {
    return messages
        .map(
          (message) => message.copyWith(
            status: streamingMessageIds.contains(message.id)
                ? MessageStatus.streaming
                : message.status,
          ),
        )
        .toList();
  }
}
