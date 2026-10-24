import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'repositories/workspace_state_repository.dart';
import 'workspace_table_access.dart';

class const WorkspaceReferenceReader(
  final Session session,
  final int workspaceId,
  final String userId,
) {
  Future<List<WorkspaceResource>> targets(
    String sourceId,
    String columnId,
    String search,
    String? afterId,
  ) => session.db.transaction((transaction) async {
    if (search.length > 200) _invalid();
    final reader = await _reader(transaction);
    final source = await reader.visible(.table, sourceId);
    final columns = (_data(source)['columns'] as List)
        .cast<Map<String, dynamic>>();
    final column = columns
        .where(
          (column) => column['id'] == columnId && column['type'] == 'reference',
        )
        .firstOrNull;
    if (column == null) _invalid();
    final target = await reader.visible(
      .table,
      column['targetTableId'] as String,
    );
    return reader.targets(target, search, afterId);
  });

  Future<List<WorkspaceResource>> reverse(
    String tableId,
    String recordId,
    String? afterId,
  ) => session.db.transaction((transaction) async {
    final reader = await _reader(transaction);
    final record = await reader.visible(.tableRecord, recordId);
    if (_data(record)['tableId'] != tableId) _invalid();
    return reader.reverse(tableId, recordId, afterId);
  });

  Future<_Reader> _reader(Transaction transaction) async {
    final repository = WorkspaceStateRepository();
    final workspace = await repository.findWorkspace(
      session,
      workspaceId,
      transaction: transaction,
      lock: true,
    );
    final member = await repository.findMember(
      session,
      workspaceId: workspaceId,
      userId: userId,
      transaction: transaction,
    );
    if (workspace == null || member == null) _denied();
    return _Reader(session, member, transaction);
  }
}

class const _Reader(
  final Session session,
  final WorkspaceMember member,
  final Transaction transaction,
) {
  Future<WorkspaceResource> visible(
    WorkspaceResourceKind kind,
    String id,
  ) async {
    final row = await WorkspaceStateRepository().findResource(
      session,
      workspaceId: member.workspaceId,
      kind: kind,
      resourceId: id,
      transaction: transaction,
    );
    if (row == null || row.deletedAt != null) _denied();
    final result = await WorkspaceTableAccess(transaction: transaction)
        .visible(session, member, row);
    if (result == null) _denied();
    return result;
  }

  Future<List<WorkspaceResource>> targets(
    WorkspaceResource table,
    String search,
    String? afterId,
  ) => _query(_targetSql, {
    'tableId': table.resourceId,
    'label': _data(table)['labelColumnId'],
    'search': search.toLowerCase(),
    'afterId': afterId ?? '',
  });

  Future<List<WorkspaceResource>> reverse(
    String tableId,
    String recordId,
    String? afterId,
  ) async {
    final rows = <WorkspaceResource>[];
    var cursor = afterId ?? '';
    while (rows.length < 51) {
      final candidates = await _query(_reverseSql, {
        'tableId': tableId,
        'recordId': recordId,
        'afterId': cursor,
      }, project: false);
      for (final row in candidates) {
        final visible = await WorkspaceTableAccess(transaction: transaction)
            .visible(session, member, row);
        if (visible != null) rows.add(visible);
        if (rows.length == 51) break;
      }
      if (candidates.length < 51) break;
      cursor = candidates.last.resourceId;
    }
    return rows;
  }

  Future<List<WorkspaceResource>> _query(
    String sql,
    Map<String, Object?> values, {
    bool project = true,
  }) async {
    final result = await session.db.unsafeQuery(
      sql,
      parameters: .named({...values, 'workspaceId': member.workspaceId}),
      transaction: transaction,
    );
    final ids = result
        .map((row) => row.toColumnMap()['resourceId'] as String)
        .toList();
    if (ids.isEmpty) return [];
    final rows = await WorkspaceResource.db.find(
      session,
      where: (row) =>
          row.workspaceId.equals(member.workspaceId) &
          row.resourceKind.equals(.tableRecord) &
          row.resourceId.inSet(ids.toSet()),
      transaction: transaction,
    );
    final indexed = {for (final row in rows) row.resourceId: row};
    if (!project) return [for (final id in ids) ?indexed[id]];
    final visible = <WorkspaceResource>[];
    for (final id in ids) {
      final row = indexed[id];
      if (row == null) continue;
      final projected = await WorkspaceTableAccess(transaction: transaction).visible(session, member, row);
      if (projected != null) visible.add(projected);
    }
    return visible;
  }
}

const _targetSql = '''SELECT "resourceId" FROM workspace_resource
WHERE "workspaceId" = @workspaceId AND "resourceKind" = 'tableRecord'
AND "deletedAt" IS NULL AND "resourceId" > @afterId
AND data::jsonb->>'tableId' = @tableId
AND strpos(lower(COALESCE(data::jsonb->'values'->>@label, '')), @search) > 0
ORDER BY "resourceId" LIMIT 51''';

const _reverseSql = '''SELECT DISTINCT r."resourceId" FROM workspace_resource r
JOIN workspace_resource t ON t."workspaceId" = r."workspaceId"
AND t."resourceId" = r.data::jsonb->>'tableId' AND t."resourceKind" = 'table',
LATERAL jsonb_array_elements(t.data::jsonb->'columns') c
WHERE r."workspaceId" = @workspaceId AND r."resourceKind" = 'tableRecord'
AND r."deletedAt" IS NULL AND t."deletedAt" IS NULL AND r."resourceId" > @afterId
AND c->>'type' = 'reference' AND c->>'targetTableId' = @tableId
AND (r.data::jsonb->'values'->>(c->>'id') = @recordId
OR (jsonb_typeof(r.data::jsonb->'values'->(c->>'id')) = 'array'
AND r.data::jsonb->'values'->(c->>'id') ? @recordId))
ORDER BY r."resourceId" LIMIT 51''';

Map<String, dynamic> _data(WorkspaceResource row) =>
    jsonDecode(row.data) as Map<String, dynamic>;
Never _denied() => throw CloudWorkspaceException(code: .permissionDenied);
Never _invalid() => throw CloudWorkspaceException(code: .validationFailed);
