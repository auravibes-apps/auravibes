import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/tool_call_approval_batch_item.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_resume_service.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_status_mapper.dart';
import 'package:auravibes_app/features/chats/agent_adapters/resolved_tool_service.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_activity_gate.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/services/cloud_tool_decision_item.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_turn_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/services/log_redaction.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:logging/logging.dart';

typedef CloudTurnResolver = Future<CloudTurnUsecase?> Function(
  String workspaceId,
);
typedef ToolSpecsResolver = LoadConversationToolSpecsUsecase Function(
  String workspaceId,
);

typedef _LocalBatchRequest = ({
  List<PendingToolCall> calls,
  String rootConversationId,
  String workspaceId,
  bool approve,
});
typedef _McpAppResultIdentity = ({String conversationId, String toolCallId});

class const BatchToolApprovalUsecase({
  required final MessageRepository messageRepository,
  required final ConversationRepository conversationRepository,
  required final ConversationActivityGate conversationActivityGate,
  required final AgentToolResumeService agentToolResumeService,
  required final ResolvedToolService runResolvedTool,
  required final AgentCancellationRuntime cancellationRuntime,
  required final ToolResolverService toolResolver,
  required final ToolSpecsResolver loadToolSpecs,
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

    return await _runLocal((
      calls: calls,
      rootConversationId: rootConversationId,
      workspaceId: workspaceId,
      approve: approve,
    ));
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
      _cloudDecisionItems(
        calls,
        rootConversationId: rootConversationId,
        approve: approve,
      ),
      approved: approve,
    );

    return _batchResultFromCloud(result, calls, rootConversationId);
  }
}

extension on BatchToolApprovalUsecase {
  Future<void> _executeClaimed(
    Iterable<ToolCallApprovalBatchClaim> claims, {
    required String workspaceId,
  }) async {
    final resolved = await _resolveClaimedTools(
      claims,
      workspaceId: workspaceId,
    );
    final plan = _prepareBatchExecution(resolved);
    final executionResults = await _executeResolvedTools(
      plan.executable,
      runResolvedTool: runResolvedTool,
      isCancellationRequested: cancellationRuntime.isCancellationRequested,
    );
    await _persistBatchExecutionResults(this, plan, executionResults);
    onToolCallChanged();
  }

  Future<List<_ResolvedBatchClaim>> _resolveClaimedTools(
    Iterable<ToolCallApprovalBatchClaim> claims, {
    required String workspaceId,
  }) async {
    final grouped = _groupClaimsByConversation(claims);
    final resolved = await Future.wait(
      grouped.entries.map(
        (entry) => _resolveConversationClaims(entry, workspaceId),
      ),
    );

    return resolved.expand((claims) => claims).toList(growable: false);
  }

  Future<List<_ResolvedBatchClaim>> _resolveConversationClaims(
    MapEntry<String, List<ToolCallApprovalBatchClaim>> entry,
    String workspaceId,
  ) async {
    final conversation = await conversationRepository.getConversationById(
      entry.key,
    );
    final sourceWorkspaceId = conversation?.workspaceId ?? workspaceId;
    try {
      return await _resolveClaimsForConversation(
        entry,
        workspaceId: sourceWorkspaceId,
      );
    } on Object {
      return _failedResolutionClaims(entry.value);
    }
  }

  Future<List<_ResolvedBatchClaim>> _resolveClaimsForConversation(
    MapEntry<String, List<ToolCallApprovalBatchClaim>> entry, {
    required String workspaceId,
  }) async {
    final catalog = await loadToolSpecs(workspaceId)
        .buildCatalog(conversationId: entry.key, workspaceId: workspaceId);

    return await Future.wait(
      entry.value.map((claim) => _resolveClaim(claim, catalog: catalog)),
    );
  }

  Future<_ResolvedBatchClaim> _resolveClaim(
    ToolCallApprovalBatchClaim claim, {
    required agent.ToolCatalog<ResolvedTool> catalog,
  }) async {
    final toolCall = claim.toolCall;
    if (toolCall == null) {
      throw StateError('Claimed tool call is missing its metadata.');
    }
    final resolved = toolResolver.resolveTool(toolCall.name, catalog);
    if (resolved == null) return _missingResolvedTool(claim);

    return _ResolvedBatchClaim(claim: claim, tool: resolved);
  }

  Future<void> _resumeSources(
    Iterable<ToolCallApprovalBatchClaim> claims,
  ) async {
    final messageByConversation = _sourceMessagesByConversation(claims);
    final _ = await Future.wait(
      messageByConversation.values.map(
        (messageId) => agentToolResumeService.call(messageId: messageId),
      ),
    );
  }

  Future<BatchToolApprovalResult> _runLocal(_LocalBatchRequest request) {
    final conversationIds = request.calls
        .map((call) => _sourceConversationId(call, request.rootConversationId))
        .toSet();

    return conversationActivityGate.runActivities(
      conversationIds,
      () => _runLocalClaims(this, request),
    );
  }

  Future<List<ToolCallApprovalBatchClaim>> _claimLocalCalls(
    _LocalBatchRequest request,
  ) async {
    if (request.calls.any(_isCloudCall)) {
      throw StateError(
        'A tool approval batch cannot mix local and cloud calls.',
      );
    }

    final items = [
      for (final call in request.calls)
        _toBatchItem(call, request.rootConversationId),
    ];

    return await messageRepository.claimToolCallBatch(
      items,
      approve: request.approve,
    );
  }

  Future<void> _finishLocalClaims(
    Iterable<ToolCallApprovalBatchClaim> claims, {
    required bool approve,
    required String workspaceId,
  }) async {
    if (claims.isEmpty) return;

    if (approve) {
      await _executeClaimed(claims, workspaceId: workspaceId);
    }
    await _resumeSources(claims);
  }
}

List<CloudToolDecisionItem> _cloudDecisionItems(
  List<PendingToolCall> calls, {
  required String rootConversationId,
  required bool approve,
}) => [
  for (final call in calls)
    _cloudDecisionItem(
      call,
      rootConversationId: rootConversationId,
      approve: approve,
    ),
];

BatchToolApprovalResult _batchResultFromCloud(
  SubmitToolDecisionBatchResult result,
  List<PendingToolCall> calls,
  String rootConversationId,
) {
  final byIdentity = {
    for (final call in calls) _cloudIdentity(call, rootConversationId): call,
  };

  return BatchToolApprovalResult(
    claimed: _cloudBatchItems(result.accepted, byIdentity, rootConversationId),
    alreadyHandled: _cloudBatchItems(
      result.alreadyHandled,
      byIdentity,
      rootConversationId,
    ),
    conflicted: _cloudBatchItems(
      result.conflicted,
      byIdentity,
      rootConversationId,
    ),
  );
}

List<ToolCallApprovalBatchItem> _cloudBatchItems(
  Iterable<String> identities,
  Map<String, PendingToolCall> callsByIdentity,
  String rootConversationId,
) => [
  for (final identity in identities)
    if (callsByIdentity[identity] case final call?)
      _toBatchItem(call, rootConversationId),
];

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

typedef _BatchExecutionPlan = ({
  List<ToolCallExecutionBatchUpdate> updates,
  List<agent.AgentToolBatchCall<ResolvedTool>> executable,
});

_BatchExecutionPlan _prepareBatchExecution(
  Iterable<_ResolvedBatchClaim> resolved,
) => (
  updates: [
    for (final entry in resolved)
      if (entry.tool == null) _executionUpdateForResolvedClaim(entry),
  ],
  executable: [
    for (final entry in resolved)
      if (entry.tool != null) _executionCallForResolvedClaim(entry),
  ],
);

ToolCallExecutionBatchUpdate _executionUpdateForResolvedClaim(
  _ResolvedBatchClaim entry,
) {
  final resultStatus = entry.resultStatus;
  final item = entry.claim.item;
  if (resultStatus == null) {
    throw StateError('Resolved tool result is missing a status.');
  }

  return _executionUpdateFromParts(
    (
      conversationId: item.conversationId,
      messageId: item.messageId,
      toolCallId: item.toolCallId,
    ),
    resultStatus,
    (
      responseRaw: entry.responseRaw,
      responseContextRaw: null,
      appData: null,
      outputTruncated: false,
      originalResponseBytes: null,
      fullOutputForContext: false,
    ),
  );
}

ToolCallExecutionBatchUpdate _executionUpdateFromParts(
  ToolCallExecutionIdentity identity,
  ToolCallResultStatus resultStatus,
  ToolCallExecutionOutput output,
) => ToolCallExecutionBatchUpdate.fromParts(
  identity: identity,
  resultStatus: resultStatus,
  output: output,
);

agent.AgentToolBatchCall<ResolvedTool> _executionCallForResolvedClaim(
  _ResolvedBatchClaim entry,
) {
  final tool = entry.tool;
  final toolCall = entry.claim.toolCall;
  final item = entry.claim.item;
  if (tool == null || toolCall == null) {
    throw StateError('Claimed tool call is missing its metadata.');
  }

  return agent.AgentToolBatchCall(
    conversationId: item.conversationId,
    messageId: item.messageId,
    toolCallId: item.toolCallId,
    tool: tool,
    argumentsRaw: toolCall.argumentsRaw,
  );
}

_ResolvedBatchClaim _missingResolvedTool(ToolCallApprovalBatchClaim claim) =>
    .new(claim: claim, resultStatus: .toolNotFound);

List<ToolCallExecutionBatchUpdate> _executionUpdates(
  Iterable<agent.AgentToolBatchResult<ResolvedTool>> results,
  Map<_McpAppResultIdentity, Map<String, Object?>> appDataByIdentity,
) => [
  for (final result in results) _executionUpdate(result, appDataByIdentity),
];

ToolCallExecutionBatchUpdate _executionUpdate(
  agent.AgentToolBatchResult<ResolvedTool> result,
  Map<_McpAppResultIdentity, Map<String, Object?>> appDataByIdentity,
) {
  final call = result.call;
  final execution = result.result;

  return _executionUpdateFromParts(
    (
      conversationId: call.conversationId,
      messageId: call.messageId,
      toolCallId: call.toolCallId,
    ),
    AgentToolStatusMapper.toResultStatus(execution.resultStatus),
    _batchToolOutput(execution, appDataByIdentity, call),
  );
}

ToolCallExecutionOutput _batchToolOutput(
  agent.AgentToolExecutionResult execution,
  Map<_McpAppResultIdentity, Map<String, Object?>> appDataByIdentity,
  agent.AgentToolBatchCall<ResolvedTool> call,
) {
  final output = _executionOutput(execution);

  return (
    responseRaw: output.responseRaw,
    responseContextRaw: output.responseContextRaw,
    appData:
        appDataByIdentity[(
          conversationId: call.conversationId,
          toolCallId: call.toolCallId,
        )],
    outputTruncated: output.outputTruncated,
    originalResponseBytes: output.originalResponseBytes,
    fullOutputForContext: output.fullOutputForContext,
  );
}

ToolCallExecutionOutput _executionOutput(
  agent.AgentToolExecutionResult result,
) => (
  responseRaw: result.responseRaw,
  responseContextRaw: result.responseContextRaw,
  appData: null,
  outputTruncated: result.outputTruncated,
  originalResponseBytes: result.originalResponseBytes,
  fullOutputForContext: result.fullOutputForContext,
);

Future<void> _persistBatchExecutionResults(
  BatchToolApprovalUsecase usecase,
  _BatchExecutionPlan plan,
  List<agent.AgentToolBatchResult<ResolvedTool>> results,
) async {
  final appData = _takeBatchAppData(usecase.runResolvedTool, results);
  final updates = [...plan.updates, ..._executionUpdates(results, appData)];
  await usecase.messageRepository.persistToolCallBatchResults(updates);
}

Map<_McpAppResultIdentity, Map<String, Object?>> _takeBatchAppData(
  ResolvedToolService runResolvedTool,
  List<agent.AgentToolBatchResult<ResolvedTool>> results,
) {
  final appDataByIdentity = <_McpAppResultIdentity, Map<String, Object?>>{};
  for (final result in results) {
    final appData = _takeBatchResultAppData(runResolvedTool, result);
    if (appData == null) continue;
    appDataByIdentity[_batchResultIdentity(
          result.call.conversationId,
          result.call.toolCallId,
        )] =
        appData;
  }

  return appDataByIdentity;
}

Map<String, Object?>? _takeBatchResultAppData(
  ResolvedToolService runResolvedTool,
  agent.AgentToolBatchResult<ResolvedTool> result,
) {
  final appData = runResolvedTool.takeMcpAppResultData(
    conversationId: result.call.conversationId,
    toolCallId: result.call.toolCallId,
  );
  if (result.result.resultStatus != .success) return null;

  return appData;
}

_McpAppResultIdentity _batchResultIdentity(
  String conversationId,
  String toolCallId,
) => (conversationId: conversationId, toolCallId: toolCallId);

Map<String, List<ToolCallApprovalBatchClaim>> _groupClaimsByConversation(
  Iterable<ToolCallApprovalBatchClaim> claims,
) {
  final grouped = <String, List<ToolCallApprovalBatchClaim>>{};
  for (final claim in claims) {
    (grouped[claim.item.conversationId] ??= []).add(claim);
  }

  return grouped;
}

List<_ResolvedBatchClaim> _failedResolutionClaims(
  Iterable<ToolCallApprovalBatchClaim> claims,
) => [
  for (final claim in claims)
    .new(
      claim: claim,
      resultStatus: .executionError,
      responseRaw: 'Tool execution failed.',
    ),
];

Map<String, String> _sourceMessagesByConversation(
  Iterable<ToolCallApprovalBatchClaim> claims,
) {
  final messageByConversation = <String, String>{};
  for (final claim in claims) {
    final _ = messageByConversation.putIfAbsent(
      claim.item.conversationId,
      () => claim.item.messageId,
    );
  }

  return messageByConversation;
}

Future<List<agent.AgentToolBatchResult<ResolvedTool>>> _executeResolvedTools(
  Iterable<agent.AgentToolBatchCall<ResolvedTool>> calls, {
  required ResolvedToolService runResolvedTool,
  required agent.AgentToolCancellationChecker isCancellationRequested,
}) => agent.AgentToolBatchExecutor<ResolvedTool>(
  runResolvedTool: _resolvedToolBatchRunner(runResolvedTool),
  isCancellationRequested: isCancellationRequested,
  logToolExecutionError: _logToolExecutionError,
).call(calls);

agent.AgentResolvedToolRunner<ResolvedTool> _resolvedToolBatchRunner(
  ResolvedToolService runResolvedTool,
) =>
    ({
      required conversationId,
      required toolCallId,
      required tool,
      required arguments,
    }) => runResolvedTool((
      conversationId: conversationId,
      toolCallId: toolCallId,
      tool: tool,
      arguments: arguments,
    ));

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
  final data = _cloudCallData(call);

  return CloudToolDecisionItem(
    conversationId: _sourceConversationId(call, rootConversationId),
    turnId: data.turnId,
    toolCallId: call.toolCall.id,
    argumentsDigest: data.argumentsDigest,
    expectedTurnRevision: data.turnRevision,
    editedArgumentsJson: approve ? call.toolCall.argumentsRaw : null,
  );
}

({String turnId, String argumentsDigest, int turnRevision}) _cloudCallData(
  PendingToolCall call,
) {
  final turnId = call.toolCall.turnId;
  final argumentsDigest = call.toolCall.argumentsDigest;
  final turnRevision = call.toolCall.turnRevision;
  if (turnId == null || argumentsDigest == null || turnRevision == null) {
    throw StateError('Cloud approval call is missing its revision data.');
  }

  return (
    turnId: turnId,
    argumentsDigest: argumentsDigest,
    turnRevision: turnRevision,
  );
}

Future<BatchToolApprovalResult> _runLocalClaims(
  BatchToolApprovalUsecase usecase,
  _LocalBatchRequest request,
) async {
  final claims = await usecase._claimLocalCalls(request);
  usecase.onToolCallChanged();
  final result = _resultFromClaims(claims);
  await usecase._finishLocalClaims(
    claims.where(
      (claim) => claim.status == ToolCallApprovalBatchClaimStatus.claimed,
    ),
    approve: request.approve,
    workspaceId: request.workspaceId,
  );

  return result;
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
