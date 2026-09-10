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

typedef _ToolResultsRequest = ({
  String messageId,
  List<agent.AgentToolResultUpdate> updates,
});

class AgentToolExecutionService({
  required AgentToolCallLoader loadLatestMessageToolCallsUsecase,
  required MessageRepository messageRepository,
  ResolveToolApprovalDecisionUsecase? resolveToolApprovalDecision,
  ResolveToolApprovalDecisionUsecase Function(String workspaceId)?
  resolveToolApprovalDecisionForWorkspace,
  ResolveSkillCommandTarget? resolveSkillCommandTarget,
  required ResolvedToolService runResolvedToolUsecase,
  required AgentToolDecisionService getAgentIterationDecisionUsecase,
  required AgentCancellationRuntime agentCancellationRuntime,
}) extends agent.AgentToolExecutionRunner<ResolvedTool> {
  this
    : super(
        provider: AppAllowedToolsDataProvider(
          messageRepository: messageRepository,
          loadLatestMessageToolCallsService: loadLatestMessageToolCallsUsecase,
          resolveToolApprovalDecisionUsecase: resolveToolApprovalDecision,
          resolveToolApprovalDecisionUsecaseForWorkspace:
              resolveToolApprovalDecisionForWorkspace,
          resolveSkillCommandTarget: resolveSkillCommandTarget,
          resolvedToolService: runResolvedToolUsecase,
          toolDecisionService: getAgentIterationDecisionUsecase,
          agentCancellationRuntime: agentCancellationRuntime,
        ),
      );
}

class const AppAllowedToolsDataProvider({
  required final MessageRepository messageRepository,
  required final AgentToolCallLoader loadLatestMessageToolCallsService,
  final ResolveToolApprovalDecisionUsecase? resolveToolApprovalDecisionUsecase,
  final ResolveToolApprovalDecisionUsecase Function(String workspaceId)?
  resolveToolApprovalDecisionUsecaseForWorkspace,
  final ResolveSkillCommandTarget? resolveSkillCommandTarget,
  required final ResolvedToolService resolvedToolService,
  required final AgentToolDecisionService toolDecisionService,
  required final AgentCancellationRuntime agentCancellationRuntime,
}) implements agent.AgentToolExecutionProvider<ResolvedTool> {
  late final Future<agent.AgentToolApprovalDecision> Function({
    required String conversationId,
    required String workspaceId,
    required String toolCallId,
    required ResolvedTool resolvedTool,
    String argumentsRaw,
  })
  resolveToolApprovalDecision =
      ({
        required conversationId,
        required workspaceId,
        required toolCallId,
        required resolvedTool,
        argumentsRaw = '{}',
      }) {
        return _resolveToolApprovalDecision((
          resolver: resolveToolApprovalDecisionUsecase,
          resolverForWorkspace: resolveToolApprovalDecisionUsecaseForWorkspace,
          resolveSkillCommandTarget: resolveSkillCommandTarget,
          conversationId: conversationId,
          workspaceId: workspaceId,
          toolCallId: toolCallId,
          resolvedTool: resolvedTool,
          argumentsRaw: argumentsRaw,
        ));
      };

  late final void Function({
    required String conversationId,
    required String toolCallId,
    required ResolvedTool tool,
    required Object error,
    required StackTrace stackTrace,
  })
  logToolExecutionError =
      ({
        required conversationId,
        required toolCallId,
        required tool,
        required error,
        required stackTrace,
      }) {
        _logToolExecutionError((
          conversationId: conversationId,
          toolCallId: toolCallId,
          tool: tool,
          error: error,
          stackTrace: stackTrace,
        ));
      };

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
  final resolver =
      request.resolverForWorkspace?.call(request.workspaceId) ??
      request.resolver;
  if (resolver == null) {
    throw StateError('No tool approval resolver is configured');
  }

  final approvalTool = await _resolveApprovalTool(request);
  if (approvalTool == null) return _notConfiguredApprovalDecision();

  final decision = await resolver.call(
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
    toolCallId: request.toolCallId,
    resolvedTool: approvalTool,
  );

  return agent.AgentToolApprovalDecision(
    permissionResult: AgentToolStatusMapper.toPermissionResult(
      decision.permissionResult,
    ),
  );
}

Future<ResolvedTool?> _resolveApprovalTool(_ToolApprovalRequest request) async {
  final tool = request.resolvedTool;
  if (!tool.isSkillCommand || tool.toolIdentifier != agent.callSkillToolName) {
    return tool;
  }

  final decoded = _decodeArguments(request.argumentsRaw);
  if (decoded == null) return null;

  final effective = await agent.resolveEffectiveToolApprovalTarget(
    requestedTarget: .skillControl(toolIdentifier: tool.toolIdentifier),
    arguments: decoded,
    resolveSkillTarget: (command) {
      final resolveTarget = request.resolveSkillCommandTarget;
      if (resolveTarget == null) {
        return Future<agent.AgentResolvedToolName?>.value();
      }

      return resolveTarget(
        conversationId: request.conversationId,
        workspaceId: request.workspaceId,
        command: command,
      );
    },
  );
  if (effective == null) return null;

  return ResolvedTool.skillCommand(
    commandName: tool.toolIdentifier,
    target: effective,
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
  var didUpdate = false;
  final updatedToolCalls = metadata.toolCalls.map((toolCall) {
    if (!toolCall.isPending) return toolCall;

    didUpdate = true;
    return toolCall.copyWith(resultStatus: ToolCallResultStatus.stoppedByUser);
  }).toList();
  if (!didUpdate) return;

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
) => toolCalls.map((toolCall) {
  final update = updates
      .where((candidate) => candidate.toolCallId == toolCall.id)
      .firstOrNull;
  if (update == null) return toolCall;

  return toolCall.copyWith(
    resultStatus: AgentToolStatusMapper.toResultStatus(update.resultStatus),
    responseRaw: update.responseRaw,
  );
}).toList();

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
    runResolvedToolUsecase: ref.watch(resolvedToolServiceProvider),
    getAgentIterationDecisionUsecase: ref.watch(
      agentToolDecisionServiceProvider,
    ),
    agentCancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
  );
});
