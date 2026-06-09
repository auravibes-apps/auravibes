// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:drift/drift.dart';

const _conversationTitleEmpty = 'Conversation title cannot be empty';
const _modelIdEmpty = 'Model ID cannot be empty';
const _unknownValidationError = 'Unknown validation error';
const _workspaceIdEmpty = 'Workspace ID cannot be empty';

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
  Future<ConversationEntity> patchConversation(
    String id,
    ConversationPatch conversation,
  ) async {
    _validateConversationPatch(conversation);

    if (!await _conversationExists(id)) {
      throw ConversationNotFoundException(id);
    }

    final conversationCompanion = _mapPatchToConversationsCompanion(
      conversation,
    );
    final updated = await _database.conversationDao.patchConversation(
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
        _conversationCreateValidationMessage(conversation),
      );
    }
  }

  String _conversationCreateValidationMessage(
    ConversationToCreate conversation,
  ) {
    if (conversation.title.isEmpty) return _conversationTitleEmpty;
    if (conversation.workspaceId.isEmpty) return _workspaceIdEmpty;
    final modelId = conversation.modelId;
    if (modelId != null && modelId.isEmpty) {
      return _modelIdEmpty;
    }

    return _unknownValidationError;
  }

  void _validateConversationPatch(ConversationPatch conversation) {
    if (!conversation.isValid) {
      throw ConversationValidationException(
        _conversationPatchValidationMessage(conversation),
      );
    }
  }

  String _conversationPatchValidationMessage(ConversationPatch conversation) {
    final title = conversation.title;
    if (title != null && title.isEmpty) {
      return _conversationTitleEmpty;
    }

    final modelId = conversation.modelId;
    if (modelId != null && modelId.isEmpty) {
      return _modelIdEmpty;
    }

    return _unknownValidationError;
  }

  ConversationEntity _mapToConversation(ConversationsTable conversationTable) {
    return ConversationEntity(
      id: conversationTable.id,
      title: conversationTable.title,
      workspaceId: conversationTable.workspaceId,
      isPinned: conversationTable.isPinned,
      createdAt: conversationTable.createdAt,
      updatedAt: conversationTable.updatedAt,
      modelId: conversationTable.modelId,
    );
  }

  ConversationsCompanion _mapToConversationsCompanion(
    ConversationToCreate conversation,
  ) {
    return ConversationsCompanion(
      workspaceId: Value(conversation.workspaceId),
      title: Value(conversation.title),
      modelId: Value(conversation.modelId),
      isPinned: Value(conversation.isPinned ?? false),
    );
  }

  ConversationsCompanion _mapPatchToConversationsCompanion(
    ConversationPatch conversation,
  ) {
    return ConversationsCompanion(
      title: Value.absentIfNull(conversation.title),
      modelId: Value.absentIfNull(conversation.modelId),
      isPinned: Value.absentIfNull(conversation.isPinned),
    );
  }
}
