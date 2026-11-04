import 'package:auravibes_app/data/database/drift/app_database.dart';

class const ConversationArchiveStateRepository(final AppDatabase _database) {
  Stream<Set<String>> watchArchivedConversationIds(String workspaceId) =>
      _database.conversationArchiveStateDao.watchArchivedConversationIds(
        workspaceId,
      );

  Future<Set<String>> getArchivedConversationIds(String workspaceId) =>
      _database.conversationArchiveStateDao.getArchivedConversationIds(
        workspaceId,
      );

  Future<void> setArchived({
    required String workspaceId,
    required String conversationId,
    required bool isArchived,
  }) => _database.conversationArchiveStateDao.setArchived(
    workspaceId: workspaceId,
    conversationId: conversationId,
    isArchived: isArchived,
  );

  Future<void> clearConversationArchive({
    required String workspaceId,
    required String conversationId,
  }) => _database.conversationArchiveStateDao.clearConversationArchive(
    workspaceId: workspaceId,
    conversationId: conversationId,
  );
}
