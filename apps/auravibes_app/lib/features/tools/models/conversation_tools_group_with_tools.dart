import 'package:auravibes_app/domain/entities/tools_group.dart';
import 'package:auravibes_app/domain/models/grouped_tools_view_item.dart';
import 'package:auravibes_app/features/tools/models/tools_group_mixin.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tools_notifier.dart';
import 'package:auravibes_app/notifiers/mcp_connection_notifier.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation_tools_group_with_tools.freezed.dart';

@freezed
abstract class ConversationToolsGroupWithTools
    with _$ConversationToolsGroupWithTools, ToolsGroupMixin {
  @Assert('group != null || defaultGroupType != null')
  @Assert('group == null || defaultGroupType == null')
  const factory ConversationToolsGroupWithTools({
    required ToolsGroupEntity? group,
    required List<ConversationToolState> tools,
    DefaultToolGroupType? defaultGroupType,
    McpConnectionState? mcpConnectionState,
  }) = _ConversationToolsGroupWithTools;

  const ConversationToolsGroupWithTools._();

  int get enabledToolsCount => tools.where((t) => t.isEnabled).length;

  int get totalToolsCount => tools.length;

  bool get areAllToolsEnabled =>
      tools.isNotEmpty && tools.every((t) => t.isEnabled);

  bool get areAnyToolsEnabled => tools.any((t) => t.isEnabled);
}
