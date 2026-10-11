import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/features/chats/usecases/delete_conversation_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
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
    );

    final deleted = await usecase.call('conversation-1');

    expect(deleted, isTrue);
    expect(calls, ['cancel detached', 'stop', 'delete']);
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
    );

    final deleted = await usecase.call('conversation-1');

    expect(deleted, isFalse);
    expect(calls, ['cancel detached', 'stop', 'reopen']);
  });
}
