// ignore_for_file: implementation_imports
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/data/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_tools_repository.dart';
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
}) {
  Future<ToolApprovalDecision> call({
    required String conversationId,
    required String workspaceId,
    required String toolCallId,
    required ResolvedTool resolvedTool,
  }) async {
    if (_isListSkillsTool(resolvedTool)) {
      return ToolApprovalDecision(
        toolCallId: toolCallId,
        permissionResult: .granted,
      );
    }

    final permissionTableId = await resolvePermissionTableId(
      conversationId: conversationId,
      workspaceId: workspaceId,
      resolvedTool: resolvedTool,
    );
    if (permissionTableId == null) {
      return _notConfiguredDecision(toolCallId);
    }

    return _configuredDecision(conversationToolsRepository, (
      conversationId: conversationId,
      workspaceId: workspaceId,
      toolCallId: toolCallId,
      permissionTableId: permissionTableId,
    ));
  }

  Future<String?> resolvePermissionTableId({
    required String conversationId,
    required String workspaceId,
    required ResolvedTool resolvedTool,
  }) async {
    if (_isSkillTool(resolvedTool)) {
      return _resolveSkillPermission(
        conversationId: conversationId,
        workspaceId: workspaceId,
        resolvedTool: resolvedTool,
      );
    }

    final mcpServerId = resolvedTool.mcpServerId;
    if (mcpServerId == null) {
      return resolvedTool.tableId;
    }

    return _resolveMcpPermission(mcpServerId, resolvedTool.toolIdentifier);
  }

  Future<String?> _resolveSkillPermission({
    required String conversationId,
    required String workspaceId,
    required ResolvedTool resolvedTool,
  }) {
    if (resolvedTool.toolIdentifier == agent.callSkillToolName &&
        resolvedTool.target == null) {
      return Future.value();
    }

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
    if (toolGroup == null) return null;
    final workspaceTool = await workspaceToolsRepository
        .getWorkspaceToolByToolName(
          toolGroupId: toolGroup.id,
          toolName: toolName,
        );
    return workspaceTool?.id;
  }

  bool _isSkillTool(ResolvedTool resolvedTool) =>
      resolvedTool.isSkillCommand ||
      resolvedTool.isSkillControl ||
      resolvedTool.isSkillTemplate ||
      resolvedTool.isSkillNative;
}

bool _isListSkillsTool(ResolvedTool tool) =>
    (tool.isSkillControl || tool.isSkillCommand) &&
    tool.toolIdentifier == agent.listSkillsToolName;

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

      return ResolveToolApprovalDecisionUsecase(
        conversationToolsRepository: ref.watch(
          conversationToolsRepositoryProvider(workspaceId),
        ),
        toolsGroupsRepository: ref.watch(
          toolsGroupsRepositoryProvider(session),
        ),
        workspaceToolsRepository: ref.watch(
          workspaceToolsRepositoryProvider(session),
        ),
        syncSkillToolPermissionsUsecase: ref.watch(
          syncSkillToolPermissionsUsecaseProvider,
        ),
      );
    });
