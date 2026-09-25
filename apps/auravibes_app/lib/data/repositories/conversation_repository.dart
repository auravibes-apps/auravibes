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

typedef _MaterializeForkRequest = ({
  String sourceId,
  String forkId,
  String? boundaryOverride,
  bool boundaryWasCaptured,
});

typedef _MaterializeForksRequest = ({
  String sourceId,
  List<String> pendingSources,
  Map<String, Map<String, String>> boundaryMaps,
  Map<String, String?> capturedBoundaries,
});

typedef _MaterializeRowsRequest = ({
  List<({MessagesTable table, bool isForkReference})> inherited,
  String? boundary,
  bool boundaryWasCaptured,
  String forkId,
});

typedef _MaterializeForkNodeRequest = ({
  String sourceId,
  String forkId,
  List<String> pendingSources,
  Map<String, Map<String, String>> boundaryMaps,
  Map<String, String?> capturedBoundaries,
});

typedef _ForkNodeBoundary = ({
  String? boundary,
  String? mappedBoundary,
  bool wasCaptured,
});

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
    final source = await _requireForkSource(sourceConversationId);
    final effective = await _effectiveMessageRows(sourceConversationId);
    final boundary = _resolveForkBoundary(effective, throughMessageId);

    final title = await _forkTitle(source.workspaceId, source.title);
    final fork = await _createFork(source, title, boundary);

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

extension ConversationRepositoryForkOperations on ConversationRepository {
  Future<Map<String, String?>> captureForkBoundaries(String id) =>
      _captureForkBoundaries(id);

  Future<bool> deleteConversationWithFrozenForkBoundaries(
    String id, {
    Map<String, String?>? frozenForkBoundaries,
    bool includeDescendantAttachmentPaths = true,
  }) => _deleteConversation(
    id,
    frozenForkBoundaries ?? const <String, String?>{},
    includeDescendantAttachmentPaths,
  );
}

extension on ConversationRepository {
  Future<Map<String, String?>> _captureForkBoundaries(String id) async {
    final boundaries = <String, String?>{};
    final pending = <String>[id];
    while (pending.isNotEmpty) {
      final sourceId = pending.removeAt(0);
      await _captureSourceBoundaries(sourceId, pending, boundaries);
    }

    return boundaries;
  }

  Future<void> _captureSourceBoundaries(
    String sourceId,
    List<String> pending,
    Map<String, String?> boundaries,
  ) async {
    final sourceRows = await _effectiveMessageRows(sourceId);
    final forks = await _unmaterializedForkIds(sourceId);
    for (final forkId in forks) {
      boundaries[forkId] = await _captureForkBoundary(forkId, sourceRows);
      pending.add(forkId);
    }
  }

  Future<List<String>> _unmaterializedForkIds(String sourceId) async {
    final rows = await _database
        .customSelect(
          'SELECT id FROM conversations '
          'WHERE fork_source_conversation_id = ? '
          'AND fork_materialized_at IS NULL',
          variables: [Variable<String>(sourceId)],
          readsFrom: {_database.conversations},
        )
        .get();

    return rows.map((row) => row.read<String>('id')).toList();
  }

  Future<String?> _captureForkBoundary(
    String forkId,
    List<({MessagesTable table, bool isForkReference})> sourceRows,
  ) async {
    final fork = await _database.conversationDao.getConversationById(forkId);
    if (fork == null) return null;
    final requested = fork.forkThroughMessageId;
    if (requested != null && _hasValidBoundary(sourceRows, requested)) {
      return requested;
    }

    return _automaticForkBoundary(sourceRows);
  }

  Future<bool> _deleteConversation(
    String id,
    Map<String, String?> frozenForkBoundaries,
    bool includeDescendantAttachmentPaths,
  ) async {
    if (!await _conversationExists(id)) return false;

    final attachmentPaths = await _attachmentPathsForDeletionMode(
      id,
      includeDescendantAttachmentPaths,
    );
    final deleted = await _database.transaction(
      () => _materializeAndDelete(id, frozenForkBoundaries),
    );
    if (deleted) await _deleteUnusedAttachments(attachmentPaths);

    return deleted;
  }

  Future<Set<String>> _attachmentPathsForDeletionMode(
    String id,
    bool includeDescendantAttachmentPaths,
  ) async {
    if (includeDescendantAttachmentPaths) {
      return await _attachmentPathsForDeletion(id);
    }

    final paths = await _attachmentPathsForConversation(id);

    return paths.toSet();
  }

  Future<bool> _materializeAndDelete(
    String id,
    Map<String, String?> capturedBoundaries,
  ) async {
    final pendingSources = <String>[id];
    final boundaryMaps = <String, Map<String, String>>{};
    while (pendingSources.isNotEmpty) {
      final sourceId = pendingSources.removeAt(0);
      await _materializeForksForSource((
        sourceId: sourceId,
        pendingSources: pendingSources,
        boundaryMaps: boundaryMaps,
        capturedBoundaries: capturedBoundaries,
      ));
    }

    return await _deleteSource(id);
  }

  Future<void> _materializeForksForSource(
    _MaterializeForksRequest request,
  ) async {
    final sourceId = request.sourceId;
    final pendingSources = request.pendingSources;
    final boundaryMaps = request.boundaryMaps;
    final capturedBoundaries = request.capturedBoundaries;
    final forkIds = await _unmaterializedForkIds(sourceId);
    for (final forkId in forkIds) {
      await _materializeForkNode((
        sourceId: sourceId,
        forkId: forkId,
        pendingSources: pendingSources,
        boundaryMaps: boundaryMaps,
        capturedBoundaries: capturedBoundaries,
      ));
    }
  }

  Future<void> _materializeForkNode(_MaterializeForkNodeRequest request) async {
    final forkId = request.forkId;
    final fork = await _database.conversationDao.getConversationById(forkId);
    if (fork == null) return;
    await _writeMaterializedForkNode(request, fork);
  }

  Future<void> _writeMaterializedForkNode(
    _MaterializeForkNodeRequest request,
    ConversationsTable fork,
  ) async {
    final nodeBoundary = _forkNodeBoundary(request, fork);
    await _updateForkBoundary(fork.id, nodeBoundary.mappedBoundary);
    request.boundaryMaps[fork.id] = await _materializeFork(
      _forkMaterializationRequest(request, fork.id, nodeBoundary),
    );
    request.pendingSources.add(fork.id);
  }

  _MaterializeForkRequest _forkMaterializationRequest(
    _MaterializeForkNodeRequest request,
    String forkId,
    _ForkNodeBoundary nodeBoundary,
  ) => (
    sourceId: request.sourceId,
    forkId: forkId,
    boundaryOverride: nodeBoundary.mappedBoundary ?? nodeBoundary.boundary,
    boundaryWasCaptured: nodeBoundary.wasCaptured,
  );

  _ForkNodeBoundary _forkNodeBoundary(
    _MaterializeForkNodeRequest request,
    ConversationsTable fork,
  ) {
    final wasCaptured = request.capturedBoundaries.containsKey(fork.id);
    final boundary = wasCaptured
        ? request.capturedBoundaries[fork.id]
        : fork.forkThroughMessageId;

    return (
      boundary: boundary,
      mappedBoundary: _mappedBoundary(request, boundary),
      wasCaptured: wasCaptured,
    );
  }

  String? _mappedBoundary(
    _MaterializeForkNodeRequest request,
    String? boundary,
  ) => boundary == null
      ? null
      : request.boundaryMaps[request.sourceId]?[boundary];

  Future<void> _updateForkBoundary(String forkId, String? boundary) async {
    if (boundary == null) return;
    final _ = await _database.conversationDao.patchConversation(
      forkId,
      .new(forkThroughMessageId: .new(boundary)),
    );
  }

  Future<bool> _deleteSource(String id) async {
    final sourceMessageIds = await _sourceMessageIds(id);
    final deleted = await _database.conversationDao.deleteConversation(id);
    if (deleted) await _deleteSourceAttachments(sourceMessageIds);

    return deleted;
  }

  Future<Set<String>> _sourceMessageIds(String id) async =>
      (await _database.messageDao.getMessagesByConversation(id))
          .map((message) => message.id)
          .toSet();

  Future<void> _deleteSourceAttachments(Set<String> messageIds) async {
    if (messageIds.isEmpty) return;
    final _ = await (_database.delete(
      _database.messageAttachments,
    )..where((table) => table.messageId.isIn(messageIds))).go();
  }

  Future<void> _deleteUnusedAttachments(Set<String> paths) async {
    final _ = await Future.wait(
      paths.map((path) async {
        if (!await _attachmentPathInUse(path)) {
          await _deleteAttachmentFile(path);
        }
      }),
    );
  }
}

extension on ConversationRepository {
  ConversationsCompanion _forkCompanion(
    ConversationsTable source,
    String title,
    String boundary,
  ) => ConversationsCompanion(
    workspaceId: .new(source.workspaceId),
    title: .new(title),
    modelId: .new(source.modelId),
    agentId: .new(source.agentId),
    reasoningConfigJson: .new(source.reasoningConfigJson),
    parentConversationId: const Value(null),
    forkSourceConversationId: .new(source.id),
    forkSourceTitle: .new(source.title),
    forkThroughMessageId: .new(boundary),
    isPinned: const Value(false),
  );

  Future<ConversationsTable> _requireForkSource(String id) async {
    final source = await _database.conversationDao.getConversationById(id);
    if (source == null) throw ConversationNotFoundException(id);

    return source;
  }

  String _resolveForkBoundary(
    List<({MessagesTable table, bool isForkReference})> rows,
    String? requestedBoundary,
  ) {
    if (requestedBoundary != null) {
      if (!_hasValidBoundary(rows, requestedBoundary)) {
        _throwInvalidForkBoundary();
      }

      return requestedBoundary;
    }
    final boundary = _automaticForkBoundary(rows);
    if (boundary == null) {
      throw const ConversationValidationException(
        'Fork requires a terminal message',
      );
    }

    return boundary;
  }

  bool _hasValidBoundary(
    List<({MessagesTable table, bool isForkReference})> rows,
    String boundary,
  ) => rows.any((row) => row.table.id == boundary && _isDurable(row.table));

  Never _throwInvalidForkBoundary() =>
      throw const ConversationValidationException(
        'Fork boundary must be a terminal message',
      );

  Future<ConversationsTable> _createFork(
    ConversationsTable source,
    String title,
    String boundary,
  ) => _database.transaction(() async {
    final created = await _database.conversationDao.insertConversation(
      _forkCompanion(source, title, boundary),
    );
    await _copyConversationSettings(source.id, created.id);

    return created;
  });

  Future<String> _forkTitle(String workspaceId, String sourceTitle) async {
    final title = sourceTitle.trim();
    if (title.isEmpty) {
      throw const ConversationValidationException(
        'Conversation title cannot be empty',
      );
    }
    final titles = await _existingTitles(workspaceId);

    return _nextForkTitle(title, titles);
  }

  Future<Set<String>> _existingTitles(String workspaceId) async =>
      (await _database.conversationDao
              .watchConversationsByWorkspace(workspaceId)
              .first)
          .map((conversation) => conversation.title)
          .toSet();

  String _nextForkTitle(String title, Set<String> titles) {
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
    final inherited = await _inheritedRows(conversation);
    final own = await _database.messageDao.getMessagesByConversation(
      conversationId,
    );

    return _sortRows(inherited, own);
  }

  Future<List<({MessagesTable table, bool isForkReference})>> _inheritedRows(
    ConversationsTable conversation,
  ) async {
    final sourceId = conversation.forkSourceConversationId;
    if (sourceId == null || conversation.forkMaterializedAt != null) {
      return const [];
    }
    final sourceRows = await _effectiveMessageRows(sourceId);

    return _rowsThroughBoundary(sourceRows, conversation.forkThroughMessageId);
  }

  List<({MessagesTable table, bool isForkReference})> _rowsThroughBoundary(
    List<({MessagesTable table, bool isForkReference})> sourceRows,
    String? boundary,
  ) {
    final rows = <({MessagesTable table, bool isForkReference})>[];
    var foundBoundary = boundary == null;
    for (final row in sourceRows) {
      if (!_isDurable(row.table)) continue;
      rows.add((table: row.table, isForkReference: true));
      if (boundary == row.table.id) {
        foundBoundary = true;
        break;
      }
    }
    if (!foundBoundary) _throwInvalidForkBoundary();

    return rows;
  }

  List<({MessagesTable table, bool isForkReference})> _sortRows(
    List<({MessagesTable table, bool isForkReference})> inherited,
    List<MessagesTable> own,
  ) => [
    ...inherited,
    ...own.map((table) => (table: table, isForkReference: false)),
  ]..sort(_compareRows);

  int _compareRows(
    ({MessagesTable table, bool isForkReference}) left,
    ({MessagesTable table, bool isForkReference}) right,
  ) {
    final created = left.table.createdAt.compareTo(right.table.createdAt);

    return created == 0 ? left.table.id.compareTo(right.table.id) : created;
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
    final activeIndex = _firstNonDurableIndex(rows);
    if (activeIndex < 0) return _latestTerminalMessageId(rows);

    final turnStart = _turnStart(rows, activeIndex);

    return _previousDurableAssistantId(rows, turnStart);
  }

  int _firstNonDurableIndex(
    List<({MessagesTable table, bool isForkReference})> rows,
  ) => rows.indexWhere((row) => !_isDurable(row.table));

  int _turnStart(
    List<({MessagesTable table, bool isForkReference})> rows,
    int activeIndex,
  ) {
    if (activeIndex == 0 || rows[activeIndex].table.isUser) {
      return activeIndex;
    }
    final previous = rows[activeIndex - 1].table;

    return previous.isUser && _isTerminalStatus(previous.status)
        ? activeIndex - 1
        : activeIndex;
  }

  String? _previousDurableAssistantId(
    List<({MessagesTable table, bool isForkReference})> rows,
    int turnStart,
  ) {
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
    await _copyConversationTools(sourceId, targetId);
    await _copyConversationSkills(sourceId, targetId);
  }

  Future<void> _copyConversationTools(String sourceId, String targetId) async {
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
  }

  Future<void> _copyConversationSkills(String sourceId, String targetId) async {
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
    _MaterializeForkRequest request,
  ) async {
    final forkId = request.forkId;
    final fork = await _database.conversationDao.getConversationById(forkId);
    if (fork == null || fork.forkMaterializedAt != null) return const {};
    final boundary = request.boundaryOverride ?? fork.forkThroughMessageId;

    return await _writeForkMaterialization(request, forkId, boundary);
  }

  Future<Map<String, String>> _writeForkMaterialization(
    _MaterializeForkRequest request,
    String forkId,
    String? boundary,
  ) async {
    final materialized = await _materializeForkRows(request, boundary);
    await _finishMaterialization(forkId, boundary, materialized);

    return materialized.idMap;
  }

  Future<({Map<String, String> idMap, String? mappedBoundary})>
  _materializeForkRows(
    _MaterializeForkRequest request,
    String? boundary,
  ) async {
    final inherited = await _effectiveMessageRows(request.sourceId);

    return await _materializeRows((
      inherited: inherited,
      boundary: boundary,
      boundaryWasCaptured: request.boundaryWasCaptured,
      forkId: request.forkId,
    ));
  }

  Future<void> _finishMaterialization(
    String forkId,
    String? boundary,
    ({Map<String, String> idMap, String? mappedBoundary}) materialized,
  ) async {
    _validateMaterializedBoundary(boundary, materialized.mappedBoundary);
    await _markMaterialized(forkId, materialized.mappedBoundary ?? boundary);
  }

  Future<({Map<String, String> idMap, String? mappedBoundary})>
  _materializeRows(_MaterializeRowsRequest request) async {
    return await _copyMaterializedRows(
      _rowsToMaterialize(
        request.inherited,
        request.boundary,
        request.boundaryWasCaptured,
      ),
      request.forkId,
      request.boundary,
    );
  }

  Future<({Map<String, String> idMap, String? mappedBoundary})>
  _copyMaterializedRows(
    Iterable<({MessagesTable table, bool isForkReference})> rows,
    String forkId,
    String? boundary,
  ) async {
    final idMap = <String, String>{};
    String? mappedBoundary;
    for (final row in rows) {
      final messageId = await _copyForkMessage(row, forkId);
      idMap[row.table.id] = messageId;
      if (row.table.id == boundary) mappedBoundary = messageId;
    }

    return (idMap: idMap, mappedBoundary: mappedBoundary);
  }

  Iterable<({MessagesTable table, bool isForkReference})> _rowsToMaterialize(
    List<({MessagesTable table, bool isForkReference})> inherited,
    String? boundary,
    bool boundaryWasCaptured,
  ) => boundaryWasCaptured && boundary == null
      ? const <({MessagesTable table, bool isForkReference})>[]
      : inherited.where((row) => _isDurable(row.table));

  Future<String> _copyForkMessage(
    ({MessagesTable table, bool isForkReference}) row,
    String forkId,
  ) async {
    final messageId = const UuidV7().generate();
    final _ = await _database
        .into(_database.messages)
        .insert(_forkMessageCompanion(row.table, messageId, forkId));
    await _copyForkAttachments(row.table.id, messageId);

    return messageId;
  }

  MessagesCompanion _forkMessageCompanion(
    MessagesTable row,
    String messageId,
    String forkId,
  ) => MessagesCompanion(
    id: .new(messageId),
    createdAt: .new(row.createdAt),
    updatedAt: .new(row.updatedAt),
    conversationId: .new(forkId),
    content: .new(row.content),
    messageType: .new(row.messageType),
    isUser: .new(row.isUser),
    status: .new(row.status),
    metadata: .new(row.metadata),
  );

  Future<void> _copyForkAttachments(
    String sourceMessageId,
    String messageId,
  ) async {
    final attachments = await (_database.select(
      _database.messageAttachments,
    )..where((table) => table.messageId.equals(sourceMessageId))).get();
    for (final attachment in attachments) {
      await _copyForkAttachment(attachment, messageId);
    }
  }

  Future<void> _copyForkAttachment(
    MessageAttachmentsTable attachment,
    String messageId,
  ) async {
    final _ = await _database
        .into(_database.messageAttachments)
        .insert(_forkAttachmentCompanion(attachment, messageId));
  }

  MessageAttachmentsCompanion _forkAttachmentCompanion(
    MessageAttachmentsTable attachment,
    String messageId,
  ) => MessageAttachmentsCompanion.insert(
    createdAt: .new(attachment.createdAt),
    updatedAt: .new(attachment.updatedAt),
    messageId: messageId,
    localPath: attachment.localPath,
    fileName: attachment.fileName,
    displayName: .new(attachment.displayName),
    mimeType: attachment.mimeType,
    modality: attachment.modality,
    sizeBytes: attachment.sizeBytes,
  ).copyWith(id: .new(const UuidV7().generate()));

  void _validateMaterializedBoundary(String? boundary, String? mappedBoundary) {
    if (boundary != null && mappedBoundary == null) _throwInvalidForkBoundary();
  }

  Future<void> _markMaterialized(String forkId, String? boundary) async {
    final _ = await _database.conversationDao.patchConversation(
      forkId,
      .new(
        forkThroughMessageId: .new(boundary),
        forkMaterializedAt: .new(DateTime.now().toUtc()),
      ),
    );
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
    final messageIds = await _messageIds(id);
    if (messageIds.isEmpty) return const [];
    final rows = await _attachmentsForMessages(messageIds);

    return rows.map((row) => row.localPath).toList();
  }

  Future<Set<String>> _messageIds(String id) async =>
      (await _database.messageDao.getMessagesByConversation(id))
          .map((message) => message.id)
          .toSet();

  Future<List<MessageAttachmentsTable>> _attachmentsForMessages(
    Set<String> messageIds,
  ) => (_database.select(
    _database.messageAttachments,
  )..where((table) => table.messageId.isIn(messageIds))).get();

  Future<Set<String>> _attachmentPathsForDeletion(String id) async {
    final paths = <String>{};
    final pending = <String>[id];
    while (pending.isNotEmpty) {
      final conversationId = pending.removeAt(0);
      paths.addAll(await _attachmentPathsForConversation(conversationId));
      pending.addAll(await _childConversationIds(conversationId));
    }

    return paths;
  }

  Future<List<String>> _childConversationIds(String id) async =>
      (await _database.conversationDao.getChildConversations(id))
          .map((conversation) => conversation.id)
          .toList();

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
    final conversation = _mapConversationCore(conversationTable);

    return conversation.copyWith(
      forkSourceConversationId: conversationTable.forkSourceConversationId,
      forkSourceTitle: conversationTable.forkSourceTitle,
      forkThroughMessageId: conversationTable.forkThroughMessageId,
      forkMaterializedAt: conversationTable.forkMaterializedAt,
    );
  }

  ConversationEntity _mapConversationCore(
    ConversationsTable conversationTable,
  ) {
    return ConversationEntity(
      id: conversationTable.id,
      title: conversationTable.title,
      workspaceId: conversationTable.workspaceId,
      isPinned: conversationTable.isPinned,
      createdAt: conversationTable.createdAt,
      updatedAt: conversationTable.updatedAt,
      modelId: conversationTable.modelId,
      agentId: conversationTable.agentId,
      reasoningConfiguration: .decode(conversationTable.reasoningConfigJson),
      parentConversationId: conversationTable.parentConversationId,
    );
  }

  ConversationsCompanion _mapToConversationsCompanion(
    ConversationToCreate conversation,
  ) => _mapConversationFieldsToCompanion(conversation).copyWith(
    createdAt: .absentIfNull(conversation.createdAt),
    updatedAt: .absentIfNull(conversation.updatedAt ?? conversation.createdAt),
  );

  ConversationsCompanion _mapConversationFieldsToCompanion(
    ConversationToCreate conversation,
  ) {
    return ConversationsCompanion(
      workspaceId: .new(conversation.workspaceId),
      title: .new(conversation.title),
      modelId: .new(conversation.modelId),
      agentId: .new(conversation.agentId),
      reasoningConfigJson: .new(conversation.reasoningConfiguration?.encode()),
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
      reasoningConfigJson: conversation.clearReasoningConfiguration
          ? const Value(null)
          : Value.absentIfNull(conversation.reasoningConfiguration?.encode()),
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
