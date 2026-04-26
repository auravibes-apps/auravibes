import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tools_notifier.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_provider.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool.dart';
import 'package:flutter/foundation.dart';
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
  });

  final ConversationToolsRepository conversationToolsRepository;
  final ToolsGroupsRepository toolsGroupsRepository;
  final WorkspaceToolsRepository workspaceToolsRepository;

  Future<ToolApprovalDecision> call({
    required String conversationId,
    required String workspaceId,
    required String toolCallId,
    required ResolvedTool resolvedTool,
  }) async {
    final permissionTableId = await _resolvePermissionTableId(resolvedTool);
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

  @visibleForTesting
  Future<String?> resolvePermissionTableId(ResolvedTool resolvedTool) =>
      _resolvePermissionTableId(resolvedTool);

  Future<String?> _resolvePermissionTableId(ResolvedTool resolvedTool) async {
    if (resolvedTool.mcpServerId == null) {
      return resolvedTool.toolIdentifier;
    }

    final toolGroup = await toolsGroupsRepository.getToolsGroupByMcpServerId(
      resolvedTool.mcpServerId!,
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
      );
    });
