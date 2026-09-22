// Required: Existing test and UI helpers keep compact return flow.

import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/messages_table_type.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/tool_call_approval_batch_item.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/utils/json_codec.dart';
import 'package:collection/collection.dart';

const _messageContentCannotBeEmpty = 'Message content cannot be empty';

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
});

class _MessageWatchController {
  new(this._repository, this._conversationId);

  final MessageRepository _repository;
  final String _conversationId;
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
      final messages = await _repository._getEffectiveMessages(_conversationId);
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
    final attachments = await _messageAttachmentRows(
      rows.map((row) => row.table).toList(),
    );
    final attachmentsByMessage = _attachmentsByMessage(attachments);

    return [
      for (final row in rows)
        _mapToMessage((
          table: row.table,
          attachments: attachmentsByMessage[row.table.id] ?? [],
          conversationIdOverride: conversationId,
          isForkReference: row.isForkReference,
        )),
    ];
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

    return await _repository._database.transaction(() async {
      final rowsById = <String, MessagesTable?>{};
      for (final item in input) {
        rowsById[item.messageId] ??= await _repository._database.messageDao
            .getMessageById(item.messageId);
      }

      final claims = <String, ToolCallApprovalBatchClaim>{};
      final updatesByMessage = <String, List<MessageToolCallEntity>>{};
      final seen = <String>{};

      for (final item in input) {
        final identity = _batchItemIdentity(item);
        if (!seen.add(identity)) {
          claims[identity] = ToolCallApprovalBatchClaim(
            item: item,
            status: .alreadyHandled,
          );
          continue;
        }

        final row = rowsById[item.messageId];
        final metadata = row == null
            ? null
            : MessageMetadataEntity.fromJsonString(row.metadata);
        final toolCall = metadata?.toolCalls
            .where((candidate) => candidate.id == item.toolCallId)
            .firstOrNull;

        if (!_matchesPendingCall(row, item, toolCall)) {
          claims[identity] = ToolCallApprovalBatchClaim(
            item: item,
            status: _alreadyHandled(row, item, toolCall)
                ? .alreadyHandled
                : .conflicted,
            toolCall: toolCall,
          );
          continue;
        }

        final pendingToolCall = toolCall;
        final currentMetadata = metadata;
        if (pendingToolCall == null || currentMetadata == null) {
          claims[identity] = ToolCallApprovalBatchClaim(
            item: item,
            status: .conflicted,
          );
          continue;
        }
        final updatedToolCall = pendingToolCall.copyWith(
          resultStatus: approve ? .running : .skippedByUser,
        );
        final currentCalls =
            updatesByMessage[item.messageId] ??
            List<MessageToolCallEntity>.of(currentMetadata.toolCalls);
        final nextCalls = [
          for (final candidate in currentCalls)
            if (candidate.id == updatedToolCall.id)
              updatedToolCall
            else
              candidate,
        ];
        updatesByMessage[item.messageId] = nextCalls;
        claims[identity] = ToolCallApprovalBatchClaim(
          item: item,
          status: .claimed,
          toolCall: toolCall,
        );
      }

      for (final entry in updatesByMessage.entries) {
        final row = rowsById[entry.key];
        if (row == null) continue;
        final metadata = MessageMetadataEntity.fromJsonString(row.metadata);
        if (metadata == null) continue;
        final updatedMetadata = metadata.copyWith(toolCalls: entry.value);
        final _ = await _repository._database.messageDao.patchMessage(
          entry.key,
          _repository._mapPatchToMessagesCompanion(
            .new(
              metadata: updatedMetadata,
              status: updatedMetadata.hasPendingToolCalls ? null : .sent,
            ),
          ),
        );
      }

      return [for (final item in input) ?claims[_batchItemIdentity(item)]];
    });
  }

  Future<void> persistToolCallBatchResults(
    Iterable<ToolCallExecutionBatchUpdate> updates,
  ) async {
    final input = updates.toList(growable: false);
    if (input.isEmpty) return;

    await _repository._database.transaction(() async {
      final rowsById = <String, MessagesTable?>{};
      final updatesByMessage = <String, List<ToolCallExecutionBatchUpdate>>{};
      for (final update in input) {
        rowsById[update.messageId] ??= await _repository._database.messageDao
            .getMessageById(update.messageId);
        (updatesByMessage[update.messageId] ??= []).add(update);
      }

      for (final entry in updatesByMessage.entries) {
        final row = rowsById[entry.key];
        if (row == null) continue;
        final metadata = MessageMetadataEntity.fromJsonString(row.metadata);
        if (metadata == null) continue;
        final updatesById = {
          for (final update in entry.value) update.toolCallId: update,
        };
        var changed = false;
        final updatedToolCalls = [
          for (final toolCall in metadata.toolCalls)
            if (updatesById[toolCall.id] case final update?
                when toolCall.resultStatus == .running)
              (() {
                changed = true;

                return toolCall.copyWith(
                  resultStatus: update.resultStatus,
                  responseRaw: update.responseRaw,
                );
              })()
            else
              toolCall,
        ];
        if (!changed) continue;
        final updatedMetadata = metadata.copyWith(toolCalls: updatedToolCalls);
        final _ = await _repository._database.messageDao.patchMessage(
          entry.key,
          _repository._mapPatchToMessagesCompanion(
            .new(
              metadata: updatedMetadata,
              status: updatedMetadata.hasPendingToolCalls ? null : .sent,
            ),
          ),
        );
      }
    });
  }
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

  return incoming.copyWith(
    userFacingDescription:
        incoming.userFacingDescription ?? current.userFacingDescription,
    resultStatus: _mergeToolCallResultStatus(
      current.resultStatus,
      incoming.resultStatus,
    ),
    responseRaw: incoming.responseRaw ?? current.responseRaw,
  );
}

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

    final deleted = await _database.messageDao.deleteMessage(id);
    if (deleted) {
      await _deleteMessageAttachments(id, message.attachments);
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

  Future<void> _deleteMessageAttachments(
    String messageId,
    List<MessageAttachmentEntity> attachments,
  ) async {
    final _ = await (_database.delete(
      _database.messageAttachments,
    )..where((table) => table.messageId.equals(messageId))).go();
    await _deletePersistedAttachmentFiles(attachments);
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
    metadata: .fromJsonString(mapping.table.metadata),
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
      conversationId: .new(message.conversationId),
      content: .new(message.content),
      messageType: .new(_messageTypeToTableType(message.messageType)),
      isUser: .new(message.isUser),
      status: .absentIfNull(_messageStatusToTableStatus(message.status)),
      metadata: .new(message.metadata),
    );
  }

  MessageAttachmentsCompanion _mapToMessageAttachmentCompanion(
    String messageId,
    MessageAttachmentToCreate attachment,
  ) {
    return MessageAttachmentsCompanion(
      messageId: .new(messageId),
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
      metadata: .absentIfNull(JsonCodec.encode(message.metadata?.toJson())),
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
