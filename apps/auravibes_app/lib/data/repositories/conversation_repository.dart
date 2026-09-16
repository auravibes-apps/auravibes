// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/messages_table_type.dart';
import 'package:auravibes_app/data/database/drift/tables/messages.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:drift/drift.dart';
import 'package:uuid/v7.dart';

const _conversationTitleEmpty = 'Conversation title cannot be empty';
const _agentIdEmpty = 'Agent ID cannot be empty';
const _modelIdEmpty = 'Model ID cannot be empty';
const _parentConversationIdEmpty = 'Parent conversation ID cannot be empty';
const _unknownValidationError = 'Unknown validation error';
const _workspaceIdEmpty = 'Workspace ID cannot be empty';

String _conversationPatchValidationMessage(ConversationPatch conversation) =>
    _emptyPatchTitle(conversation) ??
    _emptyPatchModelId(conversation) ??
    _emptyPatchAgentId(conversation) ??
    _unknownValidationError;

String? _emptyPatchTitle(ConversationPatch conversation) {
  final title = conversation.title;
  if (title != null && title.isEmpty) return _conversationTitleEmpty;

  return null;
}

String? _emptyPatchModelId(ConversationPatch conversation) {
  final modelId = conversation.modelId;
  if (modelId != null && modelId.isEmpty) return _modelIdEmpty;

  return null;
}

String? _emptyPatchAgentId(ConversationPatch conversation) {
  final agentId = conversation.agentId;
  if (agentId != null && agentId.isEmpty) return _agentIdEmpty;

  return null;
}

class ConversationRepository(
  final AppDatabase _database, {
  final AttachmentFileStore _attachmentFileStore = const AttachmentFileStore(),
}) {
  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    String workspaceId, {
    String search = '',
    int? limit,
    int offset = 0,
  }) {
    return _database.conversationDao
        .watchConversationsByWorkspace(
          workspaceId,
          search: search,
          limit: limit,
          offset: offset,
        )
        .map((rows) => rows.map(_mapToConversation).toList());
  }

  Stream<ConversationEntity?> watchConversationById(String id) {
    return _database.conversationDao
        .watchConversationById(id)
        .map((row) => row != null ? _mapToConversation(row) : null);
  }

  Stream<List<ConversationEntity>> watchChildConversations(
    String parentConversationId,
  ) {
    return _database.conversationDao
        .watchChildConversations(parentConversationId)
        .map((rows) => rows.map(_mapToConversation).toList());
  }

  Future<List<ConversationEntity>> getChildConversations(
    String parentConversationId,
  ) async {
    final rows = await _database.conversationDao.getChildConversations(
      parentConversationId,
    );

    return rows.map(_mapToConversation).toList();
  }

  Future<ConversationEntity?> getConversationById(String id) async {
    final conversationTable = await _database.conversationDao
        .getConversationById(id);

    return conversationTable != null
        ? _mapToConversation(conversationTable)
        : null;
  }

  Future<ConversationEntity> createConversation(
    ConversationToCreate conversation,
  ) async {
    _validateConversationToCreate(conversation);

    final conversationCompanion = _mapToConversationsCompanion(conversation);
    final createdConversation = await _database.conversationDao
        .insertConversation(conversationCompanion);

    return _mapToConversation(createdConversation);
  }

  Future<ConversationEntity> forkConversation(
    String sourceConversationId, {
    String? throughMessageId,
  }) async {
    final source = await _database.conversationDao.getConversationById(
      sourceConversationId,
    );
    if (source == null) {
      throw ConversationNotFoundException(sourceConversationId);
    }
    final effective = await _effectiveMessageRows(sourceConversationId);
    final boundary = throughMessageId ?? _automaticForkBoundary(effective);
    if (boundary == null) {
      throw const ConversationValidationException(
        'Fork requires a terminal message',
      );
    }
    if (throughMessageId != null &&
        !effective.any(
          (row) => row.table.id == throughMessageId && _isDurable(row.table),
        )) {
      throw const ConversationValidationException(
        'Fork boundary must be a terminal message',
      );
    }

    final title = await _forkTitle(source.workspaceId, source.title);
    final fork = await _database.transaction(() async {
      final created = await _database.conversationDao.insertConversation(
        .new(
          workspaceId: .new(source.workspaceId),
          title: .new(title),
          modelId: .new(source.modelId),
          agentId: .new(source.agentId),
          parentConversationId: const Value(null),
          forkSourceConversationId: .new(source.id),
          forkSourceTitle: .new(source.title),
          forkThroughMessageId: .new(boundary),
          isPinned: const Value(false),
        ),
      );
      await _copyConversationSettings(source.id, created.id);

      return created;
    });

    return _mapToConversation(fork);
  }

  Future<ConversationEntity> patchConversation(
    String id,
    ConversationPatch conversation,
  ) async {
    _validateConversationPatch(conversation);
    final updatedConversation = await _patchConversation(id, conversation);

    return _mapToConversation(updatedConversation);
  }

  Future<bool> deleteConversation(String id) =>
      deleteConversationWithFrozenForkBoundaries(
        id,
        includeDescendantAttachmentPaths: false,
      );
}

extension ConversationRepositoryForkDeletion on ConversationRepository {
  Future<Map<String, String?>> captureForkBoundaries(String id) async {
    final boundaries = <String, String?>{};
    final pending = <String>[id];
    while (pending.isNotEmpty) {
      final sourceId = pending.removeAt(0);
      final forks = await _database
          .customSelect(
            'SELECT id FROM conversations '
            'WHERE fork_source_conversation_id = ? '
            'AND fork_materialized_at IS NULL',
            variables: [Variable<String>(sourceId)],
            readsFrom: {_database.conversations},
          )
          .get();
      for (final row in forks) {
        final forkId = row.read<String>('id');
        final fork = await _database.conversationDao.getConversationById(
          forkId,
        );
        if (fork == null) continue;
        final sourceRows = await _effectiveMessageRows(sourceId);
        final requestedBoundary = fork.forkThroughMessageId;
        final boundary =
            requestedBoundary != null &&
                sourceRows.any(
                  (row) =>
                      row.table.id == requestedBoundary &&
                      _isDurable(row.table),
                )
            ? requestedBoundary
            : _automaticForkBoundary(sourceRows);
        boundaries[forkId] = boundary;
        pending.add(forkId);
      }
    }

    return boundaries;
  }

  Future<bool> deleteConversationWithFrozenForkBoundaries(
    String id, {
    Map<String, String?>? frozenForkBoundaries,
    bool includeDescendantAttachmentPaths = true,
  }) async {
    if (!await _conversationExists(id)) return false;

    final attachmentPaths = includeDescendantAttachmentPaths
        ? await _attachmentPathsForDeletion(id)
        : (await _attachmentPathsForConversation(id)).toSet();
    final deleted = await _database.transaction(() async {
      final pendingSources = <String>[id];
      final boundaryMaps = <String, Map<String, String>>{};
      while (pendingSources.isNotEmpty) {
        final sourceId = pendingSources.removeAt(0);
        final forks = await _database
            .customSelect(
              'SELECT id FROM conversations '
              'WHERE fork_source_conversation_id = ? '
              'AND fork_materialized_at IS NULL',
              variables: [Variable<String>(sourceId)],
              readsFrom: {_database.conversations},
            )
            .get();
        for (final row in forks) {
          final forkId = row.read<String>('id');
          final fork = await _database.conversationDao.getConversationById(
            forkId,
          );
          final capturedBoundaries =
              frozenForkBoundaries ?? const <String, String?>{};
          final hasCapturedBoundary = capturedBoundaries.containsKey(forkId);
          final boundary = hasCapturedBoundary
              ? capturedBoundaries[forkId]
              : fork?.forkThroughMessageId;
          final mappedBoundary = boundary == null
              ? null
              : boundaryMaps[sourceId]?[boundary];
          if (mappedBoundary != null) {
            final _ = await _database.conversationDao.patchConversation(
              forkId,
              .new(forkThroughMessageId: .new(mappedBoundary)),
            );
          }
          boundaryMaps[forkId] = await _materializeFork(
            sourceId,
            forkId,
            boundaryOverride: mappedBoundary ?? boundary,
            boundaryWasCaptured: hasCapturedBoundary,
          );
          pendingSources.add(forkId);
        }
      }

      final sourceMessageIds =
          (await _database.messageDao.getMessagesByConversation(id))
              .map((message) => message.id)
              .toSet();
      final deleted = await _database.conversationDao.deleteConversation(id);
      if (deleted && sourceMessageIds.isNotEmpty) {
        final _ = await (_database.delete(
          _database.messageAttachments,
        )..where((table) => table.messageId.isIn(sourceMessageIds))).go();
      }

      return deleted;
    });
    if (deleted) {
      final _ = await Future.wait(
        attachmentPaths.map((path) async {
          if (!await _attachmentPathInUse(path)) {
            await _deleteAttachmentFile(path);
          }
        }),
      );
    }

    return deleted;
  }
}

extension on ConversationRepository {
  Future<String> _forkTitle(String workspaceId, String sourceTitle) async {
    final title = sourceTitle.trim();
    if (title.isEmpty) {
      throw const ConversationValidationException(
        'Conversation title cannot be empty',
      );
    }
    final titles =
        (await _database.conversationDao
                .watchConversationsByWorkspace(workspaceId)
                .first)
            .map((conversation) => conversation.title)
            .toSet();
    for (var suffix = 1; ; suffix++) {
      final candidate = suffix == 1 ? '$title Fork' : '$title Fork $suffix';
      if (!titles.contains(candidate)) return candidate;
    }
  }

  Future<List<({MessagesTable table, bool isForkReference})>>
  _effectiveMessageRows(String conversationId) async {
    final conversation = await _database.conversationDao.getConversationById(
      conversationId,
    );
    if (conversation == null) return const [];
    final rows = <({MessagesTable table, bool isForkReference})>[];
    final sourceConversationId = conversation.forkSourceConversationId;
    if (sourceConversationId != null &&
        conversation.forkMaterializedAt == null) {
      final inherited = await _effectiveMessageRows(sourceConversationId);
      final boundary = conversation.forkThroughMessageId;
      var foundBoundary = boundary == null;
      for (final row in inherited) {
        if (!_isDurable(row.table)) continue;
        rows.add((table: row.table, isForkReference: true));
        if (boundary == row.table.id) {
          foundBoundary = true;
          break;
        }
      }
      if (!foundBoundary) {
        throw const ConversationValidationException(
          'Fork boundary must be a terminal message',
        );
      }
    }
    final own = await _database.messageDao.getMessagesByConversation(
      conversationId,
    );
    rows
      ..addAll(own.map((table) => (table: table, isForkReference: false)))
      ..sort((left, right) {
        final created = left.table.createdAt.compareTo(right.table.createdAt);

        return created == 0 ? left.table.id.compareTo(right.table.id) : created;
      });

    return rows;
  }

  String? _latestTerminalMessageId(
    List<({MessagesTable table, bool isForkReference})> rows,
  ) {
    for (final row in rows.reversed) {
      if (_isDurable(row.table)) return row.table.id;
    }

    return null;
  }

  String? _automaticForkBoundary(
    List<({MessagesTable table, bool isForkReference})> rows,
  ) {
    final activeIndex = rows.indexWhere((row) => !_isDurable(row.table));
    if (activeIndex < 0) return _latestTerminalMessageId(rows);

    var turnStart = activeIndex;
    final activeMessage = rows[activeIndex].table;
    if (!activeMessage.isUser && activeIndex > 0) {
      final previous = rows[activeIndex - 1].table;
      if (previous.isUser && _isTerminalStatus(previous.status)) {
        turnStart--;
      }
    }

    for (var index = turnStart - 1; index >= 0; index--) {
      final candidate = rows[index].table;
      if (_isDurable(candidate) && !candidate.isUser) return candidate.id;
    }

    return null;
  }

  bool _isDurable(MessagesTable message) =>
      _isTerminalStatus(message.status) &&
      !(MessageMetadataEntity.fromJsonString(message.metadata)
              ?.hasPendingToolCalls ??
          false);

  bool _isTerminalStatus(MessageTableStatus status) =>
      status == MessageTableStatus.sent || status == MessageTableStatus.error;

  Future<void> _copyConversationSettings(
    String sourceId,
    String targetId,
  ) async {
    final tools = await _database.conversationToolsDao.getConversationTools(
      sourceId,
    );
    for (final tool in tools) {
      final _ = await _database
          .into(_database.conversationTools)
          .insert(
            ConversationToolsCompanion(
              conversationId: .new(targetId),
              toolId: .new(tool.toolId),
              isEnabled: .new(tool.isEnabled),
              permissions: .new(tool.permissions),
            ),
          );
    }
    final skills = await _database.conversationSkillsDao.getConversationSkills(
      sourceId,
    );
    for (final skill in skills) {
      final _ = await _database
          .into(_database.conversationSkills)
          .insert(
            ConversationSkillsCompanion(
              conversationId: .new(targetId),
              workspaceSkillId: .new(skill.workspaceSkillId),
              appSkillIdentifier: .new(skill.appSkillIdentifier),
              isLoaded: .new(skill.isLoaded),
            ),
          );
    }
  }

  Future<Map<String, String>> _materializeFork(
    String sourceId,
    String forkId, {
    String? boundaryOverride,
    bool boundaryWasCaptured = false,
  }) async {
    final fork = await _database.conversationDao.getConversationById(forkId);
    if (fork == null || fork.forkMaterializedAt != null) return const {};
    final inherited = await _effectiveMessageRows(sourceId);
    final boundary = boundaryOverride ?? fork.forkThroughMessageId;
    final idMap = <String, String>{};
    String? mappedBoundary;
    for (final row
        in boundaryWasCaptured && boundary == null
            ? const <({MessagesTable table, bool isForkReference})>[]
            : inherited) {
      if (!_isDurable(row.table)) continue;
      final messageId = const UuidV7().generate();
      idMap[row.table.id] = messageId;
      if (row.table.id == boundary) mappedBoundary = messageId;
      final _ = await _database
          .into(_database.messages)
          .insert(
            MessagesCompanion(
              id: .new(messageId),
              createdAt: .new(row.table.createdAt),
              updatedAt: .new(row.table.updatedAt),
              conversationId: .new(forkId),
              content: .new(row.table.content),
              messageType: .new(row.table.messageType),
              isUser: .new(row.table.isUser),
              status: .new(row.table.status),
              metadata: .new(row.table.metadata),
            ),
          );
      final attachments = await (_database.select(
        _database.messageAttachments,
      )..where((table) => table.messageId.equals(row.table.id))).get();
      for (final attachment in attachments) {
        final _ = await _database
            .into(_database.messageAttachments)
            .insert(
              MessageAttachmentsCompanion(
                id: .new(const UuidV7().generate()),
                createdAt: .new(attachment.createdAt),
                updatedAt: .new(attachment.updatedAt),
                messageId: .new(messageId),
                localPath: .new(attachment.localPath),
                fileName: .new(attachment.fileName),
                displayName: .new(attachment.displayName),
                mimeType: .new(attachment.mimeType),
                modality: .new(attachment.modality),
                sizeBytes: .new(attachment.sizeBytes),
              ),
            );
      }
      if (boundary != null && row.table.id == boundary) break;
    }
    if (boundary != null && mappedBoundary == null) {
      throw const ConversationValidationException(
        'Fork boundary must be a terminal message',
      );
    }
    final _ = await _database.conversationDao.patchConversation(
      forkId,
      .new(
        forkThroughMessageId: .new(mappedBoundary ?? boundary),
        forkMaterializedAt: .new(DateTime.now().toUtc()),
      ),
    );

    return idMap;
  }

  Future<bool> _attachmentPathInUse(String path) async {
    final rows = await (_database.select(
      _database.messageAttachments,
    )..where((table) => table.localPath.equals(path))).get();

    return rows.isNotEmpty;
  }

  Future<ConversationsTable> _patchConversation(
    String id,
    ConversationPatch conversation,
  ) async {
    await _requireConversation(id);

    final updated = await _database.conversationDao.patchConversation(
      id,
      _mapPatchToConversationsCompanion(conversation),
    );
    if (!updated) {
      throw ConversationException('Failed to update conversation with ID $id');
    }

    return await _updatedConversation(id);
  }

  Future<void> _requireConversation(String id) async {
    if (!await _conversationExists(id)) {
      throw ConversationNotFoundException(id);
    }
  }

  Future<ConversationsTable> _updatedConversation(String id) async {
    final result = await _database.conversationDao.getConversationById(id);
    if (result == null) {
      throw ConversationException(
        'Failed to retrieve updated conversation with ID $id',
      );
    }

    return result;
  }

  Future<List<String>> _attachmentPathsForConversation(String id) async {
    final messageIds = (await _database.messageDao.getMessagesByConversation(
      id,
    )).map((message) => message.id).toSet();
    if (messageIds.isEmpty) return const [];
    final rows = await (_database.select(
      _database.messageAttachments,
    )..where((table) => table.messageId.isIn(messageIds))).get();

    return rows.map((row) => row.localPath).toList();
  }

  Future<Set<String>> _attachmentPathsForDeletion(String id) async {
    final paths = <String>{};
    final pending = <String>[id];
    while (pending.isNotEmpty) {
      final conversationId = pending.removeAt(0);
      paths.addAll(await _attachmentPathsForConversation(conversationId));
      final children = await _database.conversationDao.getChildConversations(
        conversationId,
      );
      pending.addAll(children.map((conversation) => conversation.id));
    }

    return paths;
  }

  Future<void> _deleteAttachmentFile(String localPath) async {
    try {
      await _attachmentFileStore.deleteFile(localPath);
    } on Object {
      return;
    }
  }

  Future<bool> _conversationExists(String id) async {
    return await _database.conversationDao.getConversationById(id) != null;
  }

  void _validateConversationToCreate(ConversationToCreate conversation) {
    if (!conversation.isValid) {
      throw ConversationValidationException(
        _conversationCreateValidationMessage(conversation),
      );
    }
  }

  String _conversationCreateValidationMessage(
    ConversationToCreate conversation,
  ) {
    if (conversation.title.isEmpty) return _conversationTitleEmpty;
    if (conversation.workspaceId.isEmpty) return _workspaceIdEmpty;

    return _optionalCreateValidationMessage(conversation) ??
        _unknownValidationError;
  }

  String? _optionalCreateValidationMessage(ConversationToCreate conversation) {
    if (conversation.modelId?.isEmpty == true) return _modelIdEmpty;
    if (conversation.agentId?.isEmpty == true) return _agentIdEmpty;
    if (conversation.parentConversationId?.isEmpty == true) {
      return _parentConversationIdEmpty;
    }

    return null;
  }
}

extension on ConversationRepository {
  void _validateConversationPatch(ConversationPatch conversation) {
    if (!conversation.isValid) {
      throw ConversationValidationException(
        _conversationPatchValidationMessage(conversation),
      );
    }
  }

  ConversationEntity _mapToConversation(ConversationsTable conversationTable) {
    return ConversationEntity(
      id: conversationTable.id,
      title: conversationTable.title,
      workspaceId: conversationTable.workspaceId,
      isPinned: conversationTable.isPinned,
      createdAt: conversationTable.createdAt,
      updatedAt: conversationTable.updatedAt,
      modelId: conversationTable.modelId,
      agentId: conversationTable.agentId,
      parentConversationId: conversationTable.parentConversationId,
      forkSourceConversationId: conversationTable.forkSourceConversationId,
      forkSourceTitle: conversationTable.forkSourceTitle,
      forkThroughMessageId: conversationTable.forkThroughMessageId,
      forkMaterializedAt: conversationTable.forkMaterializedAt,
    );
  }

  ConversationsCompanion _mapToConversationsCompanion(
    ConversationToCreate conversation,
  ) {
    return ConversationsCompanion(
      workspaceId: .new(conversation.workspaceId),
      title: .new(conversation.title),
      modelId: .new(conversation.modelId),
      agentId: .new(conversation.agentId),
      parentConversationId: .new(conversation.parentConversationId),
      isPinned: .new(conversation.isPinned ?? false),
    );
  }

  ConversationsCompanion _mapPatchToConversationsCompanion(
    ConversationPatch conversation,
  ) {
    return ConversationsCompanion(
      title: .absentIfNull(conversation.title),
      modelId: .absentIfNull(conversation.modelId),
      agentId: conversation.clearAgent
          ? const Value(null)
          : Value.absentIfNull(conversation.agentId),
      isPinned: .absentIfNull(conversation.isPinned),
    );
  }
}

class const ConversationException(
  final String message, [
  final Exception? cause,
]) implements Exception {
  @override
  String toString() {
    final causedBy = ' (Caused by: ${cause.runtimeType})';

    return 'ConversationException: $message${cause != null ? causedBy : ''}';
  }
}

class const ConversationValidationException(super.message, [super.cause])
    extends ConversationException;

class const ConversationNotFoundException(
  final String conversationId, [
  Exception? cause,
]) extends ConversationException {
  this : super('Conversation with ID "$conversationId" not found', cause);
}
