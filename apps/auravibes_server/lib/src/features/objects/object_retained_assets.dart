import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'object_asset_references.dart';
import 'object_historical_assets.dart';

/// Retention is workspace-internal; it never grants download authorization.
class const ObjectRetainedAssets(
  final Session session,
  final int workspaceId,
  final Transaction? transaction, {
  final Set<String> excluding = const {},
}) {
  Future<bool> retained(int objectId) async => (await ids()).contains(objectId);

  Future<Set<int>> ids() async {
    final resources = await _resources();
    final raw = _resourceIds(resources, excluding);
    raw.addAll(
      await ObjectHistoricalAssets(session, workspaceId, transaction).ids(),
    );
    final result = raw.map(int.tryParse).whereType<int>().toSet();
    result.addAll(await _messageIds());

    return result;
  }

  Future<Iterable<int>> _messageIds() async => (await ObjectReference.db.find(
    session,
    where: (row) =>
        row.workspaceId.equals(workspaceId) & row.deletedAt.equals(null),
    transaction: transaction,
  )).map((row) => row.objectId);

  Future<List<WorkspaceResource>> _resources() => WorkspaceResource.db.find(
    session,
    where: (row) =>
        row.workspaceId.equals(workspaceId) &
        row.resourceKind.inSet({.file, .table, .tableRecord}),
    transaction: transaction,
  );
}

Set<String> _resourceIds(List<WorkspaceResource> rows, Set<String> excluding) =>
    {
      for (final row in rows)
        if (!excluding.contains('${row.resourceKind.name}:${row.resourceId}'))
          ..._ids(row, rows),
    };

Iterable<String> _ids(WorkspaceResource row, List<WorkspaceResource> rows) =>
    switch (row.resourceKind) {
      .file => [_data(row)['assetId']].whereType<String>(),
      .table => ObjectAssetReferences.defaults(_data(row)),
      .tableRecord => _record(row, rows),
      _ => const [],
    };

Iterable<String> _record(WorkspaceResource row, List<WorkspaceResource> rows) {
  final data = _data(row);
  final table = rows
      .where(
        (item) =>
            item.resourceKind == .table && item.resourceId == data['tableId'],
      )
      .firstOrNull;
  if (table == null) return const [];

  return ObjectAssetReferences.record(_data(table), data);
}

Map<String, dynamic> _data(WorkspaceResource resource) =>
    jsonDecode(resource.data) as Map<String, dynamic>;
