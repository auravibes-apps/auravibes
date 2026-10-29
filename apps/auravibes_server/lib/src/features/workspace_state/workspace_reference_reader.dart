import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/auth_user_lock.dart';
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
  Future<List<WorkspaceResource>> tableTargets(
    WorkspaceReferenceTableRequest input,
  ) => session.db.transaction((transaction) async {
    final reader = await _reader(transaction);

    return await reader.tableTargets(input);
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
    final authUser = await const AuthUserLock().lock(
      session,
      userId: userId,
      transaction: transaction,
    );
    if (authUser == null) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.authenticationRequired,
      );
    }
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
  Future<WorkspaceResource> visible(
    WorkspaceResourceKind kind,
    String id,
  ) async {
    final row = await _resource(kind, id);
    if (row == null || row.deletedAt != null) _denied();
    final result = await WorkspaceTableAccess(transaction: transaction)
        .visible(session, member, row);

    return result ?? _denied();
  }

  Future<List<WorkspaceResource>> targets(
    WorkspaceReferenceTargetRequest input,
  ) async {
    if (input.search.length > _maximumSearchLength) _invalid();
    final selection = await _ReferenceSelection(this, input).read();

    return await _targetRows(selection.target, selection.query);
  }

  Future<List<WorkspaceResource>> tableTargets(
    WorkspaceReferenceTableRequest input,
  ) async {
    if (input.search.length > _maximumSearchLength) _invalid();
    final target = await visible(.table, input.tableId);

    return await _targetRows(target, (
      search: input.search,
      afterId: input.afterId,
      matchColumn: null,
      parentId: null,
    ));
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
  Future<List<WorkspaceResource>> _targetRows(
    WorkspaceResource target,
    ({String search, String? afterId, String? matchColumn, String? parentId})
    input,
  ) async {
    final rows = await _query(this)
        .read(_targetSql, _targetParameters(target, input));

    return await _query(this).project(rows);
  }

  Future<List<WorkspaceResource>> _reversePage(
    WorkspaceReferenceRecordRequest input,
    String? cursor,
  ) => _query(this).read(_reverseSql, _reverseParameters(input, cursor));

  Future<void> _append(
    List<WorkspaceResource> rows,
    List<WorkspaceResource> candidates,
  ) async {
    for (final row in await _query(this).project(candidates)) {
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

Map<String, Object?> _targetParameters(
  WorkspaceResource table,
  ({String search, String? afterId, String? matchColumn, String? parentId})
  input,
) => {
  'tableId': table.resourceId,
  'label': _data(table)['labelColumnId'],
  'search': input.search,
  'afterId': input.afterId ?? '',
  'matchColumn': input.matchColumn ?? '',
  'parentId': input.parentId ?? '',
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
AND strpos(
  translate(COALESCE(data::jsonb->'values'->>@label, ''),
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),
  translate(@search, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) > 0
AND (@matchColumn = '' OR data::jsonb->'values'->>@matchColumn = NULLIF(@parentId, ''))
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

_QueryRows _query(_Reader reader) =>
    _QueryRows(reader.session, reader.member, reader.transaction);

typedef _TargetQuery = ({
  String search,
  String? afterId,
  String? matchColumn,
  String? parentId,
});

class const _ReferenceSelection(
  final _Reader reader,
  final WorkspaceReferenceTargetRequest input,
) {
  Future<({WorkspaceResource target, _TargetQuery query})> read() async {
    final source = await reader.visible(.table, input.sourceTableId);
    final column = _sourceColumn(source, input.columnId);
    await _parent(source, column);
    final target = await reader.visible(
      .table,
      column['targetTableId'] as String,
    );

    return (target: target, query: _query(column));
  }

  _TargetQuery _query(Map column) => (
    search: input.search,
    afterId: input.afterId,
    matchColumn: column['targetMatchColumnId'] as String?,
    parentId: input.parentId,
  );
  Future<void> _parent(WorkspaceResource source, Map column) async {
    final id = input.parentId;
    if (column['dependsOnColumnId'] == null || id == null) return;
    final parent = _sourceColumn(source, column['dependsOnColumnId'] as String);
    final row = await reader.visible(.tableRecord, id);
    if (_data(row)['tableId'] != parent['targetTableId']) _invalid();
  }
}

Map _sourceColumn(WorkspaceResource source, String id) =>
    (_data(source)['columns'] as List)
        .cast<Map>()
        .where((column) => column['id'] == id && column['type'] == 'reference')
        .firstOrNull ??
    _invalid();
