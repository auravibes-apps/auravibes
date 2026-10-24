import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'workspace_history_purge_writer.dart';
import 'workspace_history_receipts.dart';
import 'workspace_history_retained_reader.dart';
import 'workspace_retained_references.dart';
import 'workspace_trash_access.dart';
import 'workspace_trash_context.dart';
import 'workspace_trash_store.dart';

class const WorkspacePermanentDelete(
  final Session session,
  final int workspaceId,
  final String userId,
) {
  Future<void> call(String targetJson) =>
      session.db.transaction((transaction) async {
        final context = await WorkspaceTrashContext.load(
          session,
          workspaceId,
          userId,
          transaction,
        );
        await _PurgeOperation(context).run(targetJson);
      });
}

class const _PurgeOperation(final WorkspaceTrashContext context) {
  Future<void> run(String targetJson) async {
    final selection = await _selection(targetJson);
    await context.requireBatch(selection.batch, selection.rows);
    await _validate(selection);
    await _erase(selection);
  }

  Future<_PurgeSelection> _selection(String targetJson) async {
    final target = jsonDecode(targetJson) as Map<String, dynamic>;
    final batches = await context.store.batches();
    final batch = _findBatch(batches, target);

    return _PurgeSelection(batch, await context.store.resources());
  }

  Future<void> _validate(_PurgeSelection selection) async {
    final retained = await WorkspaceHistoryRetainedReader(context)
        .read(selection.rows, selection.scope());
    if (_blocked(retained, selection.ids())) trashInvalid();
  }

  Future<void> _erase(_PurgeSelection selection) async {
    final writer = WorkspaceHistoryPurgeWriter(context.store);
    for (final resource in selection.resources()) {
      await writer.delete(resource);
    }
    await _finish(selection);
  }

  Future<void> _finish(_PurgeSelection selection) async {
    final store = context.store;
    await WorkspaceHistoryReceipts(
      store.session,
      store.workspaceId,
      store.transaction,
    ).redact(selection.scope());
    final _ = await WorkspaceTrashBatch.db.deleteRow(
      store.session,
      selection.batch,
      transaction: store.transaction,
    );
  }
}

class const _PurgeSelection(
  final WorkspaceTrashBatch batch,
  final List<WorkspaceResource> rows,
) {
  List<Map<String, dynamic>> members() => trashMembers(batch);
  Set<String> scope() => {
    for (final item in members()) '${_kind(item)}:${item['id']}',
  };
  Set<String> ids() => members().map((item) => item['id'] as String).toSet();
  Iterable<WorkspaceResource> resources() => members().reversed.map(
    (member) => trashMemberResource(rows, member) ?? trashConflict(),
  );
}

Map<String, dynamic> _decode(String data) =>
    jsonDecode(data) as Map<String, dynamic>;
String _kind(Map<String, dynamic> member) =>
    member['kind'] == 'tableRecord' ? 'record' : member['kind'] as String;
bool _same(Map<String, dynamic> left, Map<String, dynamic> right) => [
  'kind',
  'id',
  'revision',
  'tableId',
].every((key) => left[key] == right[key]);
bool _blocked(List<HistoryRetainedData> retained, Set<String> ids) {
  final columns = WorkspaceRetainedReferences.columns(
    retained.map((item) => item.data),
  );

  return retained.any(
    (row) => WorkspaceRetainedReferences.references(
      row.data,
      ids,
      (columns: columns, view: row.view),
    ),
  );
}

WorkspaceTrashBatch _findBatch(
  List<WorkspaceTrashBatch> batches,
  Map<String, dynamic> target,
) =>
    batches
        .where((row) => _same(_decode(row.targetJson), target))
        .firstOrNull ??
    trashDenied();
