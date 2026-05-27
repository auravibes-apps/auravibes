// ignore_for_file: avoid-non-null-assertion
// Required: Existing nullable API contracts still use explicit assertions.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/usecases/tools/conversation/generate_built_in_composite_id.dart';
import 'package:auravibes_app/services/tools/native_tool_service.dart';
import 'package:auravibes_app/services/tools/tool_service.dart';

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

  Future<List<ToolSpec>> call(
    List<WorkspaceToolEntity> enabledTools,
  ) async {
    final toolSpecs = <ToolSpec>[];

    for (final workspaceTool in enabledTools) {
      final toolSpec = await _buildToolSpec(workspaceTool);
      if (toolSpec != null) toolSpecs.add(toolSpec);
    }

    return toolSpecs;
  }

  Future<ToolSpec?> _buildToolSpec(WorkspaceToolEntity workspaceTool) async {
    final builtInSpec = _buildBuiltInToolSpec(workspaceTool);
    if (builtInSpec != null) return builtInSpec;

    final nativeSpec = _buildNativeToolSpec(workspaceTool);
    if (nativeSpec != null) return nativeSpec;

    return _buildMcpToolSpec(workspaceTool);
  }

  ToolSpec? _buildBuiltInToolSpec(WorkspaceToolEntity workspaceTool) {
    final toolType = workspaceTool.buildInType;
    if (toolType == null) return null;

    final userTool = ToolService.getTool(toolType);
    if (userTool == null) return null;

    final originalSpec = userTool.getTool();
    final compositeId = generateBuiltInCompositeId(
      tableId: workspaceTool.id,
      toolIdentifier: workspaceTool.toolId,
    );
    return ToolSpec(
      name: compositeId,
      description: originalSpec.description,
      inputJsonSchema: originalSpec.inputJsonSchema,
    );
  }

  ToolSpec? _buildNativeToolSpec(WorkspaceToolEntity workspaceTool) {
    final nativeToolType = workspaceTool.nativeType;
    if (nativeToolType == null) return null;

    final nativeTool = NativeToolService.getTool(nativeToolType);
    if (nativeTool == null) return null;

    final originalSpec = nativeTool.getTool();
    final compositeId = generateNativeCompositeId(
      tableId: workspaceTool.id,
      toolIdentifier: nativeToolType.value,
    );
    return ToolSpec(
      name: compositeId,
      description: originalSpec.description,
      inputJsonSchema: originalSpec.inputJsonSchema,
    );
  }

  Future<ToolSpec?> _buildMcpToolSpec(WorkspaceToolEntity workspaceTool) async {
    if (!workspaceTool.belongsToGroup ||
        workspaceTool.workspaceToolsGroupId == null) {
      return null;
    }

    final toolGroup = await _getToolsGroupById(
      workspaceTool.workspaceToolsGroupId!,
    );
    final mcpServerId = toolGroup?.mcpServerId;
    if (mcpServerId == null) return null;

    return _getMcpToolSpec(
      mcpServerId: mcpServerId,
      toolName: workspaceTool.toolId,
    );
  }
}
