import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_message_sender.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_chat_attachment_usecase.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Gateway extends Mock implements CloudChatGateway;
class _Attachments extends Mock implements CloudChatAttachmentUsecase;

void main() {
  test(
    'queues cloud message then starts idle execution and invalidates',
    () async {
      final gateway = _Gateway();
      final events = <String>[];
      final snapshot = ConversationSnapshot(
        conversation: .new(
          id: 'conversation-1',
          workspaceId: 7,
          executionState: 'idle',
          projectionRevision: 3,
          sequence: 4,
          updatedAt: DateTime.utc(2026),
        ),
        messages: const [],
        pendingMessages: const [],
        toolCalls: const [],
        sequence: 4,
      );
      when(() => gateway.getConversationSnapshot('conversation-1'))
          .thenAnswer((_) async => snapshot);
      when(() => gateway.queueConversationMessage(any()))
          .thenAnswer((_) async => snapshot);
      when(
        () => gateway.continueConversation(
          requestId: any(named: 'requestId'),
          conversationId: 'conversation-1',
          expectedProjectionRevision: 3,
        ),
      ).thenAnswer((_) async => snapshot);

      final sender = CloudChatMessageSender(
        gateway: () async => gateway,
        attachments: () async => null,
        capabilities: .cloud,
        invalidateMessages: events.add,
      );

      await sender.call('conversation-1', const ChatDraft(text: 'hello'));

      final _ = verifyInOrder([
        () => gateway.getConversationSnapshot('conversation-1'),
        () => gateway.queueConversationMessage(any()),
        () => gateway.continueConversation(
          requestId: any(named: 'requestId'),
          conversationId: 'conversation-1',
          expectedProjectionRevision: 3,
        ),
      ]);
      expect(events, ['conversation-1']);
    },
  );

  test('cleans uploaded objects when queueing fails', () async {
    final gateway = _Gateway();
    final attachments = _Attachments();
    final invalidated = <String>[];
    final object = ObjectResult(
      objectId: 4,
      workspaceId: 7,
      displayName: 'note.txt',
      mimeType: 'text/plain',
      sizeBytes: 4,
      checksumSha256: 'checksum',
      revision: 2,
    );
    final snapshot = ConversationSnapshot(
      conversation: .new(
        id: 'conversation-1',
        workspaceId: 7,
        executionState: 'running',
        projectionRevision: 3,
        sequence: 4,
        updatedAt: DateTime.utc(2026),
      ),
      messages: const [],
      pendingMessages: const [],
      toolCalls: const [],
      sequence: 4,
    );
    when(() => gateway.getConversationSnapshot('conversation-1'))
        .thenAnswer((_) async => snapshot);
    when(() => attachments.uploadDraftResults(attachments: const []))
        .thenAnswer((_) async => [object]);
    when(() => gateway.queueConversationMessage(any()))
        .thenThrow(StateError('queue failed'));
    when(() => attachments.deleteUploaded([object]))
        .thenAnswer((_) => Future<void>.value());

    final sender = CloudChatMessageSender(
      gateway: () async => gateway,
      attachments: () async => attachments,
      capabilities: .cloud,
      invalidateMessages: invalidated.add,
    );

    final _ = await expectLater(
      sender.call('conversation-1', const ChatDraft(text: 'hello')),
      throwsStateError,
    );
    final _ = verify(() => attachments.deleteUploaded([object])).called(1);
    final _ = verifyNever(
      () => gateway.continueConversation(
        requestId: any(named: 'requestId'),
        conversationId: any(named: 'conversationId'),
        expectedProjectionRevision: any(named: 'expectedProjectionRevision'),
      ),
    );
  });
}
