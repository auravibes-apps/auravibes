import 'package:auravibes_app/features/workspaces/models/workspace_reference_page.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

class const BrowseWorkspaceReferencesUsecase(
  final WorkspaceReferenceRepository repository,
) {
  Future<WorkspaceRecord> record(String tableId, String id) =>
      repository.record(tableId, id);

  Future<WorkspaceReferencePage> targets({
    required WorkspaceReferenceSource source,
    String search = '',
    String? afterId,
  }) {
    if (search.length > 200) throw const WorkspaceTableException();

    return repository.targets(source, search: search, afterId: afterId);
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
