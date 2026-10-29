import 'dart:convert';

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:material_ui/material_ui.dart';

class const ConnectorWriteResultNotice({
  required final String content,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final outcome = _outcome(content);
    if (outcome == null) return const SizedBox.shrink();

    return TextLocale(switch (outcome) {
      'completed' => LocaleKeys.connector_write_completed,
      'failed' => LocaleKeys.connector_write_failed,
      _ => LocaleKeys.connector_write_uncertain,
    });
  }
}

String? _outcome(String content) {
  try {
    final value = jsonDecode(content);
    if (value is! Map<String, dynamic> || value['kind'] != 'connectorWrite') {
      return null;
    }
    final outcome = value['outcome'];

    return outcome is String ? outcome : null;
  } on FormatException {
    return null;
  }
}
