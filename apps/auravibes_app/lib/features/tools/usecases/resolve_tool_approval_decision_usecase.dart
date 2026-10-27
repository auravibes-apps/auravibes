// ignore_for_file: implementation_imports
// Required: Existing helpers remain top-level for local feature use.
import 'dart:convert';

import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/data/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/service_connections/usecases/sync_connector_tool_permissions_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/sync_skill_tool_permissions_usecase.dart';
import 'package:auravibes_app/features/tools/models/tool_approval_decision.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tool_state.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:riverpod/src/providers/provider.dart';

export '../models/tool_approval_decision.dart';

class ResolveToolApprovalDecisionUsecase({
  required final ConversationToolsRepository conversationToolsRepository,
  required final ToolsGroupsRepositoryContract toolsGroupsRepository,
  required final WorkspaceToolsRepositoryContract workspaceToolsRepository,
  final SyncSkillToolPermissionsUsecase? syncSkillToolPermissionsUsecase,
  final SyncConnectorToolPermissionsUsecase?
  syncConnectorToolPermissionsUsecase,
  final Future<agent.ConversationToolAccessMode> Function(
    String conversationId,
  )?
  getToolAccessMode,
  final Future<bool> Function(String conversationId, String workspaceId)?
  workspaceAccess,
}) {
  Future<ToolApprovalDecision> call({
    required String conversationId,
    required String workspaceId,
    required String toolCallId,
    required ResolvedTool resolvedTool,
  }) => callForRequest((
    conversationId: conversationId,
    workspaceId: workspaceId,
    toolCallId: toolCallId,
    resolvedTool: resolvedTool,
    argumentsRaw: null,
  ));

  Future<ToolApprovalDecision> callForRequest(
    agent.AgentToolApprovalRequest<ResolvedTool> request,
  ) async {
    if (request.resolvedTool.isWorkspaceCommand) {
      return await _workspaceDecision(request);
    }

    return await _ordinaryDecision(request);
  }

  Future<String?> resolvePermissionTableId({
    required String conversationId,
    required String workspaceId,
    required ResolvedTool resolvedTool,
  }) {
    if (resolvedTool.isWorkspaceCommand) return Future.value();
    if (resolvedTool.isConnectorCommand) {
      return _resolveConnectorPermission(
        workspaceId,
        resolvedTool.toolIdentifier,
      );
    }
    if (_isSkillTool(resolvedTool)) {
      return _resolveSkillPermission(
        conversationId: conversationId,
        workspaceId: workspaceId,
        resolvedTool: resolvedTool,
      );
    }

    final mcpServerId = resolvedTool.mcpServerId;
    if (mcpServerId == null) {
      return Future.value(resolvedTool.tableId);
    }

    return _resolveMcpPermission(mcpServerId, resolvedTool.toolIdentifier);
  }

  Future<ToolApprovalDecision> _ordinaryDecision(
    agent.AgentToolApprovalRequest<ResolvedTool> request,
  ) async {
    final id = await resolvePermissionTableId(
      conversationId: request.conversationId,
      workspaceId: request.workspaceId,
      resolvedTool: request.resolvedTool,
    );
    if (id == null) return _notConfiguredDecision(request.toolCallId);
    final decision = await _configuredForRequest(request, id);

    return await _applyToolAccessMode(
      decision: _connectorApproval(decision, request),
      conversationId: request.conversationId,
      getToolAccessMode: getToolAccessMode,
    );
  }

  Future<ToolApprovalDecision> _workspaceDecision(
    agent.AgentToolApprovalRequest<ResolvedTool> request,
  ) async {
    if (!await _canAccessWorkspace(request, workspaceAccess)) {
      return ToolApprovalDecision(
        toolCallId: request.toolCallId,
        permissionResult: .disabledInWorkspace,
      );
    }

    return await _applyToolAccessMode(
      decision: _workspaceConfiguredDecision(request),
      conversationId: request.conversationId,
      getToolAccessMode: getToolAccessMode,
    );
  }

  Future<ToolApprovalDecision> _configuredForRequest(
    agent.AgentToolApprovalRequest<ResolvedTool> request,
    String permissionTableId,
  ) => _configuredDecision(conversationToolsRepository, (
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
    toolCallId: request.toolCallId,
    permissionTableId: permissionTableId,
  ));

  Future<String?> _resolveConnectorPermission(
    String workspaceId,
    String toolName,
  ) =>
      syncConnectorToolPermissionsUsecase?.permissionTableIdFor(
        workspaceId: workspaceId,
        toolName: toolName,
      ) ??
      Future.value();

  Future<String?> _resolveSkillPermission({
    required String conversationId,
    required String workspaceId,
    required ResolvedTool resolvedTool,
  }) {
    return syncSkillToolPermissionsUsecase?.permissionTableIdFor(
          conversationId: conversationId,
          workspaceId: workspaceId,
          toolName: resolvedTool.fullName,
        ) ??
        Future.value();
  }

  Future<String?> _resolveMcpPermission(
    String serverId,
    String toolName,
  ) async {
    final toolGroup = await toolsGroupsRepository.getToolsGroupByMcpServerId(
      serverId,
    );
    if (toolGroup == null || !toolGroup.isEnabled) return null;
    final workspaceTool = await workspaceToolsRepository
        .getWorkspaceToolByToolName(
          toolGroupId: toolGroup.id,
          toolName: toolName,
        );

    return workspaceTool?.id;
  }

  bool _isSkillTool(ResolvedTool resolvedTool) =>
      resolvedTool.isSkillControl || resolvedTool.isSkillNative;
}

ToolApprovalDecision _connectorApproval(
  ToolApprovalDecision decision,
  agent.AgentToolApprovalRequest<ResolvedTool> request,
) {
  if (!decision.isGranted() || !_requiresWriteApproval(request)) {
    return decision;
  }

  return ToolApprovalDecision(
    toolCallId: decision.toolCallId,
    permissionResult: .needsConfirmation,
    permissionTableId: decision.permissionTableId,
  );
}

bool _requiresWriteApproval(
  agent.AgentToolApprovalRequest<ResolvedTool> request,
) =>
    request.resolvedTool.isConnectorCommand &&
    request.resolvedTool.toolIdentifier == agent.executeConnectorToolName &&
    agent.connectorCommandMayWrite(
      request.argumentsRaw,
      agent.connectorDefinitions,
    );

Future<ToolApprovalDecision> _applyToolAccessMode({
  required ToolApprovalDecision decision,
  required String conversationId,
  required Future<agent.ConversationToolAccessMode> Function(
    String conversationId,
  )?
  getToolAccessMode,
}) async {
  if (!decision.needsConfirmation) return decision;

  return decision.withToolAccessMode(
    mode: await getToolAccessMode?.call(conversationId) ?? .defaultMode,
  );
}

ToolApprovalDecision _notConfiguredDecision(String toolCallId) =>
    ToolApprovalDecision(
      toolCallId: toolCallId,
      permissionResult: .notConfigured,
    );

Future<ToolApprovalDecision> _configuredDecision(
  ConversationToolsRepository repository,
  ({
    String conversationId,
    String workspaceId,
    String toolCallId,
    String permissionTableId,
  })
  request,
) async {
  final permissionResult = await repository.checkToolPermission(
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
    toolId: request.permissionTableId,
  );

  return ToolApprovalDecision(
    toolCallId: request.toolCallId,
    permissionResult: permissionResult,
    permissionTableId: request.permissionTableId,
  );
}

final ProviderFamily<ResolveToolApprovalDecisionUsecase, String>
resolveToolApprovalDecisionUsecaseProvider =
    Provider.family<ResolveToolApprovalDecisionUsecase, String>((
      ref,
      workspaceId,
    ) {
      final session = ref
          .watch(workspaceSessionForRouteProvider(workspaceId))
          .requireValue;

      final repository = ref.watch(
        conversationToolsRepositoryProvider(workspaceId),
      );

      return ResolveToolApprovalDecisionUsecase(
        conversationToolsRepository: repository,
        toolsGroupsRepository: ref.watch(
          toolsGroupsRepositoryProvider(session),
        ),
        workspaceToolsRepository: ref.watch(
          workspaceToolsRepositoryProvider(session),
        ),
        syncSkillToolPermissionsUsecase: ref.watch(
          syncSkillToolPermissionsUsecaseProvider,
        ),
        syncConnectorToolPermissionsUsecase: ref.watch(
          syncConnectorToolPermissionsUsecaseProvider,
        ),
        getToolAccessMode: repository.getToolAccessMode,
        workspaceAccess: (conversationId, expectedWorkspaceId) async =>
            (await ref
                    .read(conversationRepositoryProvider)
                    .getConversationById(conversationId))
                ?.workspaceId ==
            expectedWorkspaceId,
      );
    });

bool _workspaceApproval(String? arguments, String toolName) {
  try {
    final decoded = jsonDecode(arguments ?? 'null');

    return decoded is! Map<String, dynamic> ||
        agent.workspaceCommandNeedsApproval(
          agent.workspaceCommandArgumentsForTool(toolName, decoded),
        );
  } on FormatException {
    return true;
  }
}

ToolApprovalDecision _workspaceConfiguredDecision(
  agent.AgentToolApprovalRequest<ResolvedTool> request,
) => ToolApprovalDecision(
  toolCallId: request.toolCallId,
  permissionResult:
      _workspaceApproval(
        request.argumentsRaw,
        request.resolvedTool.toolIdentifier,
      )
      ? .needsConfirmation
      : .granted,
  permissionTableId: agent.workspaceCommandTableId,
);

Future<bool> _canAccessWorkspace(
  agent.AgentToolApprovalRequest<ResolvedTool> request,
  Future<bool> Function(String, String)? workspaceAccess,
) =>
    workspaceAccess?.call(request.conversationId, request.workspaceId) ??
    Future.value(false);
