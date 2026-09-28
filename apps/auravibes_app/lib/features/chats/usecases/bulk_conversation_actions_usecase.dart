import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';

typedef CloudConversationResolver = Future<CloudConversationUsecase?> Function(
  String workspaceId,
);

typedef LocalConversationDelete = Future<bool> Function(String conversationId);

typedef BulkConversationOperationError = ({
  ConversationEntity conversation,
  Object error,
  StackTrace stackTrace,
});

typedef BulkPinResult = ({
  List<ConversationEntity> updated,
  List<ConversationEntity> failures,
  List<BulkConversationOperationError> errors,
});

typedef BulkDeleteResult = ({
  List<ConversationEntity> deleted,
  List<ConversationEntity> failures,
  List<BulkConversationOperationError> errors,
});

class const BulkConversationActionsUsecase({
  required final ConversationRepository conversationRepository,
  required final LocalConversationDelete deleteConversation,
  required final CloudConversationResolver resolveCloudConversation,
}) {
  Future<ConversationEntity?> setPinned(
    ConversationEntity conversation, {
    required bool isPinned,
  }) async {
    final cloud = await resolveCloudConversation(conversation.workspaceId);
    if (cloud != null) {
      return await _setCloudPinned(cloud, conversation, isPinned);
    }

    return await _setLocalPinned(
      conversationRepository,
      conversation,
      isPinned,
    );
  }

  Future<bool> delete(ConversationEntity conversation) async {
    final cloud = await resolveCloudConversation(conversation.workspaceId);
    if (cloud != null) {
      await cloud.delete(conversation);

      return true;
    }

    return await deleteConversation(conversation.id);
  }

  Future<BulkPinResult> pinMany(
    List<ConversationEntity> conversations, {
    required bool isPinned,
  }) async {
    final updated = <ConversationEntity>[];
    final failures = <ConversationEntity>[];
    final errors = <BulkConversationOperationError>[];

    for (final conversation in conversations) {
      _appendPinResult(
        await _pinOne(this, conversation, isPinned),
        updated,
        failures,
        errors,
      );
    }

    return (updated: updated, failures: failures, errors: errors);
  }

  Future<BulkDeleteResult> deleteMany(
    List<ConversationEntity> conversations,
  ) async {
    final deleted = <ConversationEntity>[];
    final failures = <ConversationEntity>[];
    final errors = <BulkConversationOperationError>[];

    for (final conversation in conversations) {
      _appendDeleteResult(
        await _deleteOne(this, conversation),
        deleted,
        failures,
        errors,
      );
    }

    return (deleted: deleted, failures: failures, errors: errors);
  }
}

Future<ConversationEntity?> _setCloudPinned(
  CloudConversationUsecase cloud,
  ConversationEntity conversation,
  bool isPinned,
) async {
  try {
    final updated = await cloud.update(conversation, .new(isPinned: isPinned));

    return conversation.copyWith(
      isPinned: isPinned,
      revision: updated.revision,
      updatedAt: updated.updatedAt,
    );
  } on CloudAppException catch (error) {
    if (error.code != 'validationFailed') rethrow;

    return null;
  }
}

Future<ConversationEntity?> _setLocalPinned(
  ConversationRepository conversationRepository,
  ConversationEntity conversation,
  bool isPinned,
) async {
  try {
    return await conversationRepository.patchConversation(
      conversation.id,
      .new(isPinned: isPinned),
    );
  } on ConversationPinLimitException {
    return null;
  }
}

Future<BulkPinResult> _pinOne(
  BulkConversationActionsUsecase usecase,
  ConversationEntity conversation,
  bool isPinned,
) async {
  if (conversation.isPinned == isPinned) return _emptyPinResult();
  try {
    final updated = await usecase.setPinned(conversation, isPinned: isPinned);

    return _pinResult(conversation, updated);
  } on Object catch (error, stackTrace) {
    return _pinError(conversation, error, stackTrace);
  }
}

Future<BulkDeleteResult> _deleteOne(
  BulkConversationActionsUsecase usecase,
  ConversationEntity conversation,
) async {
  try {
    final deleted = await usecase.delete(conversation);

    return (
      deleted: [if (deleted) conversation],
      failures: [if (!deleted) conversation],
      errors: <BulkConversationOperationError>[],
    );
  } on Object catch (error, stackTrace) {
    return (
      deleted: <ConversationEntity>[],
      failures: [conversation],
      errors: [
        (conversation: conversation, error: error, stackTrace: stackTrace),
      ],
    );
  }
}

void _appendPinResult(
  BulkPinResult result,
  List<ConversationEntity> updated,
  List<ConversationEntity> failures,
  List<BulkConversationOperationError> errors,
) {
  updated.addAll(result.updated);
  failures.addAll(result.failures);
  errors.addAll(result.errors);
}

void _appendDeleteResult(
  BulkDeleteResult result,
  List<ConversationEntity> deleted,
  List<ConversationEntity> failures,
  List<BulkConversationOperationError> errors,
) {
  deleted.addAll(result.deleted);
  failures.addAll(result.failures);
  errors.addAll(result.errors);
}

BulkPinResult _emptyPinResult() => (
  updated: <ConversationEntity>[],
  failures: <ConversationEntity>[],
  errors: <BulkConversationOperationError>[],
);

BulkPinResult _pinResult(
  ConversationEntity conversation,
  ConversationEntity? updated,
) => (
  updated: [?updated],
  failures: [if (updated == null) conversation],
  errors: <BulkConversationOperationError>[],
);

BulkPinResult _pinError(
  ConversationEntity conversation,
  Object error,
  StackTrace stackTrace,
) => (
  updated: <ConversationEntity>[],
  failures: [conversation],
  errors: [(conversation: conversation, error: error, stackTrace: stackTrace)],
);
