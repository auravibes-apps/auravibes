import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/usecases/bulk_conversation_actions_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ConversationRepository extends Mock implements ConversationRepository {}

class _CloudConversation extends Mock implements CloudConversationUsecase {}

void main() {
  group('BulkConversationActionsUsecase', () {
    final conversation = ConversationEntity(
      id: 'conversation-1',
      title: 'Research',
      workspaceId: 'workspace-1',
      isPinned: false,
      createdAt: .utc(2026),
      updatedAt: .utc(2026),
    );

    test(
      'clears device archive state only after cloud deletion succeeds',
      () async {
        final cloud = _CloudConversation();
        final calls = <String>[];
        when(() => cloud.delete(conversation)).thenAnswer((_) async {
          calls.add('delete');
        });
        final usecase = BulkConversationActionsUsecase(
          conversationRepository: _ConversationRepository(),
          deleteConversation: (_) async => false,
          resolveCloudConversation: (_) async => cloud,
          clearConversationDraft: (_, _) async {
            calls.add('draft');
          },
          clearConversationArchive: (_, _) async {
            calls.add('archive');
          },
        );

        expect(await usecase.delete(conversation), isTrue);
        expect(calls, ['delete', 'archive', 'draft']);
      },
    );

    test('keeps device archive state when cloud deletion fails', () async {
      final cloud = _CloudConversation();
      final cleanupCalls = <String>[];
      when(() => cloud.delete(conversation))
          .thenThrow(StateError('Cloud deletion failed'));
      final usecase = BulkConversationActionsUsecase(
        conversationRepository: _ConversationRepository(),
        deleteConversation: (_) async => false,
        resolveCloudConversation: (_) async => cloud,
        clearConversationDraft: (_, _) async {
          cleanupCalls.add('draft');
        },
        clearConversationArchive: (_, _) async {
          cleanupCalls.add('archive');
        },
      );

      await expectLater(usecase.delete(conversation), throwsStateError);
      expect(cleanupCalls, isEmpty);
    });
  });
}
