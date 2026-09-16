import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/conversations.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
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
    String search = '',
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
  ) => transaction(() async {
    await _ensureInsertPinnedCapacity(conversation);

    return await into(conversations).insertReturning(conversation);
  });

  Future<void> _ensureInsertPinnedCapacity(
    ConversationsCompanion conversation,
  ) async {
    if (conversation.isPinned.present &&
        conversation.isPinned.value &&
        conversation.workspaceId.present) {
      await _ensurePinnedCapacity(conversation.workspaceId.value);
    }
  }

  Future<ConversationsTable?> getConversationById(String id) => (select(
    conversations,
  )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<bool> patchConversation(String id, ConversationsCompanion companion) =>
      transaction(() async {
        await _ensurePatchPinnedCapacity(id, companion);

        return await _writeConversationPatch(id, companion);
      });

  Future<bool> _writeConversationPatch(
    String id,
    ConversationsCompanion companion,
  ) async {
    final count = await (update(
      conversations,
    )..where((tbl) => tbl.id.equals(id))).write(companion);

    return count > 0;
  }

  Future<void> _ensurePatchPinnedCapacity(
    String id,
    ConversationsCompanion companion,
  ) async {
    final current = await getConversationById(id);
    if (current == null) return;

    final workspaceId = _pinTargetWorkspace(current, companion);
    if (workspaceId == null) return;

    await _ensurePinnedCapacity(workspaceId);
  }

  String? _pinTargetWorkspace(
    ConversationsTable current,
    ConversationsCompanion companion,
  ) {
    final workspaceId = companion.workspaceId.present
        ? companion.workspaceId.value
        : current.workspaceId;
    final isPinned = companion.isPinned.present
        ? companion.isPinned.value
        : current.isPinned;
    if (!isPinned || (current.isPinned && workspaceId == current.workspaceId)) {
      return null;
    }

    return workspaceId;
  }

  Future<void> _ensurePinnedCapacity(String workspaceId) async {
    final pinned = await _pinnedConversations(workspaceId);
    if (pinned.length >= ConversationLimits.maxPinnedPerWorkspace) {
      throw ConversationPinLimitException(workspaceId);
    }
  }

  Future<List<ConversationsTable>> _pinnedConversations(String workspaceId) =>
      (select(conversations)
            ..where(
              (tbl) =>
                  tbl.workspaceId.equals(workspaceId) &
                  tbl.isPinned.equals(true),
            )
            ..limit(ConversationLimits.maxPinnedPerWorkspace + 1))
          .get();

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
    String search = '',
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
  _buildWorkspaceQuery(String workspaceId, {String search = ''}) {
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
      (tbl) => OrderingTerm.desc(tbl.isPinned),
      (tbl) => OrderingTerm.desc(tbl.updatedAt),
      (tbl) => OrderingTerm.desc(tbl.id),
    ]);
}

Expression<bool> _conversationSearchPredicate(
  $ConversationsTable table,
  String search,
) {
  final normalizedSearch = search.trim();
  if (normalizedSearch.isEmpty) return const Constant(true);

  return table.title.like(
    '%${_escapeLike(normalizedSearch)}%',
    escapeChar: r'\',
  );
}

String _escapeLike(String value) =>
    value.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
