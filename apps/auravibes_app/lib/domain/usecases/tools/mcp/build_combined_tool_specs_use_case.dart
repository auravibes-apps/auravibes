// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/native_tool_service.dart';
import 'package:auravibes_app/services/tools/tool_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

class BuildCombinedToolSpecsUseCase {
  const BuildCombinedToolSpecsUseCase({
    required this._getToolsGroupById,
    required this._getMcpToolSpec,
  });

  final Future<ToolsGroupEntity?> Function(String groupId) _getToolsGroupById;
  final ToolSpec? Function({
    required String mcpServerId,
    required String toolName,
  })
  _getMcpToolSpec;

  Future<List<ToolCatalogCandidate<ResolvedTool>>> call(
    List<WorkspaceToolEntity> enabledTools,
  ) async {
    final candidates = <ToolCatalogCandidate<ResolvedTool>>[];

    for (final workspaceTool in enabledTools) {
      final candidate = await _buildCandidate(workspaceTool);
      if (candidate != null) candidates.add(candidate);
    }

    return candidates;
  }

  Future<ToolCatalogCandidate<ResolvedTool>?> _buildCandidate(
    WorkspaceToolEntity workspaceTool,
  ) async {
    if (workspaceTool.belongsToGroup) {
      return _buildMcpCandidate(workspaceTool);
    }

    final builtInCandidate = _buildBuiltInCandidate(workspaceTool);
    if (builtInCandidate != null) return builtInCandidate;

    return _buildNativeCandidate(workspaceTool);
  }

  ToolCatalogCandidate<ResolvedTool>? _buildBuiltInCandidate(
    WorkspaceToolEntity workspaceTool,
  ) {
    final toolType = workspaceTool.buildInType;
    if (toolType == null) return null;

    final userTool = ToolService.getTool(toolType);
    if (userTool == null) return null;

    return ToolCatalogCandidate.external(
      spec: userTool.getTool(),
      target: ResolvedTool.builtIn(
        tableId: workspaceTool.id,
        toolIdentifier: workspaceTool.toolId,
        tooltype: toolType,
      ),
      sourceId: 'user:${workspaceTool.id}',
    );
  }

  ToolCatalogCandidate<ResolvedTool>? _buildNativeCandidate(
    WorkspaceToolEntity workspaceTool,
  ) {
    final nativeToolType = workspaceTool.nativeType;
    if (nativeToolType == null) return null;

    final nativeTool = NativeToolService.getTool(nativeToolType);
    if (nativeTool == null) return null;

    return ToolCatalogCandidate.reserved(
      spec: nativeTool.getTool(),
      target: ResolvedTool.native(
        tableId: workspaceTool.id,
        nativeToolType: nativeToolType,
      ),
    );
  }

  Future<ToolCatalogCandidate<ResolvedTool>?> _buildMcpCandidate(
    WorkspaceToolEntity workspaceTool,
  ) async {
    final workspaceToolsGroupId = workspaceTool.workspaceToolsGroupId;
    if (!workspaceTool.belongsToGroup || workspaceToolsGroupId == null) {
      return null;
    }

    final toolGroup = await _getToolsGroupById(workspaceToolsGroupId);
    final mcpServerId = toolGroup?.mcpServerId;
    if (mcpServerId == null) return null;

    final originalSpec = _getMcpToolSpec(
      mcpServerId: mcpServerId,
      toolName: workspaceTool.toolId,
    );
    if (originalSpec == null) return null;

    final legacyTarget = const AgentToolNameResolver().resolve(
      originalSpec.name,
    );
    // ponytail: Legacy spec names carry slug; server ID is safe fallback.
    final mcpSlug = legacyTarget?.mcpSlug ?? mcpServerId;

    return ToolCatalogCandidate.external(
      spec: ToolSpec(
        name: 'mcp_${workspaceTool.toolId}',
        description: originalSpec.description,
        inputJsonSchema: originalSpec.inputJsonSchema,
      ),
      target: ResolvedTool.mcp(
        tableId: workspaceTool.id,
        toolIdentifier: workspaceTool.toolId,
        mcpServerId: mcpServerId,
        mcpSlug: mcpSlug,
      ),
      sourceId: 'mcp:$mcpServerId:${workspaceTool.id}:${workspaceTool.toolId}',
    );
  }
}
