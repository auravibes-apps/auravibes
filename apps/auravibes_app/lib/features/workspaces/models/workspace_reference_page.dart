import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

class const WorkspaceReferencePage({
  required final List<WorkspaceRecord> records,
  final String? nextId,
});

typedef WorkspaceReferenceSource = ({String tableId, String columnId});

abstract interface class WorkspaceReferenceRepository {
  Future<WorkspaceRecord> record(String tableId, String id);
  Future<WorkspaceReferencePage> targets(
    WorkspaceReferenceSource source, {
    required String search,
    String? afterId,
  });
  Future<WorkspaceReferencePage> reverse({
    required String tableId,
    required String recordId,
    String? afterId,
  });
}
