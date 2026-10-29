import 'package:auravibes_app/features/workspaces/models/workspace_reference_page.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

const _maximumSearchLength = 200;

class const BrowseWorkspaceReferencesUsecase(
  final WorkspaceReferenceRepository repository,
) {
  Future<WorkspaceRecord> record(String tableId, String id) =>
      repository.record(tableId, id);

  Future<WorkspaceReferencePage> targets({
    required WorkspaceReferenceSource source,
    String search = '',
    String? afterId,
    String? parentId,
  }) {
    if (search.length > _maximumSearchLength) {
      throw const WorkspaceTableException();
    }

    return repository.targets(
      source,
      search: search,
      afterId: afterId,
      parentId: parentId,
    );
  }

  Future<WorkspaceReferencePage> tableTargets({
    required String tableId,
    String search = '',
    String? afterId,
  }) {
    if (search.length > _maximumSearchLength) {
      throw const WorkspaceTableException();
    }

    return repository.tableTargets(tableId, search: search, afterId: afterId);
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
