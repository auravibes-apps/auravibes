import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/usecases/chats/project_messages_streaming_status_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

MessageEntity _message(String id, MessageStatus status) => MessageEntity(
  id: id,
  conversationId: 'c1',
  content: 'content',
  messageType: MessageType.text,
  isUser: true,
  status: status,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

void main() {
  test('marks only streaming ids as streaming', () {
    const usecase = ProjectMessagesStreamingStatusUseCase();
    final messages = [
      _message('m1', MessageStatus.sent),
      _message('m2', MessageStatus.sent),
    ];

    final result = usecase.call(
      messages: messages,
      streamingMessageIds: ['m2'],
    );

    expect(result[0].status, MessageStatus.sent);
    expect(result[1].status, MessageStatus.streaming);
  });
}
