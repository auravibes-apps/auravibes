import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';

class const OrganizeWorkspaceFilesUsecase(
  final WorkspaceFileRepository repository,
) {
  Future<List<WorkspaceFile>> list({String? parentId}) =>
      repository.list(parentId: parentId);
  Future<WorkspaceFile> file(String id) => repository.file(id);

  Future<WorkspaceFile> create(
    WorkspaceFileDraft draft, {
    bool sharingApproved = false,
  }) => repository.create(
    .new(
      id: draft.id,
      name: _name(draft.name),
      assetId: draft.assetId,
      parentId: draft.parentId,
    ),
    sharingApproved: sharingApproved,
  );

  Future<WorkspaceFile> updateMetadata({
    required WorkspaceFile file,
    required String name,
    required String? parentId,
  }) {
    if (!file.canManage) throw const WorkspaceAssetException(.denied);

    return repository.updateMetadata(
      file: file,
      name: _name(name),
      parentId: parentId,
    );
  }
}

String _name(String name) {
  final normalized = name.trim();
  if (normalized.isEmpty || normalized.length > 200) {
    throw const WorkspaceAssetException(.invalid);
  }

  return normalized;
}
