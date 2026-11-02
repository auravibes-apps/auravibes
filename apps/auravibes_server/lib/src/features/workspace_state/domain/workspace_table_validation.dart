import 'package:auravibes_server/src/features/workspace_state/domain/workspace_exact_value_validation.dart';
import 'package:auravibes_server/src/features/workspace_state/domain/workspace_time_zones.dart';

import 'workspace_reference_value.dart';

const _maximumTextLength = 16384;
const _minimumPhoneDigits = 3;

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
    'dateOnly',
    'timestamp',
    'money',
    'reference',
    'attachment',
  };

  static void schema(Map<String, Object?> data) =>
      _SchemaValidation.validate(data);

  static void values(Map<String, Object?> schema, Map<String, Object?> values) {
    final columns = (schema['columns'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
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

    return column != null &&
        (entry.value == null || _valid(column, entry.value));
  }

  static bool _valid(Map<String, Object?> column, Object? value) =>
      switch (column['type']) {
        'text' => value is String && value.length <= _maximumTextLength,
        'number' => value is num && value.isFinite,
        'checkbox' => value is bool,
        'singleSelect' || 'multiSelect' => _selectionValue(column, value),
        'url' || 'email' || 'phone' => _formattedValue(column['type'], value),
        _ => _exact(column, value),
      };

  static bool _selectionValue(Map<String, Object?> column, Object? value) {
    final options = (column['options'] as List<dynamic>? ?? const [])
        .cast<String>();
    if (column['type'] == 'singleSelect') {
      return value is String && options.contains(value);
    }

    return _multiple(options, value);
  }

  static bool _multiple(List<String> options, Object? value) =>
      value is List &&
      value.toSet().length == value.length &&
      value.every((entry) => entry is String && options.contains(entry));

  static bool _formattedValue(Object? type, Object? value) {
    if (value is! String || value.length > _maximumTextLength) return false;
    return switch (type) {
      'url' => _url(value),
      'email' => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value),
      'phone' => _phone(value),
      _ => false,
    };
  }

  static bool _phone(String value) =>
      RegExp(
        r'^\+?[0-9 ()-]+(?:\s*(?:x|ext\.?)\s*[0-9]+)?$',
        caseSensitive: false,
      ).hasMatch(value) &&
      RegExp('[0-9]').allMatches(value).length >= _minimumPhoneDigits;

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
    if (!WorkspaceReferenceValue.schema(column)) throw const FormatException();
    _constraints(column);
    _options(column);
    _timeZone(column);
  }

  static void _timeZone(Map<String, Object?> column) {
    final zone = column['timeZone'] ?? 'UTC';
    if (zone is! String || !WorkspaceTimeZones.valid(zone)) {
      throw const FormatException();
    }
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

bool _exact(Map<String, Object?> column, Object? value) =>
    switch (column['type']) {
      'dateOnly' => WorkspaceExactValueValidation.date(value),
      'timestamp' => WorkspaceExactValueValidation.timestamp(value),
      'money' => WorkspaceExactValueValidation.money(value),
      'reference' => WorkspaceReferenceValue.valid(column, value),
      'attachment' => _AttachmentValueValidation.valid(value),
      _ => false,
    };

abstract final class _AttachmentValueValidation {
  static const _maximumAttachments = 100;
  static final _id = RegExp(r'^[0-9]{1,20}$');

  static bool valid(Object? value) =>
      value is List &&
      value.length <= _maximumAttachments &&
      value.toSet().length == value.length &&
      value.every(_validId);

  static bool _validId(Object? id) => id is String && _id.hasMatch(id);
}
