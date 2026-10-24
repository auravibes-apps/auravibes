/// Checks retained structured references, including snapshots outside purge scope.
bool workspaceRetainedReference(
  Map<String, dynamic> data,
  Set<String> ids,
  Set<String> referenceColumns, {
  bool view = false,
}) {
  for (final key in ['tableId', 'targetTableId', 'parentId']) {
    if (ids.contains(data[key])) return true;
  }
  final columns = data['columns'];
  if (columns is List) {
    for (final column in columns.cast<Map<String, dynamic>>()) {
      if (column['type'] == 'reference' &&
          (ids.contains(column['targetTableId']) ||
              _contains(column['defaultValue'], ids))) {
        return true;
      }
    }
  }
  final values = data['values'];
  if (values is Map) {
    for (final column in referenceColumns) {
      if (_contains(values[column], ids)) return true;
    }
  }
  return view && _contains(data, ids);
}

bool _contains(Object? value, Set<String> ids) {
  if (value is String) return ids.contains(value);
  if (value is List) return value.any((item) => _contains(item, ids));
  if (value is Map) return value.values.any((item) => _contains(item, ids));
  return false;
}

Set<String> workspaceReferenceColumns(Iterable<Map<String, dynamic>> data) => {
  for (final item in data)
    if (item['columns'] case final List<dynamic> columns)
      for (final column in columns.cast<Map<String, dynamic>>())
        if (column['type'] == 'reference') column['id'] as String,
};
