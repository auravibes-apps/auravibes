import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/models/streaming_message_projection.dart';
import 'package:auravibes_app/domain/usecases/chats/merge_streaming_message_projection_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('overlays content metadata and mapped status', () {
    const usecase = MergeStreamingMessageProjectionUseCase();
    final base = MessageEntity(
      id: 'm1',
      conversationId: 'c1',
      content: 'old',
      messageType: MessageType.text,
      isUser: false,
      status: MessageStatus.sent,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );

    const streaming = StreamingMessageProjection(
      content: 'new',
      status: StreamingProjectionStatus.error,
      metadata: MessageMetadataEntity(),
    );

    final result = usecase.call(baseMessage: base, streamingMessage: streaming);

    expect(result.content, 'new');
    expect(result.metadata, isNotNull);
    expect(result.status, MessageStatus.error);
  });
}
