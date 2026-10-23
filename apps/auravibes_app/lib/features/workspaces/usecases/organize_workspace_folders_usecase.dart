import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';

class const OrganizeWorkspaceFoldersUsecase(
  final WorkspaceFolderRepository _repository,
) {
  Future<List<WorkspaceFolder>> list({String? parentId}) =>
      _repository.list(parentId: parentId);

  Future<WorkspaceFolder> create({required String name, String? parentId}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 200) {
      throw const WorkspaceFolderException();
    }

    return _repository.create(name: trimmed, parentId: parentId);
  }
}
