import 'package:auravibes_app/domain/models/grouped_tools_view_item.dart';
import 'package:auravibes_app/domain/usecases/tools/groups/delete_mcp_group_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deletes only mcp groups with server id', () async {
    var deletedId = '';
    const usecase = DeleteMcpGroupUseCase();

    await usecase.call(
      groupId: 'missing',
      groups: const [GroupedToolsViewItem(group: null, tools: [])],
      deleteMcpServer: (id) async {
        deletedId = id;
      },
    );

    expect(deletedId, isEmpty);
  });
}
