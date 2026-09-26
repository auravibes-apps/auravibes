import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/models/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/usecases/get_conversation_busy_state_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/restore_compaction_checkpoint_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ConversationRepository extends Mock implements ConversationRepository {}

class _MessageRepository extends Mock implements MessageRepository {}

class _BusyStateUsecase extends Mock
    implements GetConversationBusyStateUsecase {}

void main() {
  const conversationId = 'conversation-1';
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
    messageType: MessageType.system,
    isUser: false,
    status: MessageStatus.sent,
    createdAt: now,
    updatedAt: now,
    metadata: const MessageMetadataEntity(isCompactionSummary: true),
  );
  late _ConversationRepository conversations;
  late _MessageRepository messages;
  late _BusyStateUsecase busyState;
  late bool compacting;
  late RestoreCompactionCheckpointUsecase restore;

  setUpAll(() {
    registerFallbackValue(const ConversationPatch());
  });

  setUp(() {
    conversations = _ConversationRepository();
    messages = _MessageRepository();
    busyState = _BusyStateUsecase();
    compacting = false;
    restore = RestoreCompactionCheckpointUsecase(
      conversationRepository: conversations,
      messageRepository: messages,
      getConversationBusyState: busyState,
      isCompacting: (_) => compacting,
    );
    when(() => conversations.getConversationById(conversationId))
        .thenAnswer((_) async => conversation);
    when(() => messages.getMessagesByConversation(conversationId))
        .thenAnswer((_) async => [checkpoint]);
    when(
      () => busyState.call(conversationId: conversationId, isCompacting: false),
    ).thenAnswer(
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
        conversationId: conversationId,
        checkpointMessageId: checkpointId,
      );

      verify(
        () => conversations.patchConversation(
          conversationId,
          ConversationPatch(activeCompactionCheckpointId: checkpointId),
        ),
      ).called(1);
    },
  );

  test(
    'rejects restore during active turn and leaves pointer unchanged',
    () async {
      when(
        () =>
            busyState.call(conversationId: conversationId, isCompacting: false),
      ).thenAnswer(
        (_) async => const ConversationBusyState(
          isStreaming: true,
          hasPendingTools: false,
        ),
      );

      await expectLater(
        restore.call(
          conversationId: conversationId,
          checkpointMessageId: checkpointId,
        ),
        throwsA(isA<CompactionCheckpointRestoreException>()),
      );
      verifyNever(() => conversations.patchConversation(any(), any()));
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
        conversationId: conversationId,
        checkpointMessageId: checkpointId,
      ),
      throwsA(isA<CompactionCheckpointRestoreException>()),
    );
    verifyNever(() => conversations.patchConversation(any(), any()));
  });

  test('routes cloud restore through server checkpoint API', () async {
    var capturedWorkspaceId = '';
    var capturedRevision = -1;
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
            required revision,
          }) async {
            capturedWorkspaceId = workspaceId;
            capturedRevision = revision;
            expect(conversationId, 'conversation-1');
            expect(checkpointMessageId, checkpointId);
            return true;
          },
    );
    when(() => conversations.getConversationById(conversationId))
        .thenAnswer((_) async => conversation.copyWith(revision: 12));

    await usecase.call(
      conversationId: conversationId,
      checkpointMessageId: checkpointId,
    );

    expect(capturedWorkspaceId, 'workspace-1');
    expect(capturedRevision, 12);
    verifyNever(() => messages.getMessagesByConversation(any()));
    verifyNever(() => conversations.patchConversation(any(), any()));
  });
}
