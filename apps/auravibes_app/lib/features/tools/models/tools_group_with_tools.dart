// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/models/mcp_connection_view_status.dart';
import 'package:auravibes_app/features/tools/models/tools_group_mixin.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
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
