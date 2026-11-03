import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/conversation_label_entity.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';

const _maxConversationLabelNameLength = 40;

class const ConversationLabelAlreadyExistsException implements Exception;

class const ConversationLabelWorkspaceMismatchException implements Exception;

class const ConversationLabelNameInvalidException implements Exception;

class ConversationLabelsRepository {
  ConversationLabelsRepository(this._database);

  final AppDatabase _database;

  Stream<List<ConversationLabelEntity>> watchLabelsByWorkspace(
    String workspaceId,
  ) => (_database.select(_database.conversationLabels)
        ..where((label) => label.workspaceId.equals(workspaceId))
        ..orderBy([(label) => OrderingTerm.asc(label.normalizedName)]))
      .watch()
      .map((rows) => rows.map(_mapLabel).toList());

  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    String workspaceId, {
    String search = '',
    int? limit,
    int offset = 0,
    Set<String> labelIds = const {},
  }) => _database.conversationDao
      .watchConversationsWithLabelsByWorkspace(
        workspaceId,
        search: search,
        limit: limit,
        offset: offset,
        labelIds: labelIds,
      )
      .map(
        (rows) => rows
            .map((row) => _mapConversation(row.conversation, row.labels))
            .toList(),
      );

  Stream<List<ConversationEntity>> withLabels({
    required String workspaceId,
    required Stream<List<ConversationEntity>> conversations,
  }) => Rx.combineLatest2(
    conversations,
    _watchLabelAssignmentsByWorkspace(workspaceId),
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
    final normalizedName = normalized.toLowerCase();
    return await _database.transaction(() async {
      final existing = await (_database.select(_database.conversationLabels)
            ..where(
              (label) =>
                  label.workspaceId.equals(workspaceId) &
                  label.normalizedName.equals(normalizedName),
            ))
          .getSingleOrNull();
      if (existing != null) throw const ConversationLabelAlreadyExistsException();
      final now = DateTime.now().toUtc();
      final inserted = await _database
          .into(_database.conversationLabels)
          .insertReturning(
            ConversationLabelsCompanion.insert(
              workspaceId: workspaceId,
              name: normalized,
              normalizedName: normalizedName,
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      return _mapLabel(inserted);
    });
  }

  Future<ConversationLabelEntity> renameLabel({
    required String workspaceId,
    required String labelId,
    required String name,
  }) async {
    final normalized = _normalizeName(name);
    final normalizedName = normalized.toLowerCase();
    return await _database.transaction(() async {
      final label = await (_database.select(_database.conversationLabels)
            ..where(
              (row) =>
                  row.id.equals(labelId) & row.workspaceId.equals(workspaceId),
            ))
          .getSingleOrNull();
      if (label == null) throw const ConversationLabelWorkspaceMismatchException();
      final duplicate = await (_database.select(_database.conversationLabels)
            ..where(
              (row) =>
                  row.workspaceId.equals(workspaceId) &
                  row.normalizedName.equals(normalizedName) &
                  row.id.isNotIn({labelId}),
            ))
          .getSingleOrNull();
      if (duplicate != null) throw const ConversationLabelAlreadyExistsException();
      final now = DateTime.now().toUtc();
      await (_database.update(_database.conversationLabels)
            ..where((row) => row.id.equals(labelId)))
          .write(
            ConversationLabelsCompanion(
              name: Value(normalized),
              normalizedName: Value(normalizedName),
              updatedAt: Value(now),
            ),
          );
      final updated = await (_database.select(_database.conversationLabels)
            ..where((row) => row.id.equals(labelId)))
          .getSingle();
      return _mapLabel(updated);
    });
  }

  Future<void> deleteLabel({
    required String workspaceId,
    required String labelId,
  }) => _database.transaction(() async {
    final label = await (_database.select(_database.conversationLabels)
          ..where(
            (row) =>
                row.id.equals(labelId) & row.workspaceId.equals(workspaceId),
          ))
        .getSingleOrNull();
    if (label == null) throw const ConversationLabelWorkspaceMismatchException();
    await (_database.delete(_database.conversationLabelAssignments)
          ..where((row) => row.labelId.equals(labelId)))
        .go();
    await (_database.delete(_database.conversationLabels)
          ..where((row) => row.id.equals(labelId)))
        .go();
  });

  Future<void> setConversationLabels({
    required String workspaceId,
    required String conversationId,
    required Set<String> labelIds,
  }) => _database.transaction(() async {
    final conversation = await (_database.select(_database.conversations)
          ..where(
            (row) =>
                row.id.equals(conversationId) &
                row.workspaceId.equals(workspaceId),
          ))
        .getSingleOrNull();
    if (conversation == null) {
      throw const ConversationLabelWorkspaceMismatchException();
    }
    final labels = labelIds.isEmpty
        ? const <ConversationLabelsTable>[]
        : await (_database.select(_database.conversationLabels)
              ..where(
                (row) =>
                    row.workspaceId.equals(workspaceId) &
                    row.id.isIn(labelIds),
              ))
            .get();
    if (labels.length != labelIds.length) {
      throw const ConversationLabelWorkspaceMismatchException();
    }
    await (_database.delete(_database.conversationLabelAssignments)
          ..where(
            (row) =>
                row.workspaceId.equals(workspaceId) &
                row.conversationId.equals(conversationId),
          ))
        .go();
    for (final label in labels) {
      await _database.into(_database.conversationLabelAssignments).insert(
        ConversationLabelAssignmentsCompanion.insert(
          workspaceId: workspaceId,
          conversationId: conversationId,
          labelId: label.id,
        ),
      );
    }
  });

  ConversationLabelEntity _mapLabel(ConversationLabelsTable label) =>
      ConversationLabelEntity(
        id: label.id,
        workspaceId: label.workspaceId,
        name: label.name,
        createdAt: label.createdAt,
        updatedAt: label.updatedAt,
      );

  Stream<Map<String, List<ConversationLabelEntity>>>
  _watchLabelAssignmentsByWorkspace(String workspaceId) => _database
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
          _database.conversationLabels,
          _database.conversationLabelAssignments,
        },
      )
      .watch()
      .map((rows) {
        final result = <String, List<ConversationLabelEntity>>{};
        for (final row in rows) {
          result
              .putIfAbsent(row.read<String>('conversation_id'), () => [])
              .add(
                ConversationLabelEntity(
                  id: row.read<String>('label_id'),
                  workspaceId: row.read<String>('workspace_id'),
                  name: row.read<String>('name'),
                  createdAt: row.read<DateTime>('created_at'),
                  updatedAt: row.read<DateTime>('updated_at'),
                ),
              );
        }
        return result;
      });

  ConversationEntity _mapConversation(
    ConversationsTable conversation,
    List<ConversationLabelEntity> labels,
  ) =>
      ConversationEntity(
        id: conversation.id,
        title: conversation.title,
        workspaceId: conversation.workspaceId,
        isPinned: conversation.isPinned,
        createdAt: conversation.createdAt,
        updatedAt: conversation.updatedAt,
        labels: labels,
        modelId: conversation.modelId,
        agentId: conversation.agentId,
        reasoningConfiguration: .decode(conversation.reasoningConfigJson),
        taskBrief: conversation.taskBrief,
        parentConversationId: conversation.parentConversationId,
        forkSourceConversationId: conversation.forkSourceConversationId,
        forkSourceTitle: conversation.forkSourceTitle,
        forkThroughMessageId: conversation.forkThroughMessageId,
        forkMaterializedAt: conversation.forkMaterializedAt,
        activeCompactionCheckpointId:
            conversation.activeCompactionCheckpointId,
        toolAccessMode: ConversationToolAccessModeStorage.decode(
          conversation.toolAccessMode,
        ),
      );
}

String _normalizeName(String name) {
  final normalized = name.trim();
  if (normalized.isEmpty || normalized.length > _maxConversationLabelNameLength) {
    throw const ConversationLabelNameInvalidException();
  }
  return normalized;
}
