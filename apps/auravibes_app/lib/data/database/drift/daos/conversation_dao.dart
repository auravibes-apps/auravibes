import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/conversation_archive_states.dart';
import 'package:auravibes_app/data/database/drift/tables/conversation_label_assignments.dart';
import 'package:auravibes_app/data/database/drift/tables/conversation_labels.dart';
import 'package:auravibes_app/data/database/drift/tables/conversations.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/conversation_label_entity.dart';
import 'package:auravibes_app/domain/entities/conversation_list_query_options.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';

part 'conversation_dao.g.dart';

typedef _ConversationLabelQuery = ({
  String workspaceId,
  String search,
  int? limit,
  int offset,
  Set<String> labelIds,
  bool archivedOnly,
});

typedef _ConversationLabelConditions = ({
  List<String> predicates,
  List<Variable> variables,
});

typedef _ConversationLabelResultTables = ({
  $ConversationLabelAssignmentsTable assignments,
  $ConversationLabelsTable labels,
});

typedef ConversationWithLabels = ({
  ConversationsTable conversation,
  List<ConversationLabelEntity> labels,
});

@DriftAccessor(
  tables: [
    Conversations,
    ConversationArchiveStates,
    ConversationLabels,
    ConversationLabelAssignments,
  ],
)
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
  Future<ConversationToolAccessMode> getToolAccessMode(String conversationId) =>
      ConversationDaoReadOperations(this as ConversationDao)
          .getToolAccessMode(conversationId);

  Stream<ConversationsTable?> watchConversationById(String id) =>
      ConversationDaoReadOperations(this as ConversationDao)
          .watchConversationById(id);

  Stream<List<ConversationsTable>> watchConversationsByWorkspace(
    String workspaceId, {
    ConversationListQueryOptions options = const (
      search: '',
      archivedOnly: false,
      limit: null,
      offset: 0,
    ),
  }) =>
      ConversationDaoReadOperations(this as ConversationDao)
          .watchConversationsByWorkspace(workspaceId, options: options);

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
  Future<ConversationToolAccessMode> getToolAccessMode(
    String conversationId,
  ) async {
    final visited = <String>{};
    var currentId = conversationId;
    while (visited.add(currentId)) {
      final conversation = await getConversationById(currentId);
      if (conversation == null) return .defaultMode;
      final parentId = conversation.parentConversationId;
      if (parentId == null) {
        return ConversationToolAccessModeStorage.decode(
          conversation.toolAccessMode,
        );
      }
      currentId = parentId;
    }

    return .defaultMode;
  }

  Stream<ConversationsTable?> watchConversationById(String id) => (select(
    conversations,
  )..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();

  Stream<List<ConversationsTable>> watchConversationsByWorkspace(
    String workspaceId, {
    ConversationListQueryOptions options = const (
      search: '',
      archivedOnly: false,
      limit: null,
      offset: 0,
    ),
  }) {
    final query = _buildWorkspaceQuery(workspaceId, options);
    final limit = options.limit;
    if (limit != null) query.limit(limit, offset: options.offset);

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
  _buildWorkspaceQuery(
    String workspaceId,
    ConversationListQueryOptions options,
  ) {
    return _orderedConversations(
      (tbl) =>
          _workspaceAndArchivePredicate(
            tbl,
            workspaceId,
            options.archivedOnly,
          ) &
          _conversationSearchPredicate(tbl, options.search),
    );
  }

  Expression<bool> _workspaceAndArchivePredicate(
    $ConversationsTable table,
    String workspaceId,
    bool archivedOnly,
  ) {
    final archivedIds = selectOnly(conversationArchiveStates)
      ..addColumns([conversationArchiveStates.conversationId])
      ..where(conversationArchiveStates.workspaceId.equals(workspaceId));

    return table.workspaceId.equals(workspaceId) &
        table.parentConversationId.isNull() &
        (archivedOnly
            ? table.id.isInQuery(archivedIds)
            : table.id.isNotInQuery(archivedIds));
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

extension ConversationDaoLabelReadOperations on ConversationDao {
  Stream<List<ConversationWithLabels>> watchConversationsWithLabelsByWorkspace(
    _ConversationLabelQuery query,
  ) => _watchConversationsWithLabels(query);

  Stream<List<ConversationWithLabels>> _watchConversationsWithLabels(
    _ConversationLabelQuery query,
  ) =>
      _buildConversationPageQuery(query)
          .watch()
          .asyncMap((rows) => _loadConversationPage(rows, query.workspaceId));

  Selectable<QueryRow> _buildConversationPageQuery(
    _ConversationLabelQuery query,
  ) {
    final conditions = _conversationLabelConditions(query);

    return customSelect(
      _conversationPageSql(conditions, query.limit),
      variables: _conversationPageVariables(query, conditions),
      readsFrom: {
        conversations,
        conversationArchiveStates,
        conversationLabels,
        conversationLabelAssignments,
      },
    );
  }

  _ConversationLabelConditions _conversationLabelConditions(
    _ConversationLabelQuery query,
  ) {
    final predicates = _baseConversationPredicates(query);
    final variables = _baseConversationVariables(query);
    _addConversationSearchPredicate(query, predicates, variables);
    _addConversationLabelPredicate(query, predicates, variables);

    return (predicates: predicates, variables: variables);
  }

  Future<List<ConversationWithLabels>> _loadConversationPage(
    List<QueryRow> rows,
    String workspaceId,
  ) async {
    if (rows.isEmpty) return const [];
    final ids = rows.map((row) => row.read<String>('id')).toList();
    final conversationsById = await _loadConversations(ids);
    final labelsByConversation = await _loadLabels(ids, workspaceId);

    return _assembleConversationPage(
      ids,
      conversationsById,
      labelsByConversation,
    );
  }

  Future<Map<String, ConversationsTable>> _loadConversations(
    List<String> ids,
  ) async => {
    for (final conversation in await (select(
      conversations,
    )..where((table) => table.id.isIn(ids))).get())
      conversation.id: conversation,
  };

  Future<Map<String, List<ConversationLabelEntity>>> _loadLabels(
    List<String> conversationIds,
    String workspaceId,
  ) async {
    final labelRows = await _labelsForConversations(
      conversationIds,
      workspaceId,
    );

    return _indexConversationLabels(labelRows, (
      assignments: conversationLabelAssignments,
      labels: conversationLabels,
    ));
  }

  Future<List<TypedResult>> _labelsForConversations(
    List<String> conversationIds,
    String workspaceId,
  ) =>
      (select(conversationLabels).join([
            innerJoin(
              conversationLabelAssignments,
              conversationLabelAssignments.labelId.equalsExp(
                    conversationLabels.id,
                  ) &
                  conversationLabelAssignments.workspaceId.equalsExp(
                    conversationLabels.workspaceId,
                  ),
            ),
          ])..where(
            conversationLabelAssignments.workspaceId.equals(workspaceId) &
                conversationLabelAssignments.conversationId.isIn(
                  conversationIds,
                ),
          ))
          .get();
}

String _conversationPageSql(
  _ConversationLabelConditions conditions,
  int? limit,
) {
  final pageClause = limit == null ? '' : 'LIMIT ? OFFSET ?';

  return '''
WITH page AS (
  SELECT c.id, c.is_pinned, c.updated_at
  FROM conversations AS c
  WHERE ${conditions.predicates.join(' AND ')}
  ORDER BY c.is_pinned DESC, c.updated_at DESC, c.id DESC
  $pageClause
)
SELECT page.id AS id
FROM page
ORDER BY page.is_pinned DESC, page.updated_at DESC, page.id DESC
''';
}

List<Variable> _conversationPageVariables(
  _ConversationLabelQuery query,
  _ConversationLabelConditions conditions,
) {
  final variables = [...conditions.variables];
  if (query.limit case final limit?) {
    variables
      ..add(Variable<int>(limit))
      ..add(Variable<int>(query.offset));
  }

  return variables;
}

List<String> _baseConversationPredicates(_ConversationLabelQuery query) {
  final archivePredicate =
      'c.id ${query.archivedOnly ? 'IN' : 'NOT IN'} '
      '(SELECT conversation_id FROM conversation_archive_states '
      'WHERE workspace_id = ?)';

  return [
    'c.workspace_id = ?',
    'c.parent_conversation_id IS NULL',
    archivePredicate,
  ];
}

List<Variable> _baseConversationVariables(_ConversationLabelQuery query) => [
  Variable<String>(query.workspaceId),
  Variable<String>(query.workspaceId),
];

void _addConversationSearchPredicate(
  _ConversationLabelQuery query,
  List<String> predicates,
  List<Variable> variables,
) {
  final search = query.search.trim();
  if (search.isEmpty) return;

  predicates.add(r'''c.title LIKE ? ESCAPE '\' ''');
  variables.add(Variable<String>('%${_escapeLike(search)}%'));
}

void _addConversationLabelPredicate(
  _ConversationLabelQuery query,
  List<String> predicates,
  List<Variable> variables,
) {
  if (query.labelIds.isEmpty) return;

  predicates.add(_conversationLabelFilterPredicate(query.labelIds.length));
  variables.addAll(query.labelIds.map(Variable<String>.new));
}

String _conversationLabelFilterPredicate(int labelCount) {
  final placeholders = List.filled(labelCount, '?').join(', ');

  return '''
EXISTS (
        SELECT 1
        FROM conversation_label_assignments AS filter_assignment
        INNER JOIN conversation_labels AS filter_label
          ON filter_label.id = filter_assignment.label_id
          AND filter_label.workspace_id = filter_assignment.workspace_id
        WHERE filter_assignment.workspace_id = c.workspace_id
          AND filter_assignment.conversation_id = c.id
          AND filter_label.id IN ($placeholders)
      )''';
}

List<ConversationWithLabels> _assembleConversationPage(
  List<String> ids,
  Map<String, ConversationsTable> conversationsById,
  Map<String, List<ConversationLabelEntity>> labelsByConversation,
) => [
  for (final id in ids)
    if (conversationsById[id] case final conversation?)
      (
        conversation: conversation,
        labels: labelsByConversation[id] ?? const [],
      ),
];

Map<String, List<ConversationLabelEntity>> _indexConversationLabels(
  List<TypedResult> rows,
  _ConversationLabelResultTables tables,
) {
  final result = <String, List<ConversationLabelEntity>>{};
  for (final row in rows) {
    _addConversationLabel(result, row, tables);
  }

  return result;
}

void _addConversationLabel(
  Map<String, List<ConversationLabelEntity>> result,
  TypedResult row,
  _ConversationLabelResultTables tables,
) {
  final assignment = row.readTable(tables.assignments);
  final label = row.readTable(tables.labels);
  result.putIfAbsent(assignment.conversationId, () => []).add(_mapLabel(label));
}

ConversationLabelEntity _mapLabel(ConversationLabelsTable label) =>
    ConversationLabelEntity(
      id: label.id,
      workspaceId: label.workspaceId,
      name: label.name,
      createdAt: label.createdAt,
      updatedAt: label.updatedAt,
    );

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
