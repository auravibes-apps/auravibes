import 'package:auravibes_app/features/workspaces/models/workspace_reference.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

class const BrowseWorkspaceReferencesUsecase(
  final WorkspaceReferenceRepository repository,
) {
  Future<WorkspaceReferencePage> targets({
    required String sourceTableId,
    required String columnId,
    String search = '',
    String? afterId,
  }) {
    if (search.length > 200) throw const WorkspaceTableException();
    return repository.targets(
      sourceTableId: sourceTableId,
      columnId: columnId,
      search: search,
      afterId: afterId,
    );
  }

  Future<WorkspaceReferencePage> reverse({
    required String tableId,
    required String recordId,
    String? afterId,
  }) => repository.reverse(
    tableId: tableId,
    recordId: recordId,
    afterId: afterId,
  );
}
