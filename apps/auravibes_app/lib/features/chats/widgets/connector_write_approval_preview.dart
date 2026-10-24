import 'dart:convert';

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:material_ui/material_ui.dart';

class const ConnectorWriteApprovalPreview({
  required final String argumentsRaw,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!connectorCommandMayWrite(argumentsRaw, connectorDefinitions)) {
      return const SizedBox.shrink();
    }
    final preview = _preview(argumentsRaw);

    return Column(
      crossAxisAlignment: .start,
      children: [
        const TextLocale(LocaleKeys.connector_write_approval),
        if (preview != null) ...[
          Text('${preview.method} ${preview.url}'),
          if (preview.body case final body?) Text(body),
        ],
      ],
    );
  }
}

ConnectorToolRequestPreview? _preview(String raw) {
  try {
    final decoded = jsonDecode(raw);

    return decoded is Map<String, dynamic> ? _render(decoded) : null;
  } on FormatException {
    return null;
  }
}

ConnectorToolRequestPreview? _render(Map<String, dynamic> arguments) {
  final inputs = arguments['args'];
  if (inputs is! Map<String, dynamic>) return null;
  final definition = connectorCommandTarget(
    arguments,
    connectorDefinitions,
  )?.definition;
  if (definition == null) return null;

  return renderConnectorToolRequestPreview(
    definition: definition,
    inputs: inputs,
  );
}
