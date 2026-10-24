import 'package:auravibes_server/src/features/workspace_state/domain/workspace_time_zones.dart';
import 'package:auravibes_server/src/features/workspace_state/domain/workspace_exact_value_validation.dart';

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
  };

  static void schema(Map<String, Object?> data) {
    final columns = data['columns'];
    if (columns is! List ||
        columns.isEmpty ||
        data['schemaRevision'] is! int ||
        (data['schemaRevision'] as int) < 1) {
      throw const FormatException();
    }
    final ids = <String>{};
    var hasLabel = false;
    for (final column in columns) {
      if (column is! Map ||
          column['id'] is! String ||
          (column['id'] as String).isEmpty ||
          !ids.add(column['id'] as String) ||
          column['name'] is! String ||
          (column['name'] as String).trim().isEmpty ||
          (column['name'] as String).length > 200 ||
          !_types.contains(column['type'])) {
        throw const FormatException();
      }
      if (column['id'] == data['labelColumnId']) {
        hasLabel = column['type'] == 'text';
      }
      final zone = column['timeZone'] ?? 'UTC';
      if (zone is! String || !WorkspaceTimeZones.valid(zone)) {
        throw const FormatException();
      }
      final options = column['options'] ?? const <String>[];
      final selection =
          column['type'] == 'singleSelect' || column['type'] == 'multiSelect';
      if (options is! List ||
          (selection
              ? options.isEmpty ||
                    options.toSet().length != options.length ||
                    options.any(
                      (option) =>
                          option is! String ||
                          option.trim().isEmpty ||
                          option.length > 200,
                    )
              : options.isNotEmpty)) {
        throw const FormatException();
      }
    }
    if (!hasLabel) {
      throw const FormatException();
    }
  }

  static void values(Map<String, Object?> schema, Map<String, Object?> values) {
    final columns = (schema['columns'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    for (final entry in values.entries) {
      final column = columns
          .where((column) => column['id'] == entry.key)
          .firstOrNull;
      if (column == null || !_valid(column, entry.value)) {
        throw const FormatException();
      }
    }
  }

  static bool _valid(Map<String, Object?> column, Object? value) =>
      switch (column['type']) {
        'text' => value is String && value.length <= _maximumTextLength,
        'number' => value is num && value.isFinite,
        'checkbox' => value is bool,
        'singleSelect' || 'multiSelect' => _selectionValue(column, value),
        'url' || 'email' || 'phone' => _formattedValue(column['type'], value),
        'dateOnly' => WorkspaceExactValueValidation.date(value),
        'timestamp' => WorkspaceExactValueValidation.timestamp(value),
        'money' => WorkspaceExactValueValidation.money(value),
        _ => false,
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
