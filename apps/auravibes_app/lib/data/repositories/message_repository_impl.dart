import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/message_table_enums.dart';
import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/utils/encode.dart';
import 'package:drift/drift.dart';

/// Implementation of [MessageRepository] interface.
///
/// This class provides a concrete implementation of message data operations
/// using Drift database. It handles the mapping between domain entities
/// and database records, and provides proper error handling using exceptions.
class MessageRepositoryImpl implements MessageRepository {
  MessageRepositoryImpl(this._database);

  /// The database instance for message operations.
  final AppDatabase _database;

  @override
  Future<List<MessageEntity>> getMessagesByConversation(
    String conversationId,
  ) async {
    try {
      final messageTables = await _database.messageDao
          .getMessagesByConversation(conversationId);
      return messageTables.map(_mapToMessage).toList();
    } catch (e) {
      throw MessageException(
        'Failed to retrieve messages for conversation $conversationId',
        e as Exception,
      );
    }
  }

  @override
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

  @override
  Future<List<MessageEntity>> getMessagesByConversationPaginated(
    String conversationId,
    int limit,
    int offset,
  ) async {
    try {
      final messageTables = await _database.messageDao
          .getMessagesByConversationPaginated(conversationId, limit, offset);
      return messageTables.map(_mapToMessage).toList();
    } catch (e) {
      throw MessageException(
        '''
Failed to retrieve paginated messages for conversation $conversationId
''',
        e as Exception,
      );
    }
  }

  @override
  Future<List<MessageEntity>> getMessagesByType(
    String conversationId,
    MessageType messageType,
  ) async {
    try {
      final messageTables = await _database.messageDao.getMessagesByType(
        conversationId,
        _messageTypeToTableType(messageType),
      );
      return messageTables.map(_mapToMessage).toList();
    } catch (e) {
      throw MessageException(
        '''
Failed to retrieve messages of type $messageType for conversation $conversationId
''',
        e as Exception,
      );
    }
  }

  @override
  Future<List<MessageEntity>> getUserMessages(String conversationId) async {
    try {
      final messageTables = await _database.messageDao.getUserMessages(
        conversationId,
      );
      return messageTables.map(_mapToMessage).toList();
    } catch (e) {
      throw MessageException(
        'Failed to retrieve user messages for conversation $conversationId',
        e as Exception,
      );
    }
  }

  @override
  Future<List<MessageEntity>> getSystemMessages(String conversationId) async {
    try {
      final messageTables = await _database.messageDao.getSystemMessages(
        conversationId,
      );
      return messageTables.map(_mapToMessage).toList();
    } catch (e) {
      throw MessageException(
        'Failed to retrieve system messages for conversation $conversationId',
        e as Exception,
      );
    }
  }

  @override
  Future<MessageEntity?> getMessageById(String id) async {
    try {
      final messageTable = await _database.messageDao.getMessageById(id);
      return messageTable != null ? _mapToMessage(messageTable) : null;
    } catch (e) {
      throw MessageException(
        'Failed to retrieve message with ID $id',
        e as Exception,
      );
    }
  }

  @override
  Future<MessageEntity> createMessage(MessageToCreate message) async {
    try {
      // Validate message before creating
      if (!await validateMessage(message)) {
        throw const MessageValidationException('Invalid message data');
      }

      final messageCompanion = _mapToMessagesCompanion(message);
      final createdMessage = await _database.messageDao.insertMessage(
        messageCompanion,
      );

      return _mapToMessage(createdMessage);
    } catch (e) {
      if (e is MessageException) rethrow;
      throw MessageException('Failed to create message', e as Exception);
    }
  }

  @override
  Future<MessageEntity> patchMessage(
    String id,
    MessagePatch message,
  ) async {
    try {
      _validateMessagePatch(message);

      // Check if message exists
      if (!await messageExists(id)) {
        throw MessageNotFoundException(id);
      }

      final messageCompanion = _mapPatchToMessagesCompanion(message);
      final updatedMessage = await _database.messageDao.patchMessage(
        id,
        messageCompanion,
      );

      if (updatedMessage == null) {
        throw MessageException('Failed to patch message with ID $id');
      }

      return _mapToMessage(updatedMessage);
    } catch (e) {
      if (e is MessageException) rethrow;
      final wrappedError = e is Exception
          ? e
          : Exception('Unexpected message patch error: $e');
      throw MessageException('Failed to patch message', wrappedError);
    }
  }

  @override
  Future<bool> deleteMessage(String id) async {
    try {
      // Check if message exists
      if (!await messageExists(id)) {
        return false; // Return false instead of throwing for delete operations
      }

      final deleted = await _database.messageDao.deleteMessage(id);
      return deleted;
    } catch (e) {
      throw MessageException('Failed to delete message', e as Exception);
    }
  }

  @override
  Future<bool> messageExists(String id) async {
    try {
      return await _database.messageDao.messageExists(id);
    } catch (e) {
      throw MessageException(
        'Failed to check message existence',
        e as Exception,
      );
    }
  }

  @override
  Future<List<MessageEntity>> getMessagesByStatus(
    String conversationId,
    MessageStatus status,
  ) async {
    try {
      final messageTables = await _database.messageDao.getMessagesByStatus(
        conversationId,
        status.value,
      );
      return messageTables.map(_mapToMessage).toList();
    } catch (e) {
      throw MessageException(
        '''
Failed to retrieve messages with status $status for conversation $conversationId
''',
        e as Exception,
      );
    }
  }

  @override
  Future<int> getMessageCountByConversation(String conversationId) async {
    try {
      return await _database.messageDao.getMessageCountByConversation(
        conversationId,
      );
    } catch (e) {
      throw MessageException('Failed to get message count', e as Exception);
    }
  }

  @override
  Future<bool> validateMessage(MessageToCreate message) async {
    try {
      if (!message.isValid) {
        throw MessageValidationException(_getValidationErrorToCreate(message));
      }
      return true;
    } catch (e) {
      if (e is MessageValidationException) rethrow;
      final wrappedError = e is Exception
          ? e
          : Exception('Unexpected message validation error: $e');
      throw MessageValidationException(
        'Message validation failed',
        wrappedError,
      );
    }
  }

  void _validateMessagePatch(MessagePatch message) {
    try {
      final validationError = _getValidationErrorPatch(message);
      if (validationError != null) {
        throw MessageValidationException(validationError);
      }
    } catch (e) {
      if (e is MessageValidationException) rethrow;
      throw MessageValidationException(
        'Message validation failed',
        e as Exception,
      );
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
      metadata: MessageMetadataEntity.fromJsonString(messageTable.metadata),
      createdAt: messageTable.createdAt,
      updatedAt: messageTable.updatedAt,
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
    if (message.content.isEmpty) return 'Message content cannot be empty';
    if (message.conversationId.isEmpty) {
      return 'Conversation ID cannot be empty';
    }
    return 'Unknown validation error';
  }

  String? _getValidationErrorPatch(MessagePatch message) {
    if (message.content != null && message.content!.trim().isEmpty) {
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
