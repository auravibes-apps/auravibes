// Required: Existing test and UI helpers keep compact return flow.

import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/messages_table_type.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/utils/json_codec.dart';
import 'package:drift/drift.dart';

const _messageContentCannotBeEmpty = 'Message content cannot be empty';

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
  ) async {
    final messageTables = await _database.messageDao.getMessagesByConversation(
      conversationId,
    );

    return await _mapToMessagesWithAttachments(messageTables);
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
  Future<MessageEntity> patchMessage(String id, MessagePatch message) =>
      MessageRepositoryMutationOperations(this as MessageRepository)
          .patchMessage(id, message);
}

mixin _MessageRepositoryStateApi {
  Future<bool> deleteMessage(String id) =>
      MessageRepositoryStateOperations(this as MessageRepository)
          .deleteMessage(id);

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
    final messageTables = await _database.messageDao
        .getLatestAssistantMessagesByConversations(conversationIds);

    return messageTables.map(_mapToMessage).toList();
  }

  Stream<List<MessageEntity>> watchMessagesByConversation(
    String conversationId,
  ) =>
      _watchMessagesQuery(conversationId)
          .map(_mapJoinedMessageRows)
          .transform(_messageWatchTransformer(conversationId));
}

extension on MessageRepository {
  Stream<List<TypedResult>> _watchMessagesQuery(String conversationId) {
    final query =
        _database.select(_database.messages).join(_messageAttachmentJoins())
          ..where(_database.messages.conversationId.equals(conversationId))
          ..orderBy(_messageOrderTerms());

    return query.watch();
  }

  List<Join<HasResultSet, dynamic>> _messageAttachmentJoins() => [
    leftOuterJoin(
      _database.messageAttachments,
      _database.messageAttachments.messageId.equalsExp(_database.messages.id),
    ),
  ];

  List<OrderingTerm> _messageOrderTerms() => [
    OrderingTerm(expression: _database.messages.createdAt),
    OrderingTerm(expression: _database.messageAttachments.createdAt),
  ];

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
  ) {
    return _database.messageDao
        .watchLatestAssistantMessageByConversation(conversationId)
        .map((message) => message == null ? null : _mapToMessage(message));
  }

  Future<List<MessageEntity>> getMessagesByConversationPaginated(
    String conversationId,
    int limit,
    int offset,
  ) async {
    final messageTables = await _database.messageDao
        .getMessagesByConversationPaginated(conversationId, limit, offset);

    return await _mapToMessagesWithAttachments(messageTables);
  }

  Future<List<MessageEntity>> getMessagesByType(
    String conversationId,
    MessageType messageType,
  ) async {
    final messageTables = await _database.messageDao.getMessagesByType(
      conversationId,
      _messageTypeToTableType(messageType),
    );

    return await _mapToMessagesWithAttachments(messageTables);
  }

  Future<List<MessageEntity>> getUserMessages(String conversationId) async {
    final messageTables = await _database.messageDao.getUserMessages(
      conversationId,
    );

    return await _mapToMessagesWithAttachments(messageTables);
  }

  Future<List<MessageEntity>> getSystemMessages(String conversationId) async {
    final messageTables = await _database.messageDao.getSystemMessages(
      conversationId,
    );

    return await _mapToMessagesWithAttachments(messageTables);
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
  Future<MessageEntity> patchMessage(String id, MessagePatch message) async {
    _validateMessagePatch(message);
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
  Future<bool> deleteMessage(String id) async {
    final message = await getMessageById(id);
    if (message == null) {
      return false; // Return false instead of throwing for delete operations.
    }

    final deleted = await _database.messageDao.deleteMessage(id);
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
    final messageTables = await _database.messageDao.getMessagesByStatus(
      conversationId,
      status.value,
    );

    return await _mapToMessagesWithAttachments(messageTables);
  }

  Future<int> getMessageCountByConversation(String conversationId) {
    return _database.messageDao.getMessageCountByConversation(conversationId);
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
    final row = await _database.messageDao.getLatestCompactionSummary(
      conversationId,
    );

    if (row == null) return null;

    return await _mapToMessageWithAttachments(row);
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
        return _deleteAttachmentFile(attachment.localPath);
      }),
    );
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
  }) {
    return MessageEntity(
      id: messageTable.id,
      conversationId: messageTable.conversationId,
      content: messageTable.content,
      messageType: .fromString(messageTable.messageType.value),
      isUser: messageTable.isUser,
      status: _messageTableStatusToEntityStatus(messageTable.status),
      createdAt: messageTable.createdAt,
      updatedAt: messageTable.updatedAt,
      metadata: .fromJsonString(messageTable.metadata),
      attachments: attachments,
    );
  }

  List<MessageEntity> _mapJoinedMessageRows(List<TypedResult> rows) {
    final joinedRows = _collectJoinedMessageRows(rows);

    return _joinedMessages(joinedRows.messages, joinedRows.attachments);
  }

  ({
    Map<String, MessagesTable> messages,
    Map<String, List<MessageAttachmentEntity>> attachments,
  })
  _collectJoinedMessageRows(List<TypedResult> rows) {
    final messageRows = <String, MessagesTable>{};
    final attachmentsByMessage = <String, List<MessageAttachmentEntity>>{};
    for (final row in rows) {
      _collectJoinedMessageRow(row, messageRows, attachmentsByMessage);
    }

    return (messages: messageRows, attachments: attachmentsByMessage);
  }

  void _collectJoinedMessageRow(
    TypedResult row,
    Map<String, MessagesTable> messageRows,
    Map<String, List<MessageAttachmentEntity>> attachmentsByMessage,
  ) {
    final message = row.readTable(_database.messages);
    messageRows[message.id] = message;

    final attachment = row.readTableOrNull(_database.messageAttachments);
    if (attachment == null) return;

    attachmentsByMessage
        .putIfAbsent(message.id, () => [])
        .add(_mapToAttachment(attachment));
  }

  List<MessageEntity> _joinedMessages(
    Map<String, MessagesTable> messageRows,
    Map<String, List<MessageAttachmentEntity>> attachmentsByMessage,
  ) => [
    for (final message in messageRows.values)
      _mapToMessage(
        message,
        attachments: attachmentsByMessage[message.id] ?? [],
      ),
  ];
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
class MessageValidationException extends MessageException {
  /// Creates a new MessageValidationException.
  const new(super.message, [super.cause]);
}

/// Exception thrown when a message is not found.
class MessageNotFoundException extends MessageException {
  /// Creates a new MessageNotFoundException.
  const new(this.messageId, [Exception? cause])
    : super('Message with ID "$messageId" not found', cause);

  /// ID of the message that was not found.
  final String messageId;
}
