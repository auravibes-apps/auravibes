// Required: Existing test and UI helpers keep compact return flow.

import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/messages_table_type.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
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
    final controller = StreamController<List<MessageEntity>>();
    final subscriptions = <StreamSubscription<dynamic>>[];
    var pending = false;
    var running = false;

    Future<void> emit() async {
      if (running) {
        pending = true;

        return;
      }
      running = true;
      do {
        pending = false;
        try {
          final messages = await _getEffectiveMessages(conversationId);
          if (!controller.isClosed) controller.add(messages);
        } on Object catch (error, stackTrace) {
          if (!controller.isClosed) controller.addError(error, stackTrace);
        }
      } while (pending);
      running = false;
    }

    controller
      ..onListen = () {
        subscriptions
          ..add(
            _database.select(_database.messages).watch().listen((_) => emit()),
          )
          ..add(
            _database
                .select(_database.conversations)
                .watch()
                .listen((_) => emit()),
          )
          ..add(
            _database
                .select(_database.messageAttachments)
                .watch()
                .listen((_) => emit()),
          );
        emit();
      }
      ..onCancel = () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
        subscriptions.clear();
      };

    return controller.stream.transform(
      _messageWatchTransformer(conversationId),
    );
  }

  Future<List<({MessagesTable table, bool isForkReference})>>
  _effectiveMessageRows(String conversationId) async {
    final conversation = await _database.conversationDao.getConversationById(
      conversationId,
    );
    if (conversation == null) {
      final own = await _database.messageDao.getMessagesByConversation(
        conversationId,
      );

      return own
          .map((table) => (table: table, isForkReference: false))
          .toList();
    }

    final own = await _database.messageDao.getMessagesByConversation(
      conversationId,
    );
    final inherited = <({MessagesTable table, bool isForkReference})>[];
    final sourceConversationId = conversation.forkSourceConversationId;
    if (sourceConversationId != null &&
        conversation.forkMaterializedAt == null) {
      final source = await _effectiveMessageRows(sourceConversationId);
      final boundary = conversation.forkThroughMessageId;
      var foundBoundary = boundary == null;
      for (final row in source) {
        if (!_isDurableForkRow(row.table)) continue;
        inherited.add((table: row.table, isForkReference: true));
        if (boundary == row.table.id) {
          foundBoundary = true;
          break;
        }
      }
      if (!foundBoundary) {
        throw const MessageValidationException(
          'Fork boundary must be a terminal message',
        );
      }
    }

    return [
      ...inherited,
      ...own.map((table) => (table: table, isForkReference: false)),
    ]..sort((left, right) {
      final created = left.table.createdAt.compareTo(right.table.createdAt);

      return created == 0 ? left.table.id.compareTo(right.table.id) : created;
    });
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
        _mapToMessage(
          row.table,
          attachments: attachmentsByMessage[row.table.id] ?? [],
          conversationIdOverride: conversationId,
          isForkReference: row.isForkReference,
        ),
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
    final existing = await _database.messageDao.getMessageById(id);
    if (existing == null) throw MessageNotFoundException(id);
    if (conversationId != null && existing.conversationId != conversationId) {
      throw const MessageValidationException('Fork reference is read-only');
    }
    final nextStatus = _messageStatusToTableStatus(message.status);
    final existingMetadata = MessageMetadataEntity.fromJsonString(
      existing.metadata,
    );
    final isLegacyPending = existingMetadata?.hasPendingToolCalls ?? false;
    if (_isTerminalStatus(existing.status) &&
        !isLegacyPending &&
        (message.content != null ||
            message.metadata != null ||
            (nextStatus != null && nextStatus != existing.status))) {
      throw const MessageValidationException('Terminal message is immutable');
    }
    await _validateSentMessage(id, message);

    final messageCompanion = _mapPatchToMessagesCompanion(message);
    final updatedMessage = await _database.messageDao.patchMessage(
      id,
      messageCompanion,
    );

    if (updatedMessage == null) {
      throw MessageNotFoundException(id);
    }

    return await _mapToMessageWithAttachments(updatedMessage);
  }
}

extension on MessageRepository {
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

extension MessageRepositoryStateOperations on MessageRepository {
  Future<bool> deleteMessage(String id, {String? conversationId}) async {
    final message = await getMessageById(id);
    if (message == null) {
      return false; // Return false instead of throwing for delete operations.
    }
    final existing = await _database.messageDao.getMessageById(id);
    if (conversationId != null &&
        (existing == null || existing.conversationId != conversationId)) {
      throw const MessageValidationException('Fork reference is read-only');
    }

    final deleted = await _database.messageDao.deleteMessage(id);
    if (deleted) {
      final _ = await (_database.delete(
        _database.messageAttachments,
      )..where((table) => table.messageId.equals(id))).go();
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

    return messages.lastWhereOrNull(
      (message) =>
          message.messageType == MessageType.system &&
          message.status == MessageStatus.sent &&
          message.metadata?.isCompactionSummary == true,
    );
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
        (message) => _mapToMessage(
          message,
          attachments: attachmentsByMessage[message.id] ?? [],
        ),
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
  /// Maps a [messageTable] database record to a [MessageEntity] domain entity.
  ///
  /// [messageTable] The database record to map.
  /// Returns the corresponding [MessageEntity] entity.
  MessageEntity _mapToMessage(
    MessagesTable messageTable, {
    List<MessageAttachmentEntity> attachments = const [],
    String? conversationIdOverride,
    bool isForkReference = false,
  }) {
    return MessageEntity(
      id: messageTable.id,
      conversationId: conversationIdOverride ?? messageTable.conversationId,
      content: messageTable.content,
      messageType: .fromString(messageTable.messageType.value),
      isUser: messageTable.isUser,
      status: _messageTableStatusToEntityStatus(messageTable.status),
      createdAt: messageTable.createdAt,
      updatedAt: messageTable.updatedAt,
      metadata: .fromJsonString(messageTable.metadata),
      attachments: attachments,
      isForkReference: isForkReference,
    );
  }
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
