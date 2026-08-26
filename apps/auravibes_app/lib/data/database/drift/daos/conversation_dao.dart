import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/conversations.dart';
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
  ) async {
    final count = await (update(
      conversations,
    )..where((tbl) => tbl.id.equals(id))).write(companion);

    return count > 0;
  }

  Future<bool> deleteConversation(String id) async {
    final count = await (delete(
      conversations,
    )..where((tbl) => tbl.id.equals(id))).go();

    return count > 0;
  }

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

  Stream<List<ConversationsTable>> watchChildConversations(
    String parentConversationId,
  ) {
    return _buildChildrenQuery(parentConversationId).watch();
  }

  Future<List<ConversationsTable>> getChildConversations(
    String parentConversationId,
  ) {
    return _buildChildrenQuery(parentConversationId).get();
  }

  SimpleSelectStatement<$ConversationsTable, ConversationsTable>
  _buildWorkspaceQuery(String workspaceId) {
    return (select(conversations)
      ..where(
        (tbl) =>
            tbl.workspaceId.equals(workspaceId) &
            tbl.parentConversationId.isNull(),
      )
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.updatedAt, mode: OrderingMode.desc),
      ]));
  }

  SimpleSelectStatement<$ConversationsTable, ConversationsTable>
  _buildChildrenQuery(String parentConversationId) {
    return (select(conversations)
      ..where((tbl) => tbl.parentConversationId.equals(parentConversationId))
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.updatedAt, mode: OrderingMode.desc),
      ]));
  }
}
