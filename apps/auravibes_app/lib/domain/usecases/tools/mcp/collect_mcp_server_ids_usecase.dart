import 'package:auravibes_app/domain/entities/tools_group.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';

class CollectMcpServerIdsUseCase {
  const CollectMcpServerIdsUseCase({
    required Future<ToolsGroupEntity?> Function(String groupId)
    getToolsGroupById,
  }) : _getToolsGroupById = getToolsGroupById;

  final Future<ToolsGroupEntity?> Function(String groupId) _getToolsGroupById;

  Future<List<String>> call(List<WorkspaceToolEntity> enabledTools) async {
    final mcpServerIds = <String>{};

    for (final workspaceTool in enabledTools) {
      if (workspaceTool.buildInType != null) {
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
      mcpServerIds.add(toolGroup.mcpServerId!);
    }

    return mcpServerIds.toList();
  }
}
