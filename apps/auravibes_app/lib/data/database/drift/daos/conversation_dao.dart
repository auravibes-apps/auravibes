import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/conversations_table.dart';
import 'package:drift/drift.dart';

part 'conversation_dao.g.dart';

@DriftAccessor(tables: [Conversations])
class ConversationDao extends DatabaseAccessor<AppDatabase>
    with _$ConversationDaoMixin {
  ConversationDao(super.attachedDatabase);

  Future<ConversationsTable> insertConversation(
    ConversationsCompanion conversation,
  ) => into(conversations).insertReturning(conversation);

  Future<ConversationsTable?> getConversationById(String id) => (select(
    conversations,
  )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<bool> patchConversation(
    String id,
    ConversationsCompanion companion,
  ) => (update(conversations)..where((tbl) => tbl.id.equals(id)))
      .write(companion)
      .then((count) => count > 0);

  Future<bool> deleteConversation(String id) => (delete(
    conversations,
  )..where((tbl) => tbl.id.equals(id))).go().then((count) => count > 0);

  Stream<ConversationsTable?> watchConversationById(String id) => (select(
    conversations,
  )..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();

  Stream<List<ConversationsTable>> watchConversationsByWorkspace(
    String workspaceId, {
    int? limit,
  }) {
    final query = _buildWorkspaceQuery(workspaceId);
    if (limit != null) query.limit(limit, offset: 0);
    return query.watch();
  }

  SimpleSelectStatement<$ConversationsTable, ConversationsTable>
  _buildWorkspaceQuery(String workspaceId) {
    return (select(conversations)
      ..where((tbl) => tbl.workspaceId.equals(workspaceId))
      ..orderBy([
        (tbl) => OrderingTerm(
          expression: tbl.updatedAt,
          mode: OrderingMode.desc,
        ),
      ]));
  }
}
