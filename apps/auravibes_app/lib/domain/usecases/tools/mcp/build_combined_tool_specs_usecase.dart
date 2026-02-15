import 'package:auravibes_app/domain/entities/tools_group.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/usecases/tools/conversation/generate_built_in_composite_id.dart';
import 'package:auravibes_app/services/tools/tool_service.dart';
import 'package:langchain/langchain.dart';

class BuildCombinedToolSpecsUseCase {
  const BuildCombinedToolSpecsUseCase({
    required Future<ToolsGroupEntity?> Function(String groupId)
    getToolsGroupById,
    required ToolSpec? Function({
      required String mcpServerId,
      required String toolName,
    })
    getMcpToolSpec,
  }) : _getToolsGroupById = getToolsGroupById,
       _getMcpToolSpec = getMcpToolSpec;

  final Future<ToolsGroupEntity?> Function(String groupId) _getToolsGroupById;
  final ToolSpec? Function({
    required String mcpServerId,
    required String toolName,
  })
  _getMcpToolSpec;

  Future<List<ToolSpec>> call(List<WorkspaceToolEntity> enabledTools) async {
    final toolSpecs = <ToolSpec>[];

    for (final workspaceTool in enabledTools) {
      final toolType = workspaceTool.buildInType;

      if (toolType != null) {
        final userTool = ToolService.getTool(toolType);
        if (userTool == null) {
          continue;
        }

        final originalSpec = userTool.getTool();
        final compositeId = generateBuiltInCompositeId(
          tableId: workspaceTool.id,
          toolIdentifier: workspaceTool.toolId,
        );

        toolSpecs.add(
          ToolSpec(
            name: compositeId,
            description: originalSpec.description,
            inputJsonSchema: originalSpec.inputJsonSchema,
          ),
        );
        continue;
      }

      if (!workspaceTool.belongsToGroup ||
          workspaceTool.workspaceToolsGroupId == null) {
        continue;
      }

      final toolGroup = await _getToolsGroupById(
        workspaceTool.workspaceToolsGroupId!,
      );
      if (toolGroup == null || toolGroup.mcpServerId == null) {
        continue;
      }

      final mcpSpec = _getMcpToolSpec(
        mcpServerId: toolGroup.mcpServerId!,
        toolName: workspaceTool.toolId,
      );
      if (mcpSpec != null) {
        toolSpecs.add(mcpSpec);
      }
    }

    return toolSpecs;
  }
}
