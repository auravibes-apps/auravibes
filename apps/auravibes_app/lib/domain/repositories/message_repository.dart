import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';

/// Repository interface for message data operations.
///
/// This abstract class defines the contract for message data access,
/// following the Repository pattern from Clean Architecture.
/// Implementations should handle data persistence, retrieval, and
/// business logic validation for message operations.
abstract class MessageRepository {
  /// Retrieves all messages for a specific conversation.
  ///
  /// [conversationId] The unique identifier of the conversation.
  /// Returns a list of messages ordered by their creation date.
  /// Throws [MessageException] if there's an error retrieving messages.
  Future<List<MessageEntity>> getMessagesByConversation(String conversationId);

  /// Retrieves messages for a conversation with pagination.
  ///
  /// [conversationId] The unique identifier of the conversation.
  /// [limit] Maximum number of messages to retrieve.
  /// [offset] Number of messages to skip for pagination.
  /// Returns a list of messages ordered by their creation date.
  /// Throws [MessageException] if there's an error retrieving messages.
  Future<List<MessageEntity>> getMessagesByConversationPaginated(
    String conversationId,
    int limit,
    int offset,
  );

  /// Retrieves messages filtered by type for a specific conversation.
  ///
  /// [conversationId] The unique identifier of the conversation.
  /// [messageType] The type of messages to retrieve.
  /// Returns a list of messages of the specified type ordered by creation date.
  /// Throws [MessageException] if there's an error retrieving messages.
  Future<List<MessageEntity>> getMessagesByType(
    String conversationId,
    MessageType messageType,
  );

  /// Retrieves user messages for a specific conversation.
  ///
  /// [conversationId] The unique identifier of the conversation.
  /// Returns a list of user messages ordered by their creation date.
  /// Throws [MessageException] if there's an error retrieving messages.
  Future<List<MessageEntity>> getUserMessages(String conversationId);

  /// Retrieves system messages for a specific conversation.
  ///
  /// [conversationId] The unique identifier of the conversation.
  /// Returns a list of system messages ordered by their creation date.
  /// Throws [MessageException] if there's an error retrieving messages.
  Future<List<MessageEntity>> getSystemMessages(String conversationId);

  /// Retrieves a message by its unique identifier.
  ///
  /// [id] The unique identifier of the message to retrieve.
  /// Returns the message with the given [id], or null if not found.
  /// Throws [MessageException] if there's an error retrieving the message.
  Future<MessageEntity?> getMessageById(String id);

  /// Creates a new message in the data source.
  ///
  /// [message] The message to create. The message should have a unique ID.
  /// Returns the created message with any system-generated values populated.
  /// Throws [MessageValidationException] if message data is invalid.
  /// Throws [MessageDuplicateException] if a message with the same ID already
  ///  exists.
  /// Throws [MessageException] if there's an error creating the message.
  Future<MessageEntity> createMessage(MessageToCreate message);

  /// Updates an existing message in the data source.
  ///
  /// [id] The ID of the message to update.
  /// [message] The message with updated values. Must have a valid ID.
  /// Returns the updated message.
  /// Throws [MessageValidationException] if message data is invalid.
  /// Throws [MessageNotFoundException] if no message with the given ID exists.
  /// Throws [MessageException] if there's an error updating the message.
  Future<MessageEntity> updateMessage(String id, MessageToUpdate message);

  Future<MessageEntity?> appendToMessage(String id, String delta);

  /// Deletes a message from the data source.
  ///
  /// [id] The unique identifier of the message to delete.
  /// Returns true if the message was successfully deleted, false if not found.
  /// Throws [MessageException] if there's an error deleting the message.
  Future<bool> deleteMessage(String id);

  /// Checks if a message with the given ID exists.
  ///
  /// [id] The unique identifier to check.
  /// Returns true if the message exists, false otherwise.
  /// Throws [MessageException] if there's an error checking existence.
  Future<bool> messageExists(String id);

  /// Retrieves messages filtered by status for a specific conversation.
  ///
  /// [conversationId] The unique identifier of the conversation.
  /// [status] The status of messages to retrieve.
  /// Returns a list of messages with the specified status ordered by
  /// creation date.
  /// Throws [MessageException] if there's an error retrieving messages.
  Future<List<MessageEntity>> getMessagesByStatus(
    String conversationId,
    MessageStatus status,
  );

  /// Gets the total count of messages for a specific conversation.
  ///
  /// [conversationId] The unique identifier of the conversation.
  /// Returns the total number of messages in the conversation.
  /// Throws [MessageException] if there's an error counting messages.
  Future<int> getMessageCountByConversation(String conversationId);

  /// Validates message data before creation or update.
  ///
  /// [message] The message to validate.
  /// Returns true if the message data is valid.
  /// Throws [MessageValidationException] if message data is invalid.
  Future<bool> validateMessage(MessageToCreate message);
}

/// Base exception for message-related operations.
class MessageException implements Exception {
  /// Creates a new MessageException
  const MessageException(this.message, [this.cause]);

  /// Error message describing the exception
  final String message;

  /// Optional original exception that caused this exception
  final Exception? cause;

  @override
  String toString() {
    final causedBy = cause != null ? ' (Caused by: $cause)' : '';
    return 'MessageException: $message$causedBy';
  }
}

/// Exception thrown when message validation fails.
class MessageValidationException extends MessageException {
  /// Creates a new MessageValidationException
  const MessageValidationException(super.message, [super.cause]);
}

/// Exception thrown when a message is not found.
class MessageNotFoundException extends MessageException {
  /// Creates a new MessageNotFoundException
  const MessageNotFoundException(this.messageId, [Exception? cause])
    : super('Message with ID "$messageId" not found', cause);

  /// ID of the message that was not found
  final String messageId;
}

/// Exception thrown when attempting to create a duplicate message.
class MessageDuplicateException extends MessageException {
  /// Creates a new MessageDuplicateException
  const MessageDuplicateException(this.messageId, [Exception? cause])
    : super('Message with ID "$messageId" already exists', cause);

  /// ID of the duplicate message
  final String messageId;
}
