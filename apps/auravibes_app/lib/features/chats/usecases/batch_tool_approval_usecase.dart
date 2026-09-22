import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/tool_call_approval_batch_item.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_resume_service.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_status_mapper.dart';
import 'package:auravibes_app/features/chats/agent_adapters/resolved_tool_service.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/services/cloud_tool_decision_item.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_turn_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/resolve_effective_tool_approval_usecase.dart';
import 'package:auravibes_app/services/log_redaction.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:logging/logging.dart';

typedef CloudTurnResolver = Future<CloudTurnUsecase?> Function(
  String workspaceId,
);
typedef ToolSpecsResolver = LoadConversationToolSpecsUsecase Function(
  String workspaceId,
);

class const BatchToolApprovalUsecase({
  required final MessageRepository messageRepository,
  required final ConversationRepository conversationRepository,
  required final AgentToolResumeService agentToolResumeService,
  required final ResolvedToolService runResolvedTool,
  required final AgentCancellationRuntime cancellationRuntime,
  required final ToolResolverService toolResolver,
  required final ToolSpecsResolver loadToolSpecs,
  required final ResolveEffectiveToolApprovalUsecase? effectiveToolApproval,
  required final CloudTurnResolver resolveCloudTurn,
  required final void Function() onToolCallChanged,
}) implements BatchToolApprovalActions {
  @override
  Future<BatchToolApprovalResult> approveOnce({
    required String rootConversationId,
    required String workspaceId,
    required List<PendingToolCall> pendingCalls,
  }) async => await _run(
    rootConversationId: rootConversationId,
    workspaceId: workspaceId,
    pendingCalls: pendingCalls,
    approve: true,
  );

  @override
  Future<BatchToolApprovalResult> skip({
    required String rootConversationId,
    required String workspaceId,
    required List<PendingToolCall> pendingCalls,
  }) async => await _run(
    rootConversationId: rootConversationId,
    workspaceId: workspaceId,
    pendingCalls: pendingCalls,
    approve: false,
  );

  Future<BatchToolApprovalResult> _run({
    required String rootConversationId,
    required String workspaceId,
    required List<PendingToolCall> pendingCalls,
    required bool approve,
  }) async {
    final calls = _uniqueCalls(pendingCalls, rootConversationId);
    if (calls.isEmpty) return _emptyResult();

    if (_isCloudBatch(calls)) {
      return await _runCloud(
        calls: calls,
        rootConversationId: rootConversationId,
        workspaceId: workspaceId,
        approve: approve,
      );
    }

    if (calls.any(_isCloudCall)) {
      throw StateError(
        'A tool approval batch cannot mix local and cloud calls.',
      );
    }

    final items = [
      for (final call in calls) _toBatchItem(call, rootConversationId),
    ];
    final claims = await messageRepository.claimToolCallBatch(
      items,
      approve: approve,
    );
    onToolCallChanged();

    final result = _resultFromClaims(claims);
    final claimed = claims.where(
      (claim) => claim.status == ToolCallApprovalBatchClaimStatus.claimed,
    );
    if (claimed.isEmpty) return result;

    if (!approve) {
      await _resumeSources(claimed);

      return result;
    }

    await _executeClaimed(claimed, workspaceId: workspaceId);
    await _resumeSources(claimed);

    return result;
  }

  Future<BatchToolApprovalResult> _runCloud({
    required List<PendingToolCall> calls,
    required String rootConversationId,
    required String workspaceId,
    required bool approve,
  }) async {
    final cloud = await resolveCloudTurn(workspaceId);
    if (cloud == null) throw StateError('Cloud turn unavailable');

    final result = await cloud.decideBatch(
      calls
          .map(
            (call) => _cloudDecisionItem(
              call,
              rootConversationId: rootConversationId,
              approve: approve,
            ),
          )
          .toList(growable: false),
      approved: approve,
    );
    final byIdentity = {
      for (final call in calls) _cloudIdentity(call, rootConversationId): call,
    };

    return BatchToolApprovalResult(
      claimed: [
        for (final key in result.accepted)
          if (byIdentity[key] case final call?)
            _toBatchItem(call, rootConversationId),
      ],
      alreadyHandled: [
        for (final key in result.alreadyHandled)
          if (byIdentity[key] case final call?)
            _toBatchItem(call, rootConversationId),
      ],
      conflicted: [
        for (final key in result.conflicted)
          if (byIdentity[key] case final call?)
            _toBatchItem(call, rootConversationId),
      ],
    );
  }

  Future<void> _executeClaimed(
    Iterable<ToolCallApprovalBatchClaim> claims, {
    required String workspaceId,
  }) async {
    final resolved = await _resolveClaimedTools(
      claims,
      workspaceId: workspaceId,
    );
    final updates = <ToolCallExecutionBatchUpdate>[];
    final executable = <agent.AgentToolBatchCall<ResolvedTool>>[];

    for (final entry in resolved) {
      final tool = entry.tool;
      if (tool == null) {
        final resultStatus = entry.resultStatus;
        if (resultStatus == null) {
          throw StateError('Resolved tool result is missing a status.');
        }
        updates.add(
          ToolCallExecutionBatchUpdate(
            conversationId: entry.claim.item.conversationId,
            messageId: entry.claim.item.messageId,
            toolCallId: entry.claim.item.toolCallId,
            resultStatus: resultStatus,
            responseRaw: entry.responseRaw,
          ),
        );
        continue;
      }
      final toolCall = entry.claim.toolCall;
      if (toolCall == null) {
        throw StateError('Claimed tool call is missing its metadata.');
      }
      executable.add(
        agent.AgentToolBatchCall(
          conversationId: entry.claim.item.conversationId,
          messageId: entry.claim.item.messageId,
          toolCallId: entry.claim.item.toolCallId,
          tool: tool,
          argumentsRaw: toolCall.argumentsRaw,
        ),
      );
    }

    final executionResults = await agent.AgentToolBatchExecutor<ResolvedTool>(
      runResolvedTool: runResolvedTool.call,
      isCancellationRequested: cancellationRuntime.isCancellationRequested,
      logToolExecutionError: _logToolExecutionError,
    ).call(executable);
    updates.addAll(
      executionResults.map(
        (result) => ToolCallExecutionBatchUpdate(
          conversationId: result.call.conversationId,
          messageId: result.call.messageId,
          toolCallId: result.call.toolCallId,
          resultStatus: AgentToolStatusMapper.toResultStatus(
            result.result.resultStatus,
          ),
          responseRaw: result.result.responseRaw,
        ),
      ),
    );

    await messageRepository.persistToolCallBatchResults(updates);
    onToolCallChanged();
  }

  Future<List<_ResolvedBatchClaim>> _resolveClaimedTools(
    Iterable<ToolCallApprovalBatchClaim> claims, {
    required String workspaceId,
  }) async {
    final grouped = <String, List<ToolCallApprovalBatchClaim>>{};
    for (final claim in claims) {
      (grouped[claim.item.conversationId] ??= []).add(claim);
    }

    final resolved = <_ResolvedBatchClaim>[];
    final _ = await Future.wait(
      grouped.entries.map((entry) async {
        final conversation = await conversationRepository.getConversationById(
          entry.key,
        );
        final sourceWorkspaceId = conversation?.workspaceId ?? workspaceId;
        try {
          final catalog = await loadToolSpecs(sourceWorkspaceId).buildCatalog(
            conversationId: entry.key,
            workspaceId: sourceWorkspaceId,
          );
          final values = await Future.wait(
            entry.value.map(
              (claim) => _resolveClaim(
                claim,
                catalog: catalog,
                workspaceId: sourceWorkspaceId,
              ),
            ),
          );
          resolved.addAll(values);
        } on Object {
          resolved.addAll(
            entry.value.map(
              (claim) => .new(
                claim: claim,
                resultStatus: .executionError,
                responseRaw: 'Tool execution failed.',
              ),
            ),
          );
        }
      }),
    );

    return resolved;
  }

  Future<_ResolvedBatchClaim> _resolveClaim(
    ToolCallApprovalBatchClaim claim, {
    required agent.ToolCatalog<ResolvedTool> catalog,
    required String workspaceId,
  }) async {
    final toolCall = claim.toolCall;
    if (toolCall == null) {
      throw StateError('Claimed tool call is missing its metadata.');
    }
    final resolved = toolResolver.resolveTool(toolCall.name, catalog);
    if (resolved == null) {
      return _ResolvedBatchClaim(
        claim: claim,
        resultStatus: toolCall.name == agent.callSkillToolName
            ? .notConfigured
            : .toolNotFound,
      );
    }

    final effective = effectiveToolApproval;
    final tool = effective == null
        ? resolved
        : await effective.call(
            conversationId: claim.item.conversationId,
            workspaceId: workspaceId,
            requestedTool: resolved,
            argumentsRaw: toolCall.argumentsRaw,
          );
    if (tool == null) {
      return _ResolvedBatchClaim(claim: claim, resultStatus: .notConfigured);
    }

    return _ResolvedBatchClaim(claim: claim, tool: tool);
  }

  Future<void> _resumeSources(
    Iterable<ToolCallApprovalBatchClaim> claims,
  ) async {
    final messageByConversation = <String, String>{};
    for (final claim in claims) {
      final _ = messageByConversation.putIfAbsent(
        claim.item.conversationId,
        () => claim.item.messageId,
      );
    }
    final _ = await Future.wait(
      messageByConversation.values.map(
        (messageId) => agentToolResumeService.call(messageId: messageId),
      ),
    );
  }

  void _logToolExecutionError(
    agent.AgentToolExecutionErrorRequest<ResolvedTool> request,
  ) {
    _logger.severe(
      'Batch tool execution failed '
      'conversationId=${request.conversationId} '
      'toolCallId=${request.toolCallId} '
      'error=${LogRedaction.redact(request.error)} '
      'stackTrace=${LogRedaction.redact(request.stackTrace)}',
    );
  }
}

class const BatchToolApprovalResult({
  required final List<ToolCallApprovalBatchItem> claimed,
  required final List<ToolCallApprovalBatchItem> alreadyHandled,
  required final List<ToolCallApprovalBatchItem> conflicted,
});

abstract interface class BatchToolApprovalActions {
  Future<BatchToolApprovalResult> approveOnce({
    required String rootConversationId,
    required String workspaceId,
    required List<PendingToolCall> pendingCalls,
  });

  Future<BatchToolApprovalResult> skip({
    required String rootConversationId,
    required String workspaceId,
    required List<PendingToolCall> pendingCalls,
  });
}

class const _ResolvedBatchClaim({
  required final ToolCallApprovalBatchClaim claim,
  final ResolvedTool? tool,
  final ToolCallResultStatus? resultStatus,
  final String? responseRaw,
});

final _logger = Logger('batch_tool_approval_usecase');

ToolCallApprovalBatchItem _toBatchItem(
  PendingToolCall call,
  String rootConversationId,
) {
  final conversationId = _sourceConversationId(call, rootConversationId);

  return ToolCallApprovalBatchItem(
    conversationId: conversationId,
    messageId: call.messageId,
    toolCallId: call.toolCall.id,
    argumentsDigest: call.toolCall.argumentsDigest,
    turnRevision: call.toolCall.turnRevision,
  );
}

CloudToolDecisionItem _cloudDecisionItem(
  PendingToolCall call, {
  required String rootConversationId,
  required bool approve,
}) {
  final turnId = call.toolCall.turnId;
  final argumentsDigest = call.toolCall.argumentsDigest;
  final turnRevision = call.toolCall.turnRevision;
  if (turnId == null || argumentsDigest == null || turnRevision == null) {
    throw StateError('Cloud approval call is missing its revision data.');
  }

  return CloudToolDecisionItem(
    conversationId: _sourceConversationId(call, rootConversationId),
    turnId: turnId,
    toolCallId: call.toolCall.id,
    argumentsDigest: argumentsDigest,
    expectedTurnRevision: turnRevision,
    editedArgumentsJson: approve ? call.toolCall.argumentsRaw : null,
  );
}

String _sourceConversationId(PendingToolCall call, String fallback) =>
    call.sourceConversationId.isEmpty ? fallback : call.sourceConversationId;

String _cloudIdentity(PendingToolCall call, String rootConversationId) =>
    '${_sourceConversationId(call, rootConversationId)}:'
    '${call.toolCall.turnId}:${call.toolCall.id}';

bool _isCloudBatch(Iterable<PendingToolCall> calls) =>
    calls.isNotEmpty && calls.every(_isCloudCall);

bool _isCloudCall(PendingToolCall call) =>
    call.toolCall.turnId != null &&
    call.toolCall.turnRevision != null &&
    call.toolCall.argumentsDigest != null;

List<PendingToolCall> _uniqueCalls(
  Iterable<PendingToolCall> calls,
  String rootConversationId,
) {
  final seen = <String>{};

  return [
    for (final call in calls)
      if (seen.add(
        '${_sourceConversationId(call, rootConversationId)}:'
        '${call.messageId}:${call.toolCall.id}',
      ))
        call,
  ];
}

BatchToolApprovalResult _emptyResult() => const BatchToolApprovalResult(
  claimed: [],
  alreadyHandled: [],
  conflicted: [],
);

BatchToolApprovalResult _resultFromClaims(
  Iterable<ToolCallApprovalBatchClaim> claims,
) => BatchToolApprovalResult(
  claimed: [
    for (final claim in claims)
      if (claim.status == ToolCallApprovalBatchClaimStatus.claimed) claim.item,
  ],
  alreadyHandled: [
    for (final claim in claims)
      if (claim.status == ToolCallApprovalBatchClaimStatus.alreadyHandled)
        claim.item,
  ],
  conflicted: [
    for (final claim in claims)
      if (claim.status == ToolCallApprovalBatchClaimStatus.conflicted)
        claim.item,
  ],
);
