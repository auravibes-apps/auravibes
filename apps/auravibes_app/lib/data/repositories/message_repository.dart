// Required: Existing test and UI helpers keep compact return flow.

import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/messages_table_type.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/data/repositories/local_message_asset_references.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_mutation.dart';
import 'package:auravibes_app/domain/entities/conversation_message_search_result.dart';
import 'package:auravibes_app/domain/entities/message_bookmark_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/sanitize_workspace_tool_result.dart';
import 'package:auravibes_app/domain/entities/tool_call_approval_batch_item.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/utils/json_codec.dart';
import 'package:characters/characters.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';

const _messageContentCannotBeEmpty = 'Message content cannot be empty';
const _messageBookmarkExcerptLength = 160;
const _maxConversationMessageSearchQueryLength = 256;
const _maxConversationMessageSearchPageSize = 50;
const _maxConversationMessageSearchOffset = 10000;
const _conversationMessageSearchContextBefore = 50;
const _conversationMessageSearchContextLength = 100;
const _minConversationMessageSearchExcerptLength = 120;
const _maxConversationMessageSearchExcerptLength = 356;

bool _isTerminalStatus(MessageTableStatus status) =>
    status == MessageTableStatus.sent || status == MessageTableStatus.error;

typedef _MessageWatchError = ({
  Exception error,
  StackTrace stackTrace,
  EventSink<List<MessageEntity>> sink,
  String conversationId,
});

typedef _MessageWatchErrorInput = ({
  Object error,
  StackTrace stackTrace,
  EventSink<List<MessageEntity>> sink,
  String conversationId,
});

typedef _MessageMapping = ({
  MessagesTable table,
  List<MessageAttachmentEntity> attachments,
  String? conversationIdOverride,
  bool isForkReference,
  MessageMetadataEntity? metadataOverride,
});

typedef _EffectiveMessageMappingContext = ({
  String conversationId,
  Map<String, List<MessageAttachmentEntity>> attachmentsByMessage,
  Map<String, Set<String>> detachedToolCallIds,
});

class _MessageWatchController {
  new(
    this._repository,
    this._conversationId, {
    this._includeTranscriptContext = false,
  });

  final MessageRepository _repository;
  final String _conversationId;
  final bool _includeTranscriptContext;
  final _controller = StreamController<List<MessageEntity>>();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  var _pending = false;
  var _running = false;

  Stream<List<MessageEntity>> get stream => _controller.stream;

  void listen() {
    final database = _repository._database;
    _subscriptions
      ..add(database.select(database.messages).watch().listen(_onChange))
      ..add(database.select(database.conversations).watch().listen(_onChange))
      ..add(
        database.select(database.messageAttachments).watch().listen(_onChange),
      );
    unawaited(emit());
  }

  Future<void> emit() async {
    if (_running) {
      _pending = true;

      return;
    }
    _running = true;
    do {
      _pending = false;
      await _emitOnce();
    } while (_pending);
    _running = false;
  }

  Future<void> cancel() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  void _onChange(Object _) => unawaited(emit());

  Future<void> _emitOnce() async {
    try {
      final messages = _includeTranscriptContext
          ? await _repository._getEffectiveTranscriptMessages(_conversationId)
          : await _repository._getEffectiveMessages(_conversationId);
      if (!_controller.isClosed) _controller.add(messages);
    } on Object catch (error, stackTrace) {
      if (!_controller.isClosed) _controller.addError(error, stackTrace);
    }
  }
}

/// Implementation of [MessageRepository] interface.
///
/// This class provides a concrete implementation of message data operations
/// using Drift database. It handles the mapping between domain entities
/// and database records, and provides proper error handling using exceptions.
class MessageRepository(
  /// The database instance for message operations.
  final AppDatabase _database, {
  final AttachmentFileStore _attachmentFileStore = const AttachmentFileStore(),
}) with
    _MessageRepositoryReadApi,
    _MessageRepositoryQueryApi,
    _MessageRepositoryMutationApi,
    _MessageRepositoryStateApi {
  Future<List<MessageEntity>> getMessagesByConversation(
    String conversationId,
  ) => _getEffectiveMessages(conversationId);

  Future<bool> bookmarkMessage({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) => _setMessageBookmarked(
    workspaceId: workspaceId,
    conversationId: conversationId,
    messageId: messageId,
    isBookmarked: true,
  );

  Future<bool> unbookmarkMessage({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) => _setMessageBookmarked(
    workspaceId: workspaceId,
    conversationId: conversationId,
    messageId: messageId,
    isBookmarked: false,
  );

  Stream<List<MessageBookmarkEntity>> watchBookmarkedMessages([
    String? workspaceId,
  ]) => _watchBookmarkedMessageRows(
    _database,
    workspaceId,
  ).map(_messageBookmarksFromRows);

  /// Includes trusted context entries for continuation replay and fork history.
  Future<List<MessageEntity>> getTranscriptMessagesByConversation(
    String conversationId,
  ) => _getEffectiveTranscriptMessages(conversationId);

  /// Watches the full transcript, including internal agent context entries.
  Stream<List<MessageEntity>> watchTranscriptMessagesByConversation(
    String conversationId,
  ) => _watchTranscriptMessages(conversationId);
}

Stream<List<QueryRow>> _watchBookmarkedMessageRows(
  AppDatabase database,
  String? workspaceId,
) {
  final workspaceFilter = workspaceId == null
      ? ''
      : 'AND conversations.workspace_id = ?';

  return database
      .customSelect(
        '''
        SELECT conversations.workspace_id AS workspace_id,
               message_bookmarks.id AS message_id,
               message_bookmarks.conversation_id AS conversation_id,
               COALESCE(messages.content, message_bookmarks.content_snapshot)
                 AS content,
               COALESCE(messages.is_user, message_bookmarks.is_user) AS is_user,
               COALESCE(
                 messages.created_at,
                 message_bookmarks.message_created_at
               ) AS created_at,
               conversations.title AS conversation_title,
               workspaces.name AS workspace_name
        FROM message_bookmarks
        INNER JOIN conversations
          ON conversations.id = message_bookmarks.conversation_id
        INNER JOIN workspaces
          ON workspaces.id = conversations.workspace_id
        LEFT JOIN messages
          ON messages.id = message_bookmarks.id
        WHERE workspaces.type = 'local'
          $workspaceFilter
        ORDER BY COALESCE(
          messages.created_at,
          message_bookmarks.message_created_at
        ) DESC, message_bookmarks.id DESC
        ''',
        variables: [if (workspaceId != null) Variable<String>(workspaceId)],
        readsFrom: {
          database.messageBookmarks,
          database.messages,
          database.conversations,
          database.workspaces,
        },
      )
      .watch();
}

List<MessageBookmarkEntity> _messageBookmarksFromRows(List<QueryRow> rows) =>
    rows.map(_messageBookmarkFromRow).toList(growable: false);

MessageBookmarkEntity _messageBookmarkFromRow(QueryRow row) =>
    MessageBookmarkEntity(
      details: _messageBookmarkDetailsFromRow(
        row,
        isUser: row.read<bool>('is_user'),
      ),
      workspace: _messageBookmarkWorkspaceFromRow(row),
    );

MessageBookmarkDetails _messageBookmarkDetailsFromRow(
  QueryRow row, {
  required bool isUser,
}) => MessageBookmarkDetails(
  messageId: row.read<String>('message_id'),
  conversationId: row.read<String>('conversation_id'),
  excerpt: _messageBookmarkExcerptFromRow(row),
  workspaceName: row.read<String>('workspace_name'),
  createdAt: row.read<DateTime>('created_at'),
  conversationTitle: row.read<String>('conversation_title'),
  isUser: isUser,
);

String _messageBookmarkExcerptFromRow(QueryRow row) =>
    _messageBookmarkExcerpt(row.read<String>('content'));

MessageBookmarkWorkspace _messageBookmarkWorkspaceFromRow(QueryRow row) =>
    MessageBookmarkWorkspace(workspaceId: row.read<String>('workspace_id'));

String _messageBookmarkExcerpt(String content) {
  final trimmed = content.trim();
  final runes = trimmed.runes;
  if (runes.length <= _messageBookmarkExcerptLength) return trimmed;

  final excerpt = String.fromCharCodes(
    runes.take(_messageBookmarkExcerptLength),
  );

  return '$excerpt...';
}

extension on MessageRepository {
  Future<bool> _setMessageBookmarked({
    required String workspaceId,
    required String conversationId,
    required String messageId,
    required bool isBookmarked,
  }) async {
    if (!await _isBookmarkableMessage(workspaceId, conversationId, messageId)) {
      return false;
    }

    return await _database.transaction(
      () => _setMessageBookmarkInTransaction(messageId, isBookmarked),
    );
  }

  Future<bool> _setMessageBookmarkInTransaction(
    String messageId,
    bool isBookmarked,
  ) async {
    final message = await _database.messageDao.getMessageById(messageId);
    if (message == null) return false;

    final updated = await _database.messageDao.setBookmarked(
      messageId,
      isBookmarked: isBookmarked,
    );
    if (!updated) return false;

    if (isBookmarked) {
      await _upsertMessageBookmarkSnapshot(message);
    } else {
      await _deleteMessageBookmarkSnapshot(messageId);
    }

    return true;
  }

  Future<void> _upsertMessageBookmarkSnapshot(MessagesTable message) async {
    final _ = await _database
        .into(_database.messageBookmarks)
        .insertOnConflictUpdate(
          MessageBookmarksCompanion.insert(
            id: .new(message.id),
            conversationId: message.conversationId,
            contentSnapshot: message.content,
            isUser: message.isUser,
            messageCreatedAt: message.createdAt,
          ),
        );
  }

  Future<void> _deleteMessageBookmarkSnapshot(String messageId) async {
    final _ = await (_database.delete(
      _database.messageBookmarks,
    )..where((bookmark) => bookmark.id.equals(messageId))).go();
  }

  Future<bool> _isBookmarkableMessage(
    String workspaceId,
    String conversationId,
    String messageId,
  ) async {
    if (!await _isVisibleBookmarkableMessage(
      workspaceId,
      conversationId,
      messageId,
    )) {
      return false;
    }

    final sourceMessage = await _database.messageDao.getMessageById(messageId);
    if (sourceMessage == null) return false;

    return await _sourceConversationBelongsToWorkspace(
      workspaceId,
      sourceMessage.conversationId,
    );
  }

  Future<bool> _isVisibleBookmarkableMessage(
    String workspaceId,
    String conversationId,
    String messageId,
  ) async {
    final conversation = await _database.conversationDao.getConversationById(
      conversationId,
    );
    if (conversation?.workspaceId != workspaceId) return false;

    final visibleMessage = (await _getEffectiveMessages(conversationId))
        .firstWhereOrNull((message) => message.id == messageId);

    return visibleMessage != null && visibleMessage.isBookmarkEligible;
  }

  Future<bool> _sourceConversationBelongsToWorkspace(
    String workspaceId,
    String conversationId,
  ) async {
    final sourceConversation = await _database.conversationDao
        .getConversationById(conversationId);

    return sourceConversation?.workspaceId == workspaceId;
  }
}

mixin _MessageRepositoryReadApi {
  Future<List<MessageEntity>> getLatestAssistantMessagesByConversations(
    List<String> conversationIds,
  ) =>
      MessageRepositoryReadOperations(this as MessageRepository)
          .getLatestAssistantMessagesByConversations(conversationIds);

  Stream<List<MessageEntity>> watchMessagesByConversation(
    String conversationId,
  ) =>
      MessageRepositoryReadOperations(this as MessageRepository)
          .watchMessagesByConversation(conversationId);
}

mixin _MessageRepositoryQueryApi {
  Stream<MessageEntity?> watchLatestAssistantMessageByConversation(
    String conversationId,
  ) =>
      MessageRepositoryQueryOperations(this as MessageRepository)
          .watchLatestAssistantMessageByConversation(conversationId);

  Future<List<MessageEntity>> getMessagesByConversationPaginated(
    String conversationId,
    int limit,
    int offset,
  ) =>
      MessageRepositoryQueryOperations(this as MessageRepository)
          .getMessagesByConversationPaginated(conversationId, limit, offset);

  Future<List<ConversationMessageSearchResult>> searchMessages({
    required String query,
    required Set<String> workspaceIds,
    required int limit,
    int offset = 0,
  }) => MessageRepositorySearchOperations(this as MessageRepository)
      .searchMessages(
        query: query,
        workspaceIds: workspaceIds,
        limit: limit,
        offset: offset,
      );

  Future<List<MessageEntity>> getMessagesByType(
    String conversationId,
    MessageType messageType,
  ) =>
      MessageRepositoryQueryOperations(this as MessageRepository)
          .getMessagesByType(conversationId, messageType);

  Future<List<MessageEntity>> getUserMessages(String conversationId) =>
      MessageRepositoryQueryOperations(this as MessageRepository)
          .getUserMessages(conversationId);

  Future<List<MessageEntity>> getSystemMessages(String conversationId) =>
      MessageRepositoryQueryOperations(this as MessageRepository)
          .getSystemMessages(conversationId);

  Future<MessageEntity?> getMessageById(String id) =>
      MessageRepositoryQueryOperations(this as MessageRepository)
          .getMessageById(id);

  Future<MessageEntity> createMessage(MessageToCreate message) =>
      MessageRepositoryQueryOperations(this as MessageRepository)
          .createMessage(message);
}

mixin _MessageRepositoryMutationApi {
  Future<MessageEntity> patchMessage(
    String id,
    MessagePatch message, {
    String? conversationId,
  }) =>
      MessageRepositoryMutationOperations(this as MessageRepository)
          .patchMessage(id, message, conversationId: conversationId);

  Future<List<ToolCallApprovalBatchClaim>> claimToolCallBatch(
    Iterable<ToolCallApprovalBatchItem> items, {
    required bool approve,
  }) =>
      MessageRepositoryBatchOperations(this as MessageRepository)
          .claimToolCallBatch(items, approve: approve);

  Future<void> persistToolCallBatchResults(
    Iterable<ToolCallExecutionBatchUpdate> updates,
  ) =>
      MessageRepositoryBatchOperations(this as MessageRepository)
          .persistToolCallBatchResults(updates);
}

mixin _MessageRepositoryStateApi {
  Future<bool> deleteMessage(String id, {String? conversationId}) =>
      MessageRepositoryStateOperations(this as MessageRepository)
          .deleteMessage(id, conversationId: conversationId);

  Future<bool> messageExists(String id) =>
      MessageRepositoryStateOperations(this as MessageRepository)
          .messageExists(id);

  Future<List<MessageEntity>> getMessagesByStatus(
    String conversationId,
    MessageStatus status,
  ) =>
      MessageRepositoryStateOperations(this as MessageRepository)
          .getMessagesByStatus(conversationId, status);

  Future<int> getMessageCountByConversation(String conversationId) =>
      MessageRepositoryStateOperations(this as MessageRepository)
          .getMessageCountByConversation(conversationId);

  Future<bool> validateMessage(MessageToCreate message) =>
      MessageRepositoryStateOperations(this as MessageRepository)
          .validateMessage(message);

  Future<MessageEntity?> getLatestCompactionSummary(String conversationId) =>
      MessageRepositoryStateOperations(this as MessageRepository)
          .getLatestCompactionSummary(conversationId);
}

extension MessageRepositoryReadOperations on MessageRepository {
  Future<List<MessageEntity>> getLatestAssistantMessagesByConversations(
    List<String> conversationIds,
  ) async {
    final latestMessages = <MessageEntity>[];
    for (final conversationId in conversationIds) {
      final messages = await _getEffectiveMessages(conversationId);
      final latest = messages.lastWhereOrNull((message) => !message.isUser);
      if (latest != null) latestMessages.add(latest);
    }

    return latestMessages;
  }

  Stream<List<MessageEntity>> watchMessagesByConversation(
    String conversationId,
  ) => _watchEffectiveMessages(conversationId);
}

extension on MessageRepository {
  Future<List<MessageEntity>> _getEffectiveMessages(
    String conversationId,
  ) async =>
      (await _getEffectiveTranscriptMessages(conversationId))
          .where((message) => !message.isAgentTranscriptContextUpdate)
          .toList();

  Future<List<MessageEntity>> _getEffectiveTranscriptMessages(
    String conversationId,
  ) async {
    final rows = await _effectiveMessageRows(conversationId);

    return await _mapEffectiveRows(rows, conversationId);
  }

  Stream<List<MessageEntity>> _watchEffectiveMessages(String conversationId) {
    final watcher = _MessageWatchController(this, conversationId);
    watcher
      .._controller.onListen = watcher.listen
      .._controller.onCancel = watcher.cancel;

    return watcher.stream.transform(_messageWatchTransformer(conversationId));
  }

  Stream<List<MessageEntity>> _watchTranscriptMessages(String conversationId) {
    final watcher = _MessageWatchController(
      this,
      conversationId,
      includeTranscriptContext: true,
    );
    watcher
      .._controller.onListen = watcher.listen
      .._controller.onCancel = watcher.cancel;

    return watcher.stream.transform(_messageWatchTransformer(conversationId));
  }

  Future<List<({MessagesTable table, bool isForkReference})>>
  _effectiveMessageRows(String conversationId) async {
    final conversation = await _database.conversationDao.getConversationById(
      conversationId,
    );
    final own = await _database.messageDao.getMessagesByConversation(
      conversationId,
    );

    return _sortEffectiveRows(await _inheritedMessageRows(conversation), own);
  }

  Future<List<({MessagesTable table, bool isForkReference})>>
  _inheritedMessageRows(ConversationsTable? conversation) async {
    final sourceConversation = conversation;
    final sourceId = sourceConversation?.forkSourceConversationId;
    if (sourceConversation == null ||
        sourceId == null ||
        sourceConversation.forkMaterializedAt != null) {
      return const [];
    }

    final sourceRows = await _effectiveMessageRows(sourceId);

    return _collectInheritedRows(
      sourceRows,
      sourceConversation.forkThroughMessageId,
    );
  }

  List<({MessagesTable table, bool isForkReference})> _collectInheritedRows(
    List<({MessagesTable table, bool isForkReference})> sourceRows,
    String? boundary,
  ) {
    final inherited = <({MessagesTable table, bool isForkReference})>[];
    var foundBoundary = boundary == null;
    for (final row in sourceRows) {
      if (!_isDurableForkRow(row.table)) continue;
      inherited.add((table: row.table, isForkReference: true));
      if (boundary == row.table.id) {
        foundBoundary = true;
        break;
      }
    }
    if (!foundBoundary) _throwInvalidForkBoundary();

    return inherited;
  }

  Never _throwInvalidForkBoundary() => throw const MessageValidationException(
    'Fork boundary must be a terminal message',
  );

  List<({MessagesTable table, bool isForkReference})> _sortEffectiveRows(
    List<({MessagesTable table, bool isForkReference})> inherited,
    List<MessagesTable> own,
  ) => [
    ...inherited,
    ...own.map((table) => (table: table, isForkReference: false)),
  ]..sort(_compareEffectiveRows);

  int _compareEffectiveRows(
    ({MessagesTable table, bool isForkReference}) left,
    ({MessagesTable table, bool isForkReference}) right,
  ) {
    final created = left.table.createdAt.compareTo(right.table.createdAt);

    return created == 0 ? left.table.id.compareTo(right.table.id) : created;
  }

  bool _isDurableForkRow(MessagesTable message) {
    if (!_isTerminalStatus(message.status)) return false;

    return !(MessageMetadataEntity.fromJsonString(message.metadata)
            ?.hasPendingToolCalls ??
        false);
  }

  Future<List<MessageEntity>> _mapEffectiveRows(
    List<({MessagesTable table, bool isForkReference})> rows,
    String conversationId,
  ) async {
    if (rows.isEmpty) return [];
    final detachedToolCallIds = await _detachedForkToolCallIds(rows);
    final attachmentsByMessage = await _attachmentsByMessageForRows(rows);
    final context = (
      conversationId: conversationId,
      attachmentsByMessage: attachmentsByMessage,
      detachedToolCallIds: detachedToolCallIds,
    );

    return [for (final row in rows) _mapEffectiveRow(row, context)];
  }

  Future<Map<String, List<MessageAttachmentEntity>>>
  _attachmentsByMessageForRows(
    List<({MessagesTable table, bool isForkReference})> rows,
  ) async {
    final attachments = await _messageAttachmentRows(
      rows.map((row) => row.table).toList(),
    );

    return _attachmentsByMessage(attachments);
  }

  MessageEntity _mapEffectiveRow(
    ({MessagesTable table, bool isForkReference}) row,
    _EffectiveMessageMappingContext context,
  ) => _mapToMessage((
    table: row.table,
    attachments: context.attachmentsByMessage[row.table.id] ?? [],
    conversationIdOverride: context.conversationId,
    isForkReference: row.isForkReference,
    metadataOverride: _forkSafeMetadata(row, context.detachedToolCallIds),
  ));

  Future<Map<String, Set<String>>> _detachedForkToolCallIds(
    List<({MessagesTable table, bool isForkReference})> rows,
  ) async {
    final sourceConversationIds = _forkSourceConversationIds(rows);
    if (sourceConversationIds.isEmpty) return const {};
    final activeWork = await _activeBackgroundWorkForConversations(
      sourceConversationIds,
    );

    return _groupToolCallIdsByConversation(activeWork);
  }

  Set<String> _forkSourceConversationIds(
    List<({MessagesTable table, bool isForkReference})> rows,
  ) => rows
      .where((row) => row.isForkReference)
      .map((row) => row.table.conversationId)
      .toSet();

  Future<List<BackgroundWorkTable>> _activeBackgroundWorkForConversations(
    Set<String> conversationIds,
  ) => (_database.select(
    _database.backgroundWorks,
  )..where((table) => table.conversationId.isIn(conversationIds))).get();

  Map<String, Set<String>> _groupToolCallIdsByConversation(
    List<BackgroundWorkTable> activeWork,
  ) {
    final activeIdsByConversation = <String, Set<String>>{};
    for (final work in activeWork) {
      final _ = activeIdsByConversation
          .putIfAbsent(work.conversationId, () => <String>{})
          .add(work.toolCallId);
    }

    return activeIdsByConversation;
  }

  MessageMetadataEntity? _forkSafeMetadata(
    ({MessagesTable table, bool isForkReference}) row,
    Map<String, Set<String>> detachedToolCallIds,
  ) {
    if (!row.isForkReference) return null;
    final metadata = MessageMetadataEntity.fromJsonString(row.table.metadata);
    final detachedIds = detachedToolCallIds[row.table.conversationId];
    if (metadata == null || detachedIds == null) return null;

    return _metadataWithoutDetachedCalls(metadata, detachedIds);
  }

  MessageMetadataEntity? _metadataWithoutDetachedCalls(
    MessageMetadataEntity metadata,
    Set<String> detachedIds,
  ) {
    final toolCalls = metadata.toolCalls
        .where((toolCall) => !detachedIds.contains(toolCall.id))
        .toList();
    if (toolCalls.length == metadata.toolCalls.length) return null;

    return metadata.copyWith(toolCalls: toolCalls);
  }

  StreamTransformer<List<MessageEntity>, List<MessageEntity>>
  _messageWatchTransformer(String conversationId) =>
      StreamTransformer.fromHandlers(
        handleData: (messages, sink) =>
            _handleWatchData(messages, sink, conversationId),
        handleError: (error, stackTrace, sink) => _handleWatchError((
          error: error,
          stackTrace: stackTrace,
          sink: sink,
          conversationId: conversationId,
        )),
      );

  void _handleWatchData(
    List<MessageEntity> messages,
    EventSink<List<MessageEntity>> sink,
    String conversationId,
  ) {
    try {
      sink.add(messages);
    } on Exception catch (error, stackTrace) {
      _addWatchError((
        error: error,
        stackTrace: stackTrace,
        sink: sink,
        conversationId: conversationId,
      ));
    }
  }

  void _handleWatchError(_MessageWatchErrorInput data) {
    final (:error, :stackTrace, :sink, :conversationId) = data;
    if (error is Exception) {
      _addWatchError((
        error: error,
        stackTrace: stackTrace,
        sink: sink,
        conversationId: conversationId,
      ));

      return;
    }

    sink.addError(error, stackTrace);
  }

  void _addWatchError(_MessageWatchError data) {
    final (:error, :stackTrace, :sink, :conversationId) = data;

    sink.addError(
      MessageException(
        'Failed to watch messages for conversation $conversationId',
        error,
      ),
      stackTrace,
    );
  }
}

extension MessageRepositoryQueryOperations on MessageRepository {
  Stream<MessageEntity?> watchLatestAssistantMessageByConversation(
    String conversationId,
  ) => watchMessagesByConversation(
    conversationId,
  ).map((messages) => messages.lastWhereOrNull((message) => !message.isUser));

  Future<List<MessageEntity>> getMessagesByConversationPaginated(
    String conversationId,
    int limit,
    int offset,
  ) async {
    final messages = await _getEffectiveMessages(conversationId);

    return messages.skip(offset).take(limit).toList();
  }

  Future<List<MessageEntity>> getMessagesByType(
    String conversationId,
    MessageType messageType,
  ) async {
    return (await _getEffectiveMessages(conversationId))
        .where((message) => message.messageType == messageType)
        .toList();
  }

  Future<List<MessageEntity>> getUserMessages(String conversationId) async {
    return (await _getEffectiveMessages(conversationId))
        .where((message) => message.isUser)
        .toList();
  }

  Future<List<MessageEntity>> getSystemMessages(String conversationId) async {
    return (await _getEffectiveMessages(conversationId))
        .where((message) => !message.isUser)
        .toList();
  }

  Future<MessageEntity?> getMessageById(String id) async {
    final messageTable = await _database.messageDao.getMessageById(id);

    if (messageTable == null) return null;

    return await _mapToMessageWithAttachments(messageTable);
  }

  Future<MessageEntity> createMessage(MessageToCreate message) async {
    // Validate message before creating.
    if (!await validateMessage(message)) {
      throw const MessageValidationException('Invalid message data');
    }

    final promotedAttachments = <MessageAttachmentToCreate>[];
    try {
      return await _createMessage(message, promotedAttachments);
    } on Exception {
      await _deleteDraftAttachmentFiles(promotedAttachments);

      rethrow;
    }
  }

  Future<MessageEntity> _createMessage(
    MessageToCreate message,
    List<MessageAttachmentToCreate> promotedAttachments,
  ) async {
    await _promoteAttachments(message.attachments, promotedAttachments);

    final createdMessage = await _insertMessage(
      message.copyWith(attachments: promotedAttachments),
    );

    await _deleteDraftAttachmentFiles(message.attachments);

    return await _mapToMessageWithAttachments(createdMessage);
  }
}

extension MessageRepositorySearchOperations on MessageRepository {
  Future<List<ConversationMessageSearchResult>> searchMessages({
    required String query,
    required Set<String> workspaceIds,
    required int limit,
    int offset = 0,
  }) async {
    final normalizedQuery = query.trim();
    if (!_isValidSearchRequest(normalizedQuery, workspaceIds, limit, offset)) {
      return const [];
    }

    final rows = await _database.messageDao.searchMessages(
      query: normalizedQuery,
      workspaceIds: workspaceIds,
      limit: limit,
      offset: offset,
    );

    return [for (final row in rows) _searchResultFromRow(row, normalizedQuery)];
  }

  bool _isValidSearchRequest(
    String query,
    Set<String> workspaceIds,
    int limit,
    int offset,
  ) =>
      query.isNotEmpty &&
      query.length <= _maxConversationMessageSearchQueryLength &&
      workspaceIds.isNotEmpty &&
      limit >= 1 &&
      limit <= _maxConversationMessageSearchPageSize &&
      offset >= 0 &&
      offset <= _maxConversationMessageSearchOffset;

  ConversationMessageSearchResult _searchResultFromRow(
    QueryRow row,
    String query,
  ) {
    final conversation = _searchConversationFields(row);
    final message = _searchMessageFields(row, query);

    return ConversationMessageSearchResult(
      workspaceId: conversation.workspaceId,
      workspaceName: conversation.workspaceName,
      conversationId: conversation.conversationId,
      conversationTitle: conversation.conversationTitle,
      messageId: message.messageId,
      role: message.role,
      createdAt: message.createdAt,
      excerpt: message.excerpt,
    );
  }

  ({
    String workspaceId,
    String workspaceName,
    String conversationId,
    String conversationTitle,
  })
  _searchConversationFields(QueryRow row) => (
    workspaceId: row.read<String>('workspace_id'),
    workspaceName: row.read<String>('workspace_name'),
    conversationId: row.read<String>('conversation_id'),
    conversationTitle: row.read<String>('conversation_title'),
  );

  ({String messageId, String role, DateTime createdAt, String excerpt})
  _searchMessageFields(QueryRow row, String query) => (
    messageId: row.read<String>('message_id'),
    role: row.read<bool>('is_user') ? 'user' : 'assistant',
    createdAt: row.read<DateTime>('created_at'),
    excerpt: _searchExcerpt(row.read<String>('content'), query),
  );
}

extension on MessageRepository {
  Future<void> _promoteAttachments(
    Iterable<MessageAttachmentToCreate> attachments,
    List<MessageAttachmentToCreate> promotedAttachments,
  ) async {
    for (final attachment in attachments) {
      final localPath = await _attachmentFileStore.persistDraftFile(
        attachment.localPath,
      );
      promotedAttachments.add(attachment.copyWith(localPath: localPath));
    }
  }

  Future<MessagesTable> _insertMessage(MessageToCreate message) =>
      _database.transaction(() => _insertMessageRows(message));

  Future<MessagesTable> _insertMessageRows(MessageToCreate message) async {
    final createdMessage = await _database.messageDao.insertMessage(
      _mapToMessagesCompanion(message),
    );
    await _insertAttachments(createdMessage.id, message.attachments);

    return createdMessage;
  }

  Future<void> _insertAttachments(
    String messageId,
    Iterable<MessageAttachmentToCreate> attachments,
  ) async {
    for (final attachment in attachments) {
      await LocalMessageAssetReferences(
        _database,
        _attachmentFileStore.storageNamespace,
      ).validate(messageId, attachment);
      final _ = await _database
          .into(_database.messageAttachments)
          .insert(_mapToMessageAttachmentCompanion(messageId, attachment));
    }
  }
}

extension MessageRepositoryMutationOperations on MessageRepository {
  Future<MessageEntity> patchMessage(
    String id,
    MessagePatch message, {
    String? conversationId,
  }) async {
    _validateMessagePatch(message);
    final updatedMessage = await _database.transaction(
      () => _patchMessageInTransaction(id, message, conversationId),
    );
    if (updatedMessage == null) throw MessageNotFoundException(id);

    return await _mapToMessageWithAttachments(updatedMessage);
  }

  Future<MessageEntity> patchMessageWithAttachments(
    MessagePatchWithAttachmentsRequest request,
  ) => _patchMessageWithAttachments(this, request);
}

typedef MessagePatchWithAttachmentsRequest = ({
  String id,
  MessagePatch patch,
  String conversationId,
  List<MessageAttachmentToCreate> attachments,
});

Future<MessageEntity> _patchMessageWithAttachments(
  MessageRepository repository,
  MessagePatchWithAttachmentsRequest request,
) async {
  _validateToolResultAttachments(request.attachments);
  repository._validateMessagePatch(request.patch);
  final promotedAttachments = <MessageAttachmentToCreate>[];
  final updatedMessage = await repository._promoteAndPatchToolCallAttachments(
    request,
    promotedAttachments,
  );
  await repository._deleteDraftAttachmentFiles(request.attachments);

  return await repository._mapToMessageWithAttachments(updatedMessage);
}

void _validateToolResultAttachments(
  List<MessageAttachmentToCreate> attachments,
) {
  final invalid =
      attachments.isEmpty ||
      attachments.any(
        (attachment) => attachment.toolCallId?.isNotEmpty != true,
      );
  if (invalid) {
    throw const MessageValidationException(
      'Tool result attachments require a matching tool call ID.',
    );
  }
}

extension on MessageRepository {
  Future<MessagesTable> _promoteAndPatchToolCallAttachments(
    MessagePatchWithAttachmentsRequest request,
    List<MessageAttachmentToCreate> promotedAttachments,
  ) async {
    try {
      await _promoteAttachments(request.attachments, promotedAttachments);

      return await _database.transaction(
        () => _patchAndInsertToolCallAttachments(request, promotedAttachments),
      );
    } on Exception {
      await _deleteDraftAttachmentFiles(promotedAttachments);
      rethrow;
    }
  }

  Future<MessagesTable> _patchAndInsertToolCallAttachments(
    MessagePatchWithAttachmentsRequest request,
    List<MessageAttachmentToCreate> promotedAttachments,
  ) async {
    final updated = await _patchMessageInTransaction(
      request.id,
      request.patch,
      request.conversationId,
    );
    if (updated == null) throw MessageNotFoundException(request.id);
    _validateAttachmentToolCallReferences(request.attachments, updated);
    await _insertAttachments(updated.id, promotedAttachments);

    return updated;
  }

  void _validateAttachmentToolCallReferences(
    List<MessageAttachmentToCreate> attachments,
    MessagesTable updated,
  ) {
    final metadata = MessageMetadataEntity.fromJsonString(updated.metadata);
    if (metadata == null ||
        !_allAttachmentToolCallsExist(attachments, metadata.toolCalls)) {
      throw const MessageValidationException(
        'Tool result attachment references an unknown tool call.',
      );
    }
  }

  bool _allAttachmentToolCallsExist(
    List<MessageAttachmentToCreate> attachments,
    List<MessageToolCallEntity> toolCalls,
  ) {
    final toolCallIds = toolCalls.map((toolCall) => toolCall.id).toSet();

    return attachments.every(
      (attachment) => toolCallIds.contains(attachment.toolCallId),
    );
  }
}

class const MessageRepositoryBatchOperations(
  final MessageRepository _repository,
) {
  Future<List<ToolCallApprovalBatchClaim>> claimToolCallBatch(
    Iterable<ToolCallApprovalBatchItem> items, {
    required bool approve,
  }) async {
    final input = items.toList(growable: false);
    if (input.isEmpty) return const [];

    return await _repository._database.transaction(
      () => _claimToolCallBatchInTransaction(input, approve: approve),
    );
  }

  Future<void> persistToolCallBatchResults(
    Iterable<ToolCallExecutionBatchUpdate> updates,
  ) async {
    final input = updates.toList(growable: false);
    if (input.isEmpty) return;

    await _repository._database.transaction(
      () => _persistToolCallBatchResultsInTransaction(input),
    );
  }

  Future<List<ToolCallApprovalBatchClaim>> _claimToolCallBatchInTransaction(
    List<ToolCallApprovalBatchItem> input, {
    required bool approve,
  }) async {
    final state = _BatchClaimState(
      rowsById: await _loadRows(input.map((item) => item.messageId)),
      approve: approve,
    );
    input.forEach(state.claim);
    await _persistClaims(state);

    return [for (final item in input) ?state.claims[_batchItemIdentity(item)]];
  }

  Future<void> _persistToolCallBatchResultsInTransaction(
    List<ToolCallExecutionBatchUpdate> input,
  ) async {
    final updatesByMessage = _groupExecutionUpdates(input);
    final rowsById = await _loadRows(updatesByMessage.keys);
    for (final entry in updatesByMessage.entries) {
      await _persistExecutionUpdates(
        entry.key,
        rowsById[entry.key],
        entry.value,
      );
    }
  }

  Future<Map<String, MessagesTable?>> _loadRows(
    Iterable<String> messageIds,
  ) async {
    final rowsById = <String, MessagesTable?>{};
    for (final messageId in messageIds) {
      rowsById[messageId] ??= await _repository._database.messageDao
          .getMessageById(messageId);
    }

    return rowsById;
  }

  Future<void> _persistClaims(_BatchClaimState state) async {
    for (final entry in state.updatesByMessage.entries) {
      final row = state.rowsById[entry.key];
      final metadata = row == null
          ? null
          : MessageMetadataEntity.fromJsonString(row.metadata);
      if (metadata == null) continue;
      await _patchMetadata(
        entry.key,
        metadata.copyWith(toolCalls: entry.value),
      );
    }
  }

  Future<void> _persistExecutionUpdates(
    String messageId,
    MessagesTable? row,
    List<ToolCallExecutionBatchUpdate> updates,
  ) async {
    if (row == null) return;
    final metadata = MessageMetadataEntity.fromJsonString(row.metadata);
    if (metadata == null) return;
    final updatesById = {
      for (final update in updates) update.toolCallId: update,
    };
    final toolCalls = _applyExecutionUpdates(metadata.toolCalls, updatesById);
    if (toolCalls == null) return;
    await _patchMetadata(messageId, metadata.copyWith(toolCalls: toolCalls));
  }

  Future<void> _patchMetadata(
    String messageId,
    MessageMetadataEntity metadata,
  ) async {
    final _ = await _repository._database.messageDao.patchMessage(
      messageId,
      _repository._mapPatchToMessagesCompanion(
        .new(
          metadata: metadata,
          status: metadata.hasPendingToolCalls ? null : .sent,
        ),
      ),
    );
  }
}

class _BatchClaimState({
  required final Map<String, MessagesTable?> rowsById,
  required final bool approve,
}) {
  final claims = <String, ToolCallApprovalBatchClaim>{};
  final updatesByMessage = <String, List<MessageToolCallEntity>>{};
  final _seen = <String>{};

  void claim(ToolCallApprovalBatchItem item) {
    if (!_seen.add(_batchItemIdentity(item))) {
      _recordClaim(item, .alreadyHandled);

      return;
    }

    final candidate = _findBatchClaimCandidate(rowsById, item);
    if (!_matchesPendingCall(candidate.row, item, candidate.toolCall)) {
      _recordUnclaimableClaim(item, candidate);

      return;
    }

    _recordPendingClaim(item, candidate);
  }

  void _recordPendingClaim(
    ToolCallApprovalBatchItem item,
    _BatchClaimCandidate candidate,
  ) {
    final metadata = candidate.metadata;
    final toolCall = candidate.toolCall;
    if (metadata == null || toolCall == null) {
      _recordClaim(item, .conflicted);

      return;
    }

    _claimPending(item, metadata, toolCall);
  }

  void _recordUnclaimableClaim(
    ToolCallApprovalBatchItem item,
    _BatchClaimCandidate candidate,
  ) => _recordClaim(
    item,
    _alreadyHandled(candidate.row, item, candidate.toolCall)
        ? .alreadyHandled
        : .conflicted,
    toolCall: candidate.toolCall,
  );

  void _recordClaim(
    ToolCallApprovalBatchItem item,
    ToolCallApprovalBatchClaimStatus status, {
    MessageToolCallEntity? toolCall,
  }) {
    claims[_batchItemIdentity(item)] = ToolCallApprovalBatchClaim(
      item: item,
      status: status,
      toolCall: toolCall,
    );
  }

  void _claimPending(
    ToolCallApprovalBatchItem item,
    MessageMetadataEntity metadata,
    MessageToolCallEntity toolCall,
  ) {
    final updatedToolCall = toolCall.copyWith(
      resultStatus: approve ? .running : .skippedByUser,
    );
    final currentCalls =
        updatesByMessage[item.messageId] ?? List.of(metadata.toolCalls);
    updatesByMessage[item.messageId] = _replaceToolCall(
      currentCalls,
      updatedToolCall,
    );
    _recordClaim(item, .claimed, toolCall: toolCall);
  }
}

typedef _BatchClaimCandidate = ({
  MessagesTable? row,
  MessageMetadataEntity? metadata,
  MessageToolCallEntity? toolCall,
});

_BatchClaimCandidate _findBatchClaimCandidate(
  Map<String, MessagesTable?> rowsById,
  ToolCallApprovalBatchItem item,
) {
  final row = rowsById[item.messageId];
  final metadata = _metadataForBatchRow(row);
  final toolCall = _toolCallForBatchMetadata(metadata, item.toolCallId);

  return (row: row, metadata: metadata, toolCall: toolCall);
}

MessageMetadataEntity? _metadataForBatchRow(MessagesTable? row) =>
    row == null ? null : MessageMetadataEntity.fromJsonString(row.metadata);

MessageToolCallEntity? _toolCallForBatchMetadata(
  MessageMetadataEntity? metadata,
  String toolCallId,
) => metadata?.toolCalls.firstWhereOrNull(
  (candidate) => candidate.id == toolCallId,
);

List<MessageToolCallEntity> _replaceToolCall(
  List<MessageToolCallEntity> toolCalls,
  MessageToolCallEntity updatedToolCall,
) => [
  for (final toolCall in toolCalls)
    if (toolCall.id == updatedToolCall.id) updatedToolCall else toolCall,
];

Map<String, List<ToolCallExecutionBatchUpdate>> _groupExecutionUpdates(
  Iterable<ToolCallExecutionBatchUpdate> updates,
) {
  final grouped = <String, List<ToolCallExecutionBatchUpdate>>{};
  for (final update in updates) {
    (grouped[update.messageId] ??= []).add(update);
  }

  return grouped;
}

List<MessageToolCallEntity>? _applyExecutionUpdates(
  List<MessageToolCallEntity> toolCalls,
  Map<String, ToolCallExecutionBatchUpdate> updatesById,
) {
  if (!toolCalls.any(
    (toolCall) =>
        toolCall.resultStatus == .running &&
        updatesById.containsKey(toolCall.id),
  )) {
    return null;
  }

  return [
    for (final toolCall in toolCalls)
      _updatedExecutionToolCall(toolCall, updatesById) ?? toolCall,
  ];
}

MessageToolCallEntity? _updatedExecutionToolCall(
  MessageToolCallEntity toolCall,
  Map<String, ToolCallExecutionBatchUpdate> updatesById,
) {
  if (toolCall.resultStatus != .running) return null;
  final update = updatesById[toolCall.id];
  if (update == null) return null;

  return update.applyTo(toolCall);
}

bool _matchesPendingCall(
  MessagesTable? row,
  ToolCallApprovalBatchItem item,
  MessageToolCallEntity? toolCall,
) {
  if (row == null || row.conversationId != item.conversationId) return false;
  if (toolCall == null || !toolCall.isAwaitingApproval) return false;
  if (item.argumentsDigest != null &&
      toolCall.argumentsDigest != item.argumentsDigest) {
    return false;
  }
  if (item.turnRevision != null && toolCall.turnRevision != item.turnRevision) {
    return false;
  }

  return true;
}

bool _alreadyHandled(
  MessagesTable? row,
  ToolCallApprovalBatchItem item,
  MessageToolCallEntity? toolCall,
) {
  if (row == null ||
      row.conversationId != item.conversationId ||
      toolCall == null ||
      toolCall.isAwaitingApproval) {
    return false;
  }
  if (item.argumentsDigest != null &&
      toolCall.argumentsDigest != item.argumentsDigest) {
    return false;
  }
  if (item.turnRevision != null && toolCall.turnRevision != item.turnRevision) {
    return false;
  }

  return true;
}

String _batchItemIdentity(ToolCallApprovalBatchItem item) =>
    '${item.conversationId}:${item.messageId}:${item.toolCallId}';

extension on MessageRepository {
  Future<MessagesTable?> _patchMessageInTransaction(
    String id,
    MessagePatch message,
    String? conversationId,
  ) async {
    final existing = await _database.messageDao.getMessageById(id);
    if (existing == null) throw MessageNotFoundException(id);
    _validatePatchOwnership(existing, conversationId);
    _validateTerminalPatch(existing, message);
    await _validateSentMessage(id, message);

    final patch = await _mergeToolCallMetadataPatch(id, message);

    return await _database.messageDao.patchMessage(
      id,
      _mapPatchToMessagesCompanion(patch),
    );
  }

  void _validatePatchOwnership(MessagesTable existing, String? conversationId) {
    if (conversationId != null && existing.conversationId != conversationId) {
      throw const MessageValidationException('Fork reference is read-only');
    }
  }

  void _validateTerminalPatch(MessagesTable existing, MessagePatch message) {
    if (!_isTerminalStatus(existing.status) || _hasPendingToolCalls(existing)) {
      return;
    }
    if (existing.isUser &&
        existing.status == MessageTableStatus.error &&
        message.status == MessageStatus.sending &&
        message.content == null &&
        message.metadata == null) {
      return;
    }
    if (_changesFinalMessage(existing, message)) {
      throw const MessageValidationException('Terminal message is immutable');
    }
  }

  bool _changesFinalMessage(MessagesTable existing, MessagePatch message) {
    final nextStatus = _messageStatusToTableStatus(message.status);

    return message.content != null ||
        message.metadata != null ||
        (nextStatus != null && nextStatus != existing.status);
  }

  bool _hasPendingToolCalls(MessagesTable message) =>
      MessageMetadataEntity.fromJsonString(message.metadata)
          ?.hasPendingToolCalls ??
      false;

  Future<MessagePatch> _mergeToolCallMetadataPatch(
    String id,
    MessagePatch patch,
  ) async {
    final incomingMetadata = patch.metadata;
    if (incomingMetadata == null) return patch;

    final currentMessage = await _database.messageDao.getMessageById(id);
    final currentMetadata = MessageMetadataEntity.fromJsonString(
      currentMessage?.metadata,
    );
    if (currentMetadata == null) return patch;

    return patch.copyWith(
      metadata: _mergeToolCallMetadata(currentMetadata, incomingMetadata),
    );
  }

  Future<void> _validateSentMessage(String id, MessagePatch message) async {
    if (message.status != MessageStatus.sent || message.content != null) {
      return;
    }

    final existingMessage = await getMessageById(id);
    if (existingMessage == null) throw MessageNotFoundException(id);

    final metadata = message.metadata ?? existingMessage.metadata;
    if (_isEmptySentMessage(existingMessage, metadata)) {
      throw const MessageValidationException(_messageContentCannotBeEmpty);
    }
  }

  bool _isEmptySentMessage(
    MessageEntity message,
    MessageMetadataEntity? metadata,
  ) {
    return message.content.trim().isEmpty &&
        message.attachments.isEmpty &&
        !_hasMessagePayload(metadata);
  }
}

MessageMetadataEntity _mergeToolCallMetadata(
  MessageMetadataEntity current,
  MessageMetadataEntity incoming,
) {
  if (current.toolCalls.isEmpty) return incoming;
  if (incoming.toolCalls.isEmpty) {
    return incoming.copyWith(toolCalls: current.toolCalls);
  }

  return incoming.copyWith(
    toolCalls: _mergeToolCalls(current.toolCalls, incoming.toolCalls),
  );
}

List<MessageToolCallEntity> _mergeToolCalls(
  List<MessageToolCallEntity> current,
  List<MessageToolCallEntity> incoming,
) {
  final currentById = {for (final toolCall in current) toolCall.id: toolCall};
  final incomingIds = incoming.map((toolCall) => toolCall.id).toSet();

  return [
    for (final toolCall in incoming)
      _mergeToolCall(currentById[toolCall.id], toolCall),
    for (final toolCall in current)
      if (!incomingIds.contains(toolCall.id)) toolCall,
  ];
}

MessageToolCallEntity _mergeToolCall(
  MessageToolCallEntity? current,
  MessageToolCallEntity incoming,
) {
  if (current == null) return incoming;

  final merged = incoming.copyWith(
    userFacingDescription:
        incoming.userFacingDescription ?? current.userFacingDescription,
    resultStatus: _mergeToolCallResultStatus(
      current.resultStatus,
      incoming.resultStatus,
    ),
  );

  return _mergeToolCallOutput(merged, current, incoming);
}

MessageToolCallEntity _mergeToolCallOutput(
  MessageToolCallEntity merged,
  MessageToolCallEntity current,
  MessageToolCallEntity incoming,
) {
  return incoming.responseRaw == null
      ? _mergeMissingToolCallOutput(merged, current, incoming)
      : _replaceToolCallOutput(merged, incoming);
}

MessageToolCallEntity _mergeMissingToolCallOutput(
  MessageToolCallEntity merged,
  MessageToolCallEntity current,
  MessageToolCallEntity incoming,
) => merged.copyWith(
  responseRaw: current.responseRaw,
  appData: incoming.appData ?? current.appData,
  responseContextRaw: incoming.responseContextRaw ?? current.responseContextRaw,
  outputTruncated: current.outputTruncated,
  originalResponseBytes: current.originalResponseBytes,
  fullOutputForContext: current.fullOutputForContext,
);

MessageToolCallEntity _replaceToolCallOutput(
  MessageToolCallEntity merged,
  MessageToolCallEntity incoming,
) => merged.copyWith(
  responseRaw: incoming.responseRaw,
  appData: incoming.appData,
  responseContextRaw: incoming.responseContextRaw,
  outputTruncated: incoming.outputTruncated,
  originalResponseBytes: incoming.originalResponseBytes,
  fullOutputForContext: incoming.fullOutputForContext,
);

ToolCallResultStatus? _mergeToolCallResultStatus(
  ToolCallResultStatus? current,
  ToolCallResultStatus? incoming,
) {
  if (current == null) return incoming;
  if (incoming == null) return current;
  if (current != .running) return current;

  return incoming;
}

extension MessageRepositoryStateOperations on MessageRepository {
  Future<bool> deleteMessage(String id, {String? conversationId}) async {
    final message = await getMessageById(id);
    if (message == null) {
      return false; // Return false instead of throwing for delete operations.
    }
    final existing = await _database.messageDao.getMessageById(id);
    _validateDeleteOwnership(existing, conversationId);

    final deleted = await LocalWorkspaceAssetMutation(_database)
        .conversation(message.conversationId, () => _deleteMessageRows(id));
    if (deleted) {
      await _deletePersistedAttachmentFiles(message.attachments);
    }

    return deleted;
  }

  Future<bool> messageExists(String id) {
    return _database.messageDao.messageExists(id);
  }

  Future<List<MessageEntity>> getMessagesByStatus(
    String conversationId,
    MessageStatus status,
  ) async {
    return (await _getEffectiveMessages(conversationId))
        .where((message) => message.status == status)
        .toList();
  }

  Future<int> getMessageCountByConversation(String conversationId) async {
    return (await _getEffectiveMessages(conversationId)).length;
  }

  Future<bool> validateMessage(MessageToCreate message) async {
    if (!message.isValid) {
      throw MessageValidationException(_getValidationErrorToCreate(message));
    }

    return true;
  }

  Future<MessageEntity?> getLatestCompactionSummary(
    String conversationId,
  ) async {
    final messages = await _getEffectiveMessages(conversationId);

    return messages.lastWhereOrNull(_isCompactionSummary);
  }

  void _validateDeleteOwnership(
    MessagesTable? existing,
    String? conversationId,
  ) {
    if (conversationId != null &&
        (existing == null || existing.conversationId != conversationId)) {
      throw const MessageValidationException('Fork reference is read-only');
    }
  }

  bool _isCompactionSummary(MessageEntity message) =>
      message.messageType == MessageType.system &&
      message.status == MessageStatus.sent &&
      message.metadata?.isCompactionSummary == true;

  Future<bool> _deleteMessageRows(String messageId) async {
    final deleted = await _database.messageDao.deleteMessage(messageId);
    if (!deleted) return false;
    final _ = await (_database.delete(
      _database.messageAttachments,
    )..where((table) => table.messageId.equals(messageId))).go();

    return true;
  }
}

extension on MessageRepository {
  Future<List<MessageEntity>> _mapToMessagesWithAttachments(
    List<MessagesTable> messageTables,
  ) async {
    if (messageTables.isEmpty) return [];

    final attachmentRows = await _messageAttachmentRows(messageTables);

    return _mapMessageTables(
      messageTables,
      _attachmentsByMessage(attachmentRows),
    );
  }

  Future<List<MessageAttachmentsTable>> _messageAttachmentRows(
    List<MessagesTable> messageTables,
  ) async {
    final ids = messageTables.map((message) => message.id).toList();

    return await (_database.select(
      _database.messageAttachments,
    )..where((attachment) => attachment.messageId.isIn(ids))).get();
  }

  Map<String, List<MessageAttachmentEntity>> _attachmentsByMessage(
    List<MessageAttachmentsTable> rows,
  ) {
    final attachmentsByMessage = <String, List<MessageAttachmentEntity>>{};
    for (final row in rows) {
      attachmentsByMessage
          .putIfAbsent(row.messageId, () => [])
          .add(_mapToAttachment(row));
    }

    return attachmentsByMessage;
  }

  List<MessageEntity> _mapMessageTables(
    List<MessagesTable> messageTables,
    Map<String, List<MessageAttachmentEntity>> attachmentsByMessage,
  ) => messageTables
      .map(
        (message) => _mapToMessage((
          table: message,
          attachments: attachmentsByMessage[message.id] ?? [],
          conversationIdOverride: null,
          isForkReference: false,
          metadataOverride: null,
        )),
      )
      .toList();

  Future<MessageEntity> _mapToMessageWithAttachments(
    MessagesTable messageTable,
  ) async {
    final messages = await _mapToMessagesWithAttachments([messageTable]);

    return messages.single;
  }

  Future<void> _deleteDraftAttachmentFiles(
    Iterable<MessageAttachmentToCreate> attachments,
  ) async {
    final _ = await Future.wait(
      attachments.map((attachment) {
        return _deleteAttachmentFile(attachment.localPath);
      }),
    );
  }

  Future<void> _deletePersistedAttachmentFiles(
    Iterable<MessageAttachmentEntity> attachments,
  ) async {
    final _ = await Future.wait(
      attachments.map((attachment) {
        return _deleteAttachmentFileIfUnreferenced(attachment.localPath);
      }),
    );
  }

  Future<void> _deleteAttachmentFileIfUnreferenced(String localPath) async {
    final rows = await (_database.select(
      _database.messageAttachments,
    )..where((table) => table.localPath.equals(localPath))).get();
    if (rows.isNotEmpty) return;
    await _deleteAttachmentFile(localPath);
  }

  Future<void> _deleteAttachmentFile(String localPath) async {
    try {
      await _attachmentFileStore.deleteFile(localPath);
    } on Object {
      return;
    }
  }

  void _validateMessagePatch(MessagePatch message) {
    final validationError = _getValidationErrorPatch(message);
    if (validationError != null) {
      throw MessageValidationException(validationError);
    }
  }
}

extension on MessageRepository {
  /// Maps a database record to a [MessageEntity] domain entity.
  ///
  /// Returns the corresponding [MessageEntity] entity.
  MessageEntity _mapToMessage(_MessageMapping mapping) {
    return _mapMessageDetails(_mapMessageCore(mapping), mapping);
  }

  MessageEntity _mapMessageCore(_MessageMapping mapping) {
    final table = mapping.table;

    return MessageEntity(
      id: table.id,
      conversationId: mapping.conversationIdOverride ?? table.conversationId,
      content: table.content,
      messageType: .fromString(table.messageType.value),
      isUser: table.isUser,
      status: _messageTableStatusToEntityStatus(table.status),
      createdAt: table.createdAt,
      updatedAt: table.updatedAt,
    );
  }

  MessageEntity _mapMessageDetails(
    MessageEntity message,
    _MessageMapping mapping,
  ) => message.copyWith(
    metadata:
        mapping.metadataOverride ??
        MessageMetadataEntity.fromJsonString(mapping.table.metadata),
    attachments: mapping.attachments,
    isForkReference: mapping.isForkReference,
  );
}

extension on MessageRepository {
  MessageAttachmentEntity _mapToAttachment(MessageAttachmentsTable row) {
    return MessageAttachmentEntity(
      id: row.id,
      messageId: row.messageId,
      localPath: row.localPath,
      fileName: row.fileName,
      displayName: row.displayName,
      mimeType: row.mimeType,
      modality: _attachmentModalityFromString(row.modality),
      sizeBytes: row.sizeBytes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      assetId: row.assetId,
      toolCallId: row.toolCallId,
    );
  }

  bool _hasMessagePayload(MessageMetadataEntity? metadata) {
    return metadata != null &&
        [
          metadata.toolCalls.isNotEmpty,
          metadata.thinking?.trim().isNotEmpty ?? false,
          metadata.modelMetadata.isNotEmpty,
          metadata.promptTokens != null,
          metadata.completionTokens != null,
          metadata.totalTokens != null,
        ].any((hasPayload) => hasPayload);
  }
}

extension MessageRepositoryCompanionMappings on MessageRepository {
  /// Maps a [MessageEntity] domain entity to a [MessagesCompanion]
  /// for database operations.
  ///
  /// [message] The message entity to map.
  /// Returns a corresponding [MessagesCompanion].
  MessagesCompanion _mapToMessagesCompanion(MessageToCreate message) {
    return MessagesCompanion(
      createdAt: .absentIfNull(message.createdAt),
      updatedAt: .absentIfNull(message.updatedAt ?? message.createdAt),
      conversationId: .new(message.conversationId),
      content: .new(message.content),
      messageType: .new(_messageTypeToTableType(message.messageType)),
      isUser: .new(message.isUser),
      status: .absentIfNull(_messageStatusToTableStatus(message.status)),
      metadata: .new(_sanitizeMetadataJson(message.metadata)),
    );
  }

  MessageAttachmentsCompanion _mapToMessageAttachmentCompanion(
    String messageId,
    MessageAttachmentToCreate attachment,
  ) {
    return MessageAttachmentsCompanion(
      messageId: .new(messageId),
      toolCallId: .absentIfNull(attachment.toolCallId),
      assetId: .absentIfNull(attachment.assetId),
      localPath: .new(attachment.localPath),
      fileName: .new(attachment.fileName),
      displayName: .new(attachment.displayName),
      mimeType: .new(attachment.mimeType),
      modality: .new(attachment.modality.name),
      sizeBytes: .new(attachment.sizeBytes),
    );
  }

  MessagesCompanion _mapPatchToMessagesCompanion(MessagePatch message) {
    return MessagesCompanion(
      content: .absentIfNull(message.content),
      status: .absentIfNull(_messageStatusToTableStatus(message.status)),
      metadata: .absentIfNull(
        JsonCodec.encode(_sanitizeMetadata(message.metadata)?.toJson()),
      ),
    );
  }
}

extension MessageRepositoryValidationMappings on MessageRepository {
  /// Gets validation error message for a message.
  ///
  /// [message] The message to validate.
  /// Returns a string describing the validation error.
  String _getValidationErrorToCreate(MessageToCreate message) {
    if (message.conversationId.isEmpty) {
      return 'Conversation ID cannot be empty';
    }
    if (message.content.trim().isEmpty && message.attachments.isEmpty) {
      return _messageContentCannotBeEmpty;
    }

    return 'Unknown validation error';
  }

  MessageAttachmentModality _attachmentModalityFromString(String value) {
    return MessageAttachmentModality.values.asNameMap()[value] ??
        MessageAttachmentModality.file;
  }

  String? _getValidationErrorPatch(MessagePatch message) {
    final content = message.content;
    if (content != null && content.trim().isEmpty) {
      return _messageContentCannotBeEmpty;
    }
    if (message.content == null &&
        message.metadata == null &&
        message.status == null) {
      return 'Must set content, metadata, or status';
    }

    return null;
  }

  MessageStatus _messageTableStatusToEntityStatus(MessageTableStatus status) {
    return switch (status) {
      .sent => MessageStatus.sent,
      .sending => MessageStatus.sending,
      .unfinished => MessageStatus.unfinished,
      .error => MessageStatus.error,
    };
  }

  MessageTableStatus? _messageStatusToTableStatus(MessageStatus? status) {
    if (status == null) return null;

    return switch (status) {
      .sent => MessageTableStatus.sent,
      .sending => MessageTableStatus.sending,
      .unfinished => MessageTableStatus.unfinished,
      .error => MessageTableStatus.error,
    };
  }

  MessagesTableType _messageTypeToTableType(MessageType messageType) {
    return switch (messageType) {
      .text => MessagesTableType.text,
      .image => MessagesTableType.image,
      .toolCall => MessagesTableType.toolCall,
      .system => MessagesTableType.system,
    };
  }
}

/// Base exception for message-related operations.
class MessageException implements Exception {
  // Cause is optional because not all domain failures wrap an exception.
  // ignore: unnecessary-nullable
  /// Creates a new MessageException.
  const new(this.message, [this.cause]);

  /// Error message describing the exception.
  final String message;

  /// Optional original exception that caused this exception.
  final Exception? cause;

  @override
  String toString() {
    final causedBy = cause != null ? ' (Caused by: ${cause.runtimeType})' : '';

    return 'MessageException: $message$causedBy';
  }
}

/// Exception thrown when message validation fails.
// DCL sees no methods on this exception subtype.
// ignore: weight-of-class
class MessageValidationException extends MessageException {
  /// Creates a new MessageValidationException.
  const new(super.message, [super.cause]);
}

/// Exception thrown when a message is not found.
// DCL sees no methods on this exception subtype.
// ignore: weight-of-class
class MessageNotFoundException extends MessageException {
  /// Creates a new MessageNotFoundException.
  const new(this.messageId, [Exception? cause])
    : super('Message with ID "$messageId" not found', cause);

  /// ID of the message that was not found.
  final String messageId;
}

String _searchExcerpt(String content, String query) {
  final contentCharacters = content.characters;
  final start = _searchExcerptStart(contentCharacters, content, query);
  final excerptLength = _searchExcerptLength(query);
  final end = _searchExcerptEnd(contentCharacters, start, excerptLength);

  return _composeSearchExcerpt(contentCharacters, start, end);
}

int _searchExcerptLength(String query) =>
    (query.characters.length + _conversationMessageSearchContextLength).clamp(
      _minConversationMessageSearchExcerptLength,
      _maxConversationMessageSearchExcerptLength,
    );

int _searchExcerptEnd(
  Characters contentCharacters,
  int start,
  int excerptLength,
) {
  final end = start + excerptLength;

  return end < contentCharacters.length ? end : contentCharacters.length;
}

String _composeSearchExcerpt(Characters contentCharacters, int start, int end) {
  final excerpt = contentCharacters.skip(start).take(end - start);
  final prefix = start > 0 ? '...' : '';
  final suffix = end < contentCharacters.length ? '...' : '';

  return '$prefix$excerpt$suffix';
}

int _searchExcerptStart(
  Characters contentCharacters,
  String content,
  String query,
) {
  final matchOffset = content.toLowerCase().indexOf(query.toLowerCase());
  var lowerOffset = 0;
  var matchCharacterIndex = 0;
  for (final character in contentCharacters) {
    if (lowerOffset >= matchOffset) break;
    lowerOffset += character.toLowerCase().length;
    matchCharacterIndex++;
  }

  return matchCharacterIndex > _conversationMessageSearchContextBefore
      ? matchCharacterIndex - _conversationMessageSearchContextBefore
      : 0;
}

String? _sanitizeMetadataJson(String? raw) {
  if (raw == null) return null;
  final metadata = MessageMetadataEntity.fromJsonString(raw);
  if (metadata == null) return raw;
  final sanitized = sanitizeWorkspaceToolMetadata(metadata);
  if (const ListEquality<MessageToolCallEntity>().equals(
    sanitized.toolCalls,
    metadata.toolCalls,
  ))
    return raw;

  return JsonCodec.encode(sanitized.toJson());
}

MessageMetadataEntity? _sanitizeMetadata(MessageMetadataEntity? metadata) =>
    metadata == null ? null : sanitizeWorkspaceToolMetadata(metadata);
