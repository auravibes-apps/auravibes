import 'dart:async';

import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_deletion_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements ConversationRepository;

class _Cloud extends Mock implements CloudConversationUsecase;

void main() {
  for (final isCloud in [false, true]) {
    for (final fails in [false, true]) {
      test('deletion cloud=$isCloud fails=$fails', () async {
        final conversation = ConversationEntity(
          id: 'conversation',
          title: 'Conversation',
          workspaceId: 'workspace',
          isPinned: false,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
          revision: 7,
        );
        final repository = _Repository();
        final cloud = _Cloud();
        final error = StateError('delete failed');
        when(() => repository.deleteConversation(conversation.id)).thenAnswer(
          (_) => fails ? Future<bool>.error(error) : Future.value(true),
        );
        when(() => cloud.delete(conversation)).thenAnswer(
          (_) => fails ? Future<void>.error(error) : Future<void>.value(),
        );
        final lookup = Completer<CloudConversationUsecase?>();
        final container = ProviderContainer(
          overrides: [
            cloudConversationUsecaseProvider.overrideWith(
              (_, _) => lookup.future,
            ),
            conversationRepositoryProvider.overrideWith((_) {
              expect(isCloud, isFalse, reason: 'cloud never acquires local DB');

              return repository;
            }),
          ],
        );
        addTearDown(container.dispose);
        final pending = container.read(
          conversationDeletionProvider('workspace').future,
        );
        await container.pump();
        verifyZeroInteractions(repository);
        verifyZeroInteractions(cloud);
        lookup.complete(isCloud ? cloud : null);
        final delete = await pending.timeout(const Duration(seconds: 1));
        verifyZeroInteractions(repository);
        verifyZeroInteractions(cloud);
        if (fails) {
          await expectLater(delete(conversation), throwsA(same(error)));
        } else {
          await delete(conversation);
        }
        if (isCloud) {
          verify(() => cloud.delete(conversation)).called(1);
        } else {
          verify(() => repository.deleteConversation(conversation.id))
              .called(1);
        }
        verifyNoMoreInteractions(repository);
        verifyNoMoreInteractions(cloud);
      });
    }
  }
}
