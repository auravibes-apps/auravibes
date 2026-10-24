abstract final class WorkspaceTableValidation {
  static const _types = {
    'text',
    'number',
    'checkbox',
    'singleSelect',
    'multiSelect',
    'url',
    'email',
    'phone',
  };

  static void schema(Map<String, Object?> data) =>
      _SchemaValidation.validate(data);

  static void values(Map<String, Object?> schema, Map<String, Object?> values) {
    final columns = (schema['columns'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    _required(columns, values);
    for (final entry in values.entries) {
      if (!_entryValid(columns, entry)) throw const FormatException();
    }
  }

  static bool _entryValid(
    List<Map<String, dynamic>> columns,
    MapEntry<String, Object?> entry,
  ) {
    final column = columns
        .where((column) => column['id'] == entry.key)
        .firstOrNull;

    return column != null && _valid(column, entry.value);
  }

  static void _required(
    List<Map<String, dynamic>> columns,
    Map<String, Object?> values,
  ) {
    for (final column in columns) {
      if (column['required'] == true && !values.containsKey(column['id'])) {
        throw const FormatException();
      }
    }
  }

  static bool _valid(Map<String, Object?> column, Object? value) {
    final options = (column['options'] as List<dynamic>? ?? const [])
        .cast<String>();

    return switch (column['type']) {
      'text' => value is String && value.length <= 16384,
      'number' => value is num && value.isFinite,
      'checkbox' => value is bool,
      'singleSelect' => value is String && options.contains(value),
      'multiSelect' =>
        value is List &&
            value.toSet().length == value.length &&
            value.every((entry) => entry is String && options.contains(entry)),
      'url' => value is String && value.length <= 16384 && _url(value),
      'email' =>
        value is String &&
            value.length <= 16384 &&
            RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value),
      'phone' =>
        value is String &&
            value.length <= 16384 &&
            RegExp(
              r'^\+?[0-9 ()-]+(?:\s*(?:x|ext\.?)\s*[0-9]+)?$',
              caseSensitive: false,
            ).hasMatch(value) &&
            RegExp('[0-9]').allMatches(value).length >= 3,
      _ => false,
    };
  }

  static bool _url(String value) {
    final uri = Uri.tryParse(value);

    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty &&
        !value.contains(RegExp(r'\s'));
  }
}

abstract final class _SchemaValidation {
  static const _maximumNameLength = 200;

  static void validate(Map<String, Object?> data) {
    final columns = _columns(data);
    _checkColumns(columns);
    if (!columns.any(
      (column) => _label(column as Map, data['labelColumnId']),
    )) {
      throw const FormatException();
    }
  }

  static void _checkColumns(List<dynamic> columns) {
    final ids = <String>{};
    for (final raw in columns) {
      if (raw is! Map<String, dynamic>) throw const FormatException();
      _column(raw);
      if (!ids.add(raw['id'] as String)) throw const FormatException();
    }
  }

  static List<dynamic> _columns(Map<String, Object?> data) {
    final columns = data['columns'];
    final revision = data['schemaRevision'];
    if (columns is! List ||
        columns.isEmpty ||
        revision is! int ||
        revision < 1) {
      throw const FormatException();
    }

    return columns;
  }

  static bool _label(Map column, Object? id) =>
      column['id'] == id && column['type'] == 'text';

  static void _column(Map<String, dynamic> column) {
    final id = column['id'];
    if (id is! String ||
        id.isEmpty ||
        !_name(column['name']) ||
        !WorkspaceTableValidation._types.contains(column['type'])) {
      throw const FormatException();
    }
    _constraints(column);
    _options(column);
  }

  static void _constraints(Map<String, Object?> column) {
    for (final key in ['required', 'unique']) {
      if (column.containsKey(key) && column[key] is! bool) {
        throw const FormatException();
      }
    }
    if (column['defaultValue'] != null &&
        !WorkspaceTableValidation._valid(column, column['defaultValue'])) {
      throw const FormatException();
    }
  }

  static void _options(Map<String, Object?> column) {
    final options = column['options'] ?? const <String>[];
    final selection =
        column['type'] == 'singleSelect' || column['type'] == 'multiSelect';
    if (options is! List ||
        (selection ? !_selection(options) : options.isNotEmpty)) {
      throw const FormatException();
    }
  }

  static bool _selection(List options) =>
      options.isNotEmpty &&
      options.toSet().length == options.length &&
      options.every(_name);
  static bool _name(Object? name) =>
      name is String &&
      name.trim().isNotEmpty &&
      name.length <= _maximumNameLength;
}
