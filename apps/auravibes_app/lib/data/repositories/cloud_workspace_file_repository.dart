import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class const CloudWorkspaceFileRepository(
  final CloudWorkspaceResourceStore store,
) implements WorkspaceFileRepository {
  @override
  Future<List<WorkspaceFile>> list({String? parentId}) async {
    final files = <WorkspaceFile>[];
    await for (final page in _FilePages(store).read()) {
      files.addAll(_liveFiles(page).where((file) => file.parentId == parentId));
    }
    files.sort((left, right) => left.name.compareTo(right.name));

    return files;
  }

  @override
  Future<WorkspaceFile> file(String id) async {
    await for (final page in _FilePages(store).read()) {
      final found = _liveFiles(page).where((file) => file.id == id).firstOrNull;
      if (found != null) return found;
    }
    throw const WorkspaceAssetException(.denied);
  }

  @override
  Future<WorkspaceFile> create({
    required String id,
    required String name,
    required String assetId,
    String? parentId,
    bool sharingApproved = false,
  }) async {
    final _ = await store.patch(
      requestId: id,
      operations: [
        WorkspacePatchOperation(
          operation: .create,
          resourceKind: .file,
          resourceId: id,
          data: jsonEncode({
            'name': name,
            'parentId': parentId,
            'assetId': assetId,
            'sharingApproved': sharingApproved,
          }),
          fieldMask: const [],
        ),
      ],
    );

    return await file(id);
  }

  @override
  Future<WorkspaceFile> updateMetadata({
    required WorkspaceFile file,
    required String name,
    required String? parentId,
  }) async {
    await store.update(
      kind: .file,
      id: file.id,
      revision: file.revision,
      data: {'name': name, 'parentId': parentId, 'assetId': file.assetId},
    );

    return await this.file(file.id);
  }
}

class const _FilePages(final CloudWorkspaceResourceStore store) {
  Stream<List<WorkspaceResource>> read() async* {
    final seen = <String>{};
    String? cursor;
    do {
      final page = await _page(cursor);
      cursor = page.nextResourceId;
      if (cursor != null && !seen.add(cursor)) {
        throw const WorkspaceAssetException(.unavailable);
      }
      yield page.resources;
    } while (cursor != null);
  }

  Future<WorkspaceResourcePage> _page(String? cursor) async {
    final response = await store.read(
      pages: [.new(resourceKind: .file, afterResourceId: cursor, limit: 100)],
    );
    if (response.pages.length != 1 ||
        response.pages.single.resourceKind != .file) {
      throw const WorkspaceAssetException(.unavailable);
    }

    return response.pages.single;
  }
}

Iterable<WorkspaceFile> _liveFiles(List<WorkspaceResource> rows) =>
    rows.where((row) => row.deletedAt == null).map(_file);

WorkspaceFile _file(WorkspaceResource resource) {
  final data = CloudResourceMapper.decode(resource);
  final metadata = data['asset'];
  final assetId = data['assetId'] as String;

  return WorkspaceFile(
    id: resource.resourceId,
    name: data['name'] as String,
    assetId: assetId,
    revision: resource.revision,
    asset: metadata is Map && metadata['id'] == assetId
        ? WorkspaceAsset(
            id: assetId,
            name: metadata['name'] as String,
            mimeType: metadata['mimeType'] as String,
            sizeBytes: metadata['sizeBytes'] as int,
            checksum: metadata['checksum'] as String,
          )
        : null,
    parentId: data['parentId'] as String?,
    canManage: data['canManageFile'] == true,
  );
}
