import 'package:auravibes_app/domain/entities/conversation.dart';

abstract class ConversationRepository {
  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    String workspaceId, {
    int? limit,
  });

  Stream<ConversationEntity?> watchConversationById(String id);

  Future<ConversationEntity?> getConversationById(String id);

  Future<ConversationEntity> createConversation(
    ConversationToCreate conversation,
  );

  Future<ConversationEntity> patchConversation(
    String id,
    ConversationPatch conversation,
  );

  Future<bool> deleteConversation(String id);
}

class ConversationException implements Exception {
  const ConversationException(this.message, [this.cause]);

  final String message;
  final Exception? cause;

  @override
  String toString() {
    final causedBy = ' (Caused by: $cause)';
    return 'ConversationException: $message${cause != null ? causedBy : ''}';
  }
}

class ConversationValidationException extends ConversationException {
  const ConversationValidationException(super.message, [super.cause]);
}

class ConversationNotFoundException extends ConversationException {
  const ConversationNotFoundException(this.conversationId, [Exception? cause])
    : super('Conversation with ID "$conversationId" not found', cause);

  final String conversationId;
}

class ConversationDuplicateException extends ConversationException {
  const ConversationDuplicateException(this.conversationId, [Exception? cause])
    : super('Conversation with ID "$conversationId" already exists', cause);

  final String conversationId;
}
