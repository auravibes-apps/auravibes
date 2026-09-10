import 'dart:convert';

import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart'
    hide ToolToCall;
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_call_loader.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_decision_service.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_status_mapper.dart';
import 'package:auravibes_app/features/chats/agent_adapters/resolved_tool_service.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _logger = Logger('agent_tool_execution_service');

typedef ResolveSkillCommandTarget =
    Future<agent.AgentResolvedToolName?> Function({
      required String conversationId,
      required String workspaceId,
      required agent.SkillCommandTarget command,
    });

typedef _ToolApprovalRequest = ({
  ResolveToolApprovalDecisionUsecase? resolver,
  ResolveToolApprovalDecisionUsecase Function(String workspaceId)?
  resolverForWorkspace,
  ResolveSkillCommandTarget? resolveSkillCommandTarget,
  String conversationId,
  String workspaceId,
  String toolCallId,
  ResolvedTool resolvedTool,
  String argumentsRaw,
});

typedef _ToolExecutionErrorRequest = ({
  String conversationId,
  String toolCallId,
  ResolvedTool tool,
  Object error,
  StackTrace stackTrace,
});

typedef _AgentToolApprovalRequest =
    agent.AgentToolApprovalRequest<ResolvedTool>;

typedef _AgentToolExecutionErrorRequest =
    agent.AgentToolExecutionErrorRequest<ResolvedTool>;

typedef _ToolResultsRequest = ({
  String messageId,
  List<agent.AgentToolResultUpdate> updates,
});

class AgentToolExecutionService({
  required AgentToolCallLoader loadLatestMessageToolCallsUsecase,
  required MessageRepository messageRepository,
  required ResolvedToolService runResolvedToolUsecase,
  required AgentToolDecisionService getAgentIterationDecisionUsecase,
  required AgentCancellationRuntime agentCancellationRuntime,
  ResolveToolApprovalDecisionUsecase? resolveToolApprovalDecision,
  ResolveToolApprovalDecisionUsecase Function(String workspaceId)?
  resolveToolApprovalDecisionForWorkspace,
  ResolveSkillCommandTarget? resolveSkillCommandTarget,
}) extends agent.AgentToolExecutionRunner<ResolvedTool> {
  this
    : super(
        provider: AppAllowedToolsDataProvider(
          messageRepository: messageRepository,
          loadLatestMessageToolCallsService: loadLatestMessageToolCallsUsecase,
          resolvedToolService: runResolvedToolUsecase,
          toolDecisionService: getAgentIterationDecisionUsecase,
          agentCancellationRuntime: agentCancellationRuntime,
          resolveToolApprovalDecisionUsecase: resolveToolApprovalDecision,
          resolveToolApprovalDecisionUsecaseForWorkspace:
              resolveToolApprovalDecisionForWorkspace,
          resolveSkillCommandTarget: resolveSkillCommandTarget,
        ),
      );
}

class const AppAllowedToolsDataProvider({
  required final MessageRepository messageRepository,
  required final AgentToolCallLoader loadLatestMessageToolCallsService,
  required final ResolvedToolService resolvedToolService,
  required final AgentToolDecisionService toolDecisionService,
  required final AgentCancellationRuntime agentCancellationRuntime,
  final ResolveToolApprovalDecisionUsecase? resolveToolApprovalDecisionUsecase,
  final ResolveToolApprovalDecisionUsecase Function(String workspaceId)?
  resolveToolApprovalDecisionUsecaseForWorkspace,
  final ResolveSkillCommandTarget? resolveSkillCommandTarget,
}) implements agent.AgentToolExecutionProvider<ResolvedTool> {
  @override
  Future<agent.AgentToolApprovalDecision> resolveToolApprovalDecision(
    _AgentToolApprovalRequest request,
  ) => _resolveToolApprovalDecision((
    resolver: resolveToolApprovalDecisionUsecase,
    resolverForWorkspace: resolveToolApprovalDecisionUsecaseForWorkspace,
    resolveSkillCommandTarget: resolveSkillCommandTarget,
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
    toolCallId: request.toolCallId,
    resolvedTool: request.resolvedTool,
    argumentsRaw: request.argumentsRaw ?? '{}',
  ));

  @override
  void logToolExecutionError(_AgentToolExecutionErrorRequest request) =>
      _logToolExecutionError(request);

  @override
  Future<agent.LoadLatestMessageToolCallsResult<ResolvedTool>>
  loadLatestToolCalls({required String conversationId}) {
    return loadLatestMessageToolCallsService.call(
      conversationId: conversationId,
    );
  }

  @override
  Future<Object?> runResolvedTool({
    required String conversationId,
    required ResolvedTool tool,
    required Map<String, dynamic> arguments,
  }) {
    return resolvedToolService(
      conversationId: conversationId,
      tool: tool,
      arguments: arguments,
    );
  }

  @override
  Future<agent.AgentIterationDecision> getAgentIterationDecision({
    required String messageId,
  }) {
    return toolDecisionService.call(messageId: messageId);
  }

  @override
  bool isCancellationRequested(String conversationId) {
    return agentCancellationRuntime.isCancellationRequested(conversationId);
  }

  @override
  String toolIdentifier(ResolvedTool tool) {
    return tool.toolIdentifier;
  }

  @override
  Future<void> stopPendingTools({required String messageId}) async {
    await _stopPendingTools(messageRepository, messageId);
  }

  @override
  Future<void> updateToolResults({
    required String messageId,
    required List<agent.AgentToolResultUpdate> updates,
  }) async {
    await _updateToolResults(messageRepository, (
      messageId: messageId,
      updates: updates,
    ));
  }
}

Future<agent.AgentToolApprovalDecision> _resolveToolApprovalDecision(
  _ToolApprovalRequest request,
) async {
  final resolver = _approvalResolver(request);
  if (resolver == null) {
    throw StateError('No tool approval resolver is configured');
  }

  final approvalTool = await _resolveApprovalTool(request);
  if (approvalTool == null) return _notConfiguredApprovalDecision();

  final decision = await _resolvePermission(resolver, request, approvalTool);

  return _toApprovalDecision(decision);
}

ResolveToolApprovalDecisionUsecase? _approvalResolver(
  _ToolApprovalRequest request,
) =>
    request.resolverForWorkspace?.call(request.workspaceId) ?? request.resolver;

Future<ToolApprovalDecision> _resolvePermission(
  ResolveToolApprovalDecisionUsecase resolver,
  _ToolApprovalRequest request,
  ResolvedTool approvalTool,
) => resolver.call(
  conversationId: request.conversationId,
  workspaceId: request.workspaceId,
  toolCallId: request.toolCallId,
  resolvedTool: approvalTool,
);

agent.AgentToolApprovalDecision _toApprovalDecision(
  ToolApprovalDecision decision,
) => agent.AgentToolApprovalDecision(
  permissionResult: AgentToolStatusMapper.toPermissionResult(
    decision.permissionResult,
  ),
);

Future<ResolvedTool?> _resolveApprovalTool(_ToolApprovalRequest request) {
  final tool = request.resolvedTool;
  if (!_requiresSkillApproval(tool)) {
    return Future<ResolvedTool?>.value(tool);
  }

  final decoded = _decodeArguments(request.argumentsRaw);
  if (decoded == null) return Future<ResolvedTool?>.value();

  return _resolveSkillApprovalTool(request, tool, decoded);
}

bool _requiresSkillApproval(ResolvedTool tool) =>
    tool.isSkillCommand && tool.toolIdentifier == agent.callSkillToolName;

Future<ResolvedTool?> _resolveSkillApprovalTool(
  _ToolApprovalRequest request,
  ResolvedTool tool,
  Map<String, Object?> decoded,
) async {
  final effective = await _resolveEffectiveSkillTarget(request, tool, decoded);
  if (effective == null) return null;

  return ResolvedTool.skillCommand(
    commandName: tool.toolIdentifier,
    target: effective,
  );
}

Future<agent.AgentResolvedToolName?> _resolveEffectiveSkillTarget(
  _ToolApprovalRequest request,
  ResolvedTool tool,
  Map<String, Object?> decoded,
) => agent.resolveEffectiveToolApprovalTarget(
  requestedTarget: .skillControl(toolIdentifier: tool.toolIdentifier),
  arguments: decoded,
  resolveSkillTarget: (command) => _resolveSkillTarget(request, command),
);

Future<agent.AgentResolvedToolName?> _resolveSkillTarget(
  _ToolApprovalRequest request,
  agent.SkillCommandTarget command,
) {
  final resolveTarget = request.resolveSkillCommandTarget;
  if (resolveTarget == null) {
    return Future<agent.AgentResolvedToolName?>.value();
  }

  return resolveTarget(
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
    command: command,
  );
}

Map<String, Object?>? _decodeArguments(String argumentsRaw) {
  final Object? decoded;
  try {
    decoded = jsonDecode(argumentsRaw);
  } on FormatException {
    return null;
  }

  return decoded is Map<String, Object?> ? decoded : null;
}

const _notConfiguredApprovalResult = agent.AgentToolApprovalDecision(
  permissionResult: agent.AgentToolPermissionResult.notConfigured,
);

agent.AgentToolApprovalDecision _notConfiguredApprovalDecision() =>
    _notConfiguredApprovalResult;

Future<void> _stopPendingTools(
  MessageRepository messageRepository,
  String messageId,
) async {
  final message = await messageRepository.getMessageById(messageId);
  if (message == null) return;

  final metadata = message.metadata ?? const MessageMetadataEntity();
  final updated = _stoppedPendingToolCalls(metadata.toolCalls);
  if (updated == null) return;

  await _persistStoppedToolCalls(
    messageRepository,
    messageId,
    metadata,
    updated,
  );
}

List<MessageToolCallEntity>? _stoppedPendingToolCalls(
  List<MessageToolCallEntity> toolCalls,
) {
  if (!toolCalls.any((toolCall) => toolCall.isPending)) return null;

  return [
    for (final toolCall in toolCalls)
      if (toolCall.isPending)
        toolCall.copyWith(resultStatus: ToolCallResultStatus.stoppedByUser)
      else
        toolCall,
  ];
}

Future<void> _persistStoppedToolCalls(
  MessageRepository messageRepository,
  String messageId,
  MessageMetadataEntity metadata,
  List<MessageToolCallEntity> updatedToolCalls,
) async {
  final _ = await messageRepository.patchMessage(
    messageId,
    .new(metadata: metadata.copyWith(toolCalls: updatedToolCalls)),
  );
}

Future<void> _updateToolResults(
  MessageRepository messageRepository,
  _ToolResultsRequest request,
) async {
  final message = await messageRepository.getMessageById(request.messageId);
  if (message == null) return;

  final metadata = message.metadata ?? const MessageMetadataEntity();
  final updatedToolCalls = _toolCallsWithResults(
    metadata.toolCalls,
    request.updates,
  );
  final _ = await messageRepository.patchMessage(
    request.messageId,
    .new(metadata: metadata.copyWith(toolCalls: updatedToolCalls)),
  );
}

List<MessageToolCallEntity> _toolCallsWithResults(
  List<MessageToolCallEntity> toolCalls,
  List<agent.AgentToolResultUpdate> updates,
) => [for (final toolCall in toolCalls) _toolCallWithResult(toolCall, updates)];

MessageToolCallEntity _toolCallWithResult(
  MessageToolCallEntity toolCall,
  List<agent.AgentToolResultUpdate> updates,
) {
  final update = updates
      .where((candidate) => candidate.toolCallId == toolCall.id)
      .firstOrNull;
  if (update == null) return toolCall;

  return toolCall.copyWith(
    resultStatus: AgentToolStatusMapper.toResultStatus(update.resultStatus),
    responseRaw: update.responseRaw,
  );
}

void _logToolExecutionError(_ToolExecutionErrorRequest request) {
  _logger.severe(
    'Tool execution failed '
    'conversationId=${request.conversationId} '
    'toolCallId=${request.toolCallId} '
    'toolType=${request.tool.type.name} '
    'toolIdentifier=${request.tool.toolIdentifier}',
    request.error,
    request.stackTrace,
  );
}

final Provider<AgentToolExecutionService>
agentToolExecutionServiceProvider = Provider<AgentToolExecutionService>((ref) {
  return AgentToolExecutionService(
    loadLatestMessageToolCallsUsecase: ref.watch(agentToolCallLoaderProvider),
    messageRepository: ref.watch(messageRepositoryProvider),
    runResolvedToolUsecase: ref.watch(resolvedToolServiceProvider),
    getAgentIterationDecisionUsecase: ref.watch(
      agentToolDecisionServiceProvider,
    ),
    agentCancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
    resolveToolApprovalDecisionForWorkspace: (workspaceId) =>
        ref.read(resolveToolApprovalDecisionUsecaseProvider(workspaceId)),
    resolveSkillCommandTarget:
        ({
          required conversationId,
          required workspaceId,
          required command,
        }) async {
          final manifests = await ref
              .read(buildLoadedSkillManifestsUsecaseProvider)
              .call(conversationId: conversationId, workspaceId: workspaceId);
          final manifest = manifests
              .where((candidate) => candidate.slug == command.skill)
              .firstOrNull;
          if (manifest == null || manifest.revision != command.revision) {
            return null;
          }
          final specs = [
            ...await ref
                .read(buildSkillTemplateToolSpecsUsecaseProvider)
                .call(conversationId: conversationId, workspaceId: workspaceId),
            ...await ref
                .read(buildAppSkillNativeToolSpecsUsecaseProvider)
                .call(conversationId: conversationId, workspaceId: workspaceId),
          ];
          const resolver = agent.AgentToolNameResolver();
          final matches = <agent.AgentResolvedToolName>[];
          for (final spec in specs) {
            final candidate = resolver.resolve(spec.name);
            if (candidate != null &&
                candidate.skillSlug == command.skill &&
                candidate.toolIdentifier == command.tool) {
              matches.add(candidate);
            }
          }

          return matches.length == 1 ? matches.single : null;
        },
  );
});
