import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/conversation_archive_state_repository.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'reads and clears archived conversation IDs for one workspace',
    () async {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
      final workspace = await database.workspaceDao.insertWorkspace(
        .insert(name: 'Archive repository test', type: .local),
      );
      final repository = ConversationArchiveStateRepository(database);
      await repository.setArchived(
        workspaceId: workspace.id,
        conversationId: 'conversation-1',
        isArchived: true,
      );

      expect(
        await repository.getArchivedConversationIds(workspace.id),
        {'conversation-1'},
      );

      await repository.clearConversationArchive(
        workspaceId: workspace.id,
        conversationId: 'conversation-1',
      );

      expect(
        await repository.getArchivedConversationIds(workspace.id),
        isEmpty,
      );
    },
  );
}
