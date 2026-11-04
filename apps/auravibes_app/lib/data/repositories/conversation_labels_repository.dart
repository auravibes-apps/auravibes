import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/conversation_dao.dart';
import 'package:auravibes_app/data/repositories/conversation_table_mapper.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/conversation_label_entity.dart';
import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';

const _maxConversationLabelNameLength = 40;

typedef _ConversationLabelAssignment = ({
  String workspaceId,
  String conversationId,
  Set<String> labelIds,
});

typedef _ConversationLabelInsert = ({
  String workspaceId,
  String name,
  String normalizedName,
});

typedef _ConversationLabelDuplicateName = ({
  String workspaceId,
  String labelId,
  String normalizedName,
});

class ConversationLabelsRepository(final AppDatabase _database) {
  Stream<List<ConversationLabelEntity>> watchLabelsByWorkspace(
    String workspaceId,
  ) => _labelsByWorkspace(_database, workspaceId).watch().map(_mapLabels);

  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    ({
      String workspaceId,
      String search,
      int? limit,
      int offset,
      Set<String> labelIds,
    })
    query, {
    bool archivedOnly = false,
  }) => _database.conversationDao
      .watchConversationsWithLabelsByWorkspace((
        workspaceId: query.workspaceId,
        search: query.search,
        limit: query.limit,
        offset: query.offset,
        labelIds: query.labelIds,
        archivedOnly: archivedOnly,
      ))
      .map(_mapConversationsWithLabels);

  Stream<List<ConversationEntity>> withLabels({
    required String workspaceId,
    required Stream<List<ConversationEntity>> conversations,
  }) => Rx.combineLatest2(
    conversations,
    _watchLabelAssignmentsByWorkspace(_database, workspaceId),
    _applyLabelAssignments,
  );

  Future<ConversationLabelEntity> createLabel({
    required String workspaceId,
    required String name,
  }) => _database.transaction(
    () =>
        _createLabelInTransaction(_database, workspaceId, _normalizeName(name)),
  );

  Future<ConversationLabelEntity> renameLabel({
    required String workspaceId,
    required String labelId,
    required String name,
  }) => _database.transaction(
    () => _renameLabelInTransaction(
      _database,
      workspaceId,
      labelId,
      _normalizeName(name),
    ),
  );

  Future<void> deleteLabel({
    required String workspaceId,
    required String labelId,
  }) => _database.transaction(
    () => _deleteLabelInTransaction(_database, workspaceId, labelId),
  );

  Future<void> setConversationLabels({
    required String workspaceId,
    required String conversationId,
    required Set<String> labelIds,
  }) => _database.transaction(
    () => _setConversationLabelsInTransaction(_database, (
      workspaceId: workspaceId,
      conversationId: conversationId,
      labelIds: labelIds,
    )),
  );
}

SimpleSelectStatement<$ConversationLabelsTable, ConversationLabelsTable>
_labelsByWorkspace(AppDatabase database, String workspaceId) =>
    database.select(database.conversationLabels)
      ..where((label) => label.workspaceId.equals(workspaceId))
      ..orderBy([(label) => OrderingTerm.asc(label.normalizedName)]);

List<ConversationLabelEntity> _mapLabels(List<ConversationLabelsTable> rows) =>
    rows.map(_mapLabel).toList();

List<ConversationEntity> _mapConversationsWithLabels(
  List<ConversationWithLabels> rows,
) => rows
    .map(
      (row) => ConversationTableMapper.toEntity(
        row.conversation,
        labels: row.labels,
      ),
    )
    .toList();

List<ConversationEntity> _applyLabelAssignments(
  List<ConversationEntity> conversations,
  Map<String, List<ConversationLabelEntity>> labelsByConversation,
) => [
  for (final conversation in conversations)
    conversation.copyWith(
      labels: labelsByConversation[conversation.id] ?? const [],
    ),
];

Future<ConversationLabelEntity> _createLabelInTransaction(
  AppDatabase database,
  String workspaceId,
  String name,
) async {
  final normalizedName = name.toLowerCase();
  await _ensureCreateNameAvailable(database, workspaceId, normalizedName);
  final inserted = await _insertLabel(database, (
    workspaceId: workspaceId,
    name: name,
    normalizedName: normalizedName,
  ));

  return _mapLabel(inserted);
}

Future<void> _ensureCreateNameAvailable(
  AppDatabase database,
  String workspaceId,
  String normalizedName,
) async {
  final existing = await _labelByNormalizedName(
    database,
    workspaceId,
    normalizedName,
  );
  if (existing != null) {
    throw const ConversationLabelAlreadyExistsException();
  }
}

Future<ConversationLabelsTable?> _labelByNormalizedName(
  AppDatabase database,
  String workspaceId,
  String normalizedName,
) =>
    (database.select(database.conversationLabels)..where(
          (label) =>
              label.workspaceId.equals(workspaceId) &
              label.normalizedName.equals(normalizedName),
        ))
        .getSingleOrNull();

Future<ConversationLabelsTable> _insertLabel(
  AppDatabase database,
  _ConversationLabelInsert label,
) {
  final now = DateTime.now().toUtc();

  return database
      .into(database.conversationLabels)
      .insertReturning(
        ConversationLabelsCompanion.insert(
          createdAt: .new(now),
          updatedAt: .new(now),
          workspaceId: label.workspaceId,
          name: label.name,
          normalizedName: label.normalizedName,
        ),
      );
}

Future<ConversationLabelEntity> _renameLabelInTransaction(
  AppDatabase database,
  String workspaceId,
  String labelId,
  String name,
) async {
  final _ = await _requireLabel(database, workspaceId, labelId);
  await _ensureRenameNameAvailable(
    database,
    workspaceId,
    labelId,
    name.toLowerCase(),
  );
  await _updateLabelName(database, labelId, name);

  return _mapLabel(await _labelById(database, labelId));
}

Future<ConversationLabelsTable> _requireLabel(
  AppDatabase database,
  String workspaceId,
  String labelId,
) async {
  final label = await _labelForWorkspace(database, workspaceId, labelId);
  if (label == null) {
    throw const ConversationWorkspaceMismatchException();
  }

  return label;
}

Future<ConversationLabelsTable?> _labelForWorkspace(
  AppDatabase database,
  String workspaceId,
  String labelId,
) =>
    (database.select(database.conversationLabels)..where(
          (row) => row.id.equals(labelId) & row.workspaceId.equals(workspaceId),
        ))
        .getSingleOrNull();

Future<ConversationLabelsTable> _labelById(
  AppDatabase database,
  String labelId,
) => (database.select(
  database.conversationLabels,
)..where((row) => row.id.equals(labelId))).getSingle();

Future<void> _ensureRenameNameAvailable(
  AppDatabase database,
  String workspaceId,
  String labelId,
  String normalizedName,
) async {
  final duplicate = await _duplicateLabelName(database, (
    workspaceId: workspaceId,
    labelId: labelId,
    normalizedName: normalizedName,
  ));
  if (duplicate != null) {
    throw const ConversationLabelAlreadyExistsException();
  }
}

Future<ConversationLabelsTable?> _duplicateLabelName(
  AppDatabase database,
  _ConversationLabelDuplicateName request,
) => (database.select(
  database.conversationLabels,
)..where((row) => _isDuplicateLabelName(row, request))).getSingleOrNull();

Expression<bool> _isDuplicateLabelName(
  $ConversationLabelsTable row,
  _ConversationLabelDuplicateName request,
) =>
    row.workspaceId.equals(request.workspaceId) &
    row.normalizedName.equals(request.normalizedName) &
    row.id.isNotIn({request.labelId});

Future<void> _updateLabelName(
  AppDatabase database,
  String labelId,
  String name,
) async {
  final updatedRows = await _writeLabelName(database, labelId, name);
  if (updatedRows != 1) {
    throw const ConversationWorkspaceMismatchException();
  }
}

Future<int> _writeLabelName(
  AppDatabase database,
  String labelId,
  String name,
) =>
    (database.update(
      database.conversationLabels,
    )..where((row) => row.id.equals(labelId))).write(
      ConversationLabelsCompanion(
        updatedAt: .new(DateTime.now().toUtc()),
        name: .new(name),
        normalizedName: .new(name.toLowerCase()),
      ),
    );

Future<void> _deleteLabelInTransaction(
  AppDatabase database,
  String workspaceId,
  String labelId,
) async {
  final _ = await _requireLabel(database, workspaceId, labelId);
  final _ = await _deleteLabelAssignments(database, labelId);
  final deletedLabels = await _deleteLabelRow(database, labelId);
  if (deletedLabels != 1) {
    throw const ConversationWorkspaceMismatchException();
  }
}

Future<int> _deleteLabelAssignments(AppDatabase database, String labelId) =>
    (database.delete(
      database.conversationLabelAssignments,
    )..where((row) => row.labelId.equals(labelId))).go();

Future<int> _deleteLabelRow(AppDatabase database, String labelId) =>
    (database.delete(
      database.conversationLabels,
    )..where((row) => row.id.equals(labelId))).go();

Future<void> _setConversationLabelsInTransaction(
  AppDatabase database,
  _ConversationLabelAssignment assignment,
) async {
  await _requireConversation(
    database,
    assignment.workspaceId,
    assignment.conversationId,
  );
  final labels = await _labelsForAssignment(database, assignment);
  await _clearConversationLabels(database, assignment);
  await _insertConversationLabels(database, assignment, labels);
}

Future<void> _requireConversation(
  AppDatabase database,
  String workspaceId,
  String conversationId,
) async {
  final conversation = await _conversationForWorkspace(
    database,
    workspaceId,
    conversationId,
  );
  if (conversation == null) {
    throw const ConversationWorkspaceMismatchException();
  }
}

Future<ConversationsTable?> _conversationForWorkspace(
  AppDatabase database,
  String workspaceId,
  String conversationId,
) =>
    (database.select(database.conversations)..where(
          (row) =>
              row.id.equals(conversationId) &
              row.workspaceId.equals(workspaceId),
        ))
        .getSingleOrNull();

Future<List<ConversationLabelsTable>> _labelsForAssignment(
  AppDatabase database,
  _ConversationLabelAssignment assignment,
) async {
  final labels = await _loadLabelsForAssignment(database, assignment);
  if (labels.length != assignment.labelIds.length) {
    throw const ConversationWorkspaceMismatchException();
  }

  return labels;
}

Future<List<ConversationLabelsTable>> _loadLabelsForAssignment(
  AppDatabase database,
  _ConversationLabelAssignment assignment,
) {
  if (assignment.labelIds.isEmpty) {
    return Future.value(const <ConversationLabelsTable>[]);
  }

  return _queryLabelsForAssignment(database, assignment);
}

Future<List<ConversationLabelsTable>> _queryLabelsForAssignment(
  AppDatabase database,
  _ConversationLabelAssignment assignment,
) => (database.select(
  database.conversationLabels,
)..where((row) => _matchesAssignmentLabel(row, assignment))).get();

Expression<bool> _matchesAssignmentLabel(
  $ConversationLabelsTable row,
  _ConversationLabelAssignment assignment,
) =>
    row.workspaceId.equals(assignment.workspaceId) &
    row.id.isIn(assignment.labelIds);

Future<void> _clearConversationLabels(
  AppDatabase database,
  _ConversationLabelAssignment assignment,
) async {
  // The deleted count is intentionally irrelevant when replacing assignments.
  // ignore: avoid_ignoring_return_values
  final _ =
      await (database.delete(database.conversationLabelAssignments)..where(
            (row) =>
                row.workspaceId.equals(assignment.workspaceId) &
                row.conversationId.equals(assignment.conversationId),
          ))
          .go();
}

Future<void> _insertConversationLabels(
  AppDatabase database,
  _ConversationLabelAssignment assignment,
  List<ConversationLabelsTable> labels,
) async {
  for (final label in labels) {
    final _ = await database
        .into(database.conversationLabelAssignments)
        .insert(
          ConversationLabelAssignmentsCompanion.insert(
            workspaceId: assignment.workspaceId,
            conversationId: assignment.conversationId,
            labelId: label.id,
          ),
        );
  }
}

ConversationLabelEntity _mapLabel(ConversationLabelsTable label) =>
    ConversationLabelEntity(
      id: label.id,
      workspaceId: label.workspaceId,
      name: label.name,
      createdAt: label.createdAt,
      updatedAt: label.updatedAt,
    );

Stream<Map<String, List<ConversationLabelEntity>>>
_watchLabelAssignmentsByWorkspace(AppDatabase database, String workspaceId) =>
    database
        .customSelect(
          '''
SELECT labels.id AS label_id,
       labels.workspace_id AS workspace_id,
       labels.name AS name,
       labels.created_at AS created_at,
       labels.updated_at AS updated_at,
       assignments.conversation_id AS conversation_id
FROM conversation_label_assignments AS assignments
INNER JOIN conversation_labels AS labels
  ON labels.id = assignments.label_id
  AND labels.workspace_id = assignments.workspace_id
WHERE assignments.workspace_id = ?
ORDER BY labels.normalized_name ASC
''',
          variables: [Variable<String>(workspaceId)],
          readsFrom: {
            database.conversationLabels,
            database.conversationLabelAssignments,
          },
        )
        .watch()
        .map(_mapLabelAssignments);

Map<String, List<ConversationLabelEntity>> _mapLabelAssignments(
  List<QueryRow> rows,
) {
  final result = <String, List<ConversationLabelEntity>>{};
  for (final row in rows) {
    final conversationId = row.read<String>('conversation_id');
    result.putIfAbsent(conversationId, () => []).add(_mapLabelAssignment(row));
  }

  return result;
}

ConversationLabelEntity _mapLabelAssignment(QueryRow row) =>
    ConversationLabelEntity(
      id: row.read<String>('label_id'),
      workspaceId: row.read<String>('workspace_id'),
      name: row.read<String>('name'),
      createdAt: row.read<DateTime>('created_at'),
      updatedAt: row.read<DateTime>('updated_at'),
    );

String _normalizeName(String name) {
  final normalized = name.trim();
  if (normalized.isEmpty ||
      normalized.length > _maxConversationLabelNameLength) {
    throw const ConversationLabelNameInvalidException();
  }

  return normalized;
}

class const ConversationLabelAlreadyExistsException() implements Exception;

class const ConversationWorkspaceMismatchException() implements Exception;

class const ConversationLabelNameInvalidException() implements Exception;
