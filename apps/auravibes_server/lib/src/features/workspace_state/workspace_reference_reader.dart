import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'repositories/workspace_state_repository.dart';
import 'workspace_table_access.dart';

const _pageBatch = 51;
const _maximumSearchLength = 200;

class const WorkspaceReferenceReader(
  final Session session,
  final int workspaceId,
  final String userId,
) {
  Future<List<WorkspaceResource>> targets(
    WorkspaceReferenceTargetRequest input,
  ) => session.db.transaction((transaction) async {
    final reader = await _reader(transaction);

    return await reader.targets(input);
  });
  Future<WorkspaceResource> record(WorkspaceReferenceRecordRequest input) =>
      session.db.transaction((transaction) async {
        final reader = await _reader(transaction);

        return await reader.record(input);
      });
  Future<List<WorkspaceResource>> reverse(
    WorkspaceReferenceRecordRequest input,
  ) => session.db.transaction((transaction) async {
    final reader = await _reader(transaction);
    final _ = await reader.record(input);

    return await reader.reverse(input);
  });
  Future<_Reader> _reader(Transaction transaction) async {
    final member = await _member(transaction);

    return _Reader(session, member, transaction);
  }

  Future<WorkspaceMember> _member(Transaction transaction) async {
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

    return member;
  }
}

class const _Reader(
  final Session session,
  final WorkspaceMember member,
  final Transaction transaction,
) {
  _QueryRows get query => _QueryRows(session, member, transaction);
  WorkspaceTableAccess get access =>
      WorkspaceTableAccess(transaction: transaction);
  Future<WorkspaceResource> visible(
    WorkspaceResourceKind kind,
    String id,
  ) async {
    final row = await _resource(kind, id);
    if (row == null || row.deletedAt != null) _denied();
    final result = await access.visible(session, member, row);

    return result ?? _denied();
  }

  Future<List<WorkspaceResource>> targets(
    WorkspaceReferenceTargetRequest input,
  ) async {
    if (input.search.length > _maximumSearchLength) _invalid();
    final target = await _target(input);
    final rows = await query.read(_targetSql, _targetParameters(target, input));

    return await query.project(rows);
  }

  Future<WorkspaceResource> record(
    WorkspaceReferenceRecordRequest input,
  ) async {
    final row = await visible(.tableRecord, input.recordId);
    if (_data(row)['tableId'] != input.tableId) _invalid();

    return row;
  }

  Future<List<WorkspaceResource>> reverse(
    WorkspaceReferenceRecordRequest input,
  ) async {
    final rows = <WorkspaceResource>[];
    var cursor = input.afterId;
    while (rows.length < _pageBatch) {
      final candidates = await _reversePage(input, cursor);
      await _append(rows, candidates);
      if (candidates.length < _pageBatch) break;
      cursor = candidates.last.resourceId;
    }

    return rows;
  }

  Future<WorkspaceResource?> _resource(WorkspaceResourceKind kind, String id) =>
      WorkspaceStateRepository().findResource(
        session,
        workspaceId: member.workspaceId,
        kind: kind,
        resourceId: id,
        transaction: transaction,
      );
  Future<WorkspaceResource> _target(
    WorkspaceReferenceTargetRequest input,
  ) async {
    final source = await visible(.table, input.sourceTableId);

    return await visible(.table, _targetId(source, input.columnId));
  }

  Future<List<WorkspaceResource>> _reversePage(
    WorkspaceReferenceRecordRequest input,
    String? cursor,
  ) => query.read(_reverseSql, _reverseParameters(input, cursor));

  Future<void> _append(
    List<WorkspaceResource> rows,
    List<WorkspaceResource> candidates,
  ) async {
    for (final row in await query.project(candidates)) {
      rows.add(row);
      if (rows.length == _pageBatch) break;
    }
  }
}

class const _QueryRows(
  final Session session,
  final WorkspaceMember member,
  final Transaction transaction,
) {
  Future<List<WorkspaceResource>> read(
    String sql,
    Map<String, Object?> values,
  ) async {
    final ids = await _ids(sql, values);
    if (ids.isEmpty) return [];
    final rows = await _resources(ids);

    return _ordered(rows, ids);
  }

  Future<List<WorkspaceResource>> project(List<WorkspaceResource> rows) async {
    final result = <WorkspaceResource>[];
    final access = WorkspaceTableAccess(transaction: transaction);
    for (final row in rows) {
      final visible = await access.visible(session, member, row);
      if (visible != null) result.add(visible);
    }

    return result;
  }

  Future<List<String>> _ids(String sql, Map<String, Object?> values) async {
    final result = await session.db.unsafeQuery(
      sql,
      parameters: .named({...values, 'workspaceId': member.workspaceId}),
      transaction: transaction,
    );

    return result.map(_rowId).toList();
  }

  Future<List<WorkspaceResource>> _resources(List<String> ids) =>
      WorkspaceResource.db.find(
        session,
        where: (row) => _matches(row, ids),
        transaction: transaction,
      );
  Expression _matches(WorkspaceResourceTable row, List<String> ids) =>
      row.workspaceId.equals(member.workspaceId) &
      row.resourceKind.equals(.tableRecord) &
      row.resourceId.inSet(ids.toSet());
  List<WorkspaceResource> _ordered(
    List<WorkspaceResource> rows,
    List<String> ids,
  ) {
    final indexed = {for (final row in rows) row.resourceId: row};

    return [for (final id in ids) ?indexed[id]];
  }
}

String _targetId(WorkspaceResource source, String columnId) {
  final columns = (_data(source)['columns'] as List)
      .cast<Map<String, dynamic>>();
  final column = columns
      .where((column) => _referenceColumn(column, columnId))
      .firstOrNull;
  if (column == null) _invalid();

  return column['targetTableId'] as String;
}

bool _referenceColumn(Map<String, dynamic> column, String id) =>
    column['id'] == id && column['type'] == 'reference';
Map<String, Object?> _targetParameters(
  WorkspaceResource table,
  WorkspaceReferenceTargetRequest input,
) => {
  'tableId': table.resourceId,
  'label': _data(table)['labelColumnId'],
  'search': input.search.toLowerCase(),
  'afterId': input.afterId ?? '',
};
Map<String, Object?> _reverseParameters(
  WorkspaceReferenceRecordRequest input,
  String? cursor,
) => {
  'tableId': input.tableId,
  'recordId': input.recordId,
  'afterId': cursor ?? '',
};
String _rowId(DatabaseResultRow row) =>
    row.toColumnMap()['resourceId'] as String;
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
