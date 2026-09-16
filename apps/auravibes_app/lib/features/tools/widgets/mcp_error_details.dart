import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/log_redaction.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Shows copyable, redacted MCP error details.
Future<void> showMcpErrorDetails(
  BuildContext context, {
  required String? groupName,
  required String? errorMessage,
}) async {
  final details = _buildMcpErrorDetails(
    groupName: groupName,
    errorMessage: errorMessage,
  );
  final copyLabel = LocaleKeys.tools_screen_mcp_copy_error_details.tr();
  final closeLabel = LocaleKeys.common_close.tr();
  final shouldCopy = await AuraDialogs.confirm(
    context: context,
    title: Text(LocaleKeys.tools_screen_mcp_error.tr()),
    message: AuraSelectableText(details),
    actions: .new(confirmLabel: Text(copyLabel), cancelLabel: Text(closeLabel)),
  );
  if (shouldCopy != true) return;

  try {
    await Clipboard.setData(.new(text: details));
  } on Object {
    return;
  }
  if (!context.mounted) return;

  final _ = AuraSnackBars.show(
    context: context,
    content: Text(LocaleKeys.tools_screen_mcp_error_details_copied.tr()),
    variant: .success,
  );
}

String _buildMcpErrorDetails({
  required String? groupName,
  required String? errorMessage,
}) {
  final displayName = _textOrNull(groupName);
  final message =
      _textOrNull(errorMessage) ??
      LocaleKeys.tools_screen_mcp_unknown_error.tr();
  final serverLabel = LocaleKeys.tools_screen_mcp_server.tr();
  final messageLabel = LocaleKeys.tools_screen_mcp_message.tr();

  return [
    LocaleKeys.tools_screen_mcp_error.tr(),
    if (displayName != null)
      '$serverLabel: ${LogRedaction.redact(displayName)}',
    '$messageLabel: ${LogRedaction.redact(message)}',
  ].join('\n');
}

String? _textOrNull(String? value) {
  final trimmed = value?.trim();

  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
