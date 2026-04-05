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
    try {
      return _database.conversationDao
          .watchConversationsByWorkspace(workspaceId, limit: limit)
          .map((rows) => rows.map(_mapToConversation).toList())
          .handleError((Object e) {
            throw ConversationException(
              'Failed to watch conversations for workspace $workspaceId',
              e as Exception,
            );
          });
    } catch (e) {
      throw ConversationException(
        'Failed to watch conversations for workspace $workspaceId',
        e as Exception,
      );
    }
  }

  @override
  Future<ConversationEntity?> getConversationById(String id) async {
    try {
      final conversationTable = await _database.conversationDao
          .getConversationById(id);
      return conversationTable != null
          ? _mapToConversation(conversationTable)
          : null;
    } catch (e) {
      throw ConversationException(
        'Failed to retrieve conversation with ID $id',
        e as Exception,
      );
    }
  }

  @override
  Future<ConversationEntity> createConversation(
    ConversationToCreate conversation,
  ) async {
    try {
      _validateConversationToCreate(conversation);

      final conversationCompanion = _mapToConversationsCompanion(conversation);
      final createdConversation = await _database.conversationDao
          .insertConversation(conversationCompanion);

      return _mapToConversation(createdConversation);
    } catch (e) {
      if (e is ConversationException) rethrow;
      throw ConversationException(
        'Failed to create conversation',
        e as Exception,
      );
    }
  }

  @override
  Future<ConversationEntity> updateConversation(
    String id,
    ConversationToUpdate conversation,
  ) async {
    try {
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
    } catch (e) {
      if (e is ConversationException) rethrow;
      throw const ConversationException('Failed to update conversation');
    }
  }

  @override
  Future<bool> deleteConversation(String id) async {
    try {
      if (!await _conversationExists(id)) return false;

      return _database.conversationDao.deleteConversation(id);
    } catch (e) {
      throw ConversationException(
        'Failed to delete conversation',
        e as Exception,
      );
    }
  }

  Future<bool> _conversationExists(String id) async {
    try {
      return await _database.conversationDao.getConversationById(id) != null;
    } catch (e) {
      throw ConversationException(
        'Failed to check conversation existence',
        e as Exception,
      );
    }
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
