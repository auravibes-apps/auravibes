import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_retained_reader.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:drift/drift.dart';

/// Retained references protect bytes; they do not grant read permission.
class const LocalWorkspaceAssetRetention(
  final AppDatabase database,
  final String workspaceId,
) {
  Future<void> authorize() async {
    final query = database.select(database.workspaces)
      ..where((row) => row.id.equals(workspaceId));
    final workspace = await query.getSingleOrNull();
    if (workspace?.type != .local) {
      throw const WorkspaceAssetException(.denied);
    }
  }

  Future<Set<String>> ids() async {
    await authorize();
    final rows = await LocalWorkspaceRetainedReader(
      database,
      workspaceId,
    ).read({});

    return _itemAssets(rows)..addAll(await _messages());
  }

  Future<Iterable<String>> _messages() async {
    final messages = await database
        .customSelect(
          'SELECT a.asset_id FROM message_attachments a '
          'JOIN messages m ON m.id = a.message_id '
          'JOIN conversations c ON c.id = m.conversation_id '
          'WHERE c.workspace_id = ? AND a.asset_id IS NOT NULL',
          variables: [Variable(workspaceId)],
        )
        .get();

    return messages.map((row) => row.read<String>('asset_id'));
  }
}

Set<String> _itemAssets(List<LocalRetainedData> rows) {
  final result = <String>{};
  final columns = _tableColumns(rows);
  for (final row in rows) {
    result.addAll(_assets(row, columns));
  }

  return result;
}

Iterable<String> _assets(
  LocalRetainedData row,
  Map<String, Set<String>> columns,
) {
  final data = row.data;
  final assetId = data['assetId'];
  final kind = row.kind;
  if (kind == 'file' && assetId is String) return [assetId];
  if (kind == 'table') return _defaults(data);
  if (kind == 'record') return _record(data, columns);

  return const [];
}

Map<String, Set<String>> _tableColumns(List<LocalRetainedData> rows) {
  final result = <String, Set<String>>{};
  for (final row in rows.where((row) => row.kind == 'table')) {
    result.putIfAbsent(row.id, () => {}).addAll(_attachmentColumns(row.data));
  }

  return result;
}

Iterable<Map<String, dynamic>> _columns(Map<String, dynamic> data) =>
    (data['columns'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((column) => column['type'] == 'attachment');

Set<String> _attachmentColumns(Map<String, dynamic> data) =>
    _columns(data).map((column) => column['id']).whereType<String>().toSet();

Iterable<String> _defaults(Map<String, dynamic> data) =>
    _columns(data).expand((column) => _ids(column['defaultValue']));

Iterable<String> _record(
  Map<String, dynamic> data,
  Map<String, Set<String>> tables,
) {
  final columns = _recordColumns(data, tables);
  final values = data['values'];
  if (values is! Map) return const [];

  return columns.expand((column) => _ids(values[column]));
}

Iterable<String> _recordColumns(
  Map<String, dynamic> data,
  Map<String, Set<String>> tables,
) {
  final provenance = data['historyAttachmentColumns'];
  if (provenance is List) return provenance.whereType<String>();
  final tableId = data['tableId'];

  return tables[tableId is String ? tableId : ''] ?? const <String>{};
}

Iterable<String> _ids(Object? value) =>
    value is List ? value.whereType<String>() : const [];
