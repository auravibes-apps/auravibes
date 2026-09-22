import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show
        A2uiChatContract,
        a2uiChatFormSubmitActionName,
        a2uiChatFormSubmitComponentId;
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../workspaces/domain/workspace_roles.dart';
import '../../sync/stream/sync_wakeups.dart';
import '../conversation_event_writer.dart';
import '../domain/conversation_values.dart';
import '../engine/conversation_host_effects.dart';
import '../engine/a2ui_protocol.dart';

import '../repositories/conversation_repository.dart' as conversation_repo;

typedef ConversationJobPublisher = Future<void> Function(
  Session session,
  ConversationJob job,
);

typedef _DeletionForkContext = ({
  String rootConversationId,
  int workspaceId,
  String userId,
  String requestId,
  Map<String, String?> frozenForkBoundaries,
  List<String> deletedConversationIds,
});

typedef _ForkMaterializationContext = ({
  Conversation source,
  Conversation fork,
  String actorUserId,
  String requestId,
  DateTime now,
  Transaction transaction,
  String? boundaryOverride,
  bool boundaryWasCaptured,
});

typedef _ForkCopies = ({
  List<ConversationMessage> sourceMessages,
  List<ConversationMessage> targetMessages,
  Map<int, int> turnIds,
  Map<int, int> messageIds,
  Map<String, String> stableMessageIds,
});

class ConversationUseCases {
  new(
    this._repository, {
    ConversationJobPublisher? publishConversationJob,
  }) : _publishConversationJob =
           publishConversationJob ?? SyncWakeups.publishConversationJob;

  static const _maxAttachmentsPerTurn = 4;
  static const _maxAttachmentBytesPerTurn = maxAttachmentBytes * 2;
  static const _transientMessageStatuses = {
    ConversationStatuses.queued,
    ConversationStatuses.running,
    ConversationStatuses.awaitingApproval,
    ConversationStatuses.awaitingUserAction,
    ConversationStatuses.cancelRequested,
  };
  static const _transientToolCallStatuses = {
    'pending',
    'needsConfirmation',
    'approved',
    'granted',
    'running',
  };
  static const _cancelledMessageMetadata = '{"errorCode":"cancelled"}';
  static const _subAgentCancelledMessage = 'Sub-agent cancelled.';

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
      if (request.isPinned) {
        await _ensurePinnedCapacity(
          session,
          workspaceId: request.workspaceId,
          transaction: transaction,
        );
      }
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

  Future<ConversationSummary> fork(
    Session session, {
    required String userId,
    required ForkConversationRequest request,
  }) => _mutate(
    session,
    userId: userId,
    workspaceId: request.workspaceId,
    endpoint: 'conversation.fork',
    requestId: request.requestId,
    requestBody: request.toJson(),
    decode: ConversationSummary.fromJson,
    run: (transaction, now) async {
      _requireId(request.requestId);
      _requireId(request.sourceConversationId);
      _requireId(request.forkConversationId);
      final source = await _repository.findConversationByStableId(
        session,
        workspaceId: request.workspaceId,
        conversationId: request.sourceConversationId,
        transaction: transaction,
        lock: true,
      );
      if (source == null) _fail(ConversationErrorCode.notFound);
      final existing = await _repository.findConversationByStableId(
        session,
        workspaceId: request.workspaceId,
        conversationId: request.forkConversationId,
        transaction: transaction,
        lock: true,
      );
      if (existing != null) _fail(ConversationErrorCode.idempotencyConflict);
      final effectiveMessages = await _effectiveMessages(
        session,
        source: source,
        transaction: transaction,
      );
      final sourceMessages = await _durableMessages(
        session,
        messages: effectiveMessages,
        workspaceId: source.workspaceId,
        transaction: transaction,
      );
      final boundary =
          request.throughMessageId ??
          await _automaticForkBoundary(
            session,
            source: source,
            messages: effectiveMessages,
            durableMessages: sourceMessages,
            transaction: transaction,
          );
      if (boundary == null) _fail(ConversationErrorCode.validationFailed);
      if (request.throughMessageId != null &&
          !sourceMessages.any(
            (message) => message.stableId == request.throughMessageId,
          )) {
        _fail(ConversationErrorCode.validationFailed);
      }
      final title = await _copyConversationTitle(
        session,
        workspaceId: request.workspaceId,
        source: source,
        transaction: transaction,
        suffix: 'Fork',
      );
      final fork = await Conversation.db.insertRow(
        session,
        Conversation(
          workspaceId: request.workspaceId,
          stableId: request.forkConversationId,
          title: title,
          isPinned: false,
          modelId: source.modelId,
          agentId: source.agentId,
          forkSourceConversationId: source.stableId,
          forkSourceTitle: source.title,
          forkThroughMessageId: boundary,
          revision: 1,
          projectionRevision: 1,
          eventSequence: 0,
          executionState: 'idle',
          createdAt: now,
          updatedAt: now,
        ),
        transaction: transaction,
      );
      await _copyConversationResources(
        session,
        workspaceId: request.workspaceId,
        source: source,
        fork: fork,
        transaction: transaction,
      );
      final summary = _summary(fork);
      return _Mutation(summary, 'created', summary.id);
    },
  );

  Future<List<ConversationSummary>> list(
    Session session, {
    required String userId,
    required ListConversationsRequest request,
  }) async {
    if (request.limit < 1 || request.limit > 100 || (request.offset ?? 0) < 0) {
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
    if (request.limit < 1 || request.limit > 100 || (request.offset ?? 0) < 0) {
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
    final allMessages = await _effectiveMessages(
      session,
      source: conversation,
    );
    final messages = allMessages.length <= request.limit
        ? allMessages
        : allMessages.skip(allMessages.length - request.limit).toList();
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
    final messageIds = messages
        .map((message) => message.id)
        .whereType<int>()
        .toSet();
    for (final call in await _repository.listToolCallsByTurnIds(
      session,
      workspaceId: request.workspaceId,
      turnIds: turns.keys,
    )) {
      if (!messageIds.contains(call.messageId)) continue;
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
        isForkReference: message.conversationId != conversation.id,
        metadataJson: cloudA2uiMetadataForClient(
          message.metadataJson,
          cloudA2uiComponentsForClient(
            request.a2uiSupportedComponents,
            isChildConversation:
                conversation.parentConversationStableId != null,
          ),
        ),
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
      if (request.isPinned == true && !conversation.isPinned) {
        await _ensurePinnedCapacity(
          session,
          workspaceId: request.workspaceId,
          transaction: transaction,
        );
      }
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
      final hiddenDescendants = await _lockHiddenDescendants(
        session,
        root: conversation,
        transaction: transaction,
      );
      final frozenForkBoundaries = await _captureForkBoundariesForDelete(
        session,
        source: conversation,
        transaction: transaction,
      );
      final deletedConversationIds = <String>[
        conversation.stableId,
        ...hiddenDescendants.map((child) => child.stableId),
      ];
      await _cancelDeletionConversations(
        session,
        conversations: [conversation, ...hiddenDescendants],
        now: now,
        transaction: transaction,
      );
      await _materializeDeletionForks(
        session,
        context: (
          rootConversationId: conversation.stableId,
          workspaceId: request.workspaceId,
          userId: userId,
          requestId: request.requestId,
          frozenForkBoundaries: frozenForkBoundaries,
          deletedConversationIds: deletedConversationIds,
        ),
        now: now,
        transaction: transaction,
      );
      await _purgeDeletionConversations(
        session,
        root: conversation,
        hiddenDescendants: hiddenDescendants,
        transaction: transaction,
      );
      return _Mutation<void>(
        null,
        'deleted',
        request.conversationId,
        affectedConversationIds: deletedConversationIds,
      );
    },
  );

  Future<void> _cancelDeletionConversations(
    Session session, {
    required Iterable<Conversation> conversations,
    required DateTime now,
    required Transaction transaction,
  }) async {
    for (final conversation in conversations) {
      await _cancelForDeletion(
        session,
        conversation: conversation,
        now: now,
        transaction: transaction,
      );
    }
  }

  Future<void> _materializeDeletionForks(
    Session session, {
    required _DeletionForkContext context,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final pendingSources = <String>[context.rootConversationId];
    final boundaryMaps = <String, Map<String, String>>{};
    while (pendingSources.isNotEmpty) {
      final sourceId = pendingSources.removeAt(0);
      final forks = await Conversation.db.find(
        session,
        where: (table) =>
            table.workspaceId.equals(context.workspaceId) &
            table.forkSourceConversationId.equals(sourceId) &
            table.forkMaterializedAt.equals(null) &
            table.deletedAt.equals(null),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      for (final fork in forks) {
        await _materializeDeletionFork(
          session,
          context: context,
          sourceId: sourceId,
          boundaryMaps: boundaryMaps,
          fork: fork,
          now: now,
          transaction: transaction,
        );
        pendingSources.add(fork.stableId);
      }
    }
  }

  Future<void> _materializeDeletionFork(
    Session session, {
    required _DeletionForkContext context,
    required String sourceId,
    required Map<String, Map<String, String>> boundaryMaps,
    required Conversation fork,
    required DateTime now,
    required Transaction transaction,
  }) async {
    await _cancelForDeletion(
      session,
      conversation: fork,
      now: now,
      transaction: transaction,
    );
    final canceledFork = await Conversation.db.findById(
      session,
      fork.id!,
      transaction: transaction,
    );
    if (canceledFork == null) _fail(ConversationErrorCode.notFound);
    final hasCapturedBoundary = context.frozenForkBoundaries.containsKey(
      fork.stableId,
    );
    final boundary = hasCapturedBoundary
        ? context.frozenForkBoundaries[fork.stableId]
        : fork.forkThroughMessageId;
    final mappedBoundary = boundary == null
        ? null
        : boundaryMaps[sourceId]?[boundary];
    final forkToMaterialize = mappedBoundary == null
        ? canceledFork
        : canceledFork.copyWith(forkThroughMessageId: mappedBoundary);
    if (mappedBoundary != null) {
      await Conversation.db.updateRow(
        session,
        forkToMaterialize,
        transaction: transaction,
      );
    }
    final source = await _repository.findConversationByStableId(
      session,
      workspaceId: context.workspaceId,
      conversationId: sourceId,
      transaction: transaction,
      lock: true,
    );
    if (source == null) _fail(ConversationErrorCode.notFound);
    boundaryMaps[fork.stableId] = await _materializeFork(
      session,
      context: (
        source: source,
        fork: forkToMaterialize,
        actorUserId: context.userId,
        requestId: context.requestId,
        now: now,
        transaction: transaction,
        boundaryOverride: mappedBoundary ?? boundary,
        boundaryWasCaptured: hasCapturedBoundary,
      ),
    );
    context.deletedConversationIds.add(fork.stableId);
  }

  Future<void> _purgeDeletionConversations(
    Session session, {
    required Conversation root,
    required List<Conversation> hiddenDescendants,
    required Transaction transaction,
  }) async {
    for (final child in hiddenDescendants.reversed) {
      await _purgeConversation(
        session,
        conversation: child,
        transaction: transaction,
      );
    }
    await _purgeConversation(
      session,
      conversation: root,
      transaction: transaction,
    );
  }

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
            (message) => _messageView(
              message,
              conversation.stableId,
              turn.requestId,
              a2uiSupportedComponents: cloudA2uiComponentsForClient(
                request.a2uiSupportedComponents,
                isChildConversation:
                    conversation.parentConversationStableId != null,
              ),
            ),
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
        a2uiSupportedComponents: request.a2uiSupportedComponents,
        workspaceId: request.workspaceId,
        conversationId: request.conversationId,
        limit: 500,
      ),
    );
    final pendingStoredMessages = await _repository.listConversationMessages(
      session,
      workspaceId: request.workspaceId,
      conversationId: conversation.id!,
      limit: 500,
    );
    final messageViews = {for (final message in messages) message.id: message};
    final pendingMessages =
        pendingStoredMessages
            .where((message) => message.pendingOrder != null)
            .toList()
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
    final effectiveMessages = await _effectiveMessages(
      session,
      source: conversation,
    );
    final turns = {
      for (final turn in await _repository.listTurns(
        session,
        workspaceId: request.workspaceId,
        turnIds: effectiveMessages
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
    final effectiveMessageIds = effectiveMessages
        .map((message) => message.id)
        .toSet();
    return ConversationSnapshot(
      conversation: ConversationProjectionView(
        id: conversation.stableId,
        workspaceId: conversation.workspaceId,
        executionState: conversation.executionState,
        projectionRevision: conversation.projectionRevision,
        sequence: conversation.eventSequence,
        modelId: conversation.modelId,
        agentId: conversation.agentId,
        forkSourceConversationId: conversation.forkSourceConversationId,
        forkSourceTitle: conversation.forkSourceTitle,
        forkThroughMessageId: conversation.forkThroughMessageId,
        forkMaterializedAt: conversation.forkMaterializedAt,
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
          if (effectiveMessageIds.contains(toolCall.messageId))
            if (turns[toolCall.turnId] case final turn?)
              _toolCallView(
                toolCall,
                turn,
                effectiveMessages,
              ),
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
    if (request.metadataJson != null &&
        !isValidA2uiActionPayload(
          request.metadataJson!,
          conversationId: request.conversationId,
        )) {
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
        if (conversation.parentConversationStableId != null &&
            request.metadataJson != null) {
          _fail(ConversationErrorCode.validationFailed);
        }
        if (request.metadataJson case final metadata?) {
          await _validateA2uiActionAssociation(
            session,
            transaction: transaction,
            conversation: conversation,
            metadataJson: metadata,
          );
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
          metadataJson: request.metadataJson,
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
        a2uiSupportedComponents: request.a2uiSupportedComponents,
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
        a2uiSupportedComponents: request.a2uiSupportedComponents,
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
        a2uiSupportedComponents: request.a2uiSupportedComponents,
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
    String? parentToolCallId,
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
          a2uiSupportedComponents: request.a2uiSupportedComponents,
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
              conversation.executionState != ConversationStatuses.failed &&
              conversation.executionState !=
                  ConversationStatuses.awaitingUserAction) {
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
                'parentToolCallId': ?parentToolCallId,
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
                parentToolCallId: parentToolCallId,
                a2uiSupportedComponents: request.a2uiSupportedComponents,
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
          a2uiSupportedComponents: request.a2uiSupportedComponents,
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
        a2uiSupportedComponents: request.a2uiSupportedComponents,
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
          if (assistant != null &&
              !ConversationStatuses.isMessageTerminal(assistant.status)) {
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
        a2uiSupportedComponents: request.a2uiSupportedComponents,
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
        a2uiSupportedComponents: request.a2uiSupportedComponents,
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
        a2uiSupportedComponents: request.a2uiSupportedComponents,
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
        final requestedConversation = await _repository
            .findConversationByStableId(
              session,
              workspaceId: request.workspaceId,
              conversationId: request.conversationId,
              transaction: transaction,
              lock: true,
            );
        if (requestedConversation == null) {
          _fail(ConversationErrorCode.toolDecisionConflict);
        }
        final turn = await _requireTurnForMutation(
          session,
          userId: userId,
          workspaceId: request.workspaceId,
          turnId: request.turnId,
          transaction: transaction,
          initiatorOnly: false,
        );
        if (requestedConversation.id != turn.conversationId) {
          _fail(ConversationErrorCode.toolDecisionConflict);
        }
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
                metadataJson: _cancelledMessageMetadata,
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
              a2uiSupportedComponents: request.a2uiSupportedComponents,
              parentTurnId: execution == null
                  ? null
                  : conversation_repo
                        .conversationParentTurnIdForExecutionSettings(
                          execution.settingsJson,
                        ),
              parentToolCallId: execution == null
                  ? null
                  : conversation_repo
                        .conversationParentToolCallIdForExecutionSettings(
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

  Future<SubmitToolDecisionBatchResult> submitToolDecisionBatch(
    Session session, {
    required String userId,
    required SubmitToolDecisionBatchRequest request,
  }) async {
    final jobs = <ConversationJob>[];
    final result = await _mutate(
      session,
      userId: userId,
      workspaceId: request.workspaceId,
      endpoint: 'conversation.submitToolDecisionBatch',
      requestId: request.requestId,
      requestBody: request.toJson(),
      decode: SubmitToolDecisionBatchResult.fromJson,
      run: (transaction, now) async {
        _requireId(request.requestId);
        if (request.decision != 'approve' && request.decision != 'deny') {
          _fail(ConversationErrorCode.validationFailed);
        }
        if (request.calls.isEmpty) {
          _fail(ConversationErrorCode.validationFailed);
        }

        final calls = <SubmitToolDecisionBatchCall>[];
        final seenCallIds = <String>{};
        for (final call in request.calls) {
          if (seenCallIds.add(_batchCallIdentity(call))) calls.add(call);
        }
        calls.sort(
          (left, right) => _batchCallSortKey(left).compareTo(
            _batchCallSortKey(right),
          ),
        );
        final conversations = <String, Conversation>{};
        final turns = <String, ConversationTurn>{};
        final accepted = <String>[];
        final alreadyHandled = <String>[];
        final conflicted = <String>[];
        final acceptedByTurn = <int, List<ConversationToolCall>>{};

        for (final call in calls) {
          final identity = _batchCallIdentity(call);
          var conversation = conversations[call.conversationId];
          if (conversation == null) {
            conversation = await _repository.findConversationByStableId(
              session,
              workspaceId: request.workspaceId,
              conversationId: call.conversationId,
              transaction: transaction,
              lock: true,
            );
            if (conversation != null) {
              conversations[call.conversationId] = conversation;
            }
          }
          if (conversation == null) {
            conflicted.add(identity);
            continue;
          }

          var turn = turns[call.turnId];
          if (turn == null) {
            turn = await _repository.findTurnByStableId(
              session,
              workspaceId: request.workspaceId,
              turnId: call.turnId,
              transaction: transaction,
              lock: true,
            );
            if (turn != null) turns[call.turnId] = turn;
          }
          if (turn == null || turn.conversationId != conversation.id) {
            conflicted.add(identity);
            continue;
          }

          final toolCall = await _repository.findToolCallByStableId(
            session,
            workspaceId: request.workspaceId,
            turnId: turn.id!,
            toolCallId: call.toolCallId,
            transaction: transaction,
          );
          if (toolCall == null ||
              toolCall.argumentsDigest != call.argumentsDigest) {
            conflicted.add(identity);
            continue;
          }
          if (toolCall.decision != null || toolCall.status != 'pending') {
            if (toolCall.decision == null ||
                toolCall.decision == request.decision) {
              alreadyHandled.add(identity);
            } else {
              conflicted.add(identity);
            }
            continue;
          }
          if (turn.status != ConversationStatuses.awaitingApproval ||
              turn.revision != call.expectedTurnRevision) {
            conflicted.add(identity);
            continue;
          }

          final arguments = call.editedArgumentsJson ?? toolCall.argumentsJson;
          _requireJsonObject(arguments);
          final argumentsDigest = base64UrlEncode(
            (await Sha256().hash(utf8.encode(arguments))).bytes,
          );
          final updated = toolCall.copyWith(
            argumentsJson: arguments,
            argumentsDigest: argumentsDigest,
            decision: request.decision,
            decisionByUserId: userId,
            decisionAt: now,
            status: request.decision == 'approve' ? 'approved' : 'denied',
            revision: toolCall.revision + 1,
            updatedAt: now,
          );
          await ConversationToolCall.db.updateRow(
            session,
            updated,
            transaction: transaction,
          );
          accepted.add(identity);
          (acceptedByTurn[turn.id!] ??= []).add(updated);
        }

        for (final entry in acceptedByTurn.entries) {
          final turn = turns.values.firstWhere(
            (candidate) => candidate.id == entry.key,
          );
          final pending = await ConversationToolCall.db.find(
            session,
            where: (table) =>
                table.workspaceId.equals(request.workspaceId) &
                table.turnId.equals(turn.id) &
                table.status.equals('pending'),
            transaction: transaction,
            lockMode: LockMode.forUpdate,
          );
          final shouldResume = pending.isEmpty;
          final updatedTurn = await ConversationTurn.db.updateRow(
            session,
            turn.copyWith(
              status: shouldResume
                  ? ConversationStatuses.queued
                  : ConversationStatuses.awaitingApproval,
              terminalAt: null,
              revision: turn.revision + 1,
              updatedAt: now,
            ),
            transaction: transaction,
          );
          final conversation = conversations.values.firstWhere(
            (candidate) => candidate.id == updatedTurn.conversationId,
          );
          final execution = conversation.activeExecutionId == null
              ? null
              : await ConversationExecution.db.findById(
                  session,
                  conversation.activeExecutionId!,
                  transaction: transaction,
                  lockMode: LockMode.forUpdate,
                );
          final projected = await Conversation.db.updateRow(
            session,
            conversation.copyWith(
              eventSequence: conversation.eventSequence + 1,
              projectionRevision: conversation.projectionRevision + 1,
              executionState: shouldResume
                  ? 'running'
                  : ConversationStatuses.awaitingApproval,
              activeExecutionId: conversation.activeExecutionId,
              updatedAt: now,
            ),
            transaction: transaction,
          );
          await ConversationEvent.db.insertRow(
            session,
            ConversationEvent(
              workspaceId: request.workspaceId,
              conversationId: projected.id!,
              sequence: projected.eventSequence,
              eventId: const Uuid().v7(),
              actorUserId: userId,
              requestId: request.requestId,
              kind: ConversationEventType.toolDecisionRecorded,
              payloadJson: jsonEncode({
                'toolCallIds': entry.value
                    .map((call) => call.stableId)
                    .toList(),
                'decision': request.decision,
              }),
              createdAt: now,
            ),
            transaction: transaction,
          );
          if (shouldResume && execution != null) {
            await ConversationExecution.db.updateRow(
              session,
              execution.copyWith(
                status: 'running',
                terminalAt: null,
                updatedAt: now,
              ),
              transaction: transaction,
            );
            jobs.add(
              await _insertJob(
                session,
                workspaceId: turn.workspaceId,
                conversationId: turn.conversationId,
                turnId: turn.id,
                requestId: '${request.requestId}:${turn.requestId}',
                kind: ConversationJobKinds.turn,
                payloadJson: conversation_repo.conversationTurnJobPayload(
                  turn.initiatorUserId,
                  executionId: execution.stableId,
                  a2uiSupportedComponents: request.a2uiSupportedComponents,
                  parentTurnId: conversation_repo
                      .conversationParentTurnIdForExecutionSettings(
                        execution.settingsJson,
                      ),
                  parentToolCallId: conversation_repo
                      .conversationParentToolCallIdForExecutionSettings(
                        execution.settingsJson,
                      ),
                ),
                now: now,
                transaction: transaction,
              ),
            );
          }
        }

        return _Mutation(
          SubmitToolDecisionBatchResult(
            accepted: accepted,
            alreadyHandled: alreadyHandled,
            conflicted: conflicted,
          ),
          'toolDecisionBatchRecorded',
          request.requestId,
          affectedConversationIds: conversations.keys.toList(),
        );
      },
    );
    for (final job in jobs) {
      await _publishConversationJob(session, job);
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
      await _cancelQueuedTurnJobs(
        session,
        workspaceId: request.workspaceId,
        turnId: turn.id!,
        now: now,
        transaction: transaction,
      );
      await _cancelChildTurnJobs(
        session,
        workspaceId: request.workspaceId,
        parentTurnId: turn.id!,
        now: now,
        transaction: transaction,
      );
      await _cancelWaitingSubAgentTurnJobs(
        session,
        workspaceId: request.workspaceId,
        turnId: turn.id!,
        now: now,
        transaction: transaction,
      );
      final leasedJob = await _findLeasedTurnJob(
        session,
        workspaceId: request.workspaceId,
        turnId: turn.id!,
        transaction: transaction,
      );
      if (leasedJob != null) return _mutationResult(session, updated);
      await _cancelWaitingTurnToolCalls(
        session,
        workspaceId: request.workspaceId,
        turnId: turn.id!,
        userId: userId,
        now: now,
        transaction: transaction,
      );
      await _cancelAssistantMessage(
        session,
        turn: turn,
        now: now,
        transaction: transaction,
      );
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

  Future<void> _cancelQueuedTurnJobs(
    Session session, {
    required int workspaceId,
    required int turnId,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final jobs = await ConversationJob.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.turnId.equals(turnId) &
          table.status.equals(ConversationJobStatuses.queued),
      transaction: transaction,
    );
    for (final job in jobs) {
      await ConversationJob.db.updateRow(
        session,
        job.copyWith(
          status: ConversationJobStatuses.cancelled,
          updatedAt: now,
        ),
        transaction: transaction,
      );
    }
  }

  Future<void> _cancelChildTurnJobs(
    Session session, {
    required int workspaceId,
    required int parentTurnId,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final jobs = await ConversationJob.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.kind.equals(ConversationJobKinds.turn),
      transaction: transaction,
    );
    for (final job in jobs) {
      if (conversation_repo.conversationParentTurnIdForJob(job.payloadJson) !=
          parentTurnId) {
        continue;
      }
      await _cancelChildJob(
        session,
        job,
        now: now,
        transaction: transaction,
      );
    }
  }

  Future<void> _cancelWaitingSubAgentTurnJobs(
    Session session, {
    required int workspaceId,
    required int turnId,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final jobs = await ConversationJob.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.turnId.equals(turnId) &
          table.status.equals(ConversationJobStatuses.waitingForSubAgents),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    for (final job in jobs) {
      await ConversationJob.db.updateRow(
        session,
        job.copyWith(
          status: ConversationJobStatuses.cancelled,
          leaseOwner: null,
          leaseToken: null,
          leaseExpiresAt: null,
          updatedAt: now,
        ),
        transaction: transaction,
      );
    }
  }

  Future<ConversationJob?> _findLeasedTurnJob(
    Session session, {
    required int workspaceId,
    required int turnId,
    required Transaction transaction,
  }) => ConversationJob.db.findFirstRow(
    session,
    where: (table) =>
        table.workspaceId.equals(workspaceId) &
        table.turnId.equals(turnId) &
        table.status.equals(ConversationJobStatuses.leased),
    transaction: transaction,
    lockMode: LockMode.forUpdate,
  );

  Future<void> _cancelWaitingTurnToolCalls(
    Session session, {
    required int workspaceId,
    required int turnId,
    required String userId,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final calls = await ConversationToolCall.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.turnId.equals(turnId) &
          (table.status.equals('pending') |
              table.status.equals('awaitingSubAgents')),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    for (final call in calls) {
      await ConversationToolCall.db.updateRow(
        session,
        call.copyWith(
          decision: call.decision ?? 'deny',
          decisionByUserId: call.decisionByUserId ?? userId,
          decisionAt: call.decisionAt ?? now,
          status: 'cancelled',
          resultJson: _cancelledSubAgentResult(call.resultJson),
          revision: call.revision + 1,
          updatedAt: now,
        ),
        transaction: transaction,
      );
    }
  }

  Future<void> _cancelAssistantMessage(
    Session session, {
    required ConversationTurn turn,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final assistantId = turn.assistantMessageId;
    if (assistantId == null) return;
    final assistant = await ConversationMessage.db.findById(
      session,
      assistantId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (assistant == null ||
        ConversationStatuses.isMessageTerminal(assistant.status)) {
      return;
    }
    await ConversationMessage.db.updateRow(
      session,
      assistant.copyWith(
        content: '',
        status: ConversationStatuses.cancelled,
        metadataJson: _cancelledMessageMetadata,
        revision: assistant.revision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
  }

  Future<void> _cancelChildJob(
    Session session,
    ConversationJob job, {
    required DateTime now,
    required Transaction transaction,
  }) async {
    final turnId = job.turnId;
    if (turnId == null) return;
    final turn = await ConversationTurn.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(turnId) & table.workspaceId.equals(job.workspaceId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (turn == null || ConversationStatuses.isTerminal(turn.status)) return;
    final lockedJob = await ConversationJob.db.findById(
      session,
      job.id!,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (lockedJob == null) return;
    if (lockedJob.status == ConversationJobStatuses.leased) {
      await ConversationTurn.db.updateRow(
        session,
        turn.copyWith(
          status: ConversationStatuses.cancelRequested,
          cancellationRequestedAt: now,
          revision: turn.revision + 1,
          updatedAt: now,
        ),
        transaction: transaction,
      );
      return;
    }
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
          metadataJson: _cancelledMessageMetadata,
          revision: assistant.revision + 1,
          updatedAt: now,
        ),
        transaction: transaction,
      );
    }
    final activeToolCalls = await ConversationToolCall.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(job.workspaceId) &
          table.turnId.equals(turn.id) &
          (table.status.equals('pending') |
              table.status.equals('running') |
              table.status.equals('awaitingSubAgents')),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    for (final toolCall in activeToolCalls) {
      await ConversationToolCall.db.updateRow(
        session,
        toolCall.copyWith(
          decision: toolCall.decision ?? 'deny',
          decisionByUserId: toolCall.decisionByUserId ?? turn.initiatorUserId,
          decisionAt: toolCall.decisionAt ?? now,
          status: 'cancelled',
          resultJson: _cancelledSubAgentResult(toolCall.resultJson),
          revision: toolCall.revision + 1,
          updatedAt: now,
        ),
        transaction: transaction,
      );
    }
    await ConversationTurn.db.updateRow(
      session,
      turn.copyWith(
        status: ConversationStatuses.cancelled,
        terminalAt: now,
        revision: turn.revision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await ConversationJob.db.updateRow(
      session,
      lockedJob.copyWith(
        status: ConversationJobStatuses.cancelled,
        leaseOwner: null,
        leaseToken: null,
        leaseExpiresAt: null,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    final conversation = await Conversation.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(job.conversationId) &
          table.workspaceId.equals(job.workspaceId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (conversation == null || conversation.activeExecutionId == null) return;
    final execution = await ConversationExecution.db.findById(
      session,
      conversation.activeExecutionId!,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (execution == null ||
        ConversationStatuses.isTerminal(execution.status)) {
      return;
    }
    await ConversationExecution.db.updateRow(
      session,
      execution.copyWith(
        status: ConversationStatuses.cancelled,
        terminalAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await Conversation.db.updateRow(
      session,
      conversation.copyWith(
        executionState: 'idle',
        activeExecutionId: null,
        eventSequence: conversation.eventSequence + 1,
        projectionRevision: conversation.projectionRevision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await ConversationEvent.db.insertRow(
      session,
      ConversationEvent(
        workspaceId: job.workspaceId,
        conversationId: conversation.id!,
        sequence: conversation.eventSequence + 1,
        eventId: const Uuid().v7(),
        actorUserId: turn.initiatorUserId,
        requestId: job.requestId,
        kind: ConversationEventType.executionStopped,
        payloadJson: jsonEncode({
          'executionId': execution.stableId,
          'status': ConversationStatuses.cancelled,
        }),
        createdAt: now,
      ),
      transaction: transaction,
    );
  }

  String _cancelledSubAgentResult(String? source) {
    if (source == null) {
      return jsonEncode(const {
        'status': 'cancelled',
        'content': _subAgentCancelledMessage,
      });
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map && decoded['children'] is List) {
        return jsonEncode({
          'children': [
            for (final child in (decoded['children'] as List).whereType<Map>())
              {
                'conversationId': child['conversationId'],
                'status': 'cancelled',
                'content': _subAgentCancelledMessage,
                if (child['agentId'] is String) 'agentId': child['agentId'],
              },
          ],
        });
      }
      if (decoded is Map && decoded['conversationId'] is String) {
        return jsonEncode({
          'conversationId': decoded['conversationId'],
          'status': 'cancelled',
          'content': _subAgentCancelledMessage,
          if (decoded['agentId'] is String) 'agentId': decoded['agentId'],
        });
      }
    } on Object catch (_) {}
    return jsonEncode(const {
      'status': 'cancelled',
      'content': _subAgentCancelledMessage,
    });
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
      search: request.search,
      beforeIsPinned: cursor?.isPinned,
      beforeUpdatedAt: cursor?.updatedAt,
      beforeStableId: cursor?.stableId,
      limit: request.limit + 1,
      offset: request.offset ?? 0,
    );
    final hasMore = conversations.length > request.limit;
    final page = conversations.take(request.limit).toList();
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
          decoded['stableId'] is! String ||
          (decoded['isPinned'] != null && decoded['isPinned'] is! bool)) {
        _fail(ConversationErrorCode.validationFailed);
      }
      return _ConversationCursor(
        DateTime.parse(decoded['updatedAt'] as String).toUtc(),
        decoded['stableId'] as String,
        decoded['isPinned'] as bool?,
      );
    } on FormatException {
      _fail(ConversationErrorCode.validationFailed);
    }
  }

  String _encodeCursor(Conversation conversation) => base64Url.encode(
    utf8.encode(
      jsonEncode({
        'isPinned': conversation.isPinned,
        'updatedAt': conversation.updatedAt.toIso8601String(),
        'stableId': conversation.stableId,
      }),
    ),
  );

  Future<String> _copyConversationTitle(
    Session session, {
    required int workspaceId,
    required Conversation source,
    required Transaction transaction,
    String suffix = 'Copy',
  }) async {
    final sourceTitle = source.title?.trim();
    if (sourceTitle == null || sourceTitle.isEmpty) {
      _fail(ConversationErrorCode.validationFailed);
    }
    final titles = (await _repository.listConversations(
      session,
      workspaceId: workspaceId,
      transaction: transaction,
    )).map((conversation) => conversation.title).whereType<String>().toSet();

    for (var index = 1; ; index++) {
      final candidate = index == 1
          ? '$sourceTitle $suffix'
          : '$sourceTitle $suffix $index';
      if (!titles.contains(candidate)) return candidate;
    }
  }

  Future<List<ConversationMessage>> _effectiveMessages(
    Session session, {
    required Conversation source,
    Transaction? transaction,
  }) async {
    final messages = <ConversationMessage>[];
    if (source.forkSourceConversationId != null &&
        source.forkMaterializedAt == null) {
      final parent = await _repository.findConversationByStableId(
        session,
        workspaceId: source.workspaceId,
        conversationId: source.forkSourceConversationId!,
        transaction: transaction,
      );
      if (parent != null) {
        final inherited = await _durableMessages(
          session,
          messages: await _effectiveMessages(
            session,
            source: parent,
            transaction: transaction,
          ),
          workspaceId: source.workspaceId,
          transaction: transaction,
        );
        final boundary = source.forkThroughMessageId;
        if (boundary != null) {
          final boundaryIndex = inherited.indexWhere(
            (message) => message.stableId == boundary,
          );
          if (boundaryIndex < 0) {
            _fail(ConversationErrorCode.validationFailed);
          }
          inherited.removeRange(boundaryIndex + 1, inherited.length);
        }
        messages.addAll(inherited);
      }
    }
    messages.addAll(
      await ConversationMessage.db.find(
        session,
        where: (table) =>
            table.workspaceId.equals(source.workspaceId) &
            table.conversationId.equals(source.id!),
        orderBy: (table) => table.id,
        transaction: transaction,
      ),
    );
    return messages..sort((left, right) {
      final created = left.createdAt.compareTo(right.createdAt);
      return created == 0 ? left.id!.compareTo(right.id!) : created;
    });
  }

  bool _isDurableMessage(ConversationMessage message) =>
      message.pendingOrder == null &&
      !_transientMessageStatuses.contains(message.status) &&
      _isTerminalMessage(message);

  Future<List<ConversationMessage>> _durableMessages(
    Session session, {
    required List<ConversationMessage> messages,
    required int workspaceId,
    Transaction? transaction,
  }) async {
    if (messages.isEmpty) return const [];
    final transientToolMessageIds =
        (await _repository.listToolCallsByTurnIds(
              session,
              workspaceId: workspaceId,
              turnIds: messages
                  .map((message) => message.turnId)
                  .whereType<int>(),
              transaction: transaction,
            ))
            .where((call) => _transientToolCallStatuses.contains(call.status))
            .map((call) => call.messageId)
            .toSet();

    return messages
        .where(
          (message) =>
              _isDurableMessage(message) &&
              !transientToolMessageIds.contains(message.id),
        )
        .toList();
  }

  bool _isTerminalMessage(ConversationMessage message) =>
      ConversationStatuses.isMessageTerminal(message.status);

  Future<String?> _automaticForkBoundary(
    Session session, {
    required Conversation source,
    required List<ConversationMessage> messages,
    required List<ConversationMessage> durableMessages,
    Transaction? transaction,
  }) async {
    final durableIds = durableMessages
        .map((message) => message.id)
        .whereType<int>()
        .toSet();
    final activeIndex = await _automaticForkActiveIndex(
      session,
      source: source,
      messages: messages,
      durableIds: durableIds,
      transaction: transaction,
    );

    if (activeIndex < 0) {
      return durableMessages.lastOrNull?.stableId;
    }
    final turnStart = await _automaticForkTurnStart(
      session,
      messages: messages,
      activeIndex: activeIndex,
      transaction: transaction,
    );
    return _lastDurableAssistantId(
      messages,
      turnStart: turnStart,
      durableIds: durableIds,
    );
  }

  Future<int> _automaticForkActiveIndex(
    Session session, {
    required Conversation source,
    required List<ConversationMessage> messages,
    required Set<int> durableIds,
    Transaction? transaction,
  }) async {
    var activeIndex = messages.indexWhere(
      (message) => message.id == null || !durableIds.contains(message.id),
    );
    final executionId = source.activeExecutionId;
    if (executionId == null) return activeIndex;
    final execution = await ConversationExecution.db.findById(
      session,
      executionId,
      transaction: transaction,
    );
    final assistantId = execution?.assistantMessageId;
    final executionAssistantIndex = assistantId == null
        ? null
        : messages.indexWhere((message) => message.id == assistantId);
    if (executionAssistantIndex != null && executionAssistantIndex >= 0) {
      if (activeIndex < 0 || executionAssistantIndex < activeIndex) {
        activeIndex = executionAssistantIndex;
      }
    } else if (activeIndex < 0) {
      activeIndex = messages.length;
    }
    return activeIndex;
  }

  Future<int> _automaticForkTurnStart(
    Session session, {
    required List<ConversationMessage> messages,
    required int activeIndex,
    Transaction? transaction,
  }) async {
    var turnStart = activeIndex;
    if (activeIndex >= messages.length) return turnStart;
    final activeMessage = messages[activeIndex];
    if (activeMessage.turnId case final turnId?) {
      final turn = await ConversationTurn.db.findById(
        session,
        turnId,
        transaction: transaction,
      );
      final userMessageId = turn?.userMessageId;
      final userIndex = userMessageId == null
          ? -1
          : messages.indexWhere((message) => message.id == userMessageId);
      if (userIndex >= 0 && userIndex < turnStart) turnStart = userIndex;
    }
    if (turnStart == activeIndex &&
        activeMessage.role != 'user' &&
        activeIndex > 0 &&
        messages[activeIndex - 1].role == 'user') {
      turnStart--;
    }
    return turnStart;
  }

  String? _lastDurableAssistantId(
    List<ConversationMessage> messages, {
    required int turnStart,
    required Set<int> durableIds,
  }) {
    for (var index = turnStart - 1; index >= 0; index--) {
      final candidate = messages[index];
      if (candidate.role == 'assistant' &&
          candidate.id != null &&
          durableIds.contains(candidate.id)) {
        return candidate.stableId;
      }
    }
    return null;
  }

  Future<void> _copyConversationResources(
    Session session, {
    required int workspaceId,
    required Conversation source,
    required Conversation fork,
    required Transaction transaction,
  }) async {
    final resources = await WorkspaceResource.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.deletedAt.equals(null) &
          table.resourceKind.inSet({
            WorkspaceResourceKind.conversationToolSelection,
            WorkspaceResourceKind.conversationSkillSelection,
          }),
      transaction: transaction,
    );
    for (final resource in resources) {
      Map<String, dynamic> data;
      try {
        final decoded = jsonDecode(resource.data);
        if (decoded is! Map) continue;
        data = Map<String, dynamic>.from(decoded);
      } on Object {
        continue;
      }
      if (data['conversationId'] != source.stableId) continue;
      final suffix = resource.resourceId.startsWith('${source.stableId}:')
          ? resource.resourceId.substring(source.stableId.length + 1)
          : resource.resourceId;
      final resourceId = '${fork.stableId}:$suffix';
      data['id'] = resourceId;
      data['conversationId'] = fork.stableId;
      await WorkspaceResource.db.insertRow(
        session,
        WorkspaceResource(
          workspaceId: workspaceId,
          resourceKind: resource.resourceKind,
          resourceId: resourceId,
          data: jsonEncode(data),
          revision: 1,
          createdAt: resource.createdAt,
          updatedAt: resource.updatedAt,
        ),
        transaction: transaction,
      );
    }
  }

  Future<Map<String, String>> _materializeFork(
    Session session, {
    required _ForkMaterializationContext context,
  }) async {
    final sourceMessages = await _materializeForkSourceMessages(
      session,
      context,
    );
    final sourceTurns = await ConversationTurn.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(context.source.workspaceId) &
          table.id.inSet(
            sourceMessages
                .map((message) => message.turnId)
                .whereType<int>()
                .toSet(),
          ),
      transaction: context.transaction,
    );
    final copies = (
      sourceMessages: sourceMessages,
      targetMessages: <ConversationMessage>[],
      turnIds: <int, int>{},
      messageIds: <int, int>{},
      stableMessageIds: <String, String>{},
    );
    await _copyForkMessages(session, context, copies);
    await _copyForkTurns(session, context, sourceTurns, copies);
    await _updateForkMessageReferences(session, context, copies);
    await _copyForkToolCalls(session, context, copies);
    final materialized = await Conversation.db.updateRow(
      session,
      context.fork.copyWith(
        forkThroughMessageId: context.fork.forkThroughMessageId == null
            ? null
            : copies.stableMessageIds[context.fork.forkThroughMessageId!] ??
                  context.fork.forkThroughMessageId,
        forkMaterializedAt: context.now,
        revision: context.fork.revision + 1,
        projectionRevision: context.fork.projectionRevision + 1,
        eventSequence: context.fork.eventSequence + 1,
        updatedAt: context.now,
      ),
      transaction: context.transaction,
    );
    await ConversationEvent.db.insertRow(
      session,
      ConversationEvent(
        workspaceId: context.fork.workspaceId,
        conversationId: context.fork.id!,
        sequence: materialized.eventSequence,
        eventId: const Uuid().v7(),
        actorUserId: context.actorUserId,
        requestId: context.requestId,
        kind: ConversationEventType.settingsChanged,
        payloadJson: jsonEncode({'forkMaterialized': true}),
        createdAt: context.now,
      ),
      transaction: context.transaction,
    );
    return copies.stableMessageIds;
  }

  Future<List<ConversationMessage>> _materializeForkSourceMessages(
    Session session,
    _ForkMaterializationContext context,
  ) async {
    final sourceMessages = await _durableMessages(
      session,
      messages: await _effectiveMessages(
        session,
        source: context.source,
        transaction: context.transaction,
      ),
      workspaceId: context.source.workspaceId,
      transaction: context.transaction,
    );
    final boundary =
        context.boundaryOverride ?? context.fork.forkThroughMessageId;
    if (context.boundaryWasCaptured && boundary == null) {
      sourceMessages.clear();
    }
    if (boundary != null) {
      final boundaryIndex = sourceMessages.indexWhere(
        (message) => message.stableId == boundary,
      );
      if (boundaryIndex < 0) _fail(ConversationErrorCode.validationFailed);
      sourceMessages.removeRange(boundaryIndex + 1, sourceMessages.length);
    }
    return sourceMessages;
  }

  Future<void> _copyForkMessages(
    Session session,
    _ForkMaterializationContext context,
    _ForkCopies copies,
  ) async {
    for (final message in copies.sourceMessages) {
      final copy = await ConversationMessage.db.insertRow(
        session,
        ConversationMessage(
          workspaceId: context.fork.workspaceId,
          conversationId: context.fork.id!,
          stableId: const Uuid().v7(),
          role: message.role,
          kind: message.kind,
          status: message.status,
          content: message.content,
          metadataJson: message.metadataJson,
          compactedThroughMessageId: null,
          revision: message.revision,
          createdAt: message.createdAt,
          updatedAt: message.updatedAt,
        ),
        transaction: context.transaction,
      );
      copies.messageIds[message.id!] = copy.id!;
      copies.stableMessageIds[message.stableId] = copy.stableId;
      copies.targetMessages.add(copy);
      final references = await ObjectReference.db.find(
        session,
        where: (table) =>
            table.workspaceId.equals(context.source.workspaceId) &
            table.messageId.equals(message.id!) &
            table.deletedAt.equals(null),
        transaction: context.transaction,
      );
      for (final reference in references) {
        await ObjectReference.db.insertRow(
          session,
          ObjectReference(
            workspaceId: context.fork.workspaceId,
            objectId: reference.objectId,
            messageId: copy.id!,
            createdAt: reference.createdAt,
          ),
          transaction: context.transaction,
        );
      }
    }
  }

  Future<void> _copyForkTurns(
    Session session,
    _ForkMaterializationContext context,
    List<ConversationTurn> sourceTurns,
    _ForkCopies copies,
  ) async {
    for (final turn in sourceTurns.where(
      (turn) => ConversationStatuses.isTerminal(turn.status),
    )) {
      final copy = await ConversationTurn.db.insertRow(
        session,
        ConversationTurn(
          workspaceId: context.fork.workspaceId,
          conversationId: context.fork.id!,
          requestId: const Uuid().v7(),
          requestHash: turn.requestHash,
          initiatorUserId: turn.initiatorUserId,
          userMessageId: null,
          assistantMessageId: null,
          status: turn.status,
          revision: turn.revision,
          acceptedSequence: turn.acceptedSequence,
          cancellationRequestedAt: turn.cancellationRequestedAt,
          terminalAt: turn.terminalAt,
          createdAt: turn.createdAt,
          updatedAt: turn.updatedAt,
        ),
        transaction: context.transaction,
      );
      copies.turnIds[turn.id!] = copy.id!;
      await ConversationTurn.db.updateRow(
        session,
        copy.copyWith(
          userMessageId: copies.messageIds[turn.userMessageId],
          assistantMessageId: copies.messageIds[turn.assistantMessageId],
        ),
        transaction: context.transaction,
      );
      for (final message in copies.targetMessages.where(
        (message) => copies.messageIds.entries.any(
          (entry) =>
              entry.value == message.id &&
              copies.sourceMessages
                      .firstWhere((source) => source.id == entry.key)
                      .turnId ==
                  turn.id,
        ),
      )) {
        final targetIndex = copies.targetMessages.indexWhere(
          (target) => target.id == message.id,
        );
        final updatedMessage = message.copyWith(turnId: copy.id);
        await ConversationMessage.db.updateRow(
          session,
          updatedMessage,
          transaction: context.transaction,
        );
        copies.targetMessages[targetIndex] = updatedMessage;
      }
    }
  }

  Future<void> _updateForkMessageReferences(
    Session session,
    _ForkMaterializationContext context,
    _ForkCopies copies,
  ) async {
    for (final message in copies.sourceMessages) {
      final targetId = copies.messageIds[message.id!];
      if (targetId == null) continue;
      final compactedThroughMessageId =
          message.compactedThroughMessageId == null
          ? null
          : copies.messageIds[message.compactedThroughMessageId];
      if (compactedThroughMessageId == null &&
          message.compactedThroughMessageId != null) {
        continue;
      }
      final target = copies.targetMessages.firstWhere(
        (copy) => copy.id == targetId,
      );
      await ConversationMessage.db.updateRow(
        session,
        target.copyWith(
          turnId: target.turnId,
          compactedThroughMessageId: compactedThroughMessageId,
        ),
        transaction: context.transaction,
      );
    }
  }

  Future<void> _copyForkToolCalls(
    Session session,
    _ForkMaterializationContext context,
    _ForkCopies copies,
  ) async {
    final calls = await ConversationToolCall.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(context.source.workspaceId) &
          table.turnId.inSet(copies.turnIds.keys.toSet()),
      transaction: context.transaction,
    );
    for (final call in calls) {
      if (!copies.messageIds.containsKey(call.messageId)) continue;
      final newTurnId = copies.turnIds[call.turnId];
      final newMessageId = copies.messageIds[call.messageId];
      if (newTurnId == null || newMessageId == null) continue;
      await ConversationToolCall.db.insertRow(
        session,
        ConversationToolCall(
          workspaceId: context.fork.workspaceId,
          conversationId: context.fork.id!,
          turnId: newTurnId,
          messageId: newMessageId,
          stableId: const Uuid().v7(),
          name: call.name,
          argumentsJson: call.argumentsJson,
          argumentsDigest: call.argumentsDigest,
          userFacingDescription: call.userFacingDescription,
          status: call.status,
          decision: call.decision,
          decisionByUserId: call.decisionByUserId,
          decisionAt: call.decisionAt,
          resultJson: call.resultJson,
          revision: call.revision,
          createdAt: call.createdAt,
          updatedAt: call.updatedAt,
        ),
        transaction: context.transaction,
      );
    }
  }

  Future<void> _purgeConversation(
    Session session, {
    required Conversation conversation,
    required Transaction transaction,
  }) async {
    final messages = await _purgeConversationObjects(
      session,
      conversation: conversation,
      transaction: transaction,
    );
    await _purgeConversationRows(
      session,
      conversation: conversation,
      messages: messages,
      transaction: transaction,
    );
    await _purgeConversationResources(
      session,
      conversation: conversation,
      transaction: transaction,
    );
    await Conversation.db.deleteRow(
      session,
      conversation,
      transaction: transaction,
    );
  }

  Future<List<ConversationMessage>> _purgeConversationObjects(
    Session session, {
    required Conversation conversation,
    required Transaction transaction,
  }) async {
    final workspaceId = conversation.workspaceId;
    final messages = await ConversationMessage.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.conversationId.equals(conversation.id!),
      transaction: transaction,
    );
    final messageIds = messages.map((message) => message.id!).toSet();
    final references = await ObjectReference.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.messageId.inSet(messageIds),
      transaction: transaction,
    );
    final objectIds = references.map((reference) => reference.objectId).toSet();
    for (final reference in references) {
      await ObjectReference.db.deleteRow(
        session,
        reference,
        transaction: transaction,
      );
    }
    for (final objectId in objectIds) {
      final object = await WorkspaceObject.db.findById(
        session,
        objectId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (object == null ||
          object.status != 'active' ||
          object.deletedAt != null) {
        continue;
      }
      final liveReference = await ObjectReference.db.findFirstRow(
        session,
        where: (table) =>
            table.workspaceId.equals(workspaceId) &
            table.objectId.equals(objectId) &
            table.deletedAt.equals(null),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (liveReference != null) continue;
      final existingDeletion = await ObjectDeletion.db.findFirstRow(
        session,
        where: (table) => table.objectId.equals(objectId),
        transaction: transaction,
      );
      if (existingDeletion != null) continue;
      final now = DateTime.now().toUtc();
      await WorkspaceObject.db.updateRow(
        session,
        object.copyWith(
          status: 'deleted',
          revision: object.revision + 1,
          updatedAt: now,
          deletedAt: now,
        ),
        transaction: transaction,
      );
      await ObjectDeletion.db.insertRow(
        session,
        ObjectDeletion(
          workspaceId: workspaceId,
          objectId: objectId,
          objectKey: object.objectKey,
          requestId: 'conversation-purge:${conversation.stableId}:$objectId',
          expectedRevision: object.revision,
          requestedAt: now,
          attempts: 0,
          availableAt: now,
        ),
        transaction: transaction,
      );
    }
    return messages;
  }

  Future<void> _purgeConversationRows(
    Session session, {
    required Conversation conversation,
    required List<ConversationMessage> messages,
    required Transaction transaction,
  }) async {
    final workspaceId = conversation.workspaceId;
    final toolCalls = await ConversationToolCall.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.conversationId.equals(conversation.id!),
      transaction: transaction,
    );
    for (final call in toolCalls) {
      await ConversationToolCall.db.deleteRow(
        session,
        call,
        transaction: transaction,
      );
    }
    final jobs = await ConversationJob.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.conversationId.equals(conversation.id!),
      transaction: transaction,
    );
    for (final job in jobs) {
      await ConversationJob.db.deleteRow(
        session,
        job,
        transaction: transaction,
      );
    }
    final executions = await ConversationExecution.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.conversationId.equals(conversation.id!),
      transaction: transaction,
    );
    for (final execution in executions) {
      await ConversationExecution.db.deleteRow(
        session,
        execution,
        transaction: transaction,
      );
    }
    final usages = await ConversationUsage.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.conversationId.equals(conversation.id!),
      transaction: transaction,
    );
    for (final usage in usages) {
      await ConversationUsage.db.deleteRow(
        session,
        usage,
        transaction: transaction,
      );
    }
    final turns = await ConversationTurn.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.conversationId.equals(conversation.id!),
      transaction: transaction,
    );
    for (final turn in turns) {
      await ConversationTurn.db.updateRow(
        session,
        turn.copyWith(userMessageId: null, assistantMessageId: null),
        transaction: transaction,
      );
    }
    for (final message in messages) {
      await ConversationMessage.db.deleteRow(
        session,
        message,
        transaction: transaction,
      );
    }
    for (final turn in turns) {
      await ConversationTurn.db.deleteRow(
        session,
        turn,
        transaction: transaction,
      );
    }
    final events = await ConversationEvent.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.conversationId.equals(conversation.id!),
      transaction: transaction,
    );
    for (final event in events) {
      await ConversationEvent.db.deleteRow(
        session,
        event,
        transaction: transaction,
      );
    }
  }

  Future<void> _purgeConversationResources(
    Session session, {
    required Conversation conversation,
    required Transaction transaction,
  }) async {
    final resources = await WorkspaceResource.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(conversation.workspaceId) &
          table.resourceKind.inSet({
            WorkspaceResourceKind.conversationToolSelection,
            WorkspaceResourceKind.conversationSkillSelection,
          }) &
          table.deletedAt.equals(null),
      transaction: transaction,
    );
    for (final resource in resources) {
      try {
        final data = jsonDecode(resource.data);
        if (data is Map && data['conversationId'] == conversation.stableId) {
          await WorkspaceResource.db.deleteRow(
            session,
            resource,
            transaction: transaction,
          );
        }
      } on Object {
        continue;
      }
    }
  }

  Future<List<Conversation>> _lockHiddenDescendants(
    Session session, {
    required Conversation root,
    required Transaction transaction,
  }) async {
    final descendants = <Conversation>[];
    final pending = <String>[root.stableId];
    while (pending.isNotEmpty) {
      final parentId = pending.removeAt(0);
      final children = await Conversation.db.find(
        session,
        where: (table) =>
            table.workspaceId.equals(root.workspaceId) &
            table.parentConversationStableId.equals(parentId) &
            table.deletedAt.equals(null),
        orderBy: (table) => table.id,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      for (final child in children) {
        descendants.add(child);
        pending.add(child.stableId);
      }
    }

    return descendants;
  }

  Future<Map<String, String?>> _captureForkBoundariesForDelete(
    Session session, {
    required Conversation source,
    required Transaction transaction,
  }) async {
    final boundaries = <String, String?>{};
    final pendingSources = <Conversation>[source];
    while (pendingSources.isNotEmpty) {
      final current = pendingSources.removeAt(0);
      final effectiveMessages = await _effectiveMessages(
        session,
        source: current,
        transaction: transaction,
      );
      final durableMessages = await _durableMessages(
        session,
        messages: effectiveMessages,
        workspaceId: current.workspaceId,
        transaction: transaction,
      );
      final forks = await Conversation.db.find(
        session,
        where: (table) =>
            table.workspaceId.equals(current.workspaceId) &
            table.forkSourceConversationId.equals(current.stableId) &
            table.forkMaterializedAt.equals(null) &
            table.deletedAt.equals(null),
        orderBy: (table) => table.id,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      for (final fork in forks) {
        final requestedBoundary = fork.forkThroughMessageId;
        boundaries[fork.stableId] =
            requestedBoundary != null &&
                durableMessages.any(
                  (message) => message.stableId == requestedBoundary,
                )
            ? requestedBoundary
            : await _automaticForkBoundary(
                session,
                source: current,
                messages: effectiveMessages,
                durableMessages: durableMessages,
                transaction: transaction,
              );
        pendingSources.add(fork);
      }
    }

    return boundaries;
  }

  Future<void> _cancelForDeletion(
    Session session, {
    required Conversation conversation,
    required DateTime now,
    required Transaction transaction,
  }) async {
    await _cancelDeletionTurns(
      session,
      conversation: conversation,
      now: now,
      transaction: transaction,
    );
    await _cancelDeletionJobs(
      session,
      conversation: conversation,
      now: now,
      transaction: transaction,
    );
    await _cancelDeletionExecutions(
      session,
      conversation: conversation,
      now: now,
      transaction: transaction,
    );
    await _cancelDeletionToolCalls(
      session,
      conversation: conversation,
      now: now,
      transaction: transaction,
    );
    if (conversation.activeExecutionId != null ||
        conversation.executionState != 'idle') {
      await Conversation.db.updateRow(
        session,
        conversation.copyWith(
          activeExecutionId: null,
          executionState: 'idle',
          projectionRevision: conversation.projectionRevision + 1,
          updatedAt: now,
        ),
        transaction: transaction,
      );
    }
  }

  Future<void> _cancelDeletionTurns(
    Session session, {
    required Conversation conversation,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final turns = await ConversationTurn.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(conversation.workspaceId) &
          table.conversationId.equals(conversation.id),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    for (final turn in turns) {
      if (!ConversationStatuses.isTerminal(turn.status)) {
        await ConversationTurn.db.updateRow(
          session,
          turn.copyWith(
            status: ConversationStatuses.cancelled,
            cancellationRequestedAt: turn.cancellationRequestedAt ?? now,
            terminalAt: now,
            revision: turn.revision + 1,
            updatedAt: now,
          ),
          transaction: transaction,
        );
      }
      final assistantId = turn.assistantMessageId;
      if (assistantId == null) continue;
      final assistant = await ConversationMessage.db.findById(
        session,
        assistantId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (assistant == null ||
          ConversationStatuses.isMessageTerminal(assistant.status)) {
        continue;
      }
      await ConversationMessage.db.updateRow(
        session,
        assistant.copyWith(
          status: ConversationStatuses.cancelled,
          metadataJson: _cancelledMessageMetadata,
          revision: assistant.revision + 1,
          updatedAt: now,
        ),
        transaction: transaction,
      );
    }
  }

  Future<void> _cancelDeletionJobs(
    Session session, {
    required Conversation conversation,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final jobs = await ConversationJob.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(conversation.workspaceId) &
          table.conversationId.equals(conversation.id),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    for (final job in jobs) {
      if (job.status == ConversationJobStatuses.completed ||
          job.status == ConversationJobStatuses.cancelled ||
          job.status == ConversationJobStatuses.failed) {
        continue;
      }
      await ConversationJob.db.updateRow(
        session,
        job.copyWith(
          status: ConversationJobStatuses.cancelled,
          leaseOwner: null,
          leaseToken: null,
          leaseExpiresAt: null,
          updatedAt: now,
        ),
        transaction: transaction,
      );
    }
  }

  Future<void> _cancelDeletionExecutions(
    Session session, {
    required Conversation conversation,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final executions = await ConversationExecution.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(conversation.workspaceId) &
          table.conversationId.equals(conversation.id),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    for (final execution in executions) {
      if (ConversationStatuses.isTerminal(execution.status)) continue;
      await ConversationExecution.db.updateRow(
        session,
        execution.copyWith(
          status: ConversationStatuses.cancelled,
          terminalAt: now,
          updatedAt: now,
        ),
        transaction: transaction,
      );
    }
  }

  Future<void> _cancelDeletionToolCalls(
    Session session, {
    required Conversation conversation,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final toolCalls = await ConversationToolCall.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(conversation.workspaceId) &
          table.conversationId.equals(conversation.id),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    for (final toolCall in toolCalls) {
      if (!_transientToolCallStatuses.contains(toolCall.status)) continue;
      await ConversationToolCall.db.updateRow(
        session,
        toolCall.copyWith(
          status: 'cancelled',
          revision: toolCall.revision + 1,
          updatedAt: now,
        ),
        transaction: transaction,
      );
    }
  }

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

  Future<void> _ensurePinnedCapacity(
    Session session, {
    required int workspaceId,
    required Transaction transaction,
  }) async {
    final count = await _repository.countPinnedConversations(
      session,
      workspaceId: workspaceId,
      transaction: transaction,
    );
    if (count >= ConversationLimits.maxPinnedPerWorkspace) {
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
  }) async {
    var affectedConversationIds = const <String>[];
    final result = await session.db.transaction((transaction) async {
      _requireId(requestId);
      final hash = base64UrlEncode(
        (await Sha256().hash(utf8.encode(jsonEncode(requestBody)))).bytes,
      );
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
        return decode(_decodeMutationResponse(receipt.responseJson));
      }
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
        return decode(_decodeMutationResponse(lockedReceipt.responseJson));
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
      affectedConversationIds = mutation.affectedConversationIds;
      return mutation.value as T;
    });
    await SyncWakeups.publishWorkspace(session, workspaceId);
    for (final conversationId in affectedConversationIds) {
      await SyncWakeups.publishConversation(
        session,
        workspaceId: workspaceId,
        conversationId: conversationId,
      );
    }
    return result;
  }

  Map<String, dynamic> _decodeMutationResponse(String responseJson) {
    final decoded = jsonDecode(responseJson);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  ConversationSummary _summary(Conversation conversation) =>
      ConversationSummary(
        id: conversation.stableId,
        title: conversation.title ?? '',
        isPinned: conversation.isPinned,
        modelId: conversation.modelId,
        agentId: conversation.agentId,
        parentConversationId: conversation.parentConversationStableId,
        forkSourceConversationId: conversation.forkSourceConversationId,
        forkSourceTitle: conversation.forkSourceTitle,
        forkThroughMessageId: conversation.forkThroughMessageId,
        forkMaterializedAt: conversation.forkMaterializedAt,
        revision: conversation.revision,
        createdAt: conversation.createdAt,
        updatedAt: conversation.updatedAt,
      );

  ConversationMessageView _messageView(
    ConversationMessage message,
    String conversationId,
    String? turnId, {
    required Set<String> a2uiSupportedComponents,
    bool isForkReference = false,
  }) => ConversationMessageView(
    id: message.stableId,
    conversationId: conversationId,
    turnId: turnId,
    role: message.role,
    kind: message.kind,
    status: message.status,
    content: message.content,
    isForkReference: isForkReference,
    metadataJson: cloudA2uiMetadataForClient(
      message.metadataJson,
      a2uiSupportedComponents,
    ),
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
    userFacingDescription: call.userFacingDescription,
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

  Future<void> _validateA2uiActionAssociation(
    Session session, {
    required Transaction transaction,
    required Conversation conversation,
    required String metadataJson,
  }) async {
    if (conversation.parentConversationStableId != null) {
      _fail(ConversationErrorCode.validationFailed);
    }
    final decoded = _tryDecodeJson(metadataJson);
    if (!A2uiChatContract.isValidAction(
      decoded,
      conversationId: conversation.stableId,
    )) {
      _fail(ConversationErrorCode.validationFailed);
    }
    final action = Map<String, Object?>.from(decoded as Map);
    final turnId = action['turnId']! as String;
    final assistantMessageId =
        action['assistantMessageId'] as String? ?? turnId;
    final surfaceId = action['surfaceId']! as String;
    final assistant = await ConversationMessage.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(conversation.workspaceId) &
          table.conversationId.equals(conversation.id) &
          table.stableId.equals(assistantMessageId) &
          table.role.equals('assistant'),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (assistant == null ||
        assistant.status != ConversationStatuses.awaitingUserAction ||
        assistant.stableId != assistantMessageId ||
        assistant.stableId != turnId) {
      _fail(ConversationErrorCode.validationFailed);
    }
    final existingUserMessages = await ConversationMessage.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(conversation.workspaceId) &
          table.conversationId.equals(conversation.id) &
          table.role.equals('user'),
      transaction: transaction,
    );
    if (existingUserMessages.any(
      (message) => _sameA2uiAction(
        message.metadataJson == null
            ? null
            : _tryDecodeJson(message.metadataJson!),
        action,
      ),
    )) {
      _fail(ConversationErrorCode.validationFailed);
    }
    if (!surfaceId.startsWith('$turnId:') ||
        !_assistantOwnsA2uiComponent(assistant, action)) {
      _fail(ConversationErrorCode.validationFailed);
    }
  }

  bool _assistantOwnsA2uiComponent(
    ConversationMessage assistant,
    Map<String, Object?> action,
  ) {
    final metadata = assistant.metadataJson;
    if (metadata == null) return false;
    final decoded = jsonDecode(metadata);
    if (decoded is! Map || decoded['a2uiMessages'] is! List) return false;
    final surfaceId = action['surfaceId']! as String;
    final prefix = '${assistant.stableId}:';
    if (!surfaceId.startsWith(prefix)) return false;
    final derivedWireSurfaceId = surfaceId.substring(prefix.length);
    if (derivedWireSurfaceId.isEmpty) return false;
    final suppliedWireSurfaceId = action['wireSurfaceId'] as String?;
    if (suppliedWireSurfaceId != null &&
        suppliedWireSurfaceId != derivedWireSurfaceId) {
      return false;
    }
    final wireSurfaceId = suppliedWireSurfaceId ?? derivedWireSurfaceId;
    final componentId = action['componentId']! as String;
    var ownsRequiredFormSurface = false;
    final formComponents = <String, Map<String, Object?>>{};
    final issueMap = decoded['a2uiIssuesBySurface'];
    if (issueMap is Map && issueMap[wireSurfaceId] is List) return false;
    for (final payload
        in (decoded['a2uiMessages'] as List).whereType<String>()) {
      final value = _tryDecodeJson(payload);
      if (value is! Map) continue;
      final message = value['message'];
      if (message is! Map) continue;
      final interactionMode = value['interactionMode'];
      for (final key in const [
        'createSurface',
        'updateComponents',
        'updateDataModel',
        'deleteSurface',
      ]) {
        final body = message[key];
        if (body is! Map || body['surfaceId'] != wireSurfaceId) continue;
        if (key == 'deleteSurface') return false;
        if (key == 'createSurface' &&
            body['catalogId'] == a2uiChatFormCatalogId &&
            interactionMode == 'requiresUserAction') {
          ownsRequiredFormSurface = true;
        }
        if (key == 'updateComponents') {
          final components = body['components'];
          if (components is! List) return false;
          for (final component in components) {
            if (component is! Map || component['id'] is! String) return false;
            formComponents[component['id']! as String] =
                Map<String, Object?>.from(component);
          }
        }
      }
    }
    if (!ownsRequiredFormSurface ||
        componentId != a2uiChatFormSubmitComponentId ||
        action['actionName'] != a2uiChatFormSubmitActionName ||
        action['answers'] is! Map) {
      return false;
    }
    final answers = Map<String, Object?>.from(action['answers']! as Map);
    final touchedPaths =
        (action['touchedPaths'] as List?)?.whereType<String>().toList() ??
        const <String>[];
    if (touchedPaths.any((path) => !path.startsWith('/'))) return false;
    final validation = A2uiChatContract.validateFormValues(
      components: formComponents.values,
      values: answers,
      touchedPaths: touchedPaths,
    );
    final unanswered =
        (action['unansweredPaths'] as List?)?.whereType<String>().toSet() ??
        const <String>{};
    return validation.isValid &&
        unanswered.length == validation.unansweredPaths.length &&
        unanswered.containsAll(validation.unansweredPaths);
  }

  bool _sameA2uiAction(Object? value, Map<String, Object?> action) {
    if (value is! Map) return false;
    const keys = [
      'protocolVersion',
      'conversationId',
      'turnId',
      'surfaceId',
      'componentId',
      'actionName',
    ];
    if (!keys.every((key) => value[key] == action[key])) return false;
    return (value['assistantMessageId'] ?? value['turnId']) ==
        (action['assistantMessageId'] ?? action['turnId']);
  }

  Object? _tryDecodeJson(String source) {
    try {
      return jsonDecode(source);
    } on Object catch (_) {
      return null;
    }
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

class const _ContinueConversationReplay();

class const _ConversationCursor(
  final DateTime updatedAt,
  final String stableId,
  final bool? isPinned,
);

class const _Mutation<T>(
  final T? value,
  final String operation,
  final String resourceId, {
  final List<String> affectedConversationIds = const [],
});

String _batchCallSortKey(SubmitToolDecisionBatchCall call) =>
    '${call.conversationId}:${call.turnId}:${call.toolCallId}';

String _batchCallIdentity(SubmitToolDecisionBatchCall call) =>
    _batchCallSortKey(call);
