import 'package:auravibes_app/data/repositories/conversation_archive_state_repository.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';

class const ConversationArchiveStateException() implements Exception {
  String get localizationKey =>
      LocaleKeys.chats_screens_chat_conversation_archive_state_error;
}

class const SetConversationArchivedUsecase({
  required final ConversationArchiveStateRepository repository,
}) {
  final ConversationArchiveStateRepository _repository = repository;

  Future<void> call({
    required String workspaceId,
    required String conversationId,
    required bool isArchived,
  }) async {
    try {
      await _repository.setArchived(
        workspaceId: workspaceId,
        conversationId: conversationId,
        isArchived: isArchived,
      );
    } on Object catch (_, stackTrace) {
      Error.throwWithStackTrace(
        const ConversationArchiveStateException(),
        stackTrace,
      );
    }
  }
}
