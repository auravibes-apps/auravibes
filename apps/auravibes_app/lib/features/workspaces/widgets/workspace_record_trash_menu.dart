import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
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
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraPopupMenuButton(
    items: [
      AuraPopupMenuItem(
        title: const TextLocale(LocaleKeys.workspace_items_history_title),
        onTap: () => unawaited(
          WorkspaceHistoryPanel.open(
            context,
            workspaceId,
            .new(
              kind: .record,
              id: record.id,
              tableId: record.tableId,
              revision: record.revision,
            ),
            canRestore: canTrash,
          ),
        ),
        identifier: 'workspace_record_history',
      ),
      if (canTrash)
        AuraPopupMenuItem(
          title: const TextLocale(LocaleKeys.workspace_items_trash_action),
          onTap: () => unawaited(_trash(context, ref)),
          variant: .error,
          identifier: 'workspace_record_trash',
        ),
    ],
    identifier: 'workspace_record_overflow',
    tooltip: LocaleKeys.common_show_more.tr(),
  );

  Future<void> _trash(BuildContext context, WidgetRef ref) async {
    final deleted = await WorkspaceTrashActions.trash(
      context,
      ref,
      workspaceId,
      .new(
        kind: .record,
        id: record.id,
        revision: record.revision,
        tableId: record.tableId,
      ),
    );
    if (context.mounted && deleted) onTrashed();
  }
}
