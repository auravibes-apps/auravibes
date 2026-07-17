import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../workspaces/domain/workspace_roles.dart';
import '../../sync/stream/sync_wakeups.dart';
import '../domain/conversation_values.dart';
import '../engine/conversation_host_effects.dart';
import '../live_turn_broker.dart';
import '../repositories/conversation_repository.dart' as conversation_repo;

class ConversationUseCases {
  ConversationUseCases(this._repository);

  static const _maxAttachmentsPerTurn = 4;
  static const _maxAttachmentBytesPerTurn = maxAttachmentBytes * 2;

  final conversation_repo.ConversationRepository _repository;

  Future<ConversationSummary> create(
    Session session, {
    required String userId,
    required CreateConversationRequest request,
  }) => _mutate(
    session,
    userId: userId,
    workspaceId: request.workspaceId,
    endpoint: 'conversation.create',
    requestId: request.requestId,
    requestBody: request.toJson(),
    decode: ConversationSummary.fromJson,
    run: (transaction, now) async {
      _requireId(request.requestId);
      _requireId(request.conversationId);
      _validateMetadata(request.title, request.modelId, request.agentId);
      final existing = await _repository.findConversationByStableId(
        session,
        workspaceId: request.workspaceId,
        conversationId: request.conversationId,
        transaction: transaction,
        lock: true,
      );
      if (existing != null) _fail(ConversationErrorCode.idempotencyConflict);
      await _validateReferences(
        session,
        workspaceId: request.workspaceId,
        modelId: request.modelId,
        agentId: request.agentId,
        parentConversationId: request.parentConversationId,
        transaction: transaction,
      );
      final summary = _summary(
        await Conversation.db.insertRow(
          session,
          Conversation(
            workspaceId: request.workspaceId,
            stableId: request.conversationId,
            title: request.title.trim(),
            isPinned: request.isPinned,
            modelId: request.modelId,
            agentId: request.agentId,
            parentConversationStableId: request.parentConversationId,
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
          transaction: transaction,
        ),
      );
      return _Mutation(summary, 'created', summary.id);
    },
  );

  Future<List<ConversationSummary>> list(
    Session session, {
    required String userId,
    required ListConversationsRequest request,
  }) async {
    if (request.limit < 1 || request.limit > 100) {
      _fail(ConversationErrorCode.validationFailed);
    }
    await _requireMember(
      session,
      workspaceId: request.workspaceId,
      userId: userId,
    );
    return (await _page(
      session,
      request: request,
    )).conversations;
  }

  Future<ConversationPage> listPage(
    Session session, {
    required String userId,
    required ListConversationsRequest request,
  }) async {
    if (request.limit < 1 || request.limit > 100) {
      _fail(ConversationErrorCode.validationFailed);
    }
    await _requireMember(
      session,
      workspaceId: request.workspaceId,
      userId: userId,
    );
    return _page(session, request: request);
  }

  Future<ConversationSummary> get(
    Session session, {
    required String userId,
    required GetConversationRequest request,
  }) async {
    await _requireMember(
      session,
      workspaceId: request.workspaceId,
      userId: userId,
    );
    return _summary(
      await _requireConversation(
        session,
        request.workspaceId,
        request.conversationId,
      ),
    );
  }

  Future<List<ConversationMessageView>> listMessages(
    Session session, {
    required String userId,
    required ListConversationMessagesRequest request,
  }) async {
    if (request.limit < 1 || request.limit > 500) {
      _fail(ConversationErrorCode.validationFailed);
    }
    await _requireMember(
      session,
      workspaceId: request.workspaceId,
      userId: userId,
    );
    final conversation = await _requireConversation(
      session,
      request.workspaceId,
      request.conversationId,
    );
    final messages = await _repository.listConversationMessages(
      session,
      workspaceId: request.workspaceId,
      conversationId: conversation.id!,
      limit: request.limit,
    );
    final turnIds = messages.map((message) => message.turnId).whereType<int>();
    final turns = {
      for (final turn in await _repository.listTurns(
        session,
        workspaceId: request.workspaceId,
        turnIds: turnIds,
      ))
        turn.id!: turn,
    };
    final calls = <int, List<ConversationToolCall>>{};
    for (final call in await _repository.listToolCallsByTurnIds(
      session,
      workspaceId: request.workspaceId,
      turnIds: turns.keys,
    )) {
      final messageId = call.messageId;
      (calls[messageId] ??= []).add(call);
    }
    return messages.reversed.map((message) {
      final turn = turns[message.turnId];
      return ConversationMessageView(
        id: message.stableId,
        conversationId: conversation.stableId,
        turnId: turn?.requestId,
        turnRevision: turn?.revision,
        role: message.role,
        kind: message.kind,
        status: message.status,
        content: message.content,
        metadataJson: message.metadataJson,
        toolCalls: [
          for (final call in calls[message.id] ?? const [])
            _toolCallView(call, turn!, messages),
        ],
        revision: message.revision,
        createdAt: message.createdAt,
        updatedAt: message.updatedAt,
      );
    }).toList();
  }

  Future<ConversationSummary> update(
    Session session, {
    required String userId,
    required UpdateConversationRequest request,
  }) => _mutate(
    session,
    userId: userId,
    workspaceId: request.workspaceId,
    endpoint: 'conversation.update',
    requestId: request.requestId,
    requestBody: request.toJson(),
    decode: ConversationSummary.fromJson,
    run: (transaction, now) async {
      _requireId(request.requestId);
      _validateMetadata(
        request.title,
        request.modelId,
        request.agentId,
        allowNullTitle: true,
      );
      await _requireMember(
        session,
        workspaceId: request.workspaceId,
        userId: userId,
        transaction: transaction,
      );
      final conversation = await _repository.findConversationByStableId(
        session,
        workspaceId: request.workspaceId,
        conversationId: request.conversationId,
        transaction: transaction,
        lock: true,
      );
      if (conversation == null) _fail(ConversationErrorCode.notFound);
      if (conversation.revision != request.expectedRevision) {
        _fail(ConversationErrorCode.staleRevision);
      }
      await _validateReferences(
        session,
        workspaceId: request.workspaceId,
        modelId: request.clearModel ? null : request.modelId,
        agentId: request.clearAgent ? null : request.agentId,
        parentConversationId: request.clearParent
            ? null
            : request.parentConversationId,
        transaction: transaction,
      );
      final updated = await Conversation.db.updateRow(
        session,
        conversation.copyWith(
          title: request.title?.trim() ?? conversation.title,
          isPinned: request.isPinned ?? conversation.isPinned,
          modelId: request.clearModel
              ? null
              : request.modelId ?? conversation.modelId,
          agentId: request.clearAgent
              ? null
              : request.agentId ?? conversation.agentId,
          parentConversationStableId: request.clearParent
              ? null
              : request.parentConversationId ??
                    conversation.parentConversationStableId,
          revision: conversation.revision + 1,
          updatedAt: now,
        ),
        transaction: transaction,
      );
      final summary = _summary(updated);
      return _Mutation(summary, 'updated', summary.id);
    },
  );

  Future<void> delete(
    Session session, {
    required String userId,
    required DeleteConversationRequest request,
  }) => _mutate(
    session,
    userId: userId,
    workspaceId: request.workspaceId,
    endpoint: 'conversation.delete',
    requestId: request.requestId,
    requestBody: request.toJson(),
    decode: (_) {},
    run: (transaction, now) async {
      _requireId(request.requestId);
      await _requireMember(
        session,
        workspaceId: request.workspaceId,
        userId: userId,
        transaction: transaction,
      );
      final conversation = await _repository.findConversationByStableId(
        session,
        workspaceId: request.workspaceId,
        conversationId: request.conversationId,
        transaction: transaction,
        lock: true,
      );
      if (conversation == null) _fail(ConversationErrorCode.notFound);
      if (conversation.revision != request.expectedRevision) {
        _fail(ConversationErrorCode.staleRevision);
      }
      await Conversation.db.updateRow(
        session,
        conversation.copyWith(
          deletedAt: now,
          revision: conversation.revision + 1,
        ),
        transaction: transaction,
      );
      return _Mutation<void>(null, 'deleted', request.conversationId);
    },
  );

  Future<StartTurnResult> startTurn(
    Session session, {
    required String userId,
    required StartTurnRequest request,
  }) async {
    _requireId(request.requestId);
    _requireId(request.clientMessageId);
    final content = request.content.trim();
    if ((content.isEmpty && request.attachmentIds.isEmpty) ||
        content.length > 100000 ||
        request.attachmentIds.length > _maxAttachmentsPerTurn) {
      _fail(ConversationErrorCode.validationFailed);
    }
    final requestHash = jsonEncode({
      'conversationId': request.conversationId,
      'expectedRevision': request.expectedConversationRevision,
      'clientMessageId': request.clientMessageId,
      'content': content,
      'attachmentIds': request.attachmentIds,
      'modelSelectionId': request.modelSelectionId,
      'agentId': request.agentId,
    });
    final attachmentIds = request.attachmentIds.map(_parseObjectId).toSet();
    final result = await _mutate(
      session,
      userId: userId,
      workspaceId: request.workspaceId,
      endpoint: 'conversation.startTurn',
      requestId: request.requestId,
      requestBody: request.toJson(),
      decode: StartTurnResult.fromJson,
      run: (transaction, now) async {
        final duplicate = await _repository.findTurnByRequest(
          session,
          workspaceId: request.workspaceId,
          requestId: request.requestId,
          transaction: transaction,
        );
        if (duplicate != null) {
          if (duplicate.requestHash != requestHash) {
            _fail(ConversationErrorCode.idempotencyConflict);
          }
          final replay = await _startResult(session, duplicate);
          return _Mutation(replay, 'turnStarted', request.conversationId);
        }
        final conversation = await _repository.findConversationByStableId(
          session,
          workspaceId: request.workspaceId,
          conversationId: request.conversationId,
          transaction: transaction,
          lock: true,
        );
        if (conversation == null) _fail(ConversationErrorCode.notFound);
        if (conversation.revision != request.expectedConversationRevision) {
          _fail(ConversationErrorCode.staleRevision);
        }
        await _validateStartTurnReferences(
          session,
          workspaceId: request.workspaceId,
          modelSelectionId: request.modelSelectionId,
          agentId: request.agentId,
          transaction: transaction,
        );
        if (await _repository.hasActiveMutation(
          session,
          workspaceId: request.workspaceId,
          conversationId: conversation.id!,
          transaction: transaction,
        )) {
          _fail(ConversationErrorCode.turnConflict);
        }
        final attachmentBytes = await _repository.attachmentBytes(
          session,
          workspaceId: request.workspaceId,
          actorUserId: userId,
          objectIds: attachmentIds,
          transaction: transaction,
        );
        if (attachmentBytes == null ||
            attachmentBytes > _maxAttachmentBytesPerTurn) {
          _fail(ConversationErrorCode.validationFailed);
        }
        final started = await _repository.insertTurn(
          session,
          conversation: conversation,
          actorUserId: userId,
          request: request.copyWith(content: content),
          attachmentIds: attachmentIds.toList(),
          requestHash: requestHash,
          now: now,
          transaction: transaction,
        );
        return _Mutation(started, 'turnStarted', request.conversationId);
      },
    );
    session.log(
      'Conversation turn queued: workspace=${request.workspaceId}, '
      'conversation=${request.conversationId}, turn=${result.turnId}.',
    );
    await SyncWakeups.publishWorkspace(session, request.workspaceId);
    await SyncWakeups.publishConversationJob(session, result);
    return result;
  }

  Future<TurnSnapshot> getTurn(
    Session session, {
    required String userId,
    required GetTurnRequest request,
  }) async {
    await _requireMember(
      session,
      workspaceId: request.workspaceId,
      userId: userId,
    );
    final turn = await _repository.findTurnByStableId(
      session,
      workspaceId: request.workspaceId,
      turnId: request.turnId,
    );
    if (turn == null) _fail(ConversationErrorCode.notFound);
    final messages = await _repository.listMessages(session, turn: turn);
    final conversation = await _repository.findConversation(
      session,
      workspaceId: request.workspaceId,
      conversationId: turn.conversationId,
    );
    if (conversation == null) _fail(ConversationErrorCode.notFound);
    final toolCalls = await _repository.listToolCalls(session, turn: turn);
    return TurnSnapshot(
      turn: _turnView(turn, conversation.stableId, messages),
      messages: messages
          .map(
            (message) =>
                _messageView(message, conversation.stableId, turn.requestId),
          )
          .toList(),
      toolCalls: toolCalls
          .map((call) => _toolCallView(call, turn, messages))
          .toList(),
      terminal: ConversationStatuses.isTerminal(turn.status),
    );
  }

  Future<ConversationMutationResult> submitToolDecision(
    Session session, {
    required String userId,
    required SubmitToolDecisionRequest request,
  }) => session.db.transaction((transaction) async {
    _requireId(request.requestId);
    if (request.decision != 'approve' && request.decision != 'deny') {
      _fail(ConversationErrorCode.validationFailed);
    }
    final turn = await _requireTurnForMutation(
      session,
      userId: userId,
      workspaceId: request.workspaceId,
      turnId: request.turnId,
      expectedRevision: request.expectedTurnRevision,
      transaction: transaction,
      initiatorOnly: true,
    );
    final toolCall = await _repository.findToolCallByStableId(
      session,
      workspaceId: request.workspaceId,
      turnId: turn.id!,
      toolCallId: request.toolCallId,
      transaction: transaction,
    );
    if (toolCall == null) _fail(ConversationErrorCode.notFound);
    if (toolCall.argumentsDigest != request.argumentsDigest) {
      _fail(ConversationErrorCode.toolDecisionConflict);
    }
    if (toolCall.decision != null) {
      if (toolCall.decision != request.decision) {
        _fail(ConversationErrorCode.toolDecisionConflict);
      }
      return await _mutationResult(session, turn);
    }
    if (toolCall.status != 'pending') {
      _fail(ConversationErrorCode.toolDecisionConflict);
    }
    final arguments = request.editedArgumentsJson ?? toolCall.argumentsJson;
    _requireJsonObject(arguments);
    final argumentsDigest = base64UrlEncode(
      (await Sha256().hash(utf8.encode(arguments))).bytes,
    );
    final now = DateTime.now().toUtc();
    await ConversationToolCall.db.updateRow(
      session,
      toolCall.copyWith(
        argumentsJson: arguments,
        argumentsDigest: argumentsDigest,
        decision: request.decision,
        decisionByUserId: userId,
        decisionAt: now,
        status: request.decision == 'approve' ? 'approved' : 'denied',
        revision: toolCall.revision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    final updatedTurn = await ConversationTurn.db.updateRow(
      session,
      turn.copyWith(
        status: ConversationStatuses.queued,
        revision: turn.revision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await _insertJob(
      session,
      workspaceId: turn.workspaceId,
      conversationId: turn.conversationId,
      turnId: turn.id,
      requestId: request.requestId,
      kind: ConversationJobKinds.turn,
      payloadJson: conversation_repo.conversationTurnJobPayload(
        turn.initiatorUserId,
      ),
      now: now,
      transaction: transaction,
    );
    return _mutationResult(session, updatedTurn);
  });

  Future<ConversationMutationResult> cancelTurn(
    Session session, {
    required String userId,
    required CancelTurnRequest request,
  }) async {
    String? cancelledTurnId;
    final result = await session.db.transaction((transaction) async {
      _requireId(request.requestId);
      final turn = await _requireTurnForMutation(
        session,
        userId: userId,
        workspaceId: request.workspaceId,
        turnId: request.turnId,
        expectedRevision: request.expectedTurnRevision,
        transaction: transaction,
      );
      if (ConversationStatuses.isTerminal(turn.status) ||
          turn.cancellationRequestedAt != null) {
        return _mutationResult(session, turn);
      }
      final now = DateTime.now().toUtc();
      final updated = await ConversationTurn.db.updateRow(
        session,
        turn.copyWith(
          status: ConversationStatuses.cancelRequested,
          cancellationRequestedAt: now,
          revision: turn.revision + 1,
          updatedAt: now,
        ),
        transaction: transaction,
      );
      final queuedJobs = await ConversationJob.db.find(
        session,
        where: (table) =>
            table.workspaceId.equals(request.workspaceId) &
            table.turnId.equals(turn.id) &
            table.status.equals(ConversationJobStatuses.queued),
        transaction: transaction,
      );
      for (final job in queuedJobs) {
        await ConversationJob.db.updateRow(
          session,
          job.copyWith(
            status: ConversationJobStatuses.cancelled,
            updatedAt: now,
          ),
          transaction: transaction,
        );
      }
      final leasedJob = await ConversationJob.db.findFirstRow(
        session,
        where: (table) =>
            table.workspaceId.equals(request.workspaceId) &
            table.turnId.equals(turn.id) &
            table.status.equals(ConversationJobStatuses.leased),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (leasedJob != null) return _mutationResult(session, updated);
      final assistant = turn.assistantMessageId == null
          ? null
          : await ConversationMessage.db.findById(
              session,
              turn.assistantMessageId!,
              transaction: transaction,
              lockMode: LockMode.forUpdate,
            );
      if (assistant != null) {
        await ConversationMessage.db.updateRow(
          session,
          assistant.copyWith(
            content: '',
            status: ConversationStatuses.cancelled,
            metadataJson: '{"errorCode":"cancelled"}',
            revision: assistant.revision + 1,
            updatedAt: now,
          ),
          transaction: transaction,
        );
      }
      final cancelled = await ConversationTurn.db.updateRow(
        session,
        updated.copyWith(
          status: ConversationStatuses.cancelled,
          terminalAt: now,
          revision: updated.revision + 1,
          updatedAt: now,
        ),
        transaction: transaction,
      );
      cancelledTurnId = cancelled.requestId;
      return _mutationResult(session, cancelled);
    });
    if (cancelledTurnId != null) {
      await const LiveTurnBroker().publish(
        session,
        LiveTurnEvent(
          workspaceId: request.workspaceId,
          turnId: cancelledTurnId!,
          sequence: DateTime.now().toUtc().microsecondsSinceEpoch,
          kind: LiveTurnEventKind.cancelled,
        ),
      );
    }
    return result;
  }

  Future<ConversationMutationResult> compact(
    Session session, {
    required String userId,
    required CompactConversationRequest request,
  }) => session.db.transaction((transaction) async {
    _requireId(request.requestId);
    await _requireMember(
      session,
      workspaceId: request.workspaceId,
      userId: userId,
      transaction: transaction,
    );
    final conversation = await _repository.findConversationByStableId(
      session,
      workspaceId: request.workspaceId,
      conversationId: request.conversationId,
      transaction: transaction,
      lock: true,
    );
    if (conversation == null) _fail(ConversationErrorCode.notFound);
    final existing = await ConversationJob.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(request.workspaceId) &
          table.requestId.equals(request.requestId) &
          table.kind.equals(ConversationJobKinds.compact),
      transaction: transaction,
    );
    if (existing != null) {
      return ConversationMutationResult(
        conversationId: conversation.stableId,
        revision: conversation.revision,
        status: existing.status,
      );
    }
    if (conversation.revision != request.expectedConversationRevision) {
      _fail(ConversationErrorCode.staleRevision);
    }
    if (await _repository.hasActiveMutation(
      session,
      workspaceId: request.workspaceId,
      conversationId: conversation.id!,
      transaction: transaction,
    )) {
      _fail(ConversationErrorCode.turnConflict);
    }
    final now = DateTime.now().toUtc();
    await _insertJob(
      session,
      workspaceId: request.workspaceId,
      conversationId: conversation.id!,
      requestId: request.requestId,
      kind: ConversationJobKinds.compact,
      payloadJson: conversation_repo.conversationTurnJobPayload(userId),
      now: now,
      transaction: transaction,
    );
    final updated = await Conversation.db.updateRow(
      session,
      conversation.copyWith(
        revision: conversation.revision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    return ConversationMutationResult(
      conversationId: updated.stableId,
      revision: updated.revision,
      status: ConversationJobStatuses.queued,
    );
  });

  Future<ConversationTurn> _requireTurnForMutation(
    Session session, {
    required String userId,
    required int workspaceId,
    required String turnId,
    required int expectedRevision,
    required Transaction transaction,
    bool initiatorOnly = false,
  }) async {
    final member = await _requireMember(
      session,
      workspaceId: workspaceId,
      userId: userId,
      transaction: transaction,
    );
    final turn = await _repository.findTurnByStableId(
      session,
      workspaceId: workspaceId,
      turnId: turnId,
      transaction: transaction,
      lock: true,
    );
    if (turn == null) _fail(ConversationErrorCode.notFound);
    final canCancelAny =
        member.role == WorkspaceRoles.owner ||
        member.role == WorkspaceRoles.admin;
    if (turn.initiatorUserId != userId && (initiatorOnly || !canCancelAny)) {
      _fail(ConversationErrorCode.permissionDenied);
    }
    if (turn.revision != expectedRevision) {
      _fail(ConversationErrorCode.staleRevision);
    }
    return turn;
  }

  Future<WorkspaceMember> _requireMember(
    Session session, {
    required int workspaceId,
    required String userId,
    Transaction? transaction,
  }) async {
    final member = await WorkspaceMember.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.userId.equals(userId) &
          table.removedAt.equals(null),
      transaction: transaction,
    );
    if (member == null) _fail(ConversationErrorCode.permissionDenied);
    return member;
  }

  Future<void> _insertJob(
    Session session, {
    required int workspaceId,
    required int conversationId,
    required String requestId,
    required String kind,
    required DateTime now,
    required Transaction transaction,
    int? turnId,
    String? payloadJson,
  }) => ConversationJob.db
      .insertRow(
        session,
        ConversationJob(
          workspaceId: workspaceId,
          conversationId: conversationId,
          turnId: turnId,
          requestId: requestId,
          kind: kind,
          payloadJson: payloadJson,
          status: ConversationJobStatuses.queued,
          attempt: 0,
          maxAttempts: 3,
          availableAt: now,
          createdAt: now,
          updatedAt: now,
        ),
        transaction: transaction,
      )
      .then((_) {});

  Future<StartTurnResult> _startResult(
    Session session,
    ConversationTurn turn,
  ) async {
    final userMessage = await _repository.findMessage(
      session,
      workspaceId: turn.workspaceId,
      messageId: turn.userMessageId!,
    );
    final assistantMessage = await _repository.findMessage(
      session,
      workspaceId: turn.workspaceId,
      messageId: turn.assistantMessageId!,
    );
    if (userMessage == null || assistantMessage == null) {
      _fail(ConversationErrorCode.notFound);
    }
    return StartTurnResult(
      turnId: turn.requestId,
      userMessageId: userMessage.stableId,
      assistantMessageId: assistantMessage.stableId,
      acceptedSequence: turn.acceptedSequence,
      turnRevision: turn.revision,
      status: turn.status,
    );
  }

  Future<ConversationMutationResult> _mutationResult(
    Session session,
    ConversationTurn turn,
  ) async {
    final conversation = await _repository.findConversation(
      session,
      workspaceId: turn.workspaceId,
      conversationId: turn.conversationId,
    );
    if (conversation == null) _fail(ConversationErrorCode.notFound);
    return ConversationMutationResult(
      turnId: turn.requestId,
      conversationId: conversation.stableId,
      revision: turn.revision,
      status: turn.status,
    );
  }

  Future<Conversation> _requireConversation(
    Session session,
    int workspaceId,
    String conversationId,
  ) async {
    final conversation = await _repository.findConversationByStableId(
      session,
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
    if (conversation == null) _fail(ConversationErrorCode.notFound);
    return conversation;
  }

  Future<ConversationPage> _page(
    Session session, {
    required ListConversationsRequest request,
  }) async {
    final cursor = _decodeCursor(request.cursor);
    final conversations = await _repository.listConversations(
      session,
      workspaceId: request.workspaceId,
    );
    final ordered = conversations.toList()
      ..sort((left, right) {
        final date = right.updatedAt.compareTo(left.updatedAt);
        return date != 0 ? date : right.stableId.compareTo(left.stableId);
      });
    final filtered = cursor == null
        ? ordered
        : ordered.where((conversation) {
            final date = conversation.updatedAt.compareTo(cursor.updatedAt);
            return date < 0 ||
                (date == 0 &&
                    conversation.stableId.compareTo(cursor.stableId) < 0);
          }).toList();
    final hasMore = filtered.length > request.limit;
    final page = filtered.take(request.limit).toList();
    return ConversationPage(
      conversations: page.map(_summary).toList(),
      nextCursor: hasMore && page.isNotEmpty ? _encodeCursor(page.last) : null,
    );
  }

  _ConversationCursor? _decodeCursor(String? value) {
    if (value == null) return null;
    try {
      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(value))),
      );
      if (decoded is! Map<String, dynamic> ||
          decoded['updatedAt'] is! String ||
          decoded['stableId'] is! String) {
        _fail(ConversationErrorCode.validationFailed);
      }
      return _ConversationCursor(
        DateTime.parse(decoded['updatedAt'] as String).toUtc(),
        decoded['stableId'] as String,
      );
    } on FormatException {
      _fail(ConversationErrorCode.validationFailed);
    }
  }

  String _encodeCursor(Conversation conversation) => base64Url.encode(
    utf8.encode(
      jsonEncode({
        'updatedAt': conversation.updatedAt.toIso8601String(),
        'stableId': conversation.stableId,
      }),
    ),
  );

  Future<void> _validateReferences(
    Session session, {
    required int workspaceId,
    required String? modelId,
    required String? agentId,
    required String? parentConversationId,
    required Transaction transaction,
  }) async {
    if (modelId != null &&
        await _repository.resolveModelSelection(
              session,
              workspaceId: workspaceId,
              modelId: modelId,
              transaction: transaction,
            ) ==
            null) {
      _fail(ConversationErrorCode.validationFailed);
    }
    if (agentId != null &&
        !await _repository.resourceExists(
          session,
          workspaceId: workspaceId,
          kind: WorkspaceResourceKind.agent,
          resourceId: agentId,
          transaction: transaction,
        )) {
      _fail(ConversationErrorCode.validationFailed);
    }
    if (parentConversationId != null &&
        await _repository.findConversationByStableId(
              session,
              workspaceId: workspaceId,
              conversationId: parentConversationId,
              transaction: transaction,
            ) ==
            null) {
      _fail(ConversationErrorCode.validationFailed);
    }
  }

  Future<void> _validateStartTurnReferences(
    Session session, {
    required int workspaceId,
    required String? modelSelectionId,
    required String? agentId,
    required Transaction transaction,
  }) async {
    if (modelSelectionId != null) {
      final selection = await _repository.resolveModelSelection(
        session,
        workspaceId: workspaceId,
        modelId: modelSelectionId,
        transaction: transaction,
      );
      if (selection == null) _fail(ConversationErrorCode.validationFailed);
      await _validateReferences(
        session,
        workspaceId: workspaceId,
        modelId: null,
        agentId: agentId,
        parentConversationId: null,
        transaction: transaction,
      );
      return;
    }
    await _validateReferences(
      session,
      workspaceId: workspaceId,
      modelId: null,
      agentId: agentId,
      parentConversationId: null,
      transaction: transaction,
    );
  }

  Future<T> _mutate<T>(
    Session session, {
    required String userId,
    required int workspaceId,
    required String endpoint,
    required String requestId,
    required Map<String, dynamic> requestBody,
    required T Function(Map<String, dynamic>) decode,
    required Future<_Mutation<T>> Function(
      Transaction transaction,
      DateTime now,
    )
    run,
  }) => session.db.transaction((transaction) async {
    _requireId(requestId);
    final hash = base64UrlEncode(
      (await Sha256().hash(utf8.encode(jsonEncode(requestBody)))).bytes,
    );
    final receipt = await WorkspaceMutationReceipt.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.actorUserId.equals(userId) &
          table.scopeKey.equals('workspace:$workspaceId') &
          table.endpoint.equals(endpoint) &
          table.requestId.equals(requestId),
      transaction: transaction,
    );
    if (receipt != null) {
      if (receipt.requestHash != hash) {
        _fail(ConversationErrorCode.idempotencyConflict);
      }
      return decode(jsonDecode(receipt.responseJson) as Map<String, dynamic>);
    }
    await _requireMember(
      session,
      workspaceId: workspaceId,
      userId: userId,
      transaction: transaction,
    );
    final workspace = await CloudWorkspace.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(workspaceId) & table.deletedAt.equals(null),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (workspace == null) _fail(ConversationErrorCode.permissionDenied);
    final lockedReceipt = await WorkspaceMutationReceipt.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.actorUserId.equals(userId) &
          table.scopeKey.equals('workspace:$workspaceId') &
          table.endpoint.equals(endpoint) &
          table.requestId.equals(requestId),
      transaction: transaction,
    );
    if (lockedReceipt != null) {
      if (lockedReceipt.requestHash != hash) {
        _fail(ConversationErrorCode.idempotencyConflict);
      }
      return decode(
        jsonDecode(lockedReceipt.responseJson) as Map<String, dynamic>,
      );
    }
    final now = DateTime.now().toUtc();
    final mutation = await run(transaction, now);
    final sequence = workspace.sequence + 1;
    await CloudWorkspace.db.updateRow(
      session,
      workspace.copyWith(sequence: sequence, updatedAt: now),
      transaction: transaction,
    );
    await WorkspaceEvent.db.insertRow(
      session,
      WorkspaceEvent(
        eventId: const Uuid().v7(),
        workspaceId: workspaceId,
        sequence: sequence,
        actorUserId: userId,
        kind: mutation.operation,
        resourceKind: WorkspaceResourceKind.conversation.name,
        resourceId: mutation.resourceId,
        createdAt: now,
      ),
      transaction: transaction,
    );
    await WorkspaceAuditRecord.db.insertRow(
      session,
      WorkspaceAuditRecord(
        workspaceId: workspaceId,
        sequence: sequence,
        actorUserId: userId,
        operation: mutation.operation,
        targetKind: WorkspaceResourceKind.conversation.name,
        targetId: mutation.resourceId,
        createdAt: now,
      ),
      transaction: transaction,
    );
    await WorkspaceMutationReceipt.db.insertRow(
      session,
      WorkspaceMutationReceipt(
        workspaceId: workspaceId,
        actorUserId: userId,
        scopeKey: 'workspace:$workspaceId',
        endpoint: endpoint,
        requestId: requestId,
        requestHash: hash,
        responseJson: jsonEncode(mutation.value),
        createdAt: now,
      ),
      transaction: transaction,
    );
    return mutation.value as T;
  });

  ConversationSummary _summary(Conversation conversation) =>
      ConversationSummary(
        id: conversation.stableId,
        title: conversation.title ?? '',
        isPinned: conversation.isPinned,
        modelId: conversation.modelId,
        agentId: conversation.agentId,
        parentConversationId: conversation.parentConversationStableId,
        revision: conversation.revision,
        createdAt: conversation.createdAt,
        updatedAt: conversation.updatedAt,
      );

  ConversationMessageView _messageView(
    ConversationMessage message,
    String conversationId,
    String? turnId,
  ) => ConversationMessageView(
    id: message.stableId,
    conversationId: conversationId,
    turnId: turnId,
    role: message.role,
    kind: message.kind,
    status: message.status,
    content: message.content,
    metadataJson: message.metadataJson,
    toolCalls: const [],
    revision: message.revision,
    createdAt: message.createdAt,
    updatedAt: message.updatedAt,
  );

  ConversationTurnView _turnView(
    ConversationTurn turn,
    String conversationId,
    List<ConversationMessage> messages,
  ) => ConversationTurnView(
    id: turn.requestId,
    conversationId: conversationId,
    userMessageId: messages
        .where((message) => message.id == turn.userMessageId)
        .firstOrNull
        ?.stableId,
    assistantMessageId: messages
        .where((message) => message.id == turn.assistantMessageId)
        .firstOrNull
        ?.stableId,
    status: turn.status,
    revision: turn.revision,
    acceptedSequence: turn.acceptedSequence,
    cancellationRequestedAt: turn.cancellationRequestedAt,
    terminalAt: turn.terminalAt,
    createdAt: turn.createdAt,
    updatedAt: turn.updatedAt,
  );

  ConversationToolCallView _toolCallView(
    ConversationToolCall call,
    ConversationTurn turn,
    List<ConversationMessage> messages,
  ) => ConversationToolCallView(
    id: call.stableId,
    turnId: turn.requestId,
    messageId:
        messages
            .where((message) => message.id == call.messageId)
            .firstOrNull
            ?.stableId ??
        '',
    name: call.name,
    argumentsJson: call.argumentsJson,
    argumentsDigest: call.argumentsDigest,
    status: call.status,
    decision: call.decision,
    resultJson: call.resultJson,
    revision: call.revision,
    createdAt: call.createdAt,
    updatedAt: call.updatedAt,
  );

  void _validateMetadata(
    String? title,
    String? modelId,
    String? agentId, {
    bool allowNullTitle = false,
  }) {
    if ((!allowNullTitle || title != null) &&
        (title == null || title.trim().isEmpty || title.length > 500)) {
      _fail(ConversationErrorCode.validationFailed);
    }
    if (modelId != null) _requireId(modelId);
    if (agentId != null) _requireId(agentId);
  }

  void _requireId(String value) {
    if (value.trim().isEmpty || value.length > 200) {
      _fail(ConversationErrorCode.validationFailed);
    }
  }

  int _parseObjectId(String value) {
    final id = int.tryParse(value);
    if (id == null || id < 1) _fail(ConversationErrorCode.validationFailed);
    return id;
  }

  void _requireJsonObject(String value) {
    try {
      if (jsonDecode(value) is! Map<String, dynamic>) {
        _fail(ConversationErrorCode.validationFailed);
      }
    } on FormatException {
      _fail(ConversationErrorCode.validationFailed);
    }
  }

  Never _fail(ConversationErrorCode code) =>
      throw ConversationException(code: code);
}

class _ConversationCursor {
  const _ConversationCursor(this.updatedAt, this.stableId);

  final DateTime updatedAt;
  final String stableId;
}

class _Mutation<T> {
  const _Mutation(this.value, this.operation, this.resourceId);

  final T? value;
  final String operation;
  final String resourceId;
}
