import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/models/streaming_message_projection.dart';

class MergeStreamingMessageProjectionUseCase {
  const MergeStreamingMessageProjectionUseCase();

  MessageEntity call({
    required MessageEntity baseMessage,
    required StreamingMessageProjection streamingMessage,
  }) {
    return baseMessage.copyWith(
      content: streamingMessage.content,
      metadata: streamingMessage.metadata,
      status: switch (streamingMessage.status) {
        StreamingProjectionStatus.created => MessageStatus.unfinished,
        StreamingProjectionStatus.streaming => MessageStatus.unfinished,
        StreamingProjectionStatus.done => MessageStatus.sent,
        StreamingProjectionStatus.error => MessageStatus.error,
        StreamingProjectionStatus.awaitingToolConfirmation =>
          MessageStatus.sent,
        StreamingProjectionStatus.executingTools => MessageStatus.unfinished,
        StreamingProjectionStatus.waitingForMcpConnections =>
          MessageStatus.unfinished,
      },
    );
  }
}
