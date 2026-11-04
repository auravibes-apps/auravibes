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

class ConversationLabelsRepository(final AppDatabase _database) {
  Stream<List<ConversationLabelEntity>> watchLabelsByWorkspace(
    String workspaceId,
  ) => this._labelsByWorkspace(workspaceId).watch().map(this._mapLabels);

  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    ConversationLabelQuery query,
  ) => _database.conversationDao
      .watchConversationsWithLabelsByWorkspace((
        workspaceId: query.workspaceId,
        search: query.search,
        limit: query.limit,
        offset: query.offset,
        labelIds: query.labelIds,
      ))
      .map(
        (rows) => rows
            .map(
              (row) => ConversationTableMapper.toEntity(
                row.conversation,
                labels: row.labels,
              ),
            )
            .toList(),
      );

  Stream<List<ConversationEntity>> withLabels({
    required String workspaceId,
    required Stream<List<ConversationEntity>> conversations,
  }) => Rx.combineLatest2(
    conversations,
    this._watchLabelAssignmentsByWorkspace(workspaceId),
    (conversations, labelsByConversation) => [
      for (final conversation in conversations)
        conversation.copyWith(
          labels: labelsByConversation[conversation.id] ?? const [],
        ),
    ],
  );

  Future<ConversationLabelEntity> createLabel({
    required String workspaceId,
    required String name,
  }) async {
    final normalized = _normalizeName(name);

    return _database.transaction(
      () => this._createLabelInTransaction(workspaceId, normalized),
    );
  }

  Future<ConversationLabelEntity> renameLabel({
    required String workspaceId,
    required String labelId,
    required String name,
  }) async {
    final normalized = _normalizeName(name);

    return _database.transaction(
      () => this._renameLabelInTransaction(workspaceId, labelId, normalized),
    );
  }

  Future<void> deleteLabel({
    required String workspaceId,
    required String labelId,
  }) => _database.transaction(
    () => this._deleteLabelInTransaction(workspaceId, labelId),
  );

  Future<void> setConversationLabels({
    required String workspaceId,
    required String conversationId,
    required Set<String> labelIds,
  }) => _database.transaction(
    () => this._setConversationLabelsInTransaction((
      workspaceId: workspaceId,
      conversationId: conversationId,
      labelIds: labelIds,
    )),
  );
}

extension on ConversationLabelsRepository {
  SimpleSelectStatement<$ConversationLabelsTable, ConversationLabelsTable>
  _labelsByWorkspace(String workspaceId) =>
      this._database.select(this._database.conversationLabels)
        ..where((label) => label.workspaceId.equals(workspaceId))
        ..orderBy([(label) => OrderingTerm.asc(label.normalizedName)]);

  List<ConversationLabelEntity> _mapLabels(
    List<ConversationLabelsTable> rows,
  ) => rows.map(this._mapLabel).toList();

  Future<ConversationLabelEntity> _createLabelInTransaction(
    String workspaceId,
    String name,
  ) async {
    final normalizedName = name.toLowerCase();
    final existing = await this._labelByNormalizedName(
      workspaceId,
      normalizedName,
    );
    if (existing != null) {
      throw const ConversationLabelAlreadyExistsException();
    }
    final now = DateTime.now().toUtc();
    final inserted = await this._database
        .into(this._database.conversationLabels)
        .insertReturning(
          ConversationLabelsCompanion.insert(
            createdAt: .new(now),
            updatedAt: .new(now),
            workspaceId: workspaceId,
            name: name,
            normalizedName: normalizedName,
          ),
        );

    return this._mapLabel(inserted);
  }

  Future<ConversationLabelsTable?> _labelByNormalizedName(
    String workspaceId,
    String normalizedName,
  ) =>
      (this._database.select(this._database.conversationLabels)..where(
            (label) =>
                label.workspaceId.equals(workspaceId) &
                label.normalizedName.equals(normalizedName),
          ))
          .getSingleOrNull();

  Future<ConversationLabelEntity> _renameLabelInTransaction(
    String workspaceId,
    String labelId,
    String name,
  ) async {
    await this._requireLabel(workspaceId, labelId);
    await this._ensureLabelNameAvailable(
      workspaceId,
      labelId,
      name.toLowerCase(),
    );
    await this._updateLabelName(labelId, name);

    return this._mapLabel(await this._labelById(labelId));
  }

  Future<ConversationLabelsTable> _requireLabel(
    String workspaceId,
    String labelId,
  ) async {
    final label =
        await (this._database.select(this._database.conversationLabels)..where(
              (row) =>
                  row.id.equals(labelId) & row.workspaceId.equals(workspaceId),
            ))
            .getSingleOrNull();
    if (label == null) {
      throw const ConversationWorkspaceMismatchException();
    }

    return label;
  }

  Future<ConversationLabelsTable> _labelById(String labelId) =>
      (this._database.select(
        this._database.conversationLabels,
      )..where((row) => row.id.equals(labelId))).getSingle();

  Future<void> _ensureLabelNameAvailable(
    String workspaceId,
    String labelId,
    String normalizedName,
  ) async {
    final duplicate =
        await (this._database.select(this._database.conversationLabels)..where(
              (row) =>
                  row.workspaceId.equals(workspaceId) &
                  row.normalizedName.equals(normalizedName) &
                  row.id.isNotIn({labelId}),
            ))
            .getSingleOrNull();
    if (duplicate != null) {
      throw const ConversationLabelAlreadyExistsException();
    }
  }

  Future<void> _updateLabelName(String labelId, String name) async {
    final _ =
        await (this._database.update(
          this._database.conversationLabels,
        )..where((row) => row.id.equals(labelId))).write(
          ConversationLabelsCompanion(
            updatedAt: .new(DateTime.now().toUtc()),
            name: .new(name),
            normalizedName: .new(name.toLowerCase()),
          ),
        );
  }

  Future<void> _deleteLabelInTransaction(
    String workspaceId,
    String labelId,
  ) async {
    await this._requireLabel(workspaceId, labelId);
    final _ = await (this._database.delete(
      this._database.conversationLabelAssignments,
    )..where((row) => row.labelId.equals(labelId))).go();
    final _ = await (this._database.delete(
      this._database.conversationLabels,
    )..where((row) => row.id.equals(labelId))).go();
  }

  Future<void> _setConversationLabelsInTransaction(
    _ConversationLabelAssignment assignment,
  ) async {
    await this._requireConversation(
      assignment.workspaceId,
      assignment.conversationId,
    );
    final labels = await this._labelsForAssignment(assignment);
    await this._clearConversationLabels(assignment);
    await this._insertConversationLabels(assignment, labels);
  }

  Future<void> _requireConversation(
    String workspaceId,
    String conversationId,
  ) async {
    final conversation =
        await (this._database.select(this._database.conversations)..where(
              (row) =>
                  row.id.equals(conversationId) &
                  row.workspaceId.equals(workspaceId),
            ))
            .getSingleOrNull();
    if (conversation == null) {
      throw const ConversationWorkspaceMismatchException();
    }
  }

  Future<List<ConversationLabelsTable>> _labelsForAssignment(
    _ConversationLabelAssignment assignment,
  ) async {
    final labels = assignment.labelIds.isEmpty
        ? const <ConversationLabelsTable>[]
        : await (this._database.select(this._database.conversationLabels)
                ..where(
                  (row) =>
                      row.workspaceId.equals(assignment.workspaceId) &
                      row.id.isIn(assignment.labelIds),
                ))
              .get();
    if (labels.length != assignment.labelIds.length) {
      throw const ConversationWorkspaceMismatchException();
    }

    return labels;
  }

  Future<void> _clearConversationLabels(
    _ConversationLabelAssignment assignment,
  ) async {
    final _ =
        await (this._database.delete(
              this._database.conversationLabelAssignments,
            )..where(
              (row) =>
                  row.workspaceId.equals(assignment.workspaceId) &
                  row.conversationId.equals(assignment.conversationId),
            ))
            .go();
  }

  Future<void> _insertConversationLabels(
    _ConversationLabelAssignment assignment,
    List<ConversationLabelsTable> labels,
  ) async {
    for (final label in labels) {
      final _ = await this._database
          .into(this._database.conversationLabelAssignments)
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
  _watchLabelAssignmentsByWorkspace(String workspaceId) => this._database
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
          this._database.conversationLabels,
          this._database.conversationLabelAssignments,
        },
      )
      .watch()
      .map(this._mapLabelAssignments);

  Map<String, List<ConversationLabelEntity>> _mapLabelAssignments(
    List<QueryRow> rows,
  ) {
    final result = <String, List<ConversationLabelEntity>>{};
    for (final row in rows) {
      final conversationId = row.read<String>('conversation_id');
      result
          .putIfAbsent(conversationId, () => [])
          .add(this._mapLabelAssignment(row));
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
}

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
