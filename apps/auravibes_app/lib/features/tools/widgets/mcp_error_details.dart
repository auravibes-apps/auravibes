import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/log_redaction.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Shows copyable, redacted MCP error details.
abstract final class McpErrorDetails {
  static Future<void> show(
    BuildContext context, {
    required String? groupName,
    required String? errorMessage,
  }) async {
    final details = _build(groupName: groupName, errorMessage: errorMessage);
    final shouldCopy = await _showDialog(context, details);
    if (shouldCopy != true) return;

    if (!await _copy(details)) return;
    if (!context.mounted) return;
    _showCopied(context);
  }

  static void _showCopied(BuildContext context) {
    final _ = AuraSnackBars.show(
      context: context,
      content: Text(LocaleKeys.tools_screen_mcp_error_details_copied.tr()),
      variant: .success,
    );
  }

  static Future<bool?> _showDialog(BuildContext context, String details) =>
      AuraDialogs.confirm(
        context: context,
        title: Text(LocaleKeys.tools_screen_mcp_error.tr()),
        message: AuraSelectableText(details),
        actions: _dialogActions(),
      );

  static AuraConfirmDialogActions _dialogActions() => .new(
    confirmLabel: Text(LocaleKeys.tools_screen_mcp_copy_error_details.tr()),
    cancelLabel: Text(LocaleKeys.common_close.tr()),
  );

  static Future<bool> _copy(String details) async {
    try {
      await Clipboard.setData(.new(text: details));
    } on Object {
      return false;
    }

    return true;
  }

  static String _build({
    required String? groupName,
    required String? errorMessage,
  }) {
    final serverLine = _serverLine(groupName);

    return [
      LocaleKeys.tools_screen_mcp_error.tr(),
      ?serverLine,
      _messageLine(errorMessage),
    ].join('\n');
  }

  static String? _serverLine(String? groupName) {
    final displayName = _textOrNull(groupName);
    if (displayName == null) return null;

    return '${LocaleKeys.tools_screen_mcp_server.tr()}: '
        '${LogRedaction.redact(displayName)}';
  }

  static String _messageLine(String? errorMessage) {
    final message =
        _textOrNull(errorMessage) ??
        LocaleKeys.tools_screen_mcp_unknown_error.tr();

    return '${LocaleKeys.tools_screen_mcp_message.tr()}: '
        '${LogRedaction.redact(message)}';
  }

  static String? _textOrNull(String? value) {
    final trimmed = value?.trim();

    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
