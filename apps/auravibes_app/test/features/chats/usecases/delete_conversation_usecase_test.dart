import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_draft.dart';
import 'package:auravibes_app/features/chats/providers/conversation_draft_cleanup_provider.dart';
import 'package:auravibes_app/features/chats/usecases/delete_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/local_chat_attachment_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements ConversationRepository;

void main() {
  test('stops local execution before deleting the conversation', () async {
    final repository = _Repository();
    final calls = <String>[];
    when(() => repository.deleteConversation('conversation-1'))
        .thenAnswer((_) async {
          calls.add('delete');

          return true;
        });
    final usecase = DeleteConversationUsecase(
      repository,
      (_) async => calls.add('stop'),
      prepareBackgroundWorkDeletion: (_) async => calls.add('cancel detached'),
      restoreBackgroundWorkAfterFailedDeletion: (_) => calls.add('reopen'),
      clearConversationDraft: (_, _) async => calls.add('clear draft'),
    );

    final deleted = await usecase.call(
      workspaceId: 'ws-1',
      conversationId: 'conversation-1',
    );

    expect(deleted, isTrue);
    expect(calls, ['cancel detached', 'stop', 'delete', 'clear draft']);
  });

  test('reopens background work when deletion returns false', () async {
    final repository = _Repository();
    final calls = <String>[];
    when(() => repository.deleteConversation('conversation-1'))
        .thenAnswer((_) async => false);
    final usecase = DeleteConversationUsecase(
      repository,
      (_) async => calls.add('stop'),
      prepareBackgroundWorkDeletion: (_) async => calls.add('cancel detached'),
      restoreBackgroundWorkAfterFailedDeletion: (_) => calls.add('reopen'),
      clearConversationDraft: (_, _) async => calls.add('clear draft'),
    );

    final deleted = await usecase.call(
      workspaceId: 'ws-1',
      conversationId: 'conversation-1',
    );

    expect(deleted, isFalse);
    expect(calls, ['cancel detached', 'stop', 'reopen']);
  });

  test(
    'clears a deleted conversation draft and its temporary attachments',
    () async {
      final repository = _Repository();
      when(() => repository.deleteConversation('conversation-1'))
          .thenAnswer((_) async => true);
      final deletedPaths = <String>[];
      final container = ProviderContainer(
        overrides: [
          localChatAttachmentUsecaseProvider.overrideWithValue(
            _RecordingLocalChatAttachmentUsecase(deletedPaths),
          ),
        ],
      );
      addTearDown(container.dispose);
      const attachment = MessageAttachmentToCreate(
        localPath: '/tmp/draft.txt',
        fileName: 'draft.txt',
        displayName: 'draft.txt',
        mimeType: 'text/plain',
        modality: .file,
        sizeBytes: 20,
      );
      final draftProvider = conversationDraftProvider('ws-1', 'conversation-1');
      container
          .read(draftProvider.notifier)
          .save(const ChatDraft(text: 'unsent', attachments: [attachment]));
      final usecase = DeleteConversationUsecase(
        repository,
        (_) => Future<void>.value(),
        prepareBackgroundWorkDeletion: (_) => Future<void>.value(),
        restoreBackgroundWorkAfterFailedDeletion: (id) =>
            expect(id, isNotEmpty),
        clearConversationDraft: container
            .read(conversationDraftCleanupUsecaseProvider)
            .clearConversation,
      );

      final deleted = await usecase.call(
        workspaceId: 'ws-1',
        conversationId: 'conversation-1',
      );

      expect(deleted, isTrue);
      expect(container.read(draftProvider), isNull);
      expect(deletedPaths, [attachment.localPath]);
    },
  );
}

class const _RecordingLocalChatAttachmentUsecase(
  final List<String> deletedPaths,
) implements LocalChatAttachmentUsecase {
  @override
  Future<void> deleteAttachment(String localPath) async {
    deletedPaths.add(localPath);
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
