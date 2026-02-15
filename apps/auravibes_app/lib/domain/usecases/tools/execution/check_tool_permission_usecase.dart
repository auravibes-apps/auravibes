// lib/domain/usecases/tools/check_tool_permission_usecase.dart
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool.dart';

/// Use case for checking tool permissions.
///
/// This is a simple class with constructor injection - no Riverpod.
class CheckToolPermissionUseCase {
  const CheckToolPermissionUseCase(
    this._conversationToolsRepo,
    this._toolsGroupsRepo,
    this._workspaceToolsRepo,
  );

  final ConversationToolsRepository _conversationToolsRepo;
  final ToolsGroupsRepository _toolsGroupsRepo;
  final WorkspaceToolsRepository _workspaceToolsRepo;

  /// Checks permission for a tool in a conversation context
  Future<ToolPermissionResult> call({
    required String conversationId,
    required String workspaceId,
    required ResolvedTool resolvedTool,
  }) async {
    // Get the permission table ID for the tool
    final permissionTableId = await _resolvePermissionTableId(resolvedTool);

    if (permissionTableId == null) {
      return ToolPermissionResult.notConfigured;
    }

    // Check permission using the table ID for granular permissions
    return _conversationToolsRepo.checkToolPermission(
      conversationId: conversationId,
      workspaceId: workspaceId,
      toolId: permissionTableId,
    );
  }

  /// Resolves the database table ID for permission checks
  ///
  /// For built-in tools: returns the tableId directly
  /// For MCP tools: looks up the workspace tool ID
  Future<String?> _resolvePermissionTableId(ResolvedTool resolvedTool) async {
    // Built-in tools already include the workspace tool table ID
    if (resolvedTool.mcpServerId == null) {
      return resolvedTool.tableId;
    }

    // MCP tools need to resolve the workspace tool ID
    final toolGroup = await _toolsGroupsRepo.getToolsGroupByMcpServerId(
      resolvedTool.mcpServerId!,
    );

    if (toolGroup == null) {
      return null;
    }

    final workspaceTool = await _workspaceToolsRepo.getWorkspaceToolByToolName(
      toolGroupId: toolGroup.id,
      toolName: resolvedTool.toolIdentifier,
    );

    return workspaceTool?.id;
  }
}
