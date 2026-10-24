import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

class const WorkspaceReferencePage({
  required final List<WorkspaceRecord> records,
  final String? nextId,
});

abstract interface class WorkspaceReferenceRepository {
  Future<WorkspaceReferencePage> targets({
    required String sourceTableId,
    required String columnId,
    required String search,
    String? afterId,
  });
  Future<WorkspaceReferencePage> reverse({
    required String tableId,
    required String recordId,
    String? afterId,
  });
}
