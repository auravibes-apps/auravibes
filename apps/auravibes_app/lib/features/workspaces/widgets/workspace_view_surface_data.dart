import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_time_zones.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:easy_localization/easy_localization.dart';

abstract final class WorkspaceViewSurfaceData {
  static Map<String, Object?> envelope(
    WorkspaceViewData data, [
    Map<String, Object?>? connectedModel,
  ]) {
    final hasAction = data.view.action != null;
    final mode = hasAction ? 'requiresUserAction' : 'passive';

    return {
      'protocolVersion': 'v1',
      'interactionMode': mode,
      'initialSurface': _surface(data, connectedModel, mode),
    };
  }

  static Map<String, Object?> _surface(
    WorkspaceViewData data,
    Map<String, Object?>? connectedModel,
    String mode,
  ) => {
    'surfaceId': 'view',
    'catalogId': mode == 'requiresUserAction'
        ? a2uiChatFormCatalogId
        : a2uiChatCatalogId,
    'components': data.view.definition.components,
    'dataModel': connectedModel ?? _model(data),
  };
  static Map<String, Object?> _model(WorkspaceViewData data) => {
    'columns': _columns(data),
    'rows': _rows(data),
    ..._fields(data),
    ..._actionDefaults(data),
    'fieldLabels': _fieldLabels(data),
    'summary': data.summary,
    ..._chart(data),
  };

  static Map<String, Object?> _actionDefaults(WorkspaceViewData data) {
    final action = data.view.action;
    final record = data.records.firstOrNull;
    if (action == null ||
        action.type != A2uiSavedActionType.updateSelectedRecord ||
        record == null) {
      return const {};
    }

    return _WorkspaceViewFormDefaults.values(action, record);
  }

  static Map<String, String?> _fieldLabels(WorkspaceViewData data) => {
    for (final binding in data.view.bindings.entries)
      binding.key: data.table.columns
          .where((column) => column.id == binding.value)
          .firstOrNull
          ?.name,
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
            entry.key:
                _displayValue(
                  data,
                  data.records.first,
                  entry.value,
                )?.toString() ??
                '-',
        };
}

abstract final class _WorkspaceViewFormDefaults {
  static Map<String, Object?> values(
    A2uiSavedAction action,
    WorkspaceRecord record,
  ) {
    final values = <String, Object?>{};
    for (final entry in action.inputs.entries) {
      final value = record.values[entry.key];
      if (value != null) _writePath(values, entry.value, value);
    }

    return values;
  }

  static void _writePath(
    Map<String, Object?> values,
    String path,
    Object? value,
  ) => _writeSegments(values, _pathSegments(path), value);

  static List<String> _pathSegments(String path) => [
    for (final segment in path.split('/').skip(1))
      segment.replaceAll('~1', '/').replaceAll('~0', '~'),
  ];

  static void _writeSegments(
    Map<String, Object?> values,
    List<String> segments,
    Object? value,
  ) {
    final parent = _writeParents(values, segments);
    if (parent == null) return;
    parent[segments.last] = value;
  }

  static Map<String, Object?>? _writeParents(
    Map<String, Object?> values,
    List<String> segments,
  ) {
    var current = values;
    for (final segment in segments.take(segments.length - 1)) {
      final child = _childMap(current, segment);
      if (child == null) return null;
      current = child;
    }

    return current;
  }

  static Map<String, Object?>? _childMap(
    Map<String, Object?> values,
    String key,
  ) {
    final child = values.putIfAbsent(key, () => <String, Object?>{});

    return child is Map<String, Object?> ? child : null;
  }
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
  if (column?.type == .attachment) {
    return LocaleKeys.workspace_assets_attachments.tr();
  }
  if (column?.type == .timestamp && value is String) {
    return WorkspaceTimeZones.display(value, column?.timeZone ?? 'UTC');
  }

  return _scalar(value);
}

Map<String, Object?> _chart(WorkspaceViewData data) {
  final column = _chartColumn(data);
  if (column == null) {
    return {'chartLabels': <String>[], 'chartSeries': <Object>[]};
  }

  return _chartModel(data, column);
}

WorkspaceColumn? _chartColumn(WorkspaceViewData data) => data.table.columns
    .where(
      (column) =>
          column.type == .number && data.view.bindings.containsValue(column.id),
    )
    .firstOrNull;
Map<String, Object?> _chartModel(
  WorkspaceViewData data,
  WorkspaceColumn column,
) {
  final records = data.records
      .where((record) => record.values[column.id] is num)
      .toList();

  return {
    'chartLabels': _chartLabels(data, records),
    'chartSeries': [_chartSeries(column, records)],
  };
}

List<String> _chartLabels(
  WorkspaceViewData data,
  List<WorkspaceRecord> records,
) => [
  for (final record in records)
    record.values[data.table.labelColumnId]?.toString() ?? '',
];
Map<String, Object?> _chartSeries(
  WorkspaceColumn column,
  List<WorkspaceRecord> records,
) => {
  'label': column.name,
  'values': [for (final record in records) record.values[column.id]],
};
