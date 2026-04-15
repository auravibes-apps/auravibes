import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:drift/drift.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  ConversationRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    String workspaceId, {
    int? limit,
  }) {
    return _database.conversationDao
        .watchConversationsByWorkspace(workspaceId, limit: limit)
        .map((rows) => rows.map(_mapToConversation).toList());
  }

  @override
  Stream<ConversationEntity?> watchConversationById(String id) {
    return _database.conversationDao
        .watchConversationById(id)
        .map((row) => row != null ? _mapToConversation(row) : null);
  }

  @override
  Future<ConversationEntity?> getConversationById(String id) async {
    final conversationTable = await _database.conversationDao
        .getConversationById(id);
    return conversationTable != null
        ? _mapToConversation(conversationTable)
        : null;
  }

  @override
  Future<ConversationEntity> createConversation(
    ConversationToCreate conversation,
  ) async {
    _validateConversationToCreate(conversation);

    final conversationCompanion = _mapToConversationsCompanion(conversation);
    final createdConversation = await _database.conversationDao
        .insertConversation(conversationCompanion);

    return _mapToConversation(createdConversation);
  }

  @override
  Future<ConversationEntity> updateConversation(
    String id,
    ConversationToUpdate conversation,
  ) async {
    _validateConversationUpdate(conversation);

    if (!await _conversationExists(id)) {
      throw ConversationNotFoundException(id);
    }

    final conversationCompanion = _mapUpdateToConversationsCompanion(
      conversation,
    );
    final updated = await _database.conversationDao.updateConversation(
      id,
      conversationCompanion,
    );

    if (!updated) {
      throw ConversationException(
        'Failed to update conversation with ID $id',
      );
    }

    final updatedConversation = await _database.conversationDao
        .getConversationById(id);

    if (updatedConversation == null) {
      throw ConversationException(
        'Failed to retrieve updated conversation with ID $id',
      );
    }

    return _mapToConversation(updatedConversation);
  }

  @override
  Future<bool> deleteConversation(String id) async {
    if (!await _conversationExists(id)) return false;

    return _database.conversationDao.deleteConversation(id);
  }

  Future<bool> _conversationExists(String id) async {
    return await _database.conversationDao.getConversationById(id) != null;
  }

  void _validateConversationToCreate(ConversationToCreate conversation) {
    if (!conversation.isValid) {
      throw ConversationValidationException(
        conversation.title.isEmpty
            ? 'Conversation title cannot be empty'
            : conversation.workspaceId.isEmpty
            ? 'Workspace ID cannot be empty'
            : 'Unknown validation error',
      );
    }
  }

  void _validateConversationUpdate(ConversationToUpdate conversation) {
    if (!conversation.isValid) {
      throw ConversationValidationException(
        conversation.title != null && conversation.title!.isEmpty
            ? 'Conversation title cannot be empty'
            : conversation.modelId != null && conversation.modelId!.isEmpty
            ? 'Model ID cannot be empty'
            : 'Unknown validation error',
      );
    }
  }

  ConversationEntity _mapToConversation(ConversationsTable conversationTable) {
    return ConversationEntity(
      id: conversationTable.id,
      title: conversationTable.title,
      workspaceId: conversationTable.workspaceId,
      modelId: conversationTable.modelId,
      isPinned: conversationTable.isPinned,
      createdAt: conversationTable.createdAt,
      updatedAt: conversationTable.updatedAt,
    );
  }

  ConversationsCompanion _mapToConversationsCompanion(
    ConversationToCreate conversation,
  ) {
    return ConversationsCompanion(
      title: Value(conversation.title),
      workspaceId: Value(conversation.workspaceId),
      modelId: Value(conversation.modelId),
      isPinned: Value(conversation.isPinned ?? false),
    );
  }

  ConversationsCompanion _mapUpdateToConversationsCompanion(
    ConversationToUpdate conversation,
  ) {
    return ConversationsCompanion(
      title: Value.absentIfNull(conversation.title),
      modelId: Value.absentIfNull(conversation.modelId),
      isPinned: Value.absentIfNull(conversation.isPinned),
    );
  }
}
