import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../workspace_state/workspace_table_access.dart';
import 'object_historical_assets.dart';
import 'object_retained_assets.dart';

/// Item reachability never substitutes workspace membership for table grants.
class const ObjectItemAccess(
  final Session session,
  final WorkspaceMember member, {
  final Transaction? transaction,
  final String? excludedRecordId,
  final String? excludedTableId,
}) {
  ObjectHistoricalAssets get _history => .new(
    session,
    member.workspaceId,
    transaction,
  );

  Future<bool> canRead(int objectId) async {
    final sources = _ItemSources(this, await _resources());
    if (await _ItemReaders(sources).readable('$objectId')) return true;

    return await _history.readable(objectId, member);
  }

  Future<bool> retained(int objectId) => ObjectRetainedAssets(
    session,
    member.workspaceId,
    transaction,
    excluding: {
      if (excludedRecordId != null) 'tableRecord:$excludedRecordId',
      if (excludedTableId != null) 'table:$excludedTableId',
    },
  ).retained(objectId);

  Future<bool> publiclyReadable(int objectId) async => (await _resources()).any(
    (row) =>
        row.resourceKind == .file &&
        row.deletedAt == null &&
        _data(row)['assetId'] == '$objectId',
  );

  Future<bool> canReuseInTable(int objectId, String tableId) async {
    final sources = _ItemSources(this, await _resources());
    final target = sources.table(tableId);
    if (target == null) return false;

    return await _reuse(objectId, sources, _readers(target));
  }

  Future<bool> _reuse(int id, _ItemSources sources, Set<String> readers) async {
    if (await _ItemReuse(sources).allows('$id', readers)) return true;

    return await _history.readable(id, member, targetReaders: readers);
  }

  Future<List<WorkspaceResource>> _resources() => WorkspaceResource.db.find(
    session,
    where: (row) =>
        row.workspaceId.equals(member.workspaceId) &
        row.resourceKind.inSet({.file, .table, .tableRecord}),
    transaction: transaction,
  );
}

class const _ItemSources(
  final ObjectItemAccess owner,
  final List<WorkspaceResource> resources,
) {
  Iterable<WorkspaceResource> get live =>
      resources.where((row) => row.deletedAt == null);
  Iterable<WorkspaceResource> get tables => live.where(
    (row) =>
        row.resourceKind == .table && row.resourceId != owner.excludedTableId,
  );
  Iterable<WorkspaceResource> get records => live.where(
    (row) =>
        row.resourceKind == .tableRecord &&
        row.resourceId != owner.excludedRecordId,
  );

  WorkspaceResource? table(Object? id) => live
      .where((row) => row.resourceKind == .table && row.resourceId == id)
      .firstOrNull;

  WorkspaceResource? recordTable(WorkspaceResource record, String id) {
    final data = _data(record);
    final source = table(data['tableId']);

    return source != null && _contains(source, data, id) ? source : null;
  }

  Future<bool> grant(WorkspaceResource table) =>
      WorkspaceTableAccess(transaction: owner.transaction)
          .canReadTable(owner.session, owner.member, table);
}

class const _ItemReaders(final _ItemSources sources) {
  Future<bool> readable(String id) async {
    for (final resource in sources.live) {
      if (await _resource(resource, id)) return true;
    }

    return false;
  }

  Future<bool> _resource(WorkspaceResource resource, String id) async =>
      switch (resource.resourceKind) {
        .table => await _default(resource, id),
        .file => _data(resource)['assetId'] == id,
        .tableRecord => await _record(resource, id),
        _ => false,
      };

  Future<bool> _default(WorkspaceResource resource, String id) async =>
      resource.resourceId != sources.owner.excludedTableId &&
      _defaultContains(_data(resource), id) &&
      await sources.grant(resource);

  Future<bool> _record(WorkspaceResource resource, String id) async {
    if (resource.resourceId == sources.owner.excludedRecordId) return false;
    final table = sources.recordTable(resource, id);

    return table != null && await sources.grant(table);
  }
}

class const _ItemReuse(final _ItemSources sources) {
  Future<bool> allows(String id, Set<String> readers) async {
    if (await _defaults(id, readers)) return true;

    return await _records(id, readers);
  }

  Future<bool> _defaults(String id, Set<String> readers) async {
    for (final table in sources.tables) {
      if (await _default(table, id, readers)) return true;
    }

    return false;
  }

  Future<bool> _default(
    WorkspaceResource table,
    String id,
    Set<String> readers,
  ) async =>
      _defaultContains(_data(table), id) &&
      _audienceFits(table, readers) &&
      await sources.grant(table);

  Future<bool> _records(String id, Set<String> readers) async {
    for (final record in sources.records) {
      if (await _record(record, id, readers)) return true;
    }

    return false;
  }

  Future<bool> _record(
    WorkspaceResource record,
    String id,
    Set<String> readers,
  ) async {
    final table = sources.recordTable(record, id);

    return table != null &&
        _audienceFits(table, readers) &&
        await sources.grant(table);
  }
}

bool _audienceFits(WorkspaceResource source, Set<String> readers) =>
    readers.difference(_readers(source)).isEmpty;

Map<String, dynamic> _data(WorkspaceResource row) =>
    jsonDecode(row.data) as Map<String, dynamic>;

bool _contains(
  WorkspaceResource table,
  Map<String, dynamic> record,
  String id,
) {
  final columns = _data(table)['columns'];
  final values = record['values'];
  if (columns is! List || values is! Map) return false;
  for (final column in columns.whereType<Map>()) {
    if (column['type'] != 'attachment') continue;
    final value = values[column['id']];
    if (value is List && value.contains(id)) return true;
  }
  return false;
}

Set<String> _readers(WorkspaceResource table) {
  final grants = _data(table)['memberAccess'];
  return grants is Map ? grants.keys.cast<String>().toSet() : {};
}

bool _defaultContains(Map<String, dynamic> data, String id) {
  final columns = data['columns'];
  if (columns is! List) return false;
  return columns.whereType<Map>().any(
    (column) =>
        column['type'] == 'attachment' &&
        column['defaultValue'] is List &&
        (column['defaultValue'] as List).contains(id),
  );
}
