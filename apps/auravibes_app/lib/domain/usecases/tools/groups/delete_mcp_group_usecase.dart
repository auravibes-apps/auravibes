import 'package:auravibes_app/domain/models/grouped_tools_view_item.dart';
import 'package:collection/collection.dart';

class DeleteMcpGroupUseCase {
  const DeleteMcpGroupUseCase();

  Future<void> call({
    required String groupId,
    required List<GroupedToolsViewItem> groups,
    required Future<void> Function(String mcpServerId) deleteMcpServer,
  }) async {
    final group = groups.firstWhereOrNull((item) => item.group?.id == groupId);
    if (group == null || !group.isMcpGroup || group.mcpServerId == null) {
      return;
    }

    await deleteMcpServer(group.mcpServerId!);
  }
}
