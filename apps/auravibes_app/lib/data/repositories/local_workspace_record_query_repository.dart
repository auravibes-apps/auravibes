import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_record_query_sql.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_query_filter_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:drift/drift.dart';

class const LocalWorkspaceRecordQueryRepository(
  final AppDatabase database,
  final String workspaceId,
) implements WorkspaceRecordQueryRepository {
  @override
  Future<WorkspaceRecordPage> query(
    String tableId,
    WorkspaceRecordQuery query,
  ) async {
    final table = await LocalWorkspaceTableRepository(
      database,
      workspaceId,
    ).table(tableId);
    final statement = _QueryStatement(workspaceId, table, query).._validate();
    final rows = await _read(statement);

    return _page(rows, query.limit);
  }

  Future<List<QueryRow>> _read(_QueryStatement statement) => database
      .customSelect(
        statement._sql.build(),
        variables: statement._variables(),
        readsFrom: {database.workspaceTableRecords},
      )
      .get();
}

String _path(String id) => '\$.${jsonEncode(id)}';

WorkspaceRecord _record(QueryRow row) => WorkspaceRecord(
  id: row.read<String>('id'),
  tableId: row.read<String>('table_id'),
  values: _values(row.read<String>('values_json')),
  revision: row.read<int>('revision'),
);

Map<String, Object?> _values(String encoded) =>
    (jsonDecode(encoded) as Map<String, dynamic>).cast<String, Object?>();
WorkspaceRecordPage _page(List<QueryRow> rows, int limit) =>
    WorkspaceRecordPage(
      records: rows.take(limit).map(_record).toList(),
      hasMore: rows.length > limit,
    );

class const _QueryStatement(
  final String workspaceId,
  final WorkspaceTable table,
  final WorkspaceRecordQuery query,
) {
  String get _sort => query.sortColumnId ?? table.labelColumnId;
  String get _filter => switch (query.filterColumnId) {
    final String id when id.isNotEmpty => id,
    _ => table.labelColumnId,
  };
  LocalWorkspaceRecordQuerySql get _sql => LocalWorkspaceRecordQuerySql(
    _column(_sort).type.name,
    _column(_filter).type.name,
    descending: query.descending,
    contains: query.filterOperator == .contains,
  );
  String get _operand => switch (_column(_filter).type) {
    .number => num.parse(query.filterValue ?? '').toString(),
    .checkbox when query.filterValue == 'true' => '1',
    .checkbox => '0',
    _ => query.filterValue ?? '',
  };
  void _validate() {
    final _ = _column(_sort);
    if (query.filterColumnId?.isNotEmpty == true) {
      final _ = _column(_filter);
      final _ = WorkspaceQueryFilterValidation.parse(
        _column(_filter),
        query.filterValue ?? '',
        contains: query.filterOperator == .contains,
      );
    }
  }

  WorkspaceColumn _column(String id) {
    final column = table.columns.where((column) => column.id == id).firstOrNull;
    if (column == null || !WorkspaceQueryFilterValidation.supports(column)) {
      throw const WorkspaceTableException();
    }

    return column;
  }

  List<Variable<Object>> _variables() => [
    ..._projection(),
    Variable(workspaceId),
    Variable(table.id),
    ..._criteria(),
    Variable(query.limit + 1),
    Variable(query.offset),
  ];
  List<Variable<String>> _projection() => [
    Variable(_path(table.labelColumnId)),
    Variable(_path(_filter)),
    Variable(_path(_sort)),
    Variable(_operand),
  ];
  List<Variable<String>> _criteria() => [
    Variable(_fold(query.search)),
    Variable(_fold(query.search)),
    Variable(query.filterColumnId ?? ''),
  ];
}

String _fold(String value) => value.replaceAllMapped(
  RegExp('[A-Z]'),
  (match) => match.group(0)?.toLowerCase() ?? '',
);
