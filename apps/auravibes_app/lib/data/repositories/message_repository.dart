// Required: Existing test and UI helpers keep compact return flow.

import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/messages_table_type.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/utils/encode.dart';
import 'package:drift/drift.dart';

const _messageContentCannotBeEmpty = 'Message content cannot be empty';

/// Implementation of [MessageRepository] interface.
///
/// This class provides a concrete implementation of message data operations
/// using Drift database. It handles the mapping between domain entities
/// and database records, and provides proper error handling using exceptions.
class MessageRepository(
  /// The database instance for message operations.
  final AppDatabase _database, {
  final AttachmentFileStore _attachmentFileStore = const AttachmentFileStore(),
}) {
  Future<List<MessageEntity>> getMessagesByConversation(
    String conversationId,
  ) async {
    final messageTables = await _database.messageDao.getMessagesByConversation(
      conversationId,
    );

    return await _mapToMessagesWithAttachments(messageTables);
  }

  Future<List<MessageEntity>> getLatestAssistantMessagesByConversations(
    List<String> conversationIds,
  ) async {
    final messageTables = await _database.messageDao
        .getLatestAssistantMessagesByConversations(conversationIds);

    return messageTables.map(_mapToMessage).toList();
  }

  Stream<List<MessageEntity>> watchMessagesByConversation(
    String conversationId,
  ) {
    return (_database.select(_database.messages).join([
            leftOuterJoin(
              _database.messageAttachments,
              _database.messageAttachments.messageId.equalsExp(
                _database.messages.id,
              ),
            ),
          ])
          ..where(_database.messages.conversationId.equals(conversationId))
          ..orderBy([
            OrderingTerm(expression: _database.messages.createdAt),
            OrderingTerm(expression: _database.messageAttachments.createdAt),
          ]))
        .watch()
        .map(_mapJoinedMessageRows)
        .transform(
          StreamTransformer<
            List<MessageEntity>,
            List<MessageEntity>
          >.fromHandlers(
            handleData: (messages, sink) {
              try {
                sink.add(messages);
              } on Exception catch (error, stackTrace) {
                sink.addError(
                  MessageException(
                    'Failed to watch messages for conversation $conversationId',
                    error,
                  ),
                  stackTrace,
                );
              }
            },
            handleError: (error, stackTrace, sink) {
              if (error is Exception) {
                sink.addError(
                  MessageException(
                    'Failed to watch messages for conversation $conversationId',
                    error,
                  ),
                  stackTrace,
                );

                return;
              }

              sink.addError(error, stackTrace);
            },
          ),
        );
  }

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
      for (final attachment in message.attachments) {
        final localPath = await _attachmentFileStore.persistDraftFile(
          attachment.localPath,
        );
        promotedAttachments.add(attachment.copyWith(localPath: localPath));
      }

      final messageToCreate = message.copyWith(
        attachments: promotedAttachments,
      );
      final createdMessage = await _database.transaction(() async {
        final messageCompanion = _mapToMessagesCompanion(messageToCreate);
        final createdMessage = await _database.messageDao.insertMessage(
          messageCompanion,
        );

        for (final attachment in messageToCreate.attachments) {
          final _ = await _database
              .into(_database.messageAttachments)
              .insert(
                _mapToMessageAttachmentCompanion(createdMessage.id, attachment),
              );
        }

        return createdMessage;
      });

      await _deleteDraftAttachmentFiles(message.attachments);

      return await _mapToMessageWithAttachments(createdMessage);
    } on Exception {
      await _deleteDraftAttachmentFiles(promotedAttachments);

      rethrow;
    }
  }

  Future<MessageEntity> patchMessage(String id, MessagePatch message) async {
    _validateMessagePatch(message);

    if (message.status == MessageStatus.sent && message.content == null) {
      final existingMessage = await getMessageById(id);
      if (existingMessage == null) {
        throw MessageNotFoundException(id);
      }
      final metadata = message.metadata ?? existingMessage.metadata;
      if (existingMessage.content.trim().isEmpty &&
          existingMessage.attachments.isEmpty &&
          !_hasMessagePayload(metadata)) {
        throw const MessageValidationException(_messageContentCannotBeEmpty);
      }
    }

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

  Future<bool> deleteMessage(String id) async {
    final message = await getMessageById(id);
    if (message == null) {
      return false; // Return false instead of throwing for delete operations.
    }

    final deleted = await _database.messageDao.deleteMessage(id);
    if (deleted) await _deletePersistedAttachmentFiles(message.attachments);

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

  Future<List<MessageEntity>> _mapToMessagesWithAttachments(
    List<MessagesTable> messageTables,
  ) async {
    if (messageTables.isEmpty) return [];

    final ids = messageTables.map((message) => message.id).toList();
    final attachmentRows = await (_database.select(
      _database.messageAttachments,
    )..where((attachment) => attachment.messageId.isIn(ids))).get();
    final attachmentsByMessage = <String, List<MessageAttachmentEntity>>{};
    for (final row in attachmentRows) {
      attachmentsByMessage
          .putIfAbsent(row.messageId, () => [])
          .add(_mapToAttachment(row));
    }

    return messageTables
        .map(
          (message) => _mapToMessage(
            message,
            attachments: attachmentsByMessage[message.id] ?? [],
          ),
        )
        .toList();
  }

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
      messageType: MessageType.fromString(messageTable.messageType.value),
      isUser: messageTable.isUser,
      status: _messageTableStatusToEntityStatus(messageTable.status),
      createdAt: messageTable.createdAt,
      updatedAt: messageTable.updatedAt,
      metadata: MessageMetadataEntity.fromJsonString(messageTable.metadata),
      attachments: attachments,
    );
  }

  List<MessageEntity> _mapJoinedMessageRows(List<TypedResult> rows) {
    final messageRows = <String, MessagesTable>{};
    final attachmentsByMessage = <String, List<MessageAttachmentEntity>>{};
    for (final row in rows) {
      final message = row.readTable(_database.messages);
      messageRows[message.id] = message;

      final attachment = row.readTableOrNull(_database.messageAttachments);
      if (attachment == null) continue;

      attachmentsByMessage
          .putIfAbsent(message.id, () => [])
          .add(_mapToAttachment(attachment));
    }

    return [
      for (final message in messageRows.values)
        _mapToMessage(
          message,
          attachments: attachmentsByMessage[message.id] ?? [],
        ),
    ];
  }

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
    if (metadata == null) return false;

    return metadata.toolCalls.isNotEmpty ||
        (metadata.thinking?.trim().isNotEmpty ?? false) ||
        metadata.modelMetadata.isNotEmpty ||
        metadata.promptTokens != null ||
        metadata.completionTokens != null ||
        metadata.totalTokens != null;
  }

  /// Maps a [MessageEntity] domain entity to a [MessagesCompanion]
  /// for database operations.
  ///
  /// [message] The message entity to map.
  /// Returns a corresponding [MessagesCompanion].
  MessagesCompanion _mapToMessagesCompanion(MessageToCreate message) {
    return MessagesCompanion(
      conversationId: Value(message.conversationId),
      content: Value(message.content),
      messageType: Value(_messageTypeToTableType(message.messageType)),
      isUser: Value(message.isUser),
      status: Value.absentIfNull(_messageStatusToTableStatus(message.status)),
      metadata: Value(message.metadata),
    );
  }

  MessageAttachmentsCompanion _mapToMessageAttachmentCompanion(
    String messageId,
    MessageAttachmentToCreate attachment,
  ) {
    return MessageAttachmentsCompanion(
      messageId: Value(messageId),
      localPath: Value(attachment.localPath),
      fileName: Value(attachment.fileName),
      displayName: Value(attachment.displayName),
      mimeType: Value(attachment.mimeType),
      modality: Value(attachment.modality.name),
      sizeBytes: Value(attachment.sizeBytes),
    );
  }

  MessagesCompanion _mapPatchToMessagesCompanion(MessagePatch message) {
    return MessagesCompanion(
      content: Value.absentIfNull(message.content),
      status: Value.absentIfNull(_messageStatusToTableStatus(message.status)),
      metadata: Value.absentIfNull(
        JsonCodec.encode(message.metadata?.toJson()),
      ),
    );
  }

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
      MessageTableStatus.sent => MessageStatus.sent,
      MessageTableStatus.sending => MessageStatus.sending,
      MessageTableStatus.unfinished => MessageStatus.unfinished,
      MessageTableStatus.error => MessageStatus.error,
    };
  }

  MessageTableStatus? _messageStatusToTableStatus(MessageStatus? status) {
    if (status == null) return null;

    return switch (status) {
      MessageStatus.sent => MessageTableStatus.sent,
      MessageStatus.sending => MessageTableStatus.sending,
      MessageStatus.unfinished => MessageTableStatus.unfinished,
      MessageStatus.error => MessageTableStatus.error,
    };
  }

  MessagesTableType _messageTypeToTableType(MessageType messageType) {
    return switch (messageType) {
      MessageType.text => MessagesTableType.text,
      MessageType.image => MessagesTableType.image,
      MessageType.toolCall => MessagesTableType.toolCall,
      MessageType.system => MessagesTableType.system,
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
    final causedBy = cause != null ? ' (Caused by: $cause)' : '';

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
