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
      final page = await _page(cursor);
      folders.addAll(_foldersInParent(page.resources, parentId));
      cursor = page.nextResourceId;
    } while (cursor != null);
    folders.sort(_compareNames);

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

  @override
  Future<WorkspaceFolder> updateMetadata({
    required WorkspaceFolder folder,
    required String name,
    required String? parentId,
  }) async {
    await _store.update(
      kind: .folder,
      id: folder.id,
      revision: folder.revision,
      data: {'name': name, 'parentId': parentId},
    );

    return WorkspaceFolder(
      id: folder.id,
      name: name,
      revision: folder.revision + 1,
      parentId: parentId,
    );
  }

  int _compareNames(WorkspaceFolder left, WorkspaceFolder right) =>
      left.name.compareTo(right.name);

  Future<WorkspaceResourcePage> _page(String? cursor) async {
    final request = WorkspaceResourcePageRequest(
      resourceKind: .folder,
      afterResourceId: cursor,
      limit: 100,
    );
    final response = await _store.read(pages: [request]);

    return response.pages.single;
  }

  Iterable<WorkspaceFolder> _foldersInParent(
    List<WorkspaceResource> rows,
    String? parentId,
  ) => rows
      .map(_folder)
      .where((folder) => folder != null && folder.parentId == parentId)
      .nonNulls;

  WorkspaceFolder? _folder(WorkspaceResource row) {
    final data = CloudResourceMapper.decode(row);
    if (row.deletedAt != null) return null;

    return WorkspaceFolder(
      id: row.resourceId,
      name: data['name'] as String,
      revision: row.revision,
      parentId: data['parentId'] as String?,
      canManage: data['canManageFolder'] == true,
    );
  }
}
