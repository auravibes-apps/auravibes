/// Retained references include snapshots outside the explicit purge scope.
abstract final class WorkspaceRetainedReferences {
  static bool references(
    Map<String, dynamic> data,
    Set<String> ids,
    ({Set<String> columns, bool view}) options,
  ) =>
      _hierarchy(data, ids) ||
      _schema(data, ids) ||
      _records(data, ids, options.columns) ||
      (options.view && _contains(data, ids));

  static Set<String> columns(Iterable<Map<String, dynamic>> data) => {
    for (final item in data)
      if (item['columns'] case final List<dynamic> columns)
        for (final column in columns.cast<Map<String, dynamic>>())
          if (column['type'] == 'reference') column['id'] as String,
  };

  static bool _hierarchy(Map<String, dynamic> data, Set<String> ids) => [
    'tableId',
    'targetTableId',
    'parentId',
  ].any((key) => _identity(data[key], ids));

  static bool _schema(Map<String, dynamic> data, Set<String> ids) {
    final columns = data['columns'];
    if (columns is! List) return false;

    return columns.cast<Map<String, dynamic>>().any(
      (column) => _column(column, ids),
    );
  }

  static bool _column(Map<String, dynamic> column, Set<String> ids) =>
      column['type'] == 'reference' &&
      (_identity(column['targetTableId'], ids) ||
          _contains(column['defaultValue'], ids));

  static bool _records(
    Map<String, dynamic> data,
    Set<String> ids,
    Set<String> columns,
  ) {
    final values = data['values'];
    if (values is! Map) return false;

    return columns.any((column) => _contains(values[column], ids));
  }

  static bool _identity(Object? value, Set<String> ids) =>
      value is String && ids.contains(value);

  static bool _contains(Object? value, Set<String> ids) => switch (value) {
    final String text => ids.contains(text),
    final List<dynamic> items => items.any((item) => _contains(item, ids)),
    final Map<dynamic, dynamic> items => items.values.any(
      (item) => _contains(item, ids),
    ),
    _ => false,
  };
}
