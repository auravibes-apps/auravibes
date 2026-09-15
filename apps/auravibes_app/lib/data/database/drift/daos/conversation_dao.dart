import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/conversations.dart';
import 'package:drift/drift.dart';

part 'conversation_dao.g.dart';

@DriftAccessor(tables: [Conversations])
class ConversationDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with
        _$ConversationDaoMixin,
        _ConversationDaoWriteApi,
        _ConversationDaoReadApi;

mixin _ConversationDaoWriteApi {
  Future<ConversationsTable> insertConversation(
    ConversationsCompanion conversation,
  ) =>
      ConversationDaoWriteOperations(this as ConversationDao)
          .insertConversation(conversation);

  Future<ConversationsTable?> getConversationById(String id) =>
      ConversationDaoWriteOperations(this as ConversationDao)
          .getConversationById(id);

  Future<bool> patchConversation(String id, ConversationsCompanion companion) =>
      ConversationDaoWriteOperations(this as ConversationDao)
          .patchConversation(id, companion);

  Future<bool> deleteConversation(String id) =>
      ConversationDaoWriteOperations(this as ConversationDao)
          .deleteConversation(id);
}

mixin _ConversationDaoReadApi {
  Stream<ConversationsTable?> watchConversationById(String id) =>
      ConversationDaoReadOperations(this as ConversationDao)
          .watchConversationById(id);

  Stream<List<ConversationsTable>> watchConversationsByWorkspace(
    String workspaceId, {
    String? search,
    int? limit,
    int offset = 0,
  }) => ConversationDaoReadOperations(this as ConversationDao)
      .watchConversationsByWorkspace(
        workspaceId,
        search: search,
        limit: limit,
        offset: offset,
      );

  Stream<List<ConversationsTable>> watchChildConversations(
    String parentConversationId,
  ) =>
      ConversationDaoReadOperations(this as ConversationDao)
          .watchChildConversations(parentConversationId);

  Future<List<ConversationsTable>> getChildConversations(
    String parentConversationId,
  ) =>
      ConversationDaoReadOperations(this as ConversationDao)
          .getChildConversations(parentConversationId);
}

extension ConversationDaoWriteOperations on ConversationDao {
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
}

extension ConversationDaoReadOperations on ConversationDao {
  Stream<ConversationsTable?> watchConversationById(String id) => (select(
    conversations,
  )..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();

  Stream<List<ConversationsTable>> watchConversationsByWorkspace(
    String workspaceId, {
    String? search,
    int? limit,
    int offset = 0,
  }) {
    final query = _buildWorkspaceQuery(workspaceId, search: search);
    if (limit != null) query.limit(limit, offset: offset);

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
  _buildWorkspaceQuery(String workspaceId, {String? search}) {
    return _orderedConversations(
      (tbl) =>
          tbl.workspaceId.equals(workspaceId) &
          tbl.parentConversationId.isNull() &
          _conversationSearchPredicate(tbl, search),
    );
  }

  SimpleSelectStatement<$ConversationsTable, ConversationsTable>
  _buildChildrenQuery(String parentConversationId) {
    return _orderedConversations(
      (tbl) => tbl.parentConversationId.equals(parentConversationId),
    );
  }

  SimpleSelectStatement<$ConversationsTable, ConversationsTable>
  _orderedConversations(
    Expression<bool> Function($ConversationsTable) filter,
  ) => select(conversations)
    ..where(filter)
    ..orderBy([
      (tbl) => OrderingTerm(expression: tbl.updatedAt, mode: .desc),
      (tbl) => OrderingTerm(expression: tbl.id, mode: .desc),
    ]);
}

Expression<bool> _conversationSearchPredicate(
  $ConversationsTable table,
  String? search,
) {
  final normalizedSearch = search?.trim() ?? '';
  if (normalizedSearch.isEmpty) return const Constant(true);

  return table.title.like(
    '%${_escapeLike(normalizedSearch)}%',
    escapeChar: r'\',
  );
}

String _escapeLike(String value) =>
    value.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
