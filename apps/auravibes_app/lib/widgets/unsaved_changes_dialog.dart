import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';

abstract final class UnsavedChangesDialog {
  static const _title = TextLocale(LocaleKeys.common_unsaved_changes_title);
  static const _message = TextLocale(LocaleKeys.common_unsaved_changes_message);
  static const _actions = AuraConfirmDialogActions(
    confirmLabel: TextLocale(LocaleKeys.common_discard_changes),
    cancelLabel: TextLocale(LocaleKeys.common_keep_editing),
  );

  static Future<bool?> confirm(BuildContext context) => AuraDialogs.confirm(
    context: context,
    title: _title,
    message: _message,
    actions: _actions,
    isDestructive: true,
  );
}
