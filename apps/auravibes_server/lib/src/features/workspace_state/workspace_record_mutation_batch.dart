import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'repositories/workspace_state_repository.dart';
import 'workspace_table_mutation_validation.dart';

/// Staged rows remain invisible outside the transaction until final validation.
class WorkspaceRecordMutationBatch(
  final WorkspaceStateRepository repository,
  final Session session,
  final int workspaceId,
  final Transaction transaction,
  final String userId, {
  final bool applyDefaults = true,
}) {
  final _previous = <String, WorkspaceResource?>{};
  final _operations = <String, WorkspacePatchOperation>{};
  Future<void> remember(WorkspacePatchOperation operation) async {
    if (operation.resourceKind != .tableRecord ||
        operation.operation == .delete) {
      return;
    }
    if (_operations.containsKey(operation.resourceId)) {
      throw CloudWorkspaceException(code: .validationFailed);
    }
    _operations[operation.resourceId] = operation;
    _previous[operation.resourceId] = await _find(operation.resourceId);
  }

  Future<void> validate(List<WorkspaceResource> changed) async {
    for (final row in changed.where(_isRecord)) {
      await _validate(row);
    }
  }

  Future<WorkspaceResource?> _find(String id) => repository.findResource(
    session,
    workspaceId: workspaceId,
    kind: .tableRecord,
    resourceId: id,
    transaction: transaction,
  );

  Future<void> _validate(WorkspaceResource row) async {
    final operation = _operations[row.resourceId];
    if (operation == null) {
      throw CloudWorkspaceException(code: .validationFailed);
    }
    try {
      await WorkspaceTableMutationValidation(
        repository,
        session,
        workspaceId,
        transaction,
        userId,
        applyDefaults: applyDefaults,
      ).validate(operation, _data(row), _previous[row.resourceId]);
    } on FormatException {
      throw CloudWorkspaceException(code: .validationFailed);
    }
  }
}

bool _isRecord(WorkspaceResource row) =>
    row.resourceKind == .tableRecord && row.deletedAt == null;
Map<String, Object?> _data(WorkspaceResource row) =>
    (jsonDecode(row.data) as Map).cast<String, Object?>();
