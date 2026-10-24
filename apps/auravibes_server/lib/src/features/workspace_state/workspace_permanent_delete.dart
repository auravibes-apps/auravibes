import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'workspace_retained_references.dart';
import 'workspace_trash_access.dart';
import 'workspace_trash_context.dart';
import 'workspace_trash_store.dart';

class const WorkspacePermanentDelete(
  final Session session,
  final int workspaceId,
  final String userId,
) {
  Future<void> call(String targetJson) => session.db.transaction((
    transaction,
  ) async {
    final context = await WorkspaceTrashContext.load(
      session,
      workspaceId,
      userId,
      transaction,
    );
    final target = jsonDecode(targetJson) as Map<String, dynamic>;
    final batches = await context.store.batches();
    final batch = batches
        .where(
          (row) =>
              _same(jsonDecode(row.targetJson) as Map<String, dynamic>, target),
        )
        .firstOrNull;
    if (batch == null) trashDenied();
    final rows = await context.store.resources();
    await context.requireBatch(batch, rows);
    final members = trashMembers(batch);
    final scope = {for (final item in members) '${item['kind']}:${item['id']}'};
    final ids = {for (final item in members) item['id'] as String};
    final retained = await _retained(rows, scope, transaction);
    final columns = workspaceReferenceColumns(
      retained.map((item) => item.data),
    );
    if (retained.any(
      (item) =>
          workspaceRetainedReference(item.data, ids, columns, view: item.view),
    )) {
      trashInvalid();
    }
    for (final member in members.reversed) {
      final resource = trashMemberResource(rows, member);
      if (resource == null || resource.deletedAt == null) trashConflict();
      await _delete(resource, transaction);
    }
    await _redactReceipts(scope, transaction);
    final _ = await WorkspaceTrashBatch.db.deleteRow(
      session,
      batch,
      transaction: transaction,
    );
  });

  Future<List<({Map<String, dynamic> data, bool view})>> _retained(
    List<WorkspaceResource> rows,
    Set<String> scope,
    Transaction transaction,
  ) async {
    final result = <({Map<String, dynamic> data, bool view})>[
      for (final row in rows)
        if (!scope.contains('${_kind(row.resourceKind)}:${row.resourceId}'))
          (data: trashData(row), view: row.resourceKind == .view),
    ];
    final snapshots = await WorkspaceRevision.db.find(
      session,
      where: (row) => row.workspaceId.equals(workspaceId),
      transaction: transaction,
    );
    for (final row in snapshots) {
      if (!scope.contains('${_kind(row.resourceKind)}:${row.resourceId}')) {
        result.add((
          data: jsonDecode(row.data) as Map<String, dynamic>,
          view: false,
        ));
      }
    }
    final views = await WorkspaceView.db.find(
      session,
      where: (row) => row.workspaceId.equals(workspaceId),
      transaction: transaction,
    );
    for (final view in views) {
      if (scope.contains('view:${view.stableId}')) continue;
      for (final data
          in (jsonDecode(view.history) as List).cast<Map<String, dynamic>>()) {
        result.add((data: data, view: true));
      }
    }
    return result;
  }

  Future<void> _redactReceipts(
    Set<String> scope,
    Transaction transaction,
  ) async {
    final receipts = await WorkspaceMutationReceipt.db.find(
      session,
      where: (row) => row.workspaceId.equals(workspaceId),
      transaction: transaction,
    );
    for (final receipt in receipts) {
      final response = jsonDecode(receipt.responseJson) as Map<String, dynamic>;
      final resources = response['resources'];
      if (resources is! List) continue;
      response['resources'] = resources.where((item) {
        final row = item as Map<String, dynamic>;
        final kind = row['resourceKind'] == 'tableRecord'
            ? 'record'
            : row['resourceKind'];
        return !scope.contains('$kind:${row['resourceId']}');
      }).toList();
      final _ = await WorkspaceMutationReceipt.db.updateRow(
        session,
        receipt.copyWith(responseJson: jsonEncode(response)),
        transaction: transaction,
      );
    }
  }

  Future<void> _delete(WorkspaceResource row, Transaction transaction) async {
    if (row.resourceKind == .view) {
      final view = await WorkspaceView.db.findById(
        session,
        row.id!,
        transaction: transaction,
      );
      if (view == null) trashConflict();
      final _ = await WorkspaceView.db.deleteRow(
        session,
        view,
        transaction: transaction,
      );
    } else {
      final _ = await WorkspaceResource.db.deleteRow(
        session,
        row,
        transaction: transaction,
      );
    }
    final _ = await WorkspaceRevision.db.deleteWhere(
      session,
      where: (item) =>
          item.workspaceId.equals(workspaceId) &
          item.resourceKind.equals(row.resourceKind) &
          item.resourceId.equals(row.resourceId),
      transaction: transaction,
    );
    final _ = await WorkspaceRevision.db.insertRow(
      session,
      WorkspaceRevision(
        workspaceId: workspaceId,
        resourceKind: row.resourceKind,
        resourceId: row.resourceId,
        revision: 0,
        data: '{}',
        capturedAt: DateTime.now().toUtc(),
      ),
      transaction: transaction,
    );
  }
}

String _kind(WorkspaceResourceKind kind) =>
    kind == .tableRecord ? 'record' : kind.name;
bool _same(Map<String, dynamic> left, Map<String, dynamic> right) => [
  'kind',
  'id',
  'revision',
  'tableId',
].every((key) => left[key] == right[key]);
