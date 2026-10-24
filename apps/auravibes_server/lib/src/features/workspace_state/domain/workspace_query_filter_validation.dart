import 'dart:convert';

import 'workspace_table_validation.dart';

/// Typed filter inputs obey the persisted record value contract.
abstract final class WorkspaceQueryFilterValidation {
  static void validate(
    Map<String, dynamic> column,
    String encoded, {
    required String operator,
  }) {
    if (operator != 'equals' && operator != 'contains') {
      throw const FormatException();
    }
    switch (column['type']) {
      case 'reference':
        _reference(encoded, operator);
        return;
      case 'multiSelect':
        _multiple(column, encoded, operator);
        return;
    }
    _scalar(column, encoded, operator);
  }

  static void _reference(String encoded, String operator) {
    if (operator != 'equals' || encoded.isEmpty || encoded.length > 200) {
      throw const FormatException();
    }
  }

  static void _multiple(
    Map<String, dynamic> column,
    String encoded,
    String operator,
  ) {
    if (operator != 'contains' ||
        !(column['options'] as List<dynamic>).contains(encoded)) {
      throw const FormatException();
    }
  }

  static void _scalar(
    Map<String, dynamic> column,
    String encoded,
    String operator,
  ) {
    if (operator == 'contains') {
      if (!{'text', 'email', 'url', 'phone'}.contains(column['type']) ||
          encoded.length > 16384) {
        throw const FormatException();
      }

      return;
    }
    _exact(column, encoded);
  }

  static void _exact(Map<String, dynamic> column, String encoded) {
    final value = _value(column, encoded);
    WorkspaceTableValidation.values(
      {
        'columns': [column],
      },
      {
        column['id'] as String: value,
      },
    );
  }

  static Object? _value(Map<String, dynamic> column, String encoded) =>
      switch (column['type']) {
        'number' => num.tryParse(encoded),
        'checkbox' => switch (encoded) {
          'true' => true,
          'false' => false,
          _ => null,
        },
        'money' => jsonDecode(encoded),
        _ => encoded,
      };
}
