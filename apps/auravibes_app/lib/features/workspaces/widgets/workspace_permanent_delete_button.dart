import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_history_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_history_panel.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_actions.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_trash_actions.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspacePermanentDeleteButton({
  required final String workspaceId,
  required final WorkspaceTrashTarget target,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = WorkspaceTableActions.use(context);
    return Column(
      mainAxisSize: .min,
      children: [
        AuraButton(
          identifier: 'workspace_permanent_delete_${target.id}',
          variant: .outlined,
          disabled: action.pending,
          isLoading: action.pending,
          onPressed: () => unawaited(action.run(() => _delete(context, ref))),
          child: const TextLocale(LocaleKeys.workspace_items_history_purge),
        ),
        if (action.error case final Object error)
          WorkspaceItemFailure(error: error),
      ],
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final usecase = await ref.read(
      workspaceHistoryUsecaseProvider(workspaceId).future,
    );
    if (!context.mounted) return;
    final deleted = await usecase.permanentlyDelete(
      target,
      approve: () => approveWorkspaceHistory(context, purge: true),
    );
    if (context.mounted && deleted) WorkspaceTrashActions.refresh(ref);
  }
}
