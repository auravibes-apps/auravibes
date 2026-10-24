import 'dart:convert';

import 'package:auravibes_app/i18n/locale_keys.dart';

class const WorkspaceHistoryBlockedException(final List<String> resources)
    implements Exception {
  factory decode(String encoded) => .new(
    (jsonDecode(encoded) as List)
        .cast<Map<String, dynamic>>()
        .map(_label)
        .toList(),
  );
  String get localizationKey => LocaleKeys.workspace_items_history_blocked;
  @override
  String toString() => localizationKey;
}

String _label(Map<String, dynamic> resource) {
  final name = resource['name'];

  return name is String && name.isNotEmpty ? name : resource['id'] as String;
}
