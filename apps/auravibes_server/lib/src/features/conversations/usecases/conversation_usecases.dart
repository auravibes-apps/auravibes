import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../workspaces/domain/workspace_roles.dart';
import '../../sync/stream/sync_wakeups.dart';
import '../conversation_event_writer.dart';
import '../domain/conversation_values.dart';
import '../engine/conversation_host_effects.dart';

import '../repositories/conversation_repository.dart' as conversation_repo;

typedef ConversationJobPublisher =
    Future<void> Function(
      Session session,
      ConversationJob job,
    );

class ConversationUseCases {
  ConversationUseCases(
    this._repository, {
    ConversationJobPublisher? publishConversationJob,
  }) : _publishConversationJob =
           publishConversationJob ?? SyncWakeups.publishConversationJob;

  static const _maxAttachmentsPerTurn = 4;
  static const _maxAttachmentBytesPerTurn = maxAttachmentBytes * 2;

  final conversation_repo.ConversationRepository _repository;
  final ConversationJobPublisher _publishConversationJob;

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
            projectionRevision: 1,
            eventSequence: 0,
            executionState: 'idle',
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
    final job = await ConversationJob.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(request.workspaceId) &
          table.requestId.equals(result.turnId),
    );
    if (job != null) await _publishConversationJob(session, job);
    return result;
  }

  Future<ConversationMutationResult> continueTurn(
    Session session, {
    required String userId,
    required ContinueTurnRequest request,
  }) async {
    _requireId(request.requestId);
    final requestHash = jsonEncode({
      'conversationId': request.conversationId,
      'expectedRevision': request.expectedConversationRevision,
    });
    final result = await _mutate(
      session,
      userId: userId,
      workspaceId: request.workspaceId,
      endpoint: 'conversation.continueTurn',
      requestId: request.requestId,
      requestBody: request.toJson(),
      decode: ConversationMutationResult.fromJson,
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
          final replay = await _mutationResult(session, duplicate);
          return _Mutation(replay, 'turnContinued', request.conversationId);
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
          modelSelectionId: conversation.modelId,
          agentId: conversation.agentId,
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
        final turn = await _repository.insertContinuationTurn(
          session,
          conversation: conversation,
          actorUserId: userId,
          request: request,
          requestHash: requestHash,
          now: now,
          transaction: transaction,
        );
        final mutation = await _mutationResult(session, turn);
        return _Mutation(mutation, 'turnContinued', request.conversationId);
      },
    );
    session.log(
      'Conversation continuation queued: workspace=${request.workspaceId}, '
      'conversation=${request.conversationId}, turn=${result.turnId}.',
    );
    await SyncWakeups.publishWorkspace(session, request.workspaceId);
    final job = await ConversationJob.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(request.workspaceId) &
          table.requestId.equals(result.turnId),
    );
    if (job != null) await _publishConversationJob(session, job);
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

  Future<ConversationSnapshot> getConversationSnapshot(
    Session session, {
    required String userId,
    required GetConversationRequest request,
  }) async {
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
    final messages = await listMessages(
      session,
      userId: userId,
      request: ListConversationMessagesRequest(
        workspaceId: request.workspaceId,
        conversationId: request.conversationId,
        limit: 500,
      ),
    );
    final storedMessages = await _repository.listConversationMessages(
      session,
      workspaceId: request.workspaceId,
      conversationId: conversation.id!,
      limit: 500,
    );
    final messageViews = {for (final message in messages) message.id: message};
    final pendingMessages =
        storedMessages.where((message) => message.pendingOrder != null).toList()
          ..sort(
            (left, right) => left.pendingOrder!.compareTo(right.pendingOrder!),
          );
    final execution = conversation.activeExecutionId == null
        ? null
        : await ConversationExecution.db.findById(
            session,
            conversation.activeExecutionId!,
          );
    final assistant = execution?.assistantMessageId == null
        ? null
        : await ConversationMessage.db.findById(
            session,
            execution!.assistantMessageId!,
          );
    final turns = {
      for (final turn in await _repository.listTurns(
        session,
        workspaceId: request.workspaceId,
        turnIds: storedMessages
            .map((message) => message.turnId)
            .whereType<int>(),
      ))
        turn.id!: turn,
    };
    final toolCalls = await _repository.listToolCallsByTurnIds(
      session,
      workspaceId: request.workspaceId,
      turnIds: turns.keys,
    );
    return ConversationSnapshot(
      conversation: ConversationProjectionView(
        id: conversation.stableId,
        workspaceId: conversation.workspaceId,
        executionState: conversation.executionState,
        projectionRevision: conversation.projectionRevision,
        sequence: conversation.eventSequence,
        modelId: conversation.modelId,
        agentId: conversation.agentId,
        activeExecutionId: execution?.stableId,
        updatedAt: conversation.updatedAt,
      ),
      messages: messages,
      pendingMessages: [
        for (final message in pendingMessages)
          if (messageViews.containsKey(message.stableId))
            messageViews[message.stableId]!,
      ],
      activeExecution: execution == null
          ? null
          : ConversationExecutionView(
              id: execution.stableId,
              status: execution.status,
              attempt: execution.attempt,
              claimedMessageIds: List<String>.from(
                jsonDecode(execution.claimedMessageIdsJson) as List,
              ),
              assistantMessageId: assistant?.stableId,
              createdByUserId: execution.createdByUserId,
              createdAt: execution.createdAt,
              updatedAt: execution.updatedAt,
              terminalAt: execution.terminalAt,
            ),
      toolCalls: [
        for (final toolCall in toolCalls)
          if (turns[toolCall.turnId] case final turn?)
            _toolCallView(toolCall, turn, storedMessages),
      ],
      sequence: conversation.eventSequence,
    );
  }

  Future<ConversationSnapshot> queueConversationMessage(
    Session session, {
    required String userId,
    required QueueConversationMessageRequest request,
  }) async {
    _requireId(request.requestId);
    _requireId(request.conversationId);
    _requireId(request.clientMessageId);
    final content = request.content.trim();
    if ((content.isEmpty && request.attachmentIds.isEmpty) ||
        content.length > 100000 ||
        request.attachmentIds.length > _maxAttachmentsPerTurn) {
      _fail(ConversationErrorCode.validationFailed);
    }
    final attachmentIds = request.attachmentIds.map(_parseObjectId).toSet();
    await ConversationEventWriter().write(
      session,
      workspaceId: request.workspaceId,
      conversationId: request.conversationId,
      actorUserId: userId,
      requestId: request.requestId,
      kind: ConversationEventType.messageQueued,
      payloadJson: jsonEncode({'messageId': request.clientMessageId}),
      persist: (transaction, conversation, now) async {
        await _requireMember(
          session,
          workspaceId: request.workspaceId,
          userId: userId,
          transaction: transaction,
        );
        if (conversation.projectionRevision !=
            request.expectedProjectionRevision) {
          _fail(ConversationErrorCode.staleRevision);
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
        await _repository.insertPendingMessage(
          session,
          conversation: conversation,
          clientMessageId: request.clientMessageId,
          content: content,
          attachmentIds: attachmentIds.toList(),
          now: now,
          transaction: transaction,
        );
      },
      updateProjection: (conversation) => conversation,
    );
    return getConversationSnapshot(
      session,
      userId: userId,
      request: GetConversationRequest(
        workspaceId: request.workspaceId,
        conversationId: request.conversationId,
      ),
    );
  }

  Future<ConversationSnapshot> editPendingConversationMessage(
    Session session, {
    required String userId,
    required EditPendingConversationMessageRequest request,
  }) async {
    final content = request.content.trim();
    if (content.isEmpty || content.length > 100000) {
      _fail(ConversationErrorCode.validationFailed);
    }
    await ConversationEventWriter().write(
      session,
      workspaceId: request.workspaceId,
      conversationId: request.conversationId,
      actorUserId: userId,
      requestId: request.requestId,
      kind: ConversationEventType.messageEdited,
      payloadJson: jsonEncode({'messageId': request.messageId}),
      persist: (transaction, conversation, now) async {
        await _requireMember(
          session,
          workspaceId: request.workspaceId,
          userId: userId,
          transaction: transaction,
        );
        if (conversation.projectionRevision !=
            request.expectedProjectionRevision) {
          _fail(ConversationErrorCode.staleRevision);
        }
        final message = await _repository.findPendingMessage(
          session,
          workspaceId: request.workspaceId,
          conversationId: conversation.id!,
          messageId: request.messageId,
          transaction: transaction,
        );
        if (message == null) _fail(ConversationErrorCode.notFound);
        await ConversationMessage.db.updateRow(
          session,
          message.copyWith(
            content: content,
            revision: message.revision + 1,
            updatedAt: now,
          ),
          transaction: transaction,
        );
      },
      updateProjection: (conversation) => conversation,
    );
    return getConversationSnapshot(
      session,
      userId: userId,
      request: GetConversationRequest(
        workspaceId: request.workspaceId,
        conversationId: request.conversationId,
      ),
    );
  }

  Future<ConversationSnapshot> reorderPendingConversationMessage(
    Session session, {
    required String userId,
    required ReorderPendingConversationMessageRequest request,
  }) async {
    _requireId(request.requestId);
    _requireId(request.conversationId);
    _requireId(request.messageId);
    if (request.beforeMessageId == request.messageId) {
      _fail(ConversationErrorCode.validationFailed);
    }
    await ConversationEventWriter().write(
      session,
      workspaceId: request.workspaceId,
      conversationId: request.conversationId,
      actorUserId: userId,
      requestId: request.requestId,
      kind: ConversationEventType.messageReordered,
      payloadJson: jsonEncode({
        'messageId': request.messageId,
        'beforeMessageId': request.beforeMessageId,
      }),
      persist: (transaction, conversation, now) async {
        await _requireMember(
          session,
          workspaceId: request.workspaceId,
          userId: userId,
          transaction: transaction,
        );
        if (conversation.projectionRevision !=
            request.expectedProjectionRevision) {
          _fail(ConversationErrorCode.staleRevision);
        }
        final pendingMessages = await _repository.listPendingMessages(
          session,
          workspaceId: request.workspaceId,
          conversationId: conversation.id!,
          transaction: transaction,
        );
        final messageIndex = pendingMessages.indexWhere(
          (message) => message.stableId == request.messageId,
        );
        if (messageIndex < 0) _fail(ConversationErrorCode.notFound);
        final message = pendingMessages.removeAt(messageIndex);
        if (request.beforeMessageId case final beforeMessageId?) {
          final beforeIndex = pendingMessages.indexWhere(
            (candidate) => candidate.stableId == beforeMessageId,
          );
          if (beforeIndex < 0) _fail(ConversationErrorCode.notFound);
          pendingMessages.insert(beforeIndex, message);
        } else {
          pendingMessages.add(message);
        }
        for (var index = 0; index < pendingMessages.length; index++) {
          final pending = pendingMessages[index];
          final pendingOrder = index + 1;
          if (pending.pendingOrder != pendingOrder) {
            await ConversationMessage.db.updateRow(
              session,
              pending.copyWith(pendingOrder: pendingOrder, updatedAt: now),
              transaction: transaction,
            );
          }
        }
      },
      updateProjection: (conversation) => conversation,
    );
    return getConversationSnapshot(
      session,
      userId: userId,
      request: GetConversationRequest(
        workspaceId: request.workspaceId,
        conversationId: request.conversationId,
      ),
    );
  }

  Future<ConversationSnapshot> continueConversation(
    Session session, {
    required String userId,
    required ContinueConversationRequest request,
    int? parentTurnId,
  }) async {
    _requireId(request.requestId);
    _requireId(request.conversationId);
    final duplicateEvent = await ConversationEvent.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(request.workspaceId) &
          table.requestId.equals(request.requestId),
    );
    if (duplicateEvent != null) {
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
      final payload = jsonDecode(duplicateEvent.payloadJson) as Map;
      final executionId = payload['executionId'];
      if (duplicateEvent.kind != ConversationEventType.executionStarted ||
          duplicateEvent.conversationId != conversation.id ||
          executionId is! String) {
        _fail(ConversationErrorCode.idempotencyConflict);
      }
      final duplicateExecution = await ConversationExecution.db.findFirstRow(
        session,
        where: (table) =>
            table.workspaceId.equals(request.workspaceId) &
            table.stableId.equals(executionId),
      );
      if (duplicateExecution == null ||
          duplicateExecution.conversationId != conversation.id) {
        _fail(ConversationErrorCode.idempotencyConflict);
      }
      return getConversationSnapshot(
        session,
        userId: userId,
        request: GetConversationRequest(
          workspaceId: request.workspaceId,
          conversationId: request.conversationId,
        ),
      );
    }
    final executionId = const Uuid().v7();
    late ConversationExecution execution;
    late int executionDatabaseId;
    late ConversationJob job;
    try {
      await ConversationEventWriter().write(
        session,
        workspaceId: request.workspaceId,
        conversationId: request.conversationId,
        actorUserId: userId,
        requestId: request.requestId,
        kind: ConversationEventType.executionStarted,
        payloadJson: jsonEncode({
          'requestId': request.requestId,
          'executionId': executionId,
        }),
        guard: parentTurnId == null
            ? null
            : (transaction) => _requireActiveParentTurn(
                session,
                workspaceId: request.workspaceId,
                parentTurnId: parentTurnId,
                transaction: transaction,
              ),
        persist: (transaction, conversation, now) async {
          await _requireMember(
            session,
            workspaceId: request.workspaceId,
            userId: userId,
            transaction: transaction,
          );
          final duplicateEvent = await ConversationEvent.db.findFirstRow(
            session,
            where: (table) =>
                table.workspaceId.equals(request.workspaceId) &
                table.requestId.equals(request.requestId),
            transaction: transaction,
          );
          if (duplicateEvent != null) {
            final payload = jsonDecode(duplicateEvent.payloadJson) as Map;
            final duplicateExecutionId = payload['executionId'];
            if (duplicateEvent.kind != ConversationEventType.executionStarted ||
                duplicateEvent.conversationId != conversation.id ||
                duplicateExecutionId is! String) {
              _fail(ConversationErrorCode.idempotencyConflict);
            }
            final duplicateExecution = await ConversationExecution.db
                .findFirstRow(
                  session,
                  where: (table) =>
                      table.workspaceId.equals(request.workspaceId) &
                      table.stableId.equals(duplicateExecutionId),
                  transaction: transaction,
                );
            if (duplicateExecution == null ||
                duplicateExecution.conversationId != conversation.id) {
              _fail(ConversationErrorCode.idempotencyConflict);
            }
            throw const _ContinueConversationReplay();
          }
          if (conversation.projectionRevision !=
              request.expectedProjectionRevision) {
            _fail(ConversationErrorCode.staleRevision);
          }
          if (conversation.executionState != 'idle' &&
              conversation.executionState != ConversationStatuses.failed) {
            _fail(ConversationErrorCode.turnConflict);
          }
          final pendingMessages = await _repository.listPendingMessages(
            session,
            workspaceId: request.workspaceId,
            conversationId: conversation.id!,
            transaction: transaction,
          );
          execution = await ConversationExecution.db.insertRow(
            session,
            ConversationExecution(
              workspaceId: request.workspaceId,
              conversationId: conversation.id!,
              stableId: executionId,
              status: ConversationStatuses.running,
              settingsJson: jsonEncode({
                'modelId': conversation.modelId,
                'agentId': conversation.agentId,
                'parentTurnId': ?parentTurnId,
              }),
              claimedMessageIdsJson: pendingMessages.isEmpty
                  ? jsonEncode(const <String>[])
                  : jsonEncode(
                      pendingMessages
                          .map((message) => message.stableId)
                          .toList(),
                    ),
              attempt: 0,
              createdByUserId: userId,
              createdAt: now,
              updatedAt: now,
            ),
            transaction: transaction,
          );
          executionDatabaseId = execution.id!;
          final assistant = await ConversationMessage.db.insertRow(
            session,
            ConversationMessage(
              workspaceId: request.workspaceId,
              conversationId: conversation.id!,
              stableId: const Uuid().v7(),
              role: 'assistant',
              kind: 'text',
              status: ConversationStatuses.running,
              content: '',
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
            transaction: transaction,
          );
          execution = await ConversationExecution.db.updateRow(
            session,
            execution.copyWith(assistantMessageId: assistant.id),
            transaction: transaction,
          );
          final turn = await ConversationTurn.db.insertRow(
            session,
            ConversationTurn(
              workspaceId: request.workspaceId,
              conversationId: conversation.id!,
              requestId: execution.stableId,
              requestHash: jsonEncode({'executionId': execution.stableId}),
              initiatorUserId: userId,
              userMessageId: pendingMessages.isEmpty
                  ? null
                  : pendingMessages.first.id,
              assistantMessageId: assistant.id,
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
            assistant.copyWith(turnId: turn.id),
            transaction: transaction,
          );
          for (final message in pendingMessages) {
            final metadata = message.metadataJson == null
                ? <String, dynamic>{}
                : Map<String, dynamic>.from(
                    jsonDecode(message.metadataJson!) as Map,
                  );
            metadata['modelSelectionId'] = conversation.modelId;
            await ConversationMessage.db.updateRow(
              session,
              message.copyWith(
                turnId: turn.id,
                pendingOrder: null,
                pendingAt: null,
                status: ConversationStatuses.running,
                metadataJson: jsonEncode(metadata),
                revision: message.revision + 1,
                updatedAt: now,
              ),
              transaction: transaction,
            );
          }
          job = await ConversationJob.db.insertRow(
            session,
            ConversationJob(
              workspaceId: request.workspaceId,
              conversationId: conversation.id!,
              turnId: turn.id,
              requestId: execution.stableId,
              kind: ConversationJobKinds.turn,
              status: ConversationJobStatuses.queued,
              payloadJson: conversation_repo.conversationTurnJobPayload(
                userId,
                executionId: execution.stableId,
                parentTurnId: parentTurnId,
              ),
              attempt: 0,
              maxAttempts: 3,
              availableAt: now,
              createdAt: now,
              updatedAt: now,
            ),
            transaction: transaction,
          );
        },
        updateProjection: (conversation) => conversation.copyWith(
          executionState: ConversationStatuses.running,
          activeExecutionId: executionDatabaseId,
        ),
      );
    } on _ContinueConversationReplay {
      return getConversationSnapshot(
        session,
        userId: userId,
        request: GetConversationRequest(
          workspaceId: request.workspaceId,
          conversationId: request.conversationId,
        ),
      );
    }
    await _publishConversationJob(session, job);
    return getConversationSnapshot(
      session,
      userId: userId,
      request: GetConversationRequest(
        workspaceId: request.workspaceId,
        conversationId: request.conversationId,
      ),
    );
  }

  Future<ConversationSnapshot> stopConversation(
    Session session, {
    required String userId,
    required StopConversationRequest request,
  }) async {
    _requireId(request.requestId);
    _requireId(request.conversationId);
    await ConversationEventWriter().write(
      session,
      workspaceId: request.workspaceId,
      conversationId: request.conversationId,
      actorUserId: userId,
      requestId: request.requestId,
      kind: ConversationEventType.executionStopped,
      payloadJson: jsonEncode({'requestId': request.requestId}),
      persist: (transaction, conversation, now) async {
        await _requireMember(
          session,
          workspaceId: request.workspaceId,
          userId: userId,
          transaction: transaction,
        );
        if (conversation.projectionRevision !=
            request.expectedProjectionRevision) {
          _fail(ConversationErrorCode.staleRevision);
        }
        final executionId = conversation.activeExecutionId;
        if (executionId == null ||
            (conversation.executionState != ConversationStatuses.running &&
                conversation.executionState !=
                    ConversationStatuses.awaitingApproval)) {
          _fail(ConversationErrorCode.turnConflict);
        }
        final execution = await ConversationExecution.db.findById(
          session,
          executionId,
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (execution == null) _fail(ConversationErrorCode.notFound);
        final turn = await ConversationTurn.db.findFirstRow(
          session,
          where: (table) =>
              table.workspaceId.equals(request.workspaceId) &
              table.requestId.equals(execution.stableId),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (turn != null && !ConversationStatuses.isTerminal(turn.status)) {
          await ConversationTurn.db.updateRow(
            session,
            turn.copyWith(
              cancellationRequestedAt: now,
              revision: turn.revision + 1,
              updatedAt: now,
            ),
            transaction: transaction,
          );
        }
        await ConversationJob.db.updateWhere(
          session,
          where: (table) =>
              table.workspaceId.equals(request.workspaceId) &
              table.requestId.equals(execution.stableId) &
              table.status.equals(ConversationJobStatuses.queued),
          columnValues: (table) => [
            table.status(ConversationJobStatuses.cancelled),
            table.updatedAt(now),
          ],
          transaction: transaction,
        );
        await ConversationExecution.db.updateRow(
          session,
          execution.copyWith(
            status: ConversationStatuses.cancelled,
            terminalAt: now,
            updatedAt: now,
          ),
          transaction: transaction,
        );
        if (execution.assistantMessageId case final assistantMessageId?) {
          final assistant = await ConversationMessage.db.findById(
            session,
            assistantMessageId,
            transaction: transaction,
            lockMode: LockMode.forUpdate,
          );
          if (assistant != null) {
            await ConversationMessage.db.updateRow(
              session,
              assistant.copyWith(
                status: ConversationStatuses.cancelled,
                revision: assistant.revision + 1,
                updatedAt: now,
              ),
              transaction: transaction,
            );
          }
        }
      },
      updateProjection: (conversation) => conversation.copyWith(
        executionState: 'idle',
        activeExecutionId: null,
      ),
    );
    return getConversationSnapshot(
      session,
      userId: userId,
      request: GetConversationRequest(
        workspaceId: request.workspaceId,
        conversationId: request.conversationId,
      ),
    );
  }

  Future<ConversationSnapshot> removePendingConversationMessage(
    Session session, {
    required String userId,
    required RemovePendingConversationMessageRequest request,
  }) async {
    _requireId(request.requestId);
    _requireId(request.conversationId);
    _requireId(request.messageId);
    await ConversationEventWriter().write(
      session,
      workspaceId: request.workspaceId,
      conversationId: request.conversationId,
      actorUserId: userId,
      requestId: request.requestId,
      kind: ConversationEventType.messageRemoved,
      payloadJson: jsonEncode({'messageId': request.messageId}),
      persist: (transaction, conversation, now) async {
        await _requireMember(
          session,
          workspaceId: request.workspaceId,
          userId: userId,
          transaction: transaction,
        );
        if (conversation.projectionRevision !=
            request.expectedProjectionRevision) {
          _fail(ConversationErrorCode.staleRevision);
        }
        final message = await _repository.findPendingMessage(
          session,
          workspaceId: request.workspaceId,
          conversationId: conversation.id!,
          messageId: request.messageId,
          transaction: transaction,
        );
        if (message == null) _fail(ConversationErrorCode.notFound);
        await ConversationMessage.db.deleteRow(
          session,
          message,
          transaction: transaction,
        );
      },
      updateProjection: (conversation) => conversation,
    );
    return getConversationSnapshot(
      session,
      userId: userId,
      request: GetConversationRequest(
        workspaceId: request.workspaceId,
        conversationId: request.conversationId,
      ),
    );
  }

  Future<ConversationSnapshot> updateConversationSettings(
    Session session, {
    required String userId,
    required UpdateConversationSettingsRequest request,
  }) async {
    _requireId(request.requestId);
    _requireId(request.conversationId);
    await ConversationEventWriter().write(
      session,
      workspaceId: request.workspaceId,
      conversationId: request.conversationId,
      actorUserId: userId,
      requestId: request.requestId,
      kind: ConversationEventType.settingsChanged,
      payloadJson: jsonEncode({
        'modelId': request.modelId,
        'agentId': request.agentId,
      }),
      persist: (transaction, conversation, _) async {
        await _requireMember(
          session,
          workspaceId: request.workspaceId,
          userId: userId,
          transaction: transaction,
        );
        if (conversation.projectionRevision !=
            request.expectedProjectionRevision) {
          _fail(ConversationErrorCode.staleRevision);
        }
        await _validateReferences(
          session,
          workspaceId: request.workspaceId,
          modelId: request.modelId,
          agentId: request.agentId,
          parentConversationId: null,
          transaction: transaction,
        );
      },
      updateProjection: (conversation) => conversation.copyWith(
        modelId: request.modelId,
        agentId: request.agentId,
      ),
    );
    return getConversationSnapshot(
      session,
      userId: userId,
      request: GetConversationRequest(
        workspaceId: request.workspaceId,
        conversationId: request.conversationId,
      ),
    );
  }

  Future<ConversationMutationResult> submitToolDecision(
    Session session, {
    required String userId,
    required SubmitToolDecisionRequest request,
  }) async {
    String? conversationId;
    ConversationJob? job;
    final result = await _mutate(
      session,
      userId: userId,
      workspaceId: request.workspaceId,
      endpoint: 'conversation.submitToolDecision',
      requestId: request.requestId,
      requestBody: request.toJson(),
      decode: ConversationMutationResult.fromJson,
      run: (transaction, now) async {
        _requireId(request.requestId);
        if (request.decision != 'approve' && request.decision != 'deny') {
          _fail(ConversationErrorCode.validationFailed);
        }
        if (request.stopAll && request.decision != 'deny') {
          _fail(ConversationErrorCode.validationFailed);
        }
        final turn = await _requireTurnForMutation(
          session,
          userId: userId,
          workspaceId: request.workspaceId,
          turnId: request.turnId,
          transaction: transaction,
          initiatorOnly: false,
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
        final decisionAlreadyRecorded = toolCall.decision != null;
        if (decisionAlreadyRecorded) {
          if (toolCall.decision != request.decision) {
            _fail(ConversationErrorCode.toolDecisionConflict);
          }
          if (!request.stopAll) {
            return _Mutation(
              await _mutationResult(session, turn),
              'toolDecisionRecorded',
              request.turnId,
            );
          }
        }
        if (turn.status != ConversationStatuses.awaitingApproval) {
          _fail(ConversationErrorCode.toolDecisionConflict);
        }
        if (!decisionAlreadyRecorded &&
            turn.revision != request.expectedTurnRevision) {
          _fail(ConversationErrorCode.staleRevision);
        }
        if (!decisionAlreadyRecorded && toolCall.status != 'pending') {
          _fail(ConversationErrorCode.toolDecisionConflict);
        }
        if (!decisionAlreadyRecorded) {
          final arguments =
              request.editedArgumentsJson ?? toolCall.argumentsJson;
          _requireJsonObject(arguments);
          final argumentsDigest = base64UrlEncode(
            (await Sha256().hash(utf8.encode(arguments))).bytes,
          );
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
        }
        if (request.stopAll) {
          final pendingCalls = await ConversationToolCall.db.find(
            session,
            where: (table) =>
                table.workspaceId.equals(request.workspaceId) &
                table.turnId.equals(turn.id) &
                table.status.equals('pending'),
            transaction: transaction,
            lockMode: LockMode.forUpdate,
          );
          for (final pendingCall in pendingCalls) {
            await ConversationToolCall.db.updateRow(
              session,
              pendingCall.copyWith(
                decision: 'deny',
                decisionByUserId: userId,
                decisionAt: now,
                status: 'denied',
                revision: pendingCall.revision + 1,
                updatedAt: now,
              ),
              transaction: transaction,
            );
          }
        }
        final pendingCalls = await ConversationToolCall.db.find(
          session,
          where: (table) =>
              table.workspaceId.equals(request.workspaceId) &
              table.turnId.equals(turn.id) &
              table.status.equals('pending'),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        final shouldResume = !request.stopAll && pendingCalls.isEmpty;
        final updatedTurn = await ConversationTurn.db.updateRow(
          session,
          turn.copyWith(
            status: shouldResume
                ? ConversationStatuses.queued
                : (request.stopAll
                      ? ConversationStatuses.cancelled
                      : ConversationStatuses.awaitingApproval),
            terminalAt: request.stopAll ? now : null,
            revision: turn.revision + 1,
            updatedAt: now,
          ),
          transaction: transaction,
        );
        final conversation = await Conversation.db.findFirstRow(
          session,
          where: (table) =>
              table.id.equals(turn.conversationId) &
              table.workspaceId.equals(request.workspaceId) &
              table.deletedAt.equals(null),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (conversation == null) _fail(ConversationErrorCode.notFound);
        conversationId = conversation.stableId;
        final execution = conversation.activeExecutionId == null
            ? null
            : await ConversationExecution.db.findById(
                session,
                conversation.activeExecutionId!,
                transaction: transaction,
                lockMode: LockMode.forUpdate,
              );
        final projection = await Conversation.db.updateRow(
          session,
          conversation.copyWith(
            eventSequence: conversation.eventSequence + 1,
            projectionRevision: conversation.projectionRevision + 1,
            executionState: shouldResume
                ? 'running'
                : (request.stopAll
                      ? 'idle'
                      : ConversationStatuses.awaitingApproval),
            activeExecutionId: shouldResume || !request.stopAll
                ? conversation.activeExecutionId
                : null,
            updatedAt: now,
          ),
          transaction: transaction,
        );
        if (execution != null) {
          await ConversationExecution.db.updateRow(
            session,
            execution.copyWith(
              status: shouldResume
                  ? 'running'
                  : (request.stopAll
                        ? 'cancelled'
                        : ConversationStatuses.awaitingApproval),
              terminalAt: request.stopAll ? now : null,
              updatedAt: now,
            ),
            transaction: transaction,
          );
        }
        if (request.stopAll) {
          final awaitingApprovalAssistants = await ConversationMessage.db.find(
            session,
            where: (table) =>
                table.workspaceId.equals(request.workspaceId) &
                table.turnId.equals(turn.id) &
                table.role.equals('assistant') &
                table.status.equals(ConversationStatuses.awaitingApproval),
            transaction: transaction,
            lockMode: LockMode.forUpdate,
          );
          for (final assistant in awaitingApprovalAssistants) {
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
        }
        await ConversationEvent.db.insertRow(
          session,
          ConversationEvent(
            workspaceId: request.workspaceId,
            conversationId: conversation.id!,
            sequence: projection.eventSequence,
            eventId: const Uuid().v7(),
            actorUserId: userId,
            requestId: request.requestId,
            kind: ConversationEventType.toolDecisionRecorded,
            payloadJson: jsonEncode({
              'toolCallId': request.toolCallId,
              'decision': request.decision,
              'stopAll': request.stopAll,
              'executionId': execution?.stableId,
            }),
            createdAt: now,
          ),
          transaction: transaction,
        );
        if (shouldResume) {
          job = await _insertJob(
            session,
            workspaceId: turn.workspaceId,
            conversationId: turn.conversationId,
            turnId: turn.id,
            requestId: request.requestId,
            kind: ConversationJobKinds.turn,
            payloadJson: conversation_repo.conversationTurnJobPayload(
              turn.initiatorUserId,
              executionId: execution?.stableId,
              parentTurnId: execution == null
                  ? null
                  : conversation_repo
                        .conversationParentTurnIdForExecutionSettings(
                          execution.settingsJson,
                        ),
            ),
            now: now,
            transaction: transaction,
          );
        }
        return _Mutation(
          await _mutationResult(session, updatedTurn),
          'toolDecisionRecorded',
          conversation.stableId,
        );
      },
    );
    if (job != null) await _publishConversationJob(session, job!);
    if (conversationId != null) {
      await SyncWakeups.publishConversation(
        session,
        workspaceId: request.workspaceId,
        conversationId: conversationId!,
      );
    }
    return result;
  }

  Future<ConversationMutationResult> cancelTurn(
    Session session, {
    required String userId,
    required CancelTurnRequest request,
  }) async {
    String? cancelledConversationId;
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
      final conversation = await Conversation.db.findById(
        session,
        cancelled.conversationId,
        transaction: transaction,
      );
      cancelledConversationId = conversation?.stableId;
      return _mutationResult(session, cancelled);
    });
    if (cancelledConversationId != null) {
      await SyncWakeups.publishConversation(
        session,
        workspaceId: request.workspaceId,
        conversationId: cancelledConversationId!,
      );
    }
    return result;
  }

  Future<ConversationMutationResult> compact(
    Session session, {
    required String userId,
    required CompactConversationRequest request,
  }) async {
    late ConversationJob job;
    final result = await session.db.transaction((transaction) async {
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
        job = existing;
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
      job = await _insertJob(
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
    await _publishConversationJob(session, job);
    return result;
  }

  Future<void> _requireActiveParentTurn(
    Session session, {
    required int workspaceId,
    required int parentTurnId,
    required Transaction transaction,
  }) async {
    final parent = await _repository.findTurn(
      session,
      workspaceId: workspaceId,
      turnId: parentTurnId,
      transaction: transaction,
      lock: true,
    );
    if (parent == null ||
        parent.cancellationRequestedAt != null ||
        ConversationStatuses.isTerminal(parent.status)) {
      throw const ConversationCancelledException();
    }
  }

  Future<ConversationTurn> _requireTurnForMutation(
    Session session, {
    required String userId,
    required int workspaceId,
    required String turnId,
    int? expectedRevision,
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
    if (expectedRevision != null && turn.revision != expectedRevision) {
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

  Future<ConversationJob> _insertJob(
    Session session, {
    required int workspaceId,
    required int conversationId,
    required String requestId,
    required String kind,
    required DateTime now,
    required Transaction transaction,
    int? turnId,
    String? payloadJson,
  }) => ConversationJob.db.insertRow(
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
  );

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

class _ContinueConversationReplay {
  const _ContinueConversationReplay();
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
