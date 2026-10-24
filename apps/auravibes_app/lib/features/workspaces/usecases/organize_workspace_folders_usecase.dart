import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';

class const OrganizeWorkspaceFoldersUsecase(
  final WorkspaceFolderRepository _repository,
) {
  Future<List<WorkspaceFolder>> list({String? parentId}) =>
      _repository.list(parentId: parentId);

  Future<WorkspaceFolder> create({required String name, String? parentId}) {
    return _repository.create(name: _name(name), parentId: parentId);
  }

  Future<WorkspaceFolder> updateMetadata({
    required WorkspaceFolder folder,
    required String name,
    required String? parentId,
  }) => _repository.updateMetadata(
    folder: folder,
    name: _name(name),
    parentId: parentId,
  );
}

String _name(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty || trimmed.length > 200) {
    throw const WorkspaceFolderException();
  }

  return trimmed;
}
