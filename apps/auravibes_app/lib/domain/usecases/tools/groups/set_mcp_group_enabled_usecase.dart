import 'package:auravibes_app/domain/models/grouped_tools_view_item.dart';
import 'package:collection/collection.dart';

class SetMcpGroupEnabledUseCase {
  const SetMcpGroupEnabledUseCase({
    required Future<void> Function(String groupId, {required bool isEnabled})
    setToolsGroupEnabled,
  }) : _setToolsGroupEnabled = setToolsGroupEnabled;

  final Future<void> Function(String groupId, {required bool isEnabled})
  _setToolsGroupEnabled;

  Future<void> call({
    required String groupId,
    required bool isEnabled,
    required List<GroupedToolsViewItem> groups,
    required void Function(String mcpServerId) disconnectMcpServer,
    required Future<void> Function(String mcpServerId) reconnectMcpServer,
  }) async {
    await _setToolsGroupEnabled(groupId, isEnabled: isEnabled);

    final group = groups.where((item) => item.group?.id == groupId).firstOrNull;
    if (group == null || !group.isMcpGroup || group.mcpServerId == null) {
      return;
    }

    if (!isEnabled) {
      disconnectMcpServer(group.mcpServerId!);
      return;
    }

    await reconnectMcpServer(group.mcpServerId!);
  }
}
