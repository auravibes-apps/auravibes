import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

abstract final class WorkspaceHistoryApproval {
  static Future<bool> ask(BuildContext context, {required bool purge}) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => _RestoreApproval(purge: purge),
      ) ??
      false;

  static Future<bool> trashAction(
    BuildContext context, {
    required bool all,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => _ApprovalDialog(
          notice: all
              ? LocaleKeys.workspace_items_trash_delete_all_notice
              : LocaleKeys.workspace_items_trash_restore_notice,
          action: all
              ? LocaleKeys.workspace_items_trash_delete_all
              : LocaleKeys.workspace_items_trash_restore,
        ),
      ) ??
      false;

  static Future<bool> configure(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => const _ApprovalDialog(
          notice: LocaleKeys.workspace_items_history_policy_notice,
          action: LocaleKeys.common_save,
        ),
      ) ??
      false;

  static Future<bool> removeReportedContent(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => const _ApprovalDialog(
          notice: LocaleKeys.workspace_items_history_report_remove_notice,
          action: LocaleKeys.workspace_items_history_report_remove,
        ),
      ) ??
      false;
}

class const _ApprovalDialog({
  required final String notice,
  required final String action,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _ApprovalContent(notice: notice, action: action),
        ),
      ),
    ),
  );
}

class const _ApprovalContent({
  required final String notice,
  required final String action,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    children: [
      TextLocale(notice),
      _Approve(action: action),
      const _Cancel(),
    ],
  );
}

class const _Approve({required final String action}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => Navigator.of(context).pop(true),
    child: TextLocale(action),
    identifier: 'workspace_history_confirm',
  );
}

class const _Cancel() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => Navigator.of(context).pop(false),
    child: const TextLocale(LocaleKeys.common_cancel),
    variant: .ghost,
    identifier: 'workspace_history_cancel',
  );
}

class const _RestoreApproval({required final bool purge})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ApprovalDialog(
    notice: purge
        ? LocaleKeys.workspace_items_history_purge_notice
        : LocaleKeys.workspace_items_history_restore_notice,
    action: purge
        ? LocaleKeys.workspace_items_history_purge
        : LocaleKeys.workspace_items_history_restore,
  );
}
