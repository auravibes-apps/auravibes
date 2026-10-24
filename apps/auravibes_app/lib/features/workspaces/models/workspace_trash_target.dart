import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

class const WorkspaceTrashTarget({
  required final WorkspaceTrashKind kind,
  required final String id,
  required final int revision,
  final String? tableId,
}) {
  factory fromJson(Map<String, dynamic> data) => .new(
    kind: WorkspaceTrashKind.values.byName(data['kind'] as String),
    id: data['id'] as String,
    revision: data['revision'] as int,
    tableId: data['tableId'] as String?,
  );

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'id': id,
    'revision': revision,
    'tableId': ?tableId,
  };
}

class const WorkspaceTrashBatch({
  required final String id,
  required final WorkspaceTrashTarget target,
  required final String name,
  required final int affectedCount,
  final String planToken = '',
  final bool canRestore = true,
});

class const WorkspaceTrashRestoration({
  final bool movedToRoot = false,
  final bool unresolvedDependencies = false,
});

class const WorkspaceDeletedReference({
  required final String batchId,
  required final bool canRestore,
});

abstract interface class WorkspaceTrashRepository {
  Future<List<WorkspaceTrashBatch>> list();
  Future<WorkspaceDeletedReference?> deletedReference(
    String tableId,
    String recordId,
  );
  Future<WorkspaceTrashBatch> preview(WorkspaceTrashTarget target);
  Future<WorkspaceTrashBatch> trash(
    WorkspaceTrashTarget target, {
    required String planToken,
  });
  Future<WorkspaceTrashRestoration> restore(String batchId);
}

void validateWorkspaceTrashTarget(WorkspaceTrashTarget target) {
  if (target.id.isEmpty ||
      target.revision < 1 ||
      (target.kind == .record && (target.tableId?.isEmpty ?? true))) {
    throw const WorkspaceTableException();
  }
}

enum WorkspaceTrashKind { folder, table, record, view }
