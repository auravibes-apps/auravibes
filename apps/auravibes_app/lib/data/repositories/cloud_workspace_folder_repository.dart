import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:uuid/v7.dart';

class const CloudWorkspaceFolderRepository(
  final CloudWorkspaceResourceStore _store,
) implements WorkspaceFolderRepository {
  @override
  Future<List<WorkspaceFolder>> list({String? parentId}) async {
    final folders = <WorkspaceFolder>[];
    String? cursor;
    do {
      final response = await _store.read(
        pages: [
          WorkspaceResourcePageRequest(
            resourceKind: .folder,
            afterResourceId: cursor,
            limit: 100,
          ),
        ],
      );
      final page = response.pages.single;
      for (final row in page.resources) {
        final data = CloudResourceMapper.decode(row);
        if (data['parentId'] == parentId && row.deletedAt == null) {
          folders.add(
            WorkspaceFolder(
              id: row.resourceId,
              name: data['name'] as String,
              revision: row.revision,
              parentId: data['parentId'] as String?,
            ),
          );
        }
      }
      cursor = page.nextResourceId;
    } while (cursor != null);
    folders.sort((a, b) => a.name.compareTo(b.name));

    return folders;
  }

  @override
  Future<WorkspaceFolder> create({
    required String name,
    String? parentId,
  }) async {
    final id = const UuidV7().generate();
    await _store.create(
      kind: .folder,
      id: id,
      data: {'name': name, 'parentId': parentId},
    );

    return WorkspaceFolder(id: id, name: name, revision: 1, parentId: parentId);
  }
}
