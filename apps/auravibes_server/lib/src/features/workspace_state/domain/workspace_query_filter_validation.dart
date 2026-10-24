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
    if (operator == 'contains') {
      if (!{'text', 'email', 'url', 'phone'}.contains(column['type']) ||
          encoded.length > 16384) {
        throw const FormatException();
      }

      return;
    }
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
