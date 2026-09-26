import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/usecases/get_conversation_busy_state_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/restore_compaction_checkpoint_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ConversationRepository extends Mock implements ConversationRepository;

class _MessageRepository extends Mock implements MessageRepository;

class _BusyStateUsecase extends Mock implements GetConversationBusyStateUsecase;

void main() {
  const conversationId = 'conversation-1';
  const workspaceId = 'workspace-1';
  const checkpointId = 'summary-1';
  final now = DateTime(2026);
  final conversation = ConversationEntity(
    id: conversationId,
    title: 'Conversation',
    workspaceId: 'workspace-1',
    isPinned: false,
    createdAt: now,
    updatedAt: now,
    activeCompactionCheckpointId: 'summary-2',
  );
  final checkpoint = MessageEntity(
    id: checkpointId,
    conversationId: conversationId,
    content: 'summary text',
    messageType: .system,
    isUser: false,
    status: .sent,
    createdAt: now,
    updatedAt: now,
    metadata: const MessageMetadataEntity(isCompactionSummary: true),
  );
  var conversations = _ConversationRepository();
  var messages = _MessageRepository();
  var busyState = _BusyStateUsecase();

  RestoreCompactionCheckpointUsecase createRestore() =>
      RestoreCompactionCheckpointUsecase(
        conversationRepository: conversations,
        messageRepository: messages,
        getConversationBusyState: busyState,
        isCompacting: (_) => false,
      );
  var restore = createRestore();

  setUpAll(() {
    registerFallbackValue(const ConversationPatch());
  });

  setUp(() {
    conversations = _ConversationRepository();
    messages = _MessageRepository();
    busyState = _BusyStateUsecase();
    restore = createRestore();
    when(() => conversations.getConversationById(conversationId))
        .thenAnswer((_) async => conversation);
    when(() => messages.getMessagesByConversation(conversationId))
        .thenAnswer((_) async => [checkpoint]);
    when(() => busyState.call(conversationId: conversationId)).thenAnswer(
      (_) async => const ConversationBusyState(
        isStreaming: false,
        hasPendingTools: false,
      ),
    );
    when(() => conversations.patchConversation(conversationId, any()))
        .thenAnswer((_) async => conversation);
  });

  test(
    'restores an existing sent checkpoint without changing messages',
    () async {
      await restore.call(
        workspaceId: workspaceId,
        conversationId: conversationId,
        checkpointMessageId: checkpointId,
      );

      verify(
        () => conversations.patchConversation(
          conversationId,
          const .new(activeCompactionCheckpointId: checkpointId),
        ),
      ).called(1);
    },
  );

  test(
    'rejects restore during active turn and leaves pointer unchanged',
    () async {
      when(() => busyState.call(conversationId: conversationId)).thenAnswer(
        (_) async => const ConversationBusyState(
          isStreaming: true,
          hasPendingTools: false,
        ),
      );

      await expectLater(
        restore.call(
          workspaceId: workspaceId,
          conversationId: conversationId,
          checkpointMessageId: checkpointId,
        ),
        throwsA(isA<CompactionCheckpointRestoreException>()),
      );
      final _ = verifyNever(
        () => conversations.patchConversation(any(), any()),
      );
    },
  );

  test('rejects checkpoint from another conversation', () async {
    when(() => messages.getMessagesByConversation(conversationId)).thenAnswer(
      (_) async => [
        checkpoint.copyWith(conversationId: 'another-conversation'),
      ],
    );

    await expectLater(
      restore.call(
        workspaceId: workspaceId,
        conversationId: conversationId,
        checkpointMessageId: checkpointId,
      ),
      throwsA(isA<CompactionCheckpointRestoreException>()),
    );
    final _ = verifyNever(() => conversations.patchConversation(any(), any()));
  });

  test(
    'restores cloud checkpoint without requiring a local conversation row',
    () async {
      var capturedWorkspaceId = '';
      final usecase = RestoreCompactionCheckpointUsecase(
        conversationRepository: conversations,
        messageRepository: messages,
        getConversationBusyState: busyState,
        isCompacting: (_) => false,
        restoreCloudCheckpoint:
            ({
              required workspaceId,
              required conversationId,
              required checkpointMessageId,
            }) async {
              capturedWorkspaceId = workspaceId;
              expect(conversationId, 'conversation-1');
              expect(checkpointMessageId, checkpointId);

              return true;
            },
      );
      when(() => conversations.getConversationById(conversationId))
          .thenAnswer((_) async => null);

      await usecase.call(
        workspaceId: workspaceId,
        conversationId: conversationId,
        checkpointMessageId: checkpointId,
      );

      expect(capturedWorkspaceId, workspaceId);
    },
  );
}
