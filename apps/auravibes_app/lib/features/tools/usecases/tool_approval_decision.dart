// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/features/skills/usecases/sync_skill_tool_permissions_usecase.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tool_state.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:riverpod/riverpod.dart';

class ToolApprovalDecision {
  const ToolApprovalDecision({
    required this.toolCallId,
    required this.permissionResult,
    this.permissionTableId,
  });

  final String toolCallId;
  final ToolPermissionResult permissionResult;
  final String? permissionTableId;

  bool get needsConfirmation =>
      permissionResult == ToolPermissionResult.needsConfirmation;
}

class ResolveToolApprovalDecisionUsecase {
  const ResolveToolApprovalDecisionUsecase({
    required this.conversationToolsRepository,
    required this.toolsGroupsRepository,
    required this.workspaceToolsRepository,
    this.syncSkillToolPermissionsUsecase,
  });

  final ConversationToolsRepository conversationToolsRepository;
  final ToolsGroupsRepository toolsGroupsRepository;
  final WorkspaceToolsRepository workspaceToolsRepository;
  final SyncSkillToolPermissionsUsecase? syncSkillToolPermissionsUsecase;

  Future<ToolApprovalDecision> call({
    required String conversationId,
    required String workspaceId,
    required String toolCallId,
    required ResolvedTool resolvedTool,
  }) async {
    final permissionTableId = await resolvePermissionTableId(
      conversationId: conversationId,
      workspaceId: workspaceId,
      resolvedTool: resolvedTool,
    );
    if (permissionTableId == null) {
      return ToolApprovalDecision(
        toolCallId: toolCallId,
        permissionResult: ToolPermissionResult.notConfigured,
      );
    }

    final permissionResult = await conversationToolsRepository
        .checkToolPermission(
          conversationId: conversationId,
          workspaceId: workspaceId,
          toolId: permissionTableId,
        );

    return ToolApprovalDecision(
      toolCallId: toolCallId,
      permissionResult: permissionResult,
      permissionTableId: permissionTableId,
    );
  }

  Future<String?> resolvePermissionTableId({
    required String conversationId,
    required String workspaceId,
    required ResolvedTool resolvedTool,
  }) async {
    if (resolvedTool.isSkillControl ||
        resolvedTool.isSkillTemplate ||
        resolvedTool.isSkillNative) {
      return syncSkillToolPermissionsUsecase?.permissionTableIdFor(
        conversationId: conversationId,
        workspaceId: workspaceId,
        toolName: resolvedTool.fullName,
      );
    }

    final mcpServerId = resolvedTool.mcpServerId;
    if (mcpServerId == null) {
      return resolvedTool.tableId;
    }

    final toolGroup = await toolsGroupsRepository.getToolsGroupByMcpServerId(
      mcpServerId,
    );
    if (toolGroup == null) return null;

    final workspaceTool = await workspaceToolsRepository
        .getWorkspaceToolByToolName(
          toolGroupId: toolGroup.id,
          toolName: resolvedTool.toolIdentifier,
        );

    return workspaceTool?.id;
  }
}

final resolveToolApprovalDecisionUsecaseProvider =
    Provider<ResolveToolApprovalDecisionUsecase>((ref) {
      return ResolveToolApprovalDecisionUsecase(
        conversationToolsRepository: ref.watch(
          conversationToolsRepositoryProvider,
        ),
        toolsGroupsRepository: ref.watch(toolsGroupsRepositoryProvider),
        workspaceToolsRepository: ref.watch(workspaceToolsRepositoryProvider),
        syncSkillToolPermissionsUsecase: ref.watch(
          syncSkillToolPermissionsUsecaseProvider,
        ),
      );
    });
