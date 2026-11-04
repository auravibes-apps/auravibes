import 'package:auravibes_app/data/repositories/conversation_archive_state_repository.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_archive_state_exception.dart';
import 'package:auravibes_app/features/chats/usecases/set_conversation_archived_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ConversationArchiveStateRepository extends Mock
    implements ConversationArchiveStateRepository {}

void main() {
  test(
    'maps archive persistence failures to a user-facing exception',
    () async {
      final repository = _ConversationArchiveStateRepository();
      when(
        () => repository.setArchived(
          workspaceId: 'workspace-1',
          conversationId: 'conversation-1',
          isArchived: true,
        ),
      ).thenThrow(StateError('database is unavailable'));
      final usecase = SetConversationArchivedUsecase(repository: repository);

      await expectLater(
        usecase.call(
          workspaceId: 'workspace-1',
          conversationId: 'conversation-1',
          isArchived: true,
        ),
        throwsA(isA<ConversationArchiveStateException>()),
      );
    },
  );

  test('includes the localization key in the exception description', () {
    const exception = ConversationArchiveStateException();

    expect(
      exception.toString(),
      'ConversationArchiveStateException('
      '${LocaleKeys.chats_screens_chat_conversation_archive_state_error})',
    );
  });
}
