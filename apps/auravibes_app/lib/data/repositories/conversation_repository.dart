// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:drift/drift.dart';

const _conversationTitleEmpty = 'Conversation title cannot be empty';
const _agentIdEmpty = 'Agent ID cannot be empty';
const _modelIdEmpty = 'Model ID cannot be empty';
const _parentConversationIdEmpty = 'Parent conversation ID cannot be empty';
const _unknownValidationError = 'Unknown validation error';
const _workspaceIdEmpty = 'Workspace ID cannot be empty';

class ConversationRepository {
  ConversationRepository(
    this._database, {
    AttachmentFileStore? attachmentFileStore,
  }) : _attachmentFileStore = attachmentFileStore ?? AttachmentFileStore();

  final AppDatabase _database;
  final AttachmentFileStore _attachmentFileStore;

  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    String workspaceId, {
    int? limit,
  }) {
    return _database.conversationDao
        .watchConversationsByWorkspace(workspaceId, limit: limit)
        .map((rows) => rows.map(_mapToConversation).toList());
  }

  Stream<ConversationEntity?> watchConversationById(String id) {
    return _database.conversationDao
        .watchConversationById(id)
        .map((row) => row != null ? _mapToConversation(row) : null);
  }

  Stream<List<ConversationEntity>> watchChildConversations(
    String parentConversationId,
  ) {
    return _database.conversationDao
        .watchChildConversations(parentConversationId)
        .map((rows) => rows.map(_mapToConversation).toList());
  }

  Future<List<ConversationEntity>> getChildConversations(
    String parentConversationId,
  ) async {
    final rows = await _database.conversationDao.getChildConversations(
      parentConversationId,
    );

    return rows.map(_mapToConversation).toList();
  }

  Future<ConversationEntity?> getConversationById(String id) async {
    final conversationTable = await _database.conversationDao
        .getConversationById(id);

    return conversationTable != null
        ? _mapToConversation(conversationTable)
        : null;
  }

  Future<ConversationEntity> createConversation(
    ConversationToCreate conversation,
  ) async {
    _validateConversationToCreate(conversation);

    final conversationCompanion = _mapToConversationsCompanion(conversation);
    final createdConversation = await _database.conversationDao
        .insertConversation(conversationCompanion);

    return _mapToConversation(createdConversation);
  }

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

  Future<bool> deleteConversation(String id) async {
    if (!await _conversationExists(id)) return false;

    final attachmentPaths = await _attachmentPathsForConversation(id);
    final deleted = await _database.conversationDao.deleteConversation(id);
    if (deleted) {
      final _ = await Future.wait(
        attachmentPaths.map(_deleteAttachmentFile),
      );
    }

    return deleted;
  }

  Future<List<String>> _attachmentPathsForConversation(String id) async {
    final rows = await (_database.select(_database.messageAttachments).join([
      innerJoin(
        _database.messages,
        _database.messages.id.equalsExp(
          _database.messageAttachments.messageId,
        ),
      ),
    ])..where(_database.messages.conversationId.equals(id))).get();

    return [
      for (final row in rows)
        row.readTable(_database.messageAttachments).localPath,
    ];
  }

  Future<void> _deleteAttachmentFile(String localPath) async {
    try {
      await _attachmentFileStore.deleteFile(localPath);
    } on Object {
      return;
    }
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

    final agentId = conversation.agentId;
    if (agentId != null && agentId.isEmpty) {
      return _agentIdEmpty;
    }

    final parentConversationId = conversation.parentConversationId;
    if (parentConversationId != null && parentConversationId.isEmpty) {
      return _parentConversationIdEmpty;
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

    final agentId = conversation.agentId;
    if (agentId != null && agentId.isEmpty) {
      return _agentIdEmpty;
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
      agentId: conversationTable.agentId,
      parentConversationId: conversationTable.parentConversationId,
    );
  }

  ConversationsCompanion _mapToConversationsCompanion(
    ConversationToCreate conversation,
  ) {
    return ConversationsCompanion(
      workspaceId: Value(conversation.workspaceId),
      title: Value(conversation.title),
      modelId: Value(conversation.modelId),
      agentId: Value(conversation.agentId),
      parentConversationId: Value(conversation.parentConversationId),
      isPinned: Value(conversation.isPinned ?? false),
    );
  }

  ConversationsCompanion _mapPatchToConversationsCompanion(
    ConversationPatch conversation,
  ) {
    return ConversationsCompanion(
      title: Value.absentIfNull(conversation.title),
      modelId: Value.absentIfNull(conversation.modelId),
      agentId: conversation.clearAgent
          ? const Value(null)
          : Value.absentIfNull(conversation.agentId),
      isPinned: Value.absentIfNull(conversation.isPinned),
    );
  }
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
