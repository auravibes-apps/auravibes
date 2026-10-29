import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_assets.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_retention.dart';
import 'package:auravibes_app/data/repositories/local_workspace_retained_reader.dart';
import 'package:drift/drift.dart';

typedef _Schema = Map<String, Set<String>>;

/// Retention protects bytes, while a live source authorizes their use.
class const LocalWorkspaceAssetAccess(
  final AppDatabase database,
  final String workspaceId,
) {
  Future<bool> allows(String id) async {
    final sources = _Sources(database, workspaceId);
    if (await sources.file(id) || await sources.conversation(id)) return true;
    if (await _TableAssets(sources).allows(id)) return true;

    // Fresh owner uploads have no references yet.
    return !(await LocalWorkspaceAssetRetention(
      database,
      workspaceId,
    ).ids()).contains(id);
  }
}

class const _Sources(final AppDatabase database, final String workspaceId) {
  Future<bool> file(String id) async {
    final query = database.select(database.workspaceFiles)
      ..where((row) => _liveFile(row, id))
      ..limit(1);

    return await query.getSingleOrNull() != null;
  }

  Future<bool> conversation(String id) async {
    final rows = await database
        .customSelect(
          'SELECT a.asset_id FROM message_attachments a '
          'JOIN messages m ON m.id = a.message_id '
          'JOIN conversations c ON c.id = m.conversation_id '
          'WHERE c.workspace_id = ? AND a.asset_id = ? LIMIT 1',
          variables: [Variable(workspaceId), Variable(id)],
        )
        .get();

    return rows.isNotEmpty;
  }

  Future<List<WorkspaceTableRow>> tables() {
    final query = database.select(database.workspaceTables)
      ..where(
        (row) => row.workspaceId.equals(workspaceId) & row.deletedAt.isNull(),
      );

    return query.get();
  }

  Future<List<WorkspaceTableRecordRow>> records() {
    final query = database.select(database.workspaceTableRecords)
      ..where(
        (row) => row.workspaceId.equals(workspaceId) & row.deletedAt.isNull(),
      );

    return query.get();
  }

  Future<List<LocalRetainedData>> retained() =>
      LocalWorkspaceRetainedReader(database, workspaceId).read({});
  Expression<bool> _liveFile(WorkspaceFiles row, String id) =>
      row.workspaceId.equals(workspaceId) &
      row.assetId.equals(id) &
      row.deletedAt.isNull();
}

class const _TableAssets(final _Sources sources) {
  Future<bool> allows(String id) async {
    final schema = await _schema();
    final records = await sources.records();
    if (records.any((row) => _current(id, row, schema))) return true;
    final retained = await sources.retained();

    return retained.any((row) => _retained(id, row, schema));
  }

  Future<_Schema> _schema() async => {
    for (final table in await sources.tables())
      table.id: _Cells.columns(jsonDecode(table.columnsJson))
          .map((column) => column['id'])
          .whereType<String>()
          .toSet(),
  };

  static bool _current(String id, WorkspaceTableRecordRow row, _Schema schema) {
    final columns = schema[row.tableId] ?? const <String>{};
    final values = jsonDecode(row.valuesJson) as Map<String, dynamic>;

    return columns.any((column) => _Cells.contains(values[column], id));
  }

  static bool _retained(String id, LocalRetainedData row, _Schema schema) {
    if (row.kind == 'table' && schema.containsKey(row.id)) {
      return _Cells.columns(row.data['columns'])
          .any((column) => _Cells.contains(column['defaultValue'], id));
    }
    if (row.kind != 'record') return false;

    return _snapshot(id, row.data, schema);
  }

  static bool _liveSource(Map<String, dynamic> data, _Schema schema) {
    final tableId = data['tableId'];

    return tableId is String && schema.containsKey(tableId);
  }

  static bool _snapshot(String id, Map<String, dynamic> data, _Schema schema) {
    if (!_liveSource(data, schema)) return false;
    final columns = data['historyAttachmentColumns'];
    final values = data['values'];
    if (columns is! List || values is! Map) return false;

    return columns.whereType<String>().any(
      (column) => _Cells.contains(values[column], id),
    );
  }
}

abstract final class _Cells {
  static Iterable<Map<String, dynamic>> columns(Object? value) => value is List
      ? value.whereType<Map<String, dynamic>>().where(
          (column) => column['type'] == 'attachment',
        )
      : const [];

  static bool contains(Object? value, String id) =>
      value is List && value.contains(id);
}
