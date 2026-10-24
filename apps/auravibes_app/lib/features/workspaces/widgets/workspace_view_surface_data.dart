import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_time_zones.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:easy_localization/easy_localization.dart';

abstract final class WorkspaceViewSurfaceData {
  static Map<String, Object?> envelope(WorkspaceViewData data) => {
    'protocolVersion': 'v1',
    'interactionMode': 'passive',
    'initialSurface': _surface(data),
  };
  static Map<String, Object?> _surface(WorkspaceViewData data) => {
    'surfaceId': 'view',
    'catalogId': a2uiChatCatalogId,
    'components': data.view.definition.components,
    'dataModel': _model(data),
  };
  static Map<String, Object?> _model(WorkspaceViewData data) => {
    'columns': _columns(data),
    'rows': _rows(data),
    ..._fields(data),
  };
  static List<String?> _columns(WorkspaceViewData data) {
    final names = {
      for (final column in data.table.columns) column.id: column.name,
    };

    return data.view.bindings.values.map((id) => names[id]).toList();
  }

  static List<List<Object?>> _rows(WorkspaceViewData data) => [
    for (final record in data.records)
      [
        for (final id in data.view.bindings.values)
          _displayValue(data, record, id),
      ],
  ];
  static Map<String, Object?> _fields(WorkspaceViewData data) =>
      data.records.isEmpty
      ? {}
      : {
          for (final entry in data.view.bindings.entries)
            entry.key: _displayValue(data, data.records.first, entry.value),
        };
}

Object? _displayValue(
  WorkspaceViewData data,
  WorkspaceRecord record,
  String id,
) {
  if (_restricted(record, id) || _unavailable(data, record, id)) {
    return LocaleKeys.workspace_views_unavailable.tr();
  }

  return _formatted(data, record, id);
}

bool _restricted(WorkspaceRecord record, String id) =>
    record.restrictedReferenceColumns.contains(id);
bool _unavailable(WorkspaceViewData data, WorkspaceRecord record, String id) =>
    record.values[id] == null &&
    data.table.columns.any(
      (column) => column.id == id && column.type == .reference,
    );
Object? _scalar(Object? value) => switch (value) {
  final Map<Object?, Object?> money => _money(money),
  final List<dynamic> list => list.join(', '),
  _ => value,
};
String _money(Map<Object?, Object?> money) =>
    '${money['amount']} ${money['currency']}';

Object? _formatted(WorkspaceViewData data, WorkspaceRecord record, String id) {
  final column = data.table.columns
      .where((column) => column.id == id)
      .firstOrNull;
  final value = record.values[id];

  return _columnValue(column, value);
}

Object? _columnValue(WorkspaceColumn? column, Object? value) {
  if (column?.type == .timestamp && value is String) {
    return WorkspaceTimeZones.display(value, column?.timeZone ?? 'UTC');
  }

  return _scalar(value);
}
