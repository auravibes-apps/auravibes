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
  Future<bool> retained(int objectId) async {
    final resources = await _resources();
    final id = '$objectId';
    for (final resource in resources) {
      if (excluding.contains(
        '${resource.resourceKind.name}:${resource.resourceId}',
      )) {
        continue;
      }
      final data = _data(resource);
      if (_direct(resource, id)) return true;
      if (resource.resourceKind != .tableRecord) continue;
      final table = resources
          .where(
            (row) =>
                row.resourceKind == .table && row.resourceId == data['tableId'],
          )
          .firstOrNull;
      if (table != null &&
          ObjectAssetReferences.record(_data(table), data).contains(id)) {
        return true;
      }
    }
    return await ObjectHistoricalAssets(
      session,
      workspaceId,
      transaction,
    ).retained(objectId);
  }

  Future<List<WorkspaceResource>> _resources() => WorkspaceResource.db.find(
    session,
    where: (row) =>
        row.workspaceId.equals(workspaceId) &
        row.resourceKind.inSet({.file, .table, .tableRecord}),
    transaction: transaction,
  );
}

bool _direct(WorkspaceResource resource, String id) =>
    switch (resource.resourceKind) {
      .file => _data(resource)['assetId'] == id,
      .table => ObjectAssetReferences.defaults(_data(resource)).contains(id),
      _ => false,
    };
Map<String, dynamic> _data(WorkspaceResource resource) =>
    jsonDecode(resource.data) as Map<String, dynamic>;
