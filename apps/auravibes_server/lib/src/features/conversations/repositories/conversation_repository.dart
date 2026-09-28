import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../model_connections/domain/virtual_workspace_model_selection.dart';
import '../../objects/object_reference_service.dart';
import '../domain/conversation_values.dart';

const _transientForkToolCallStatuses = {
  'pending',
  'needsConfirmation',
  'approved',
  'granted',
  'running',
};

Map<String, dynamic> _safeMetadata(String? source) {
  if (source == null) return <String, dynamic>{};
  try {
    final value = jsonDecode(source);
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  } on Object catch (_) {
    return <String, dynamic>{};
  }
}

String conversationTurnJobPayload(
  String actorUserId, {
  String? executionId,
  int? parentTurnId,
  String? parentToolCallId,
  List<String>? a2uiSupportedComponents,
  String? reasoningConfigJson,
  bool includeReasoningConfigSnapshot = false,
}) => jsonEncode({
  'actorUserId': actorUserId,
  'executionId': ?executionId,
  'parentTurnId': ?parentTurnId,
  'parentToolCallId': ?parentToolCallId,
  'a2uiSupportedComponents': ?a2uiSupportedComponents,
  if (includeReasoningConfigSnapshot)
    'reasoningConfigJson': reasoningConfigJson,
});

String? conversationReasoningConfigForExecutionSettings(String settingsJson) {
  final settings = jsonDecode(settingsJson);
  return settings is Map && settings['reasoningConfigJson'] is String
      ? settings['reasoningConfigJson']! as String
      : null;
}

String _escapeLike(String value) =>
    value.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

String conversationExecutionIdForJob(
  String jobRequestId,
  String? payloadJson,
) {
  if (payloadJson == null) return jobRequestId;
  final payload = jsonDecode(payloadJson);
  return payload is Map && payload['executionId'] is String
      ? payload['executionId']! as String
      : jobRequestId;
}

int? conversationParentTurnIdForJob(String? payloadJson) {
  if (payloadJson == null) return null;
  final payload = jsonDecode(payloadJson);
  return payload is Map && payload['parentTurnId'] is int
      ? payload['parentTurnId']! as int
      : null;
}

String? conversationParentToolCallIdForJob(String? payloadJson) {
  if (payloadJson == null) return null;
  final payload = jsonDecode(payloadJson);
  return payload is Map && payload['parentToolCallId'] is String
      ? payload['parentToolCallId']! as String
      : null;
}

int? conversationParentTurnIdForExecutionSettings(String settingsJson) {
  final settings = jsonDecode(settingsJson);
  return settings is Map && settings['parentTurnId'] is int
      ? settings['parentTurnId']! as int
      : null;
}

String? conversationParentToolCallIdForExecutionSettings(String settingsJson) {
  final settings = jsonDecode(settingsJson);
  return settings is Map && settings['parentToolCallId'] is String
      ? settings['parentToolCallId']! as String
      : null;
}

class ConversationRepository({ObjectReferenceService? objectReferenceService}) {
  final ObjectReferenceService _objectReferenceService =
      objectReferenceService ?? ObjectReferenceService();
  Future<Conversation?> findConversationByStableId(
    Session session, {
    required int workspaceId,
    required String conversationId,
    Transaction? transaction,
    bool lock = false,
  }) => Conversation.db.findFirstRow(
    session,
    where: (table) =>
        table.stableId.equals(conversationId) &
        table.workspaceId.equals(workspaceId) &
        table.deletedAt.equals(null),
    transaction: transaction,
    lockMode: lock ? LockMode.forUpdate : null,
  );

  Future<List<Conversation>> listConversations(
    Session session, {
    required int workspaceId,
    String? search,
    bool? beforeIsPinned,
    DateTime? beforeUpdatedAt,
    String? beforeStableId,
    int? limit,
    int offset = 0,
    Transaction? transaction,
  }) {
    final normalizedSearch = search?.trim();

    return Conversation.db.find(
      session,
      where: (table) {
        var where =
            table.workspaceId.equals(workspaceId) &
            table.deletedAt.equals(null);
        if (normalizedSearch != null && normalizedSearch.isNotEmpty) {
          where &= table.title.ilike('%${_escapeLike(normalizedSearch)}%');
        }
        if (beforeUpdatedAt case final updatedAt?) {
          final stableId = beforeStableId;
          if (stableId == null) return where;
          final beforeDate =
              (table.updatedAt < updatedAt) |
              (table.updatedAt.equals(updatedAt) & (table.stableId < stableId));
          if (beforeIsPinned == true) {
            where &=
                table.isPinned.equals(false) |
                (table.isPinned.equals(true) & beforeDate);
          } else if (beforeIsPinned == false) {
            where &= table.isPinned.equals(false) & beforeDate;
          } else {
            where &= beforeDate;
          }
        }
        return where;
      },
      orderByList: (table) => [
        table.isPinned.desc(),
        table.updatedAt.desc(),
        table.stableId.desc(),
      ],
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  Future<int> countPinnedConversations(
    Session session, {
    required int workspaceId,
    Transaction? transaction,
  }) async {
    final conversations = await Conversation.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.isPinned.equals(true) &
          table.deletedAt.equals(null),
      limit: ConversationLimits.maxPinnedPerWorkspace + 1,
      transaction: transaction,
    );

    return conversations.length;
  }

  Future<bool> resourceExists(
    Session session, {
    required int workspaceId,
    required WorkspaceResourceKind kind,
    required String resourceId,
    required Transaction transaction,
  }) async =>
      await WorkspaceResource.db.findFirstRow(
        session,
        where: (table) =>
            table.workspaceId.equals(workspaceId) &
            table.resourceKind.equals(kind) &
            table.resourceId.equals(resourceId) &
            table.deletedAt.equals(null),
        transaction: transaction,
      ) !=
      null;

  Future<ResolvedVirtualWorkspaceModelSelection?> resolveModelSelection(
    Session session, {
    required int workspaceId,
    required String modelId,
    required Transaction transaction,
  }) => const VirtualWorkspaceModelSelectionResolver().resolve(
    session,
    workspaceId: workspaceId,
    selectionId: modelId,
    transaction: transaction,
  );

  Future<WorkspaceResource?> findResource(
    Session session, {
    required int workspaceId,
    required WorkspaceResourceKind kind,
    required String resourceId,
    required Transaction transaction,
  }) => WorkspaceResource.db.findFirstRow(
    session,
    where: (table) =>
        table.workspaceId.equals(workspaceId) &
        table.resourceKind.equals(kind) &
        table.resourceId.equals(resourceId) &
        table.deletedAt.equals(null),
    transaction: transaction,
  );

  Future<Conversation?> findConversation(
    Session session, {
    required int workspaceId,
    required int conversationId,
    Transaction? transaction,
    bool lock = false,
  }) => Conversation.db.findFirstRow(
    session,
    where: (table) =>
        table.id.equals(conversationId) &
        table.workspaceId.equals(workspaceId) &
        table.deletedAt.equals(null),
    transaction: transaction,
    lockMode: lock ? LockMode.forUpdate : null,
  );

  Future<ConversationTurn?> findTurn(
    Session session, {
    required int workspaceId,
    required int turnId,
    Transaction? transaction,
    bool lock = false,
  }) => ConversationTurn.db.findFirstRow(
    session,
    where: (table) =>
        table.id.equals(turnId) & table.workspaceId.equals(workspaceId),
    transaction: transaction,
    lockMode: lock ? LockMode.forUpdate : null,
  );

  Future<List<ConversationTurn>> listTurns(
    Session session, {
    required int workspaceId,
    required Iterable<int> turnIds,
  }) {
    final ids = turnIds.toList();
    if (ids.isEmpty) return Future.value(const []);
    return ConversationTurn.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) & table.id.inSet(ids.toSet()),
    );
  }

  Future<ConversationTurn?> findTurnByRequest(
    Session session, {
    required int workspaceId,
    required String requestId,
    Transaction? transaction,
  }) => ConversationTurn.db.findFirstRow(
    session,
    where: (table) =>
        table.workspaceId.equals(workspaceId) &
        table.requestId.equals(requestId),
    transaction: transaction,
  );

  Future<ConversationTurn?> findTurnByStableId(
    Session session, {
    required int workspaceId,
    required String turnId,
    Transaction? transaction,
    bool lock = false,
  }) => ConversationTurn.db.findFirstRow(
    session,
    where: (table) =>
        table.workspaceId.equals(workspaceId) & table.requestId.equals(turnId),
    transaction: transaction,
    lockMode: lock ? LockMode.forUpdate : null,
  );

  Future<bool> hasActiveMutation(
    Session session, {
    required int workspaceId,
    required int conversationId,
    Transaction? transaction,
  }) async {
    final turns = await ConversationTurn.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.conversationId.equals(conversationId),
      transaction: transaction,
    );
    if (turns.any((turn) => ConversationStatuses.isActive(turn.status))) {
      return true;
    }
    return await ConversationJob.db.findFirstRow(
          session,
          where: (table) =>
              table.workspaceId.equals(workspaceId) &
              table.conversationId.equals(conversationId) &
              table.kind.equals(ConversationJobKinds.compact) &
              (table.status.equals(ConversationJobStatuses.queued) |
                  table.status.equals(ConversationJobStatuses.leased)),
          transaction: transaction,
        ) !=
        null;
  }

  Future<int?> attachmentBytes(
    Session session, {
    required int workspaceId,
    required String actorUserId,
    required Iterable<int> objectIds,
    required Transaction transaction,
  }) async {
    final ids = objectIds.toSet();
    if (ids.isEmpty) return 0;
    final objects = await WorkspaceObject.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) & table.id.inSet(ids),
      transaction: transaction,
    );
    final uploads = await ObjectUpload.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.actorUserId.equals(actorUserId) &
          table.objectId.inSet(ids),
      transaction: transaction,
    );
    if (objects.length != ids.length ||
        uploads.length != ids.length ||
        objects.any(
          (object) => object.status != 'active' || object.deletedAt != null,
        )) {
      return null;
    }
    return objects.fold<int>(
      0,
      (total, object) => total + object.sizeBytes,
    );
  }

  Future<StartTurnResult> insertTurn(
    Session session, {
    required Conversation conversation,
    required String actorUserId,
    required StartTurnRequest request,
    required List<int> attachmentIds,
    required String requestHash,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final userMessage = await ConversationMessage.db.insertRow(
      session,
      ConversationMessage(
        workspaceId: request.workspaceId,
        conversationId: conversation.id!,
        stableId: request.clientMessageId,
        role: 'user',
        kind: 'text',
        status: 'sent',
        content: request.content,
        metadataJson: jsonEncode({
          'attachmentIds': attachmentIds,
          if (request.modelSelectionId != null)
            'modelSelectionId': request.modelSelectionId,
          if (request.agentId != null) 'agentId': request.agentId,
        }),
        revision: 1,
        createdAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    final assistantMessage = await ConversationMessage.db.insertRow(
      session,
      ConversationMessage(
        workspaceId: request.workspaceId,
        conversationId: conversation.id!,
        stableId: '${request.requestId}:assistant',
        role: 'assistant',
        kind: 'text',
        status: ConversationStatuses.queued,
        content: '',
        revision: 1,
        createdAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    final turn = await ConversationTurn.db.insertRow(
      session,
      ConversationTurn(
        workspaceId: request.workspaceId,
        conversationId: conversation.id!,
        requestId: request.requestId,
        requestHash: requestHash,
        initiatorUserId: actorUserId,
        userMessageId: userMessage.id,
        assistantMessageId: assistantMessage.id,
        status: ConversationStatuses.queued,
        revision: 1,
        acceptedSequence: conversation.revision + 1,
        createdAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await ConversationMessage.db.updateRow(
      session,
      userMessage.copyWith(turnId: turn.id),
      transaction: transaction,
    );
    for (final objectId in attachmentIds) {
      await _objectReferenceService.attachToMessage(
        session,
        workspaceId: request.workspaceId,
        objectId: objectId,
        messageId: userMessage.id!,
        transaction: transaction,
      );
    }
    await ConversationMessage.db.updateRow(
      session,
      assistantMessage.copyWith(turnId: turn.id),
      transaction: transaction,
    );
    await ConversationJob.db.insertRow(
      session,
      ConversationJob(
        workspaceId: request.workspaceId,
        conversationId: conversation.id!,
        turnId: turn.id,
        requestId: request.requestId,
        kind: ConversationJobKinds.turn,
        status: ConversationJobStatuses.queued,
        payloadJson: conversationTurnJobPayload(
          actorUserId,
          a2uiSupportedComponents: request.a2uiSupportedComponents,
          reasoningConfigJson: conversation.reasoningConfigJson,
          includeReasoningConfigSnapshot: true,
        ),
        attempt: 0,
        maxAttempts: 3,
        availableAt: now,
        createdAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await Conversation.db.updateRow(
      session,
      conversation.copyWith(
        revision: conversation.revision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    return StartTurnResult(
      turnId: turn.requestId,
      userMessageId: userMessage.stableId,
      assistantMessageId: assistantMessage.stableId,
      acceptedSequence: conversation.revision + 1,
      turnRevision: turn.revision,
      status: turn.status,
    );
  }

  Future<ConversationTurn> insertContinuationTurn(
    Session session, {
    required Conversation conversation,
    required String actorUserId,
    required ContinueTurnRequest request,
    required String requestHash,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final assistantMessage = await ConversationMessage.db.insertRow(
      session,
      ConversationMessage(
        workspaceId: request.workspaceId,
        conversationId: conversation.id!,
        stableId: '${request.requestId}:assistant',
        role: 'assistant',
        kind: 'text',
        status: ConversationStatuses.queued,
        content: '',
        revision: 1,
        createdAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    final turn = await ConversationTurn.db.insertRow(
      session,
      ConversationTurn(
        workspaceId: request.workspaceId,
        conversationId: conversation.id!,
        requestId: request.requestId,
        requestHash: requestHash,
        initiatorUserId: actorUserId,
        assistantMessageId: assistantMessage.id,
        status: ConversationStatuses.queued,
        revision: 1,
        acceptedSequence: conversation.revision + 1,
        createdAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await ConversationMessage.db.updateRow(
      session,
      assistantMessage.copyWith(turnId: turn.id),
      transaction: transaction,
    );
    await ConversationJob.db.insertRow(
      session,
      ConversationJob(
        workspaceId: request.workspaceId,
        conversationId: conversation.id!,
        turnId: turn.id,
        requestId: request.requestId,
        kind: ConversationJobKinds.turn,
        status: ConversationJobStatuses.queued,
        payloadJson: conversationTurnJobPayload(
          actorUserId,
          a2uiSupportedComponents: request.a2uiSupportedComponents,
          reasoningConfigJson: conversation.reasoningConfigJson,
          includeReasoningConfigSnapshot: true,
        ),
        attempt: 0,
        maxAttempts: 3,
        availableAt: now,
        createdAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await Conversation.db.updateRow(
      session,
      conversation.copyWith(
        revision: conversation.revision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    return turn;
  }

  Future<ConversationMessage> insertPendingMessage(
    Session session, {
    required Conversation conversation,
    required String clientMessageId,
    required String content,
    required List<int> attachmentIds,
    String? metadataJson,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final messages = await ConversationMessage.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(conversation.workspaceId) &
          table.conversationId.equals(conversation.id),
      transaction: transaction,
    );
    final pendingOrder =
        messages.fold<int>(
          0,
          (highest, message) =>
              message.pendingOrder != null && message.pendingOrder! > highest
              ? message.pendingOrder!
              : highest,
        ) +
        1;
    final message = await ConversationMessage.db.insertRow(
      session,
      ConversationMessage(
        workspaceId: conversation.workspaceId,
        conversationId: conversation.id!,
        stableId: clientMessageId,
        role: 'user',
        kind: 'text',
        status: ConversationStatuses.queued,
        content: content,
        metadataJson: jsonEncode({
          ..._safeMetadata(metadataJson),
          'attachmentIds': attachmentIds,
        }),
        pendingOrder: pendingOrder,
        pendingAt: now,
        revision: 1,
        createdAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    for (final objectId in attachmentIds) {
      await _objectReferenceService.attachToMessage(
        session,
        workspaceId: conversation.workspaceId,
        objectId: objectId,
        messageId: message.id!,
        transaction: transaction,
      );
    }
    return message;
  }

  Future<ConversationMessage?> findPendingMessage(
    Session session, {
    required int workspaceId,
    required int conversationId,
    required String messageId,
    required Transaction transaction,
  }) => ConversationMessage.db.findFirstRow(
    session,
    where: (table) =>
        table.workspaceId.equals(workspaceId) &
        table.conversationId.equals(conversationId) &
        table.stableId.equals(messageId) &
        table.pendingOrder.notEquals(null),
    transaction: transaction,
    lockMode: LockMode.forUpdate,
  );

  Future<List<ConversationMessage>> listPendingMessages(
    Session session, {
    required int workspaceId,
    required int conversationId,
    required Transaction transaction,
  }) => ConversationMessage.db.find(
    session,
    where: (table) =>
        table.workspaceId.equals(workspaceId) &
        table.conversationId.equals(conversationId) &
        table.pendingOrder.notEquals(null),
    orderBy: (table) => table.pendingOrder,
    transaction: transaction,
    lockMode: LockMode.forUpdate,
  );

  Future<List<ConversationMessage>> listMessages(
    Session session, {
    required ConversationTurn turn,
  }) => ConversationMessage.db.find(
    session,
    where: (table) =>
        table.workspaceId.equals(turn.workspaceId) &
        table.turnId.equals(turn.id),
    orderBy: (table) => table.id,
  );

  Future<ConversationMessage?> findMessage(
    Session session, {
    required int workspaceId,
    required int messageId,
  }) => ConversationMessage.db.findFirstRow(
    session,
    where: (table) =>
        table.id.equals(messageId) & table.workspaceId.equals(workspaceId),
  );

  Future<List<ConversationMessage>> listConversationMessages(
    Session session, {
    required int workspaceId,
    required int conversationId,
    required int limit,
  }) => ConversationMessage.db.find(
    session,
    where: (table) =>
        table.workspaceId.equals(workspaceId) &
        table.conversationId.equals(conversationId),
    orderBy: (table) => table.id.desc(),
    limit: limit,
  );

  Future<List<ConversationMessage>> listEffectiveMessages(
    Session session, {
    required int workspaceId,
    required String conversationId,
    Transaction? transaction,
  }) async {
    final conversation = await findConversationByStableId(
      session,
      workspaceId: workspaceId,
      conversationId: conversationId,
      transaction: transaction,
    );
    if (conversation == null) return const [];
    final messages = <ConversationMessage>[];
    if (conversation.forkSourceConversationId != null &&
        conversation.forkMaterializedAt == null) {
      final inherited = await listEffectiveMessages(
        session,
        workspaceId: workspaceId,
        conversationId: conversation.forkSourceConversationId!,
        transaction: transaction,
      );
      final transientToolMessageIds =
          (await listToolCallsByTurnIds(
                session,
                workspaceId: workspaceId,
                turnIds: inherited
                    .map((message) => message.turnId)
                    .whereType<int>(),
                transaction: transaction,
              ))
              .where(
                (call) => _transientForkToolCallStatuses.contains(call.status),
              )
              .map((call) => call.messageId)
              .toSet();
      messages.addAll(
        inherited.where(
          (message) =>
              message.pendingOrder == null &&
              ConversationStatuses.isMessageTerminal(message.status) &&
              !transientToolMessageIds.contains(message.id),
        ),
      );
      final boundary = conversation.forkThroughMessageId;
      if (boundary != null) {
        final index = messages.indexWhere(
          (message) => message.stableId == boundary,
        );
        if (index < 0) {
          throw StateError('Fork boundary must be terminal');
        }
        messages.removeRange(index + 1, messages.length);
      }
    }
    final own = await ConversationMessage.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.conversationId.equals(conversation.id!),
      orderBy: (table) => table.id,
      transaction: transaction,
    );
    messages.addAll(own);
    messages.sort((left, right) {
      final created = left.createdAt.compareTo(right.createdAt);
      return created == 0 ? left.id!.compareTo(right.id!) : created;
    });
    return messages;
  }

  Future<ConversationToolCall?> findToolCallByStableId(
    Session session, {
    required int workspaceId,
    required int turnId,
    required String toolCallId,
    required Transaction transaction,
  }) => ConversationToolCall.db.findFirstRow(
    session,
    where: (table) =>
        table.stableId.equals(toolCallId) &
        table.workspaceId.equals(workspaceId) &
        table.turnId.equals(turnId),
    transaction: transaction,
    lockMode: LockMode.forUpdate,
  );

  Future<List<ConversationToolCall>> listToolCalls(
    Session session, {
    required ConversationTurn turn,
  }) => ConversationToolCall.db.find(
    session,
    where: (table) =>
        table.workspaceId.equals(turn.workspaceId) &
        table.turnId.equals(turn.id),
    orderBy: (table) => table.id,
  );

  Future<List<ConversationToolCall>> listToolCallsByTurnIds(
    Session session, {
    required int workspaceId,
    required Iterable<int> turnIds,
    Transaction? transaction,
  }) {
    final ids = turnIds.toList();
    if (ids.isEmpty) return Future.value(const []);
    return ConversationToolCall.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.turnId.inSet(ids.toSet()),
      orderBy: (table) => table.id,
      transaction: transaction,
    );
  }

  Future<ConversationToolCall?> findToolCall(
    Session session, {
    required int workspaceId,
    required int turnId,
    required int toolCallId,
    required Transaction transaction,
  }) => ConversationToolCall.db.findFirstRow(
    session,
    where: (table) =>
        table.id.equals(toolCallId) &
        table.workspaceId.equals(workspaceId) &
        table.turnId.equals(turnId),
    transaction: transaction,
    lockMode: LockMode.forUpdate,
  );
}
