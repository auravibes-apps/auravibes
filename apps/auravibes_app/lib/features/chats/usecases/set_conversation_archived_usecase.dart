import 'package:auravibes_app/data/repositories/conversation_archive_state_repository.dart';

import 'package:auravibes_app/features/chats/usecases/conversation_archive_state_exception.dart';

class const SetConversationArchivedUsecase({
  required final ConversationArchiveStateRepository repository,
}) {
  Future<void> call({
    required String workspaceId,
    required String conversationId,
    required bool isArchived,
  }) async {
    try {
      await repository.setArchived(
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
