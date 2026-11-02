import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/conversation_archive_states.dart';
import 'package:drift/drift.dart';

part 'conversation_archive_state_dao.g.dart';

@DriftAccessor(tables: [ConversationArchiveStates])
class ConversationArchiveStateDao extends DatabaseAccessor<AppDatabase>
    with _$ConversationArchiveStateDaoMixin {
  new(super.attachedDatabase);

  Stream<Set<String>> watchArchivedConversationIds(String workspaceId) =>
      (select(conversationArchiveStates)
            ..where((row) => row.workspaceId.equals(workspaceId)))
          .watch()
          .map((rows) => rows.map((row) => row.conversationId).toSet());

  Future<Set<String>> getArchivedConversationIds(String workspaceId) async =>
      (await (select(
            conversationArchiveStates,
          )..where((row) => row.workspaceId.equals(workspaceId))).get())
          .map((row) => row.conversationId)
          .toSet();

  Future<void> setArchived({
    required String workspaceId,
    required String conversationId,
    required bool isArchived,
  }) async {
    if (isArchived) {
      final _ = await into(conversationArchiveStates).insertOnConflictUpdate(
        ConversationArchiveStatesCompanion.insert(
          workspaceId: workspaceId,
          conversationId: conversationId,
          archivedAt: .new(.now().toUtc()),
        ),
      );
    } else {
      final _ =
          await (delete(conversationArchiveStates)..where(
                (row) =>
                    row.workspaceId.equals(workspaceId) &
                    row.conversationId.equals(conversationId),
              ))
              .go();
    }
  }

  Future<void> clearConversationArchive({
    required String workspaceId,
    required String conversationId,
  }) async {
    final _ =
        await (delete(conversationArchiveStates)..where(
              (row) =>
                  row.workspaceId.equals(workspaceId) &
                  row.conversationId.equals(conversationId),
            ))
            .go();
  }
}
