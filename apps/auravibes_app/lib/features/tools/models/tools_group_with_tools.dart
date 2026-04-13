import 'package:auravibes_app/domain/entities/tools_group.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/models/grouped_tools_view_item.dart';
import 'package:auravibes_app/features/tools/models/tools_group_mixin.dart';
import 'package:auravibes_app/notifiers/mcp_connection_notifier.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tools_group_with_tools.freezed.dart';

@freezed
abstract class ToolsGroupWithTools with _$ToolsGroupWithTools, ToolsGroupMixin {
  @Assert('group != null || defaultGroupType != null')
  @Assert('group == null || defaultGroupType == null')
  const factory ToolsGroupWithTools({
    required ToolsGroupEntity? group,
    required List<WorkspaceToolEntity> tools,
    DefaultToolGroupType? defaultGroupType,
    McpConnectionState? mcpConnectionState,
  }) = _ToolsGroupWithTools;

  const ToolsGroupWithTools._();

  int get enabledToolsCount => tools.where((t) => t.isEnabled).length;

  int get totalToolsCount => tools.length;
}
