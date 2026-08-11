// ignore_for_file: always_put_required_named_parameters_first
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.

import 'dart:convert';

import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart'
    hide ToolToCall;
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_call_loader.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_decision_service.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_status_mapper.dart';
import 'package:auravibes_app/services/agent_harness/resolved_tool_service.dart';
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

class AgentToolExecutionService
    extends agent.AgentToolExecutionRunner<ResolvedTool> {
  AgentToolExecutionService({
    required AgentToolCallLoader loadLatestMessageToolCallsUsecase,
    required MessageRepository messageRepository,
    ResolveToolApprovalDecisionUsecase? resolveToolApprovalDecision,
    ResolveToolApprovalDecisionUsecase Function(String workspaceId)?
    resolveToolApprovalDecisionForWorkspace,
    ResolveSkillCommandTarget? resolveSkillCommandTarget,
    required ResolvedToolService runResolvedToolUsecase,
    required AgentToolDecisionService getAgentIterationDecisionUsecase,
    required AgentCancellationRuntime agentCancellationRuntime,
  }) : super(
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

class AppAllowedToolsDataProvider
    implements agent.AgentToolExecutionProvider<ResolvedTool> {
  const AppAllowedToolsDataProvider({
    required this.messageRepository,
    required this.loadLatestMessageToolCallsService,
    this.resolveToolApprovalDecisionUsecase,
    this.resolveToolApprovalDecisionUsecaseForWorkspace,
    this.resolveSkillCommandTarget,
    required this.resolvedToolService,
    required this.toolDecisionService,
    required this.agentCancellationRuntime,
  });

  final MessageRepository messageRepository;
  final AgentToolCallLoader loadLatestMessageToolCallsService;
  final ResolveToolApprovalDecisionUsecase? resolveToolApprovalDecisionUsecase;
  final ResolveToolApprovalDecisionUsecase Function(String workspaceId)?
  resolveToolApprovalDecisionUsecaseForWorkspace;
  final ResolveSkillCommandTarget? resolveSkillCommandTarget;
  final ResolvedToolService resolvedToolService;
  final AgentToolDecisionService toolDecisionService;
  final AgentCancellationRuntime agentCancellationRuntime;

  @override
  Future<agent.LoadLatestMessageToolCallsResult<ResolvedTool>>
  loadLatestToolCalls({required String conversationId}) {
    return loadLatestMessageToolCallsService.call(
      conversationId: conversationId,
    );
  }

  @override
  Future<agent.AgentToolApprovalDecision> resolveToolApprovalDecision({
    required String conversationId,
    required String workspaceId,
    required String toolCallId,
    required ResolvedTool resolvedTool,
    String argumentsRaw = '{}',
  }) async {
    final resolver =
        resolveToolApprovalDecisionUsecaseForWorkspace?.call(workspaceId) ??
        resolveToolApprovalDecisionUsecase;
    if (resolver == null) {
      throw StateError('No tool approval resolver is configured');
    }

    var approvalTool = resolvedTool;
    if (resolvedTool.isSkillCommand &&
        resolvedTool.toolIdentifier == agent.callSkillToolName) {
      final Object? decoded;
      try {
        decoded = jsonDecode(argumentsRaw);
      } on FormatException {
        return const agent.AgentToolApprovalDecision(
          permissionResult: agent.AgentToolPermissionResult.notConfigured,
        );
      }
      if (decoded is! Map<String, Object?>) {
        return const agent.AgentToolApprovalDecision(
          permissionResult: agent.AgentToolPermissionResult.notConfigured,
        );
      }

      final effective = await agent.resolveEffectiveToolApprovalTarget(
        requestedTarget: agent.AgentResolvedToolName.skillControl(
          toolIdentifier: resolvedTool.toolIdentifier,
        ),
        arguments: decoded,
        resolveSkillTarget: (command) {
          final resolveTarget = resolveSkillCommandTarget;
          if (resolveTarget == null) {
            return Future<agent.AgentResolvedToolName?>.value();
          }

          return resolveTarget(
            conversationId: conversationId,
            workspaceId: workspaceId,
            command: command,
          );
        },
      );
      if (effective == null) {
        return const agent.AgentToolApprovalDecision(
          permissionResult: agent.AgentToolPermissionResult.notConfigured,
        );
      }
      approvalTool = ResolvedTool.skillCommand(
        commandName: resolvedTool.toolIdentifier,
        target: effective,
      );
    }

    final decision = await resolver.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      toolCallId: toolCallId,
      resolvedTool: approvalTool,
    );

    return agent.AgentToolApprovalDecision(
      permissionResult: toAgentToolPermissionResult(
        decision.permissionResult,
      ),
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
  void logToolExecutionError({
    required String conversationId,
    required String toolCallId,
    required ResolvedTool tool,
    required Object error,
    required StackTrace stackTrace,
  }) {
    _logToolExecutionError(
      conversationId: conversationId,
      toolCallId: toolCallId,
      tool: tool,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  Future<void> stopPendingTools({required String messageId}) async {
    final message = await messageRepository.getMessageById(messageId);
    if (message == null) return;

    final metadata = message.metadata ?? const MessageMetadataEntity();
    var didUpdate = false;
    final updatedToolCalls = metadata.toolCalls.map((toolCall) {
      if (!toolCall.isPending) return toolCall;

      didUpdate = true;

      return toolCall.copyWith(
        resultStatus: ToolCallResultStatus.stoppedByUser,
      );
    }).toList();
    if (!didUpdate) return;

    final _ = await messageRepository.patchMessage(
      messageId,
      MessagePatch(
        metadata: metadata.copyWith(toolCalls: updatedToolCalls),
      ),
    );
  }

  @override
  Future<void> updateToolResults({
    required String messageId,
    required List<agent.AgentToolResultUpdate> updates,
  }) async {
    final message = await messageRepository.getMessageById(messageId);
    if (message == null) return;

    final metadata = message.metadata ?? const MessageMetadataEntity();
    final updatedToolCalls = metadata.toolCalls.map((toolCall) {
      final update = updates
          .where((candidate) => candidate.toolCallId == toolCall.id)
          .firstOrNull;
      if (update == null) return toolCall;

      return toolCall.copyWith(
        resultStatus: toAppToolCallResultStatus(update.resultStatus),
        responseRaw: update.responseRaw,
      );
    }).toList();

    final _ = await messageRepository.patchMessage(
      messageId,
      MessagePatch(
        metadata: metadata.copyWith(toolCalls: updatedToolCalls),
      ),
    );
  }
}

void _logToolExecutionError({
  required String conversationId,
  required String toolCallId,
  required ResolvedTool tool,
  required Object error,
  required StackTrace stackTrace,
}) {
  _logger.severe(
    'Tool execution failed '
    'conversationId=$conversationId '
    'toolCallId=$toolCallId '
    'toolType=${tool.type.name} '
    'toolIdentifier=${tool.toolIdentifier}',
    error,
    stackTrace,
  );
}

final Provider<AgentToolExecutionService> agentToolExecutionServiceProvider =
    Provider<AgentToolExecutionService>((
      ref,
    ) {
      return AgentToolExecutionService(
        loadLatestMessageToolCallsUsecase: ref.watch(
          agentToolCallLoaderProvider,
        ),
        messageRepository: ref.watch(messageRepositoryProvider),
        resolveToolApprovalDecisionForWorkspace: (workspaceId) => ref.read(
          resolveToolApprovalDecisionUsecaseProvider(workspaceId),
        ),
        resolveSkillCommandTarget:
            ({
              required conversationId,
              required workspaceId,
              required command,
            }) async {
              final manifests = await ref
                  .read(buildLoadedSkillManifestsUsecaseProvider)
                  .call(
                    conversationId: conversationId,
                    workspaceId: workspaceId,
                  );
              final manifest = manifests
                  .where((candidate) => candidate.slug == command.skill)
                  .firstOrNull;
              if (manifest == null || manifest.revision != command.revision) {
                return null;
              }
              final specs = [
                ...await ref
                    .read(buildSkillTemplateToolSpecsUsecaseProvider)
                    .call(
                      conversationId: conversationId,
                      workspaceId: workspaceId,
                    ),
                ...await ref
                    .read(buildAppSkillNativeToolSpecsUsecaseProvider)
                    .call(
                      conversationId: conversationId,
                      workspaceId: workspaceId,
                    ),
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
