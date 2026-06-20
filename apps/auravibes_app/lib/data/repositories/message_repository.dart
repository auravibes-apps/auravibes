// Required: Existing test and UI helpers keep compact return flow.

import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/messages_table_type.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/utils/encode.dart';
import 'package:drift/drift.dart';

/// Implementation of [MessageRepository] interface.
///
/// This class provides a concrete implementation of message data operations
/// using Drift database. It handles the mapping between domain entities
/// and database records, and provides proper error handling using exceptions.
class MessageRepository {
  MessageRepository(this._database);

  /// The database instance for message operations.
  final AppDatabase _database;

  Future<List<MessageEntity>> getMessagesByConversation(
    String conversationId,
  ) async {
    final messageTables = await _database.messageDao.getMessagesByConversation(
      conversationId,
    );

    return messageTables.map(_mapToMessage).toList();
  }

  Stream<List<MessageEntity>> watchMessagesByConversation(
    String conversationId,
  ) {
    return _database.messageDao
        .watchMessagesByConversation(conversationId)
        .transform(
          StreamTransformer<
            List<MessagesTable>,
            List<MessageEntity>
          >.fromHandlers(
            handleData: (messageTables, sink) {
              try {
                sink.add(messageTables.map(_mapToMessage).toList());
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

  Future<List<MessageEntity>> getMessagesByConversationPaginated(
    String conversationId,
    int limit,
    int offset,
  ) async {
    final messageTables = await _database.messageDao
        .getMessagesByConversationPaginated(conversationId, limit, offset);

    return messageTables.map(_mapToMessage).toList();
  }

  Future<List<MessageEntity>> getMessagesByType(
    String conversationId,
    MessageType messageType,
  ) async {
    final messageTables = await _database.messageDao.getMessagesByType(
      conversationId,
      _messageTypeToTableType(messageType),
    );

    return messageTables.map(_mapToMessage).toList();
  }

  Future<List<MessageEntity>> getUserMessages(String conversationId) async {
    final messageTables = await _database.messageDao.getUserMessages(
      conversationId,
    );

    return messageTables.map(_mapToMessage).toList();
  }

  Future<List<MessageEntity>> getSystemMessages(String conversationId) async {
    final messageTables = await _database.messageDao.getSystemMessages(
      conversationId,
    );

    return messageTables.map(_mapToMessage).toList();
  }

  Future<MessageEntity?> getMessageById(String id) async {
    final messageTable = await _database.messageDao.getMessageById(id);

    return messageTable != null ? _mapToMessage(messageTable) : null;
  }

  Future<MessageEntity> createMessage(MessageToCreate message) async {
    // Validate message before creating.
    if (!await validateMessage(message)) {
      throw const MessageValidationException('Invalid message data');
    }

    final messageCompanion = _mapToMessagesCompanion(message);
    final createdMessage = await _database.messageDao.insertMessage(
      messageCompanion,
    );

    return _mapToMessage(createdMessage);
  }

  Future<MessageEntity> patchMessage(
    String id,
    MessagePatch message,
  ) async {
    _validateMessagePatch(message);

    final messageCompanion = _mapPatchToMessagesCompanion(message);
    final updatedMessage = await _database.messageDao.patchMessage(
      id,
      messageCompanion,
    );

    if (updatedMessage == null) {
      throw MessageNotFoundException(id);
    }

    return _mapToMessage(updatedMessage);
  }

  Future<bool> deleteMessage(String id) async {
    // Check if message exists.
    if (!await messageExists(id)) {
      return false; // Return false instead of throwing for delete operations.
    }

    return _database.messageDao.deleteMessage(id);
  }

  Future<bool> messageExists(String id) async {
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

    return messageTables.map(_mapToMessage).toList();
  }

  Future<int> getMessageCountByConversation(String conversationId) async {
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

    return row != null ? _mapToMessage(row) : null;
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
  MessageEntity _mapToMessage(MessagesTable messageTable) {
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
    );
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

  MessagesCompanion _mapPatchToMessagesCompanion(MessagePatch message) {
    return MessagesCompanion(
      content: Value.absentIfNull(message.content),
      status: Value.absentIfNull(
        _messageStatusToTableStatus(message.status),
      ),
      metadata: Value.absentIfNull(safeJsonEncode(message.metadata?.toJson())),
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
    if (message.content.isEmpty) return 'Message content cannot be empty';

    return 'Unknown validation error';
  }

  String? _getValidationErrorPatch(MessagePatch message) {
    final content = message.content;
    if (content != null && content.trim().isEmpty) {
      return 'Message content cannot be empty';
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
  const MessageException(
    this.message, [
    this.cause,
  ]);

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
  const MessageValidationException(super.message, [super.cause]);
}

/// Exception thrown when a message is not found.
class MessageNotFoundException extends MessageException {
  /// Creates a new MessageNotFoundException.
  const MessageNotFoundException(this.messageId, [Exception? cause])
    : super('Message with ID "$messageId" not found', cause);

  /// ID of the message that was not found.
  final String messageId;
}

/// Exception thrown when attempting to create a duplicate message.
class MessageDuplicateException extends MessageException {
  /// Creates a new MessageDuplicateException.
  const MessageDuplicateException(this.messageId, [Exception? cause])
    : super('Message with ID "$messageId" already exists', cause);

  /// ID of the duplicate message.
  final String messageId;
}
