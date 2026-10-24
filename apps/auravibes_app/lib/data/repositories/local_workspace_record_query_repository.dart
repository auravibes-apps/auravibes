import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_values.dart';
import 'package:auravibes_app/data/repositories/local_workspace_record_query_sql.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_query_filter_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';

class const LocalWorkspaceRecordQueryRepository(
  final AppDatabase database,
  final String workspaceId,
) implements WorkspaceRecordQueryRepository {
  LocalWorkspaceTableRepository get _tables =>
      LocalWorkspaceTableRepository(database, workspaceId);
  @override
  Future<WorkspaceRecordPage> query(
    String tableId,
    WorkspaceRecordQuery query,
  ) => database.transaction(() => _query(tableId, query));

  @override
  Future<Map<String, Object?>> summarize(
    String tableId,
    WorkspaceRecordQuery query,
    List<String> columnIds,
  ) => database.transaction(
    () => _LocalRecordSummary(this, tableId, query, columnIds).read(),
  );

  Future<WorkspaceRecordPage> _query(
    String tableId,
    WorkspaceRecordQuery query,
  ) async {
    final table = await _tables.table(tableId);
    final statement = _QueryStatement(workspaceId, table, query).._validate();
    await _reference(table, query);

    return await _authorized(statement, query);
  }

  Future<WorkspaceRecordPage> _authorized(
    _QueryStatement statement,
    WorkspaceRecordQuery query,
  ) async {
    final rows = await _read(statement);

    final page = _page(rows, query.limit);
    if (!statement.table.columns.any((column) => column.type == .attachment)) {
      return page;
    }

    return WorkspaceRecordPage(
      records: await Future.wait(
        page.records.map(
          (record) => LocalWorkspaceAssetValues(
            database,
            workspaceId,
          ).project(statement.table.columns, record),
        ),
      ),
      hasMore: page.hasMore,
    );
  }

  Future<void> _reference(
    WorkspaceTable table,
    WorkspaceRecordQuery query,
  ) async {
    final column = _filterColumn(table, query.filterColumnId);
    if (column == null || column.type != .reference) return;
    final _ = await _tables.record(
      column.targetTableId ?? '',
      query.filterValue ?? '',
    );
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
    referenceMultiple: _column(_filter).referenceMultiple,
  );
  String get _operand => switch (_column(_filter).type) {
    .number => num.parse(query.filterValue ?? '').toString(),
    .checkbox when query.filterValue == 'true' => '1',
    .checkbox => '0',
    _ => query.filterValue ?? '',
  };
  void _validate() {
    if (!WorkspaceQueryFilterValidation.supports(_column(_sort))) {
      throw const WorkspaceTableException();
    }
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
    if (column == null ||
        !WorkspaceQueryFilterValidation.supportsFilter(column)) {
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

WorkspaceColumn? _filterColumn(WorkspaceTable table, String? id) =>
    table.columns.where((column) => column.id == id).firstOrNull;

WorkspaceRecordQuery _summaryPage(WorkspaceRecordQuery query, int offset) =>
    WorkspaceRecordQuery(
      search: query.search,
      filterColumnId: query.filterColumnId,
      filterValue: query.filterValue,
      filterOperator: query.filterOperator,
      sortColumnId: query.sortColumnId,
      descending: query.descending,
      offset: offset,
      limit: _summaryBatchSize,
    );

const _summaryBatchSize = 100;
const _maximumSummaryColumns = 50;

class const _LocalRecordSummary(
  final LocalWorkspaceRecordQueryRepository repository,
  final String tableId,
  final WorkspaceRecordQuery query,
  final List<String> columnIds,
) {
  Future<Map<String, Object?>> read() async {
    final summary = await _summary();
    var offset = 0;
    while (await _appendPage(summary, offset)) {
      offset += _summaryBatchSize;
    }

    return summary.toJson();
  }

  Future<A2uiDataSummary> _summary() async {
    final table = await repository._tables.table(tableId);
    _validateSummaryColumns(table, columnIds);

    return A2uiDataSummary(_summaryTypes(table, columnIds));
  }

  Future<bool> _appendPage(A2uiDataSummary summary, int offset) async {
    final page = await repository._query(tableId, _summaryPage(query, offset));
    for (final record in page.records) {
      summary.add(record.values);
    }

    return page.hasMore;
  }
}

void _validateSummaryColumns(WorkspaceTable table, List<String> ids) {
  if (!_validSummaryIds(ids) ||
      ids.any((id) => !_summaryColumnExists(table, id))) {
    throw const WorkspaceTableException();
  }
}

bool _validSummaryIds(List<String> ids) =>
    ids.length <= _maximumSummaryColumns && ids.length == ids.toSet().length;
Map<String, String> _summaryTypes(WorkspaceTable table, List<String> ids) => {
  for (final column in table.columns.where((column) => ids.contains(column.id)))
    column.id: column.type.name,
};

bool _summaryColumnExists(WorkspaceTable table, String id) => table.columns.any(
  (column) => column.id == id && column.type.name != 'attachment',
);
