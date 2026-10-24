import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'repositories/workspace_state_repository.dart';
import 'usecases/workspace_state_usecases.dart';
import 'workspace_history_context.dart';
import 'workspace_history_reader.dart';
import 'workspace_trash_access.dart';

class const WorkspaceHistoryService(
  final Session session,
  final int workspaceId,
  final String userId,
) {
  Future<List<String>> history(String targetJson) => session.db.transaction(
    (transaction) =>
        WorkspaceHistoryReader(_context(transaction))
            .read(WorkspaceHistoryContext.target(targetJson)),
  );

  Future<void> restore(
    String targetJson,
    int revision,
    String requestId,
  ) async {
    final target = WorkspaceHistoryContext.target(targetJson);
    final operation = await session.db.transaction(
      (transaction) =>
          _Restoration(_context(transaction)).prepare(target, revision),
    );
    await _apply(operation, requestId);
  }

  Future<void> _apply(
    WorkspacePatchOperation operation,
    String requestId,
  ) async {
    final request = PatchWorkspaceStateRequest(
      workspaceId: workspaceId,
      requestId: requestId,
      operations: [operation],
    );
    final _ = await WorkspaceStateUseCases(WorkspaceStateRepository())
        .patch(session, userId: userId, request: request);
  }

  WorkspaceHistoryContext _context(Transaction transaction) =>
      .new(session, workspaceId, userId, transaction);
}

class const _Restoration(final WorkspaceHistoryContext context) {
  Future<WorkspacePatchOperation> prepare(
    HistoryTarget target,
    int revision,
  ) async {
    final current = await context.current(target, write: true);
    final selected = await _selected(current, revision);

    return _operation(
      current,
      target.revision,
      await _data(current, selected),
    );
  }

  Future<WorkspaceRevision> _selected(
    WorkspaceResource current,
    int revision,
  ) async {
    final snapshots = await context.snapshots(current);

    return snapshots.where((row) => row.revision == revision).firstOrNull ??
        trashInvalid();
  }

  Future<String> _data(
    WorkspaceResource current,
    WorkspaceRevision snapshot,
  ) async {
    final data =
        jsonDecode(_restoredData(current, snapshot)) as Map<String, dynamic>;
    if (current.resourceKind == .tableRecord) {
      data['schemaRevision'] = await _schemaRevision(current);
    }

    return jsonEncode(data);
  }

  Future<int> _schemaRevision(WorkspaceResource record) async {
    final id =
        (jsonDecode(record.data) as Map<String, dynamic>)['tableId'] as String;
    final table = await _table(id);

    return (jsonDecode(table.data) as Map<String, dynamic>)['schemaRevision']
        as int;
  }

  Future<WorkspaceResource> _table(String id) async {
    final table = await WorkspaceStateRepository().findResource(
      context.session,
      workspaceId: context.workspaceId,
      kind: .table,
      resourceId: id,
      transaction: context.transaction,
    );

    return table ?? trashInvalid();
  }
}

String _restoredData(WorkspaceResource current, WorkspaceRevision snapshot) {
  final data = jsonDecode(current.data) as Map<String, dynamic>;
  final saved = jsonDecode(snapshot.data) as Map<String, dynamic>;
  data.addAll(_restoredFields(current.resourceKind, data, saved));

  return jsonEncode(data);
}

WorkspacePatchOperation _operation(
  WorkspaceResource current,
  int revision,
  String data,
) => WorkspacePatchOperation(
  operation: .update,
  resourceKind: current.resourceKind,
  resourceId: current.resourceId,
  expectedRevision: revision,
  data: data,
  fieldMask: const [],
);

Map<String, dynamic> _restoredFields(
  WorkspaceResourceKind kind,
  Map<String, dynamic> current,
  Map<String, dynamic> saved,
) => kind == .tableRecord
    ? {'values': saved['values']}
    : {
        'columns': saved['columns'],
        'schemaRevision': (current['schemaRevision'] as int) + 1,
      };
