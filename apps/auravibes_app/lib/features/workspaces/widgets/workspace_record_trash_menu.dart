import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_history_panel.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_trash_actions.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceRecordTrashMenu({
  required final String workspaceId,
  required final WorkspaceRecord record,
  required final VoidCallback onTrashed,
  final bool canTrash = true,
  final VoidCallback? onRestored,
  super.key,
}) extends ConsumerWidget {
  WorkspaceTrashTarget get _target => .new(
    kind: .record,
    id: record.id,
    revision: record.revision,
    tableId: record.tableId,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraPopupMenuButton(
    items: [_history(context), if (canTrash) _trashItem(context, ref)],
    identifier: 'workspace_record_overflow',
    tooltip: LocaleKeys.common_show_more.tr(),
  );

  AuraPopupMenuItem _history(BuildContext context) => AuraPopupMenuItem(
    title: const TextLocale(LocaleKeys.workspace_items_history_title),
    onTap: () => unawaited(_openHistory(context)),
    identifier: 'workspace_record_history',
  );

  Future<void> _openHistory(BuildContext context) async {
    final restored = await WorkspaceHistoryPanel.open(context, (
      workspaceId: workspaceId,
      target: _target,
      canRestore: canTrash,
    ));
    if (context.mounted && restored == true) onRestored?.call();
  }

  AuraPopupMenuItem _trashItem(BuildContext context, WidgetRef ref) =>
      AuraPopupMenuItem(
        title: const TextLocale(LocaleKeys.workspace_items_trash_action),
        onTap: () => unawaited(_trash(context, ref)),
        variant: .error,
        identifier: 'workspace_record_trash',
      );

  Future<void> _trash(BuildContext context, WidgetRef ref) async {
    final deleted = await WorkspaceTrashActions.trash(
      context,
      ref,
      workspaceId,
      _target,
    );
    if (context.mounted && deleted) onTrashed();
  }
}
